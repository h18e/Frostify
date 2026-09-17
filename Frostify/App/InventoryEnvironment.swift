import SwiftUI

private struct InventoryRepositoryKey: EnvironmentKey {
    /// Fuer SwiftUI-Vorschauen: ein Repository auf dem Arbeitsspeicher-Store.
    static let defaultValue: InventoryRepositoryProtocol = InventoryRepository(persistence: .preview)
}

extension EnvironmentValues {
    var inventory: InventoryRepositoryProtocol {
        get { self[InventoryRepositoryKey.self] }
        set { self[InventoryRepositoryKey.self] = newValue }
    }
}

private struct NotificationSchedulerKey: EnvironmentKey {
    /// In Vorschauen gibt es keinen Planer – die Views kommen mit `nil` zurecht.
    static let defaultValue: NotificationScheduler? = nil
}

extension EnvironmentValues {
    var notificationScheduler: NotificationScheduler? {
        get { self[NotificationSchedulerKey.self] }
        set { self[NotificationSchedulerKey.self] = newValue }
    }
}
