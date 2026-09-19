import CloudKit
import CoreData
import Foundation
import os

/// Erstellt und verwaltet die CloudKit-Freigabe des Tiefkuehlers.
///
/// ## Zwei Wege, und warum es beide braucht
///
/// **Einladung verwalten** oeffnet Apples `UICloudSharingController`. Dort sieht
/// man Teilnehmer, kann Leute namentlich einladen und die Freigabe beenden.
///
/// **Link verschicken** erzeugt einen Link, den **jede Person mit dem Link**
/// benutzen kann. Das ist ein eigener Weg, weil ein frisch erstellter `CKShare`
/// auf `publicPermission = .none` steht: Herein kommt dann nur, wer vorher
/// namentlich eingetragen wurde. So ein Link ist technisch gueltig, aber fuer
/// niemanden freigeschaltet – beim Empfaenger endet er mit
///
///   „Objekt nicht verfügbar. Die Person, der die Datei gehört, teilt diese nicht
///    mehr oder dein Account ist nicht berechtigt, sie zu öffnen."
///
/// Fuer einen weiterschickbaren Link muss die Reichweite deshalb ausdruecklich auf
/// `.readWrite` gesetzt **und** nach iCloud gespeichert werden. Das Setzen allein
/// genuegt nicht: Es aendert nur die lokale Kopie. `persistUpdatedShare(_:in:)`
/// schreibt sie zum Server – und liefert die aktualisierte Fassung zurueck, aus der
/// dann die gueltige URL stammt.
@MainActor
final class CloudSharingService: ObservableObject {
    private static let logger = Logger(subsystem: "ch.hebera.frostify", category: "Sharing")

    private let persistence: PersistenceController

    @Published private(set) var isPreparingLink = false
    @Published private(set) var isPreparingInvitation = false
    @Published var errorMessage: String?

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    var cloudContainer: CKContainer {
        CKContainer(identifier: PersistenceController.cloudKitContainerIdentifier)
    }

    // MARK: - Zustand

    /// `true`, wenn dieser Tiefkuehler dir gehoert (und nicht dir freigegeben wurde).
    func isOwner(of freezer: Freezer) -> Bool {
        !persistence.isShared(freezer)
    }

    func existingShare(for freezer: Freezer) -> CKShare? {
        persistence.existingShare(for: freezer)
    }

    /// Steht der Link allen offen, oder nur namentlich eingeladenen Personen?
    func linkIsOpen(for freezer: Freezer) -> Bool {
        existingShare(for: freezer)?.publicPermission == .readWrite
    }

    // MARK: - Freigabe erstellen

    /// Erzeugt die Freigabe oder holt die bestehende.
    ///
    /// Die Reichweite wird hier bewusst **nicht** erzwungen: In Apples
    /// Freigabe-Oberflaeche entscheidet die Person selbst zwischen „nur
    /// eingeladene Personen" und „jede Person mit dem Link". Wer einen Link zum
    /// Weiterschicken will, nimmt `makeLinkShare(for:)`.
    func makeShare(for freezer: Freezer) async throws -> CKShare {
        // Vor dem Teilen alles sichern, sonst wandern noch nicht gespeicherte
        // Eintraege nicht in die geteilte Zone.
        persistence.save()

        if let existing = existingShare(for: freezer) { return existing }

        // Den Titel vorher auslesen: Nach dem `await` sollte kein NSManagedObject
        // mehr angefasst werden.
        let title = freezer.displayName
        let (_, share, _) = try await persistence.container.share([freezer], to: nil)
        share[CKShare.SystemFieldKey.title] = title as CKRecordValue
        Self.logger.info("Freigabe erstellt.")
        return share
    }

    /// Schaltet den Link fuer alle frei und liefert ihn zurueck.
    func makeLinkShare(for freezer: Freezer) async throws -> URL {
        guard isOwner(of: freezer) else { throw SharingError.notOwner }
        guard let privateStore = persistence.privateStore else {
            throw SharingError.sharedStoreUnavailable
        }

        isPreparingLink = true
        defer { isPreparingLink = false }

        let share = try await makeShare(for: freezer)
        share.publicPermission = .readWrite

        let updated = try await persistence.container.persistUpdatedShare(share, in: privateStore)
        guard let url = updated.url else { throw SharingError.linkUnavailable }
        Self.logger.info("Einladungs-Link freigeschaltet.")
        return url
    }

    /// Bestehende Freigabe holen oder eine neue erstellen – fuer die Verwaltung.
    func invitationShare(for freezer: Freezer) async -> CKShare? {
        isPreparingInvitation = true
        defer { isPreparingInvitation = false }
        do {
            return try await makeShare(for: freezer)
        } catch {
            Self.logger.error("Freigabe fehlgeschlagen: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func prepareLink(for freezer: Freezer) async -> URL? {
        do {
            return try await makeLinkShare(for: freezer)
        } catch {
            Self.logger.error("Link fehlgeschlagen: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            return nil
        }
    }

    // MARK: - Freigabe beenden

    /// Hebt die Freigabe auf. Beim Besitzer wird sie geloescht, beim Teilnehmer
    /// entfernt sich dieser selbst daraus.
    func stopSharing(_ freezer: Freezer) async {
        guard let share = existingShare(for: freezer) else { return }
        let database = isOwner(of: freezer)
            ? cloudContainer.privateCloudDatabase
            : cloudContainer.sharedCloudDatabase
        do {
            _ = try await database.deleteRecord(withID: share.recordID)
            Self.logger.info("Freigabe beendet.")
        } catch {
            Self.logger.error("Freigabe beenden fehlgeschlagen: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
}
