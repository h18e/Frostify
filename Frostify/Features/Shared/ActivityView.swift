import SwiftUI
import UIKit

/// Das Teilen-Blatt von iOS – zum Weiterschicken des Einladungs-Links über
/// Nachrichten, WhatsApp, Mail und so weiter.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
