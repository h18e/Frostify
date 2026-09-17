import CloudKit
import CoreData
import Foundation
import os

/// Erstellt und verwaltet die CloudKit-Freigabe des Tiefkuehlers.
@MainActor
final class CloudSharingService: ObservableObject {
    private static let logger = Logger(subsystem: "ch.hebera.frostify", category: "Sharing")

    private let persistence: PersistenceController

    @Published private(set) var isWorking = false
    @Published var errorMessage: String?

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    var cloudContainer: CKContainer {
        CKContainer(identifier: PersistenceController.cloudKitContainerIdentifier)
    }

    /// `true`, wenn dieser Tiefkuehler dir gehoert (und nicht dir freigegeben wurde).
    func isOwner(of freezer: Freezer) -> Bool {
        !persistence.isShared(freezer)
    }

    func existingShare(for freezer: Freezer) -> CKShare? {
        persistence.existingShare(for: freezer)
    }

    /// Erzeugt die Freigabe.
    ///
    /// Die beiden Zeilen zu `publicPermission` und `persistUpdatedShare` sind der Kern:
    /// Ohne sie startet eine CloudKit-Freigabe mit `.none` und gilt ausschliesslich fuer
    /// namentlich eingeladene Personen – ein weitergeleiteter Link laeuft dann ins Leere,
    /// ohne dass irgendwo eine Fehlermeldung erscheint.
    func makeShare(for freezer: Freezer) async throws -> CKShare {
        guard let store = persistence.store(for: freezer) else {
            throw SharingError.sharedStoreUnavailable
        }

        isWorking = true
        defer { isWorking = false }

        let (_, share, _) = try await persistence.container.share([freezer], to: nil)
        share[CKShare.SystemFieldKey.title] = freezer.displayName as CKRecordValue
        share.publicPermission = .readWrite
        _ = try await persistence.container.persistUpdatedShare(share, in: store)
        Self.logger.info("Freigabe erstellt.")
        return share
    }

    /// Bestehende Freigabe holen oder eine neue erstellen.
    func shareOrCreate(for freezer: Freezer) async -> CKShare? {
        if let existing = existingShare(for: freezer) { return existing }
        do {
            return try await makeShare(for: freezer)
        } catch {
            Self.logger.error("Freigabe fehlgeschlagen: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
