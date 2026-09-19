import CloudKit
import SwiftUI
import UIKit

/// Apples Standard-Dialog zum Einladen, Rechte setzen und Beenden einer Freigabe.
/// SwiftUI hat dafuer keine Entsprechung, deshalb der Umweg ueber UIKit.
struct CloudSharingSheet: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let title: String
    var onFinish: (() -> Void)?
    var onFailed: ((Error) -> Void)?

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        // Alle Beteiligten duerfen erfassen und bearbeiten (`allowReadWrite`).
        //
        // Bei der Reichweite hat die Person die Wahl:
        // * `allowPrivate` – nur namentlich eingeladene Apple-Accounts
        // * `allowPublic`  – jede Person, die den Link hat, kann beitreten
        //
        // `allowPublic` muss hier stehen. Fehlt es, bietet der Dialog die Option
        // gar nicht an und speichert die Freigabe als „nur eingeladene Personen" –
        // ein weitergeschickter Link laeuft dann beim Empfaenger ins Leere.
        controller.availablePermissions = [.allowReadWrite, .allowPrivate, .allowPublic]
        controller.modalPresentationStyle = .formSheet
        return controller
    }

    func updateUIViewController(_ controller: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(title: title, onFinish: onFinish, onFailed: onFailed)
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        private let title: String
        private let onFinish: (() -> Void)?
        private let onFailed: ((Error) -> Void)?

        init(title: String, onFinish: (() -> Void)?, onFailed: ((Error) -> Void)?) {
            self.title = title
            self.onFinish = onFinish
            self.onFailed = onFailed
        }

        func itemTitle(for csc: UICloudSharingController) -> String? { title }

        func itemType(for csc: UICloudSharingController) -> String? { nil }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            onFailed?(error)
            onFinish?()
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            onFinish?()
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            onFinish?()
        }
    }
}
