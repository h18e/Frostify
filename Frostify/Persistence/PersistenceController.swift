import CloudKit
import CoreData
import Foundation
import os

/// Haelt den Core-Data-Stack mit **zwei** Stores:
///
/// - `private.sqlite`  → deine eigenen Tiefkuehler (CloudKit-Bereich `.private`)
/// - `shared.sqlite`   → Tiefkuehler, die dir jemand freigegeben hat (Bereich `.shared`)
///
/// Beide haengen am selben CloudKit-Container. Diese Trennung ist Pflicht: CloudKit
/// liefert freigegebene Daten ausschliesslich ueber den Shared-Bereich aus, und ein
/// einzelner Store kann nicht beide Bereiche bedienen.
final class PersistenceController {
    static let shared = PersistenceController()

    /// Muss mit dem Eintrag in Config/Frostify.entitlements uebereinstimmen.
    static let cloudKitContainerIdentifier = "iCloud.ch.hebera.frostify"

    private static let logger = Logger(subsystem: "ch.hebera.frostify", category: "Persistence")

    /// Das Datenmodell wird genau **einmal** geladen und von allen Containern geteilt.
    ///
    /// `NSPersistentCloudKitContainer(name:)` laedt sonst fuer jeden Container eine
    /// eigene Kopie des Modells. Es gibt dann zwei `NSEntityDescription`-Objekte, die
    /// beide "Freezer" heissen, und Core Data kann der Klasse `Freezer` keine
    /// eindeutige Entitaet mehr zuordnen. Die Folge ist die auf den ersten Blick
    /// unsinnige Meldung "Unacceptable type of value for to-one relationship:
    /// desired type = Freezer; given type = Freezer" – gleicher Name, verschiedene
    /// Objekte. Mit einem geteilten Modell kann das nicht mehr passieren, egal wie
    /// viele Container es gibt (App-Stack, Vorschau-Stack, Tests).
    private static let managedObjectModel: NSManagedObjectModel = {
        if let url = Bundle.main.url(forResource: "Frostify", withExtension: "momd"),
           let model = NSManagedObjectModel(contentsOf: url) {
            return model
        }
        if let model = NSManagedObjectModel.mergedModel(from: [Bundle.main]) {
            logger.warning("Modell ueber mergedModel geladen – 'Frostify.momd' wurde nicht gefunden.")
            return model
        }
        fatalError("Frostify: Das Core-Data-Modell 'Frostify.momd' liegt nicht im App-Bundle.")
    }()

    let container: NSPersistentCloudKitContainer
    private(set) var privateStore: NSPersistentStore?
    private(set) var sharedStore: NSPersistentStore?

    /// `true`, wenn die Stores geladen werden konnten. Bei `false` laeuft die App in
    /// einem klar erkennbaren Fehlerzustand weiter, statt still zu stuerzen.
    private(set) var loadError: Error?

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(
            name: "Frostify",
            managedObjectModel: Self.managedObjectModel
        )

        guard let privateDescription = container.persistentStoreDescriptions.first else {
            fatalError("Frostify: Der Core-Data-Stack hat keine Store-Beschreibung – das Modell fehlt.")
        }

        if inMemory {
            privateDescription.url = URL(fileURLWithPath: "/dev/null")
            privateDescription.cloudKitContainerOptions = nil
            container.persistentStoreDescriptions = [privateDescription]
        } else {
            let directory = privateDescription.url?.deletingLastPathComponent()
                ?? NSPersistentContainer.defaultDirectoryURL()

            privateDescription.url = directory.appendingPathComponent("private.sqlite")
            Self.enableHistoryTracking(on: privateDescription)
            let privateOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: Self.cloudKitContainerIdentifier
            )
            privateOptions.databaseScope = .private
            privateDescription.cloudKitContainerOptions = privateOptions

            guard let sharedDescription = privateDescription.copy() as? NSPersistentStoreDescription else {
                fatalError("Frostify: Die Store-Beschreibung liess sich nicht kopieren.")
            }
            sharedDescription.url = directory.appendingPathComponent("shared.sqlite")
            let sharedOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: Self.cloudKitContainerIdentifier
            )
            sharedOptions.databaseScope = .shared
            sharedDescription.cloudKitContainerOptions = sharedOptions

            container.persistentStoreDescriptions = [privateDescription, sharedDescription]
        }

        container.loadPersistentStores { [weak self] description, error in
            if let error {
                Self.logger.error("Store \(description.url?.lastPathComponent ?? "?") nicht geladen: \(error.localizedDescription)")
                self?.loadError = error
                return
            }
            guard let url = description.url,
                  let store = self?.container.persistentStoreCoordinator.persistentStore(for: url)
            else { return }

            switch description.cloudKitContainerOptions?.databaseScope {
            case .shared: self?.sharedStore = store
            default: self?.privateStore = store
            }
        }

        viewContext.automaticallyMergesChangesFromParent = true
        // Feldweise "letzte Aenderung gewinnt". Der kritische Fall – gleichzeitige
        // Entnahmen – ist durch das Event-Modell entschaerft, nicht durch diese Regel.
        viewContext.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        viewContext.transactionAuthor = "app"
        viewContext.name = "viewContext"
    }

    private static func enableHistoryTracking(on description: NSPersistentStoreDescription) {
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(
            true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
        )
    }

    // MARK: - Speichern

    func save() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
            Self.logger.error("Speichern fehlgeschlagen: \(error.localizedDescription)")
        }
    }

    // MARK: - Freigabe-Zustand

    /// In welchem Store liegt das Objekt? Neue Objekte muessen demselben Store zugewiesen
    /// werden wie ihr Tiefkuehler, sonst lehnt Core Data die Beziehung ab.
    func store(for object: NSManagedObject) -> NSPersistentStore? {
        object.objectID.persistentStore
    }

    /// Gehoert das Objekt zu einem Tiefkuehler, den jemand mit dir geteilt hat?
    func isShared(_ object: NSManagedObject) -> Bool {
        guard let sharedStore else { return false }
        return object.objectID.persistentStore === sharedStore
    }

    /// Darf dieses Geraet das Objekt aendern? Bei einer Freigabe mit Nur-Lese-Recht `false`.
    func canEdit(_ object: NSManagedObject) -> Bool {
        container.canUpdateRecord(forManagedObjectWith: object.objectID)
    }

    func existingShare(for object: NSManagedObject) -> CKShare? {
        let shares = try? container.fetchShares(matching: [object.objectID])
        return shares?[object.objectID]
    }

    // MARK: - Einrichtung

    #if DEBUG
    /// Legt das CloudKit-Schema in der Development-Umgebung an.
    ///
    /// Einmal nach dem ersten Start ausfuehren (Einstellungen → Entwicklung), damit die
    /// Record-Typen im CloudKit-Dashboard erscheinen und spaeter nach Production
    /// uebertragen werden koennen.
    func initializeCloudKitSchema() throws {
        try container.initializeCloudKitSchema(options: [])
    }
    #endif
}
