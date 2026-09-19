import CloudKit
import CoreData
import Foundation
import os

extension Notification.Name {
    /// Wird nach der Annahme einer Freigabe gesendet, damit die Oberflaeche reagieren kann.
    static let frostifyDidAcceptShare = Notification.Name("ch.hebera.frostify.didAcceptShare")
}

/// Nimmt eine CloudKit-Freigabe an.
///
/// Wichtig: Der Einstiegspunkt dafuer ist `windowScene(_:userDidAcceptCloudKitShareWith:)`
/// im SceneDelegate. Bei einer SwiftUI-App reicht die aeltere AppDelegate-Variante nicht –
/// die Annahme verpufft dann lautlos, ohne Fehlermeldung.
enum ShareAcceptance {
    private static let logger = Logger(subsystem: "ch.hebera.frostify", category: "Sharing")

    static func accept(_ metadata: CKShare.Metadata, persistence: PersistenceController = .shared) {
        guard let sharedStore = persistence.sharedStore else {
            logger.error("Freigabe kann nicht angenommen werden: Der Shared-Store ist nicht geladen.")
            post(error: SharingError.sharedStoreUnavailable)
            return
        }

        persistence.container.acceptShareInvitations(from: [metadata], into: sharedStore) { _, error in
            if let error {
                logger.error("Freigabe abgelehnt: \(error.localizedDescription)")
                post(error: error)
            } else {
                logger.info("Freigabe angenommen.")
                post(error: nil)
            }
        }
    }

    private static func post(error: Error?) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .frostifyDidAcceptShare,
                object: nil,
                userInfo: error.map { ["error": $0] }
            )
        }
    }
}

enum SharingError: LocalizedError {
    case sharedStoreUnavailable
    case noCloudAccount
    case shareCreationFailed
    /// Nur wer den Tiefkuehler angelegt hat, kann die Reichweite des Links aendern.
    case notOwner
    /// iCloud hat noch keinen Link geliefert (z. B. kein Netz beim Speichern).
    case linkUnavailable

    var errorDescription: String? {
        switch self {
        case .sharedStoreUnavailable:
            return "Dr teilt Bereich het sech nid la lade. Lueg, öb du i de iOS-Istellige bi iCloud aagmäudet bisch."
        case .noCloudAccount:
            return "Zum Teile muesch i de iOS-Istellige bi iCloud aagmäudet si."
        case .shareCreationFailed:
            return "D Iiladig het sech nid la erstelle. Probier's speter nomau."
        case .notOwner:
            return "Nume wär dr Tiefchüeler aagleit het, cha dr Link freischaute."
        case .linkUnavailable:
            return "iCloud het no kei Link glieferet. Lueg, öb du Netz hesch, u probier's nomau."
        }
    }
}
