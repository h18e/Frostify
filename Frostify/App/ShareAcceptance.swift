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

    var errorDescription: String? {
        switch self {
        case .sharedStoreUnavailable:
            return "Der geteilte Bereich konnte nicht geladen werden. Prüfe, ob du in den iOS-Einstellungen bei iCloud angemeldet bist."
        case .noCloudAccount:
            return "Für das Teilen musst du in den iOS-Einstellungen bei iCloud angemeldet sein."
        case .shareCreationFailed:
            return "Die Einladung konnte nicht erstellt werden. Versuch es später nochmals."
        }
    }
}
