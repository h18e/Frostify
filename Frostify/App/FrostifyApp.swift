import CoreData
import SwiftUI

@main
struct FrostifyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var preferences = AppPreferences.shared
    @Environment(\.scenePhase) private var scenePhase

    private let persistence = PersistenceController.shared
    private let repository: InventoryRepositoryProtocol
    private let notificationScheduler: NotificationScheduler

    init() {
        let persistence = PersistenceController.shared
        let repository = InventoryRepository(persistence: persistence)
        self.repository = repository
        self.notificationScheduler = NotificationScheduler(
            persistence: persistence,
            repository: repository,
            preferences: AppPreferences.shared
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView(loadError: persistence.loadError)
                .environment(\.managedObjectContext, persistence.viewContext)
                .environment(\.inventory, repository)
                .environmentObject(preferences)
                .environment(\.notificationScheduler, notificationScheduler)
                .task {
                    // Beim Start neu planen: die Sammelmeldung nennt eine Anzahl, die
                    // sich seit dem letzten Planen geaendert haben kann.
                    await notificationScheduler.refresh()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await notificationScheduler.refresh() }
            }
        }
    }
}
