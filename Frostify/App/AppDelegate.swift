import CloudKit
import UIKit
import UserNotifications

/// Wird per `@UIApplicationDelegateAdaptor` an die SwiftUI-App gehaengt.
///
/// Zweck: Fernmitteilungen fuer den CloudKit-Abgleich anmelden und – ueber den
/// SceneDelegate – die Annahme von Freigabe-Links ermoeglichen.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Ohne diese Anmeldung schickt CloudKit keine stillen Mitteilungen, und
        // Aenderungen der Partnerin kaemen erst beim naechsten App-Start an.
        application.registerForRemoteNotifications()
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Der NSPersistentCloudKitContainer verarbeitet die Mitteilung selbst;
        // hier wird nur bestaetigt, dass sie angekommen ist.
        completionHandler(.newData)
    }
}

/// Der SceneDelegate erzeugt bewusst **kein** eigenes Fenster – das macht SwiftUI.
/// Er existiert nur, damit iOS die Annahme einer CloudKit-Freigabe hier ausliefern kann.
final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        ShareAcceptance.accept(cloudKitShareMetadata)
    }
}

/// Zeigt Erinnerungen auch an, wenn die App gerade offen ist.
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresenter()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
