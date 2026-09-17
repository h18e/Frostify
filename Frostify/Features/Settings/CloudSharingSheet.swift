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

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        return controller
    }

    func updateUIViewController(_ controller: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(title: title, onFinish: onFinish)
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        private let title: String
        private let onFinish: (() -> Void)?

        init(title: String, onFinish: (() -> Void)?) {
            self.title = title
            self.onFinish = onFinish
        }

        func itemTitle(for csc: UICloudSharingController) -> String? { title }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
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
