import SwiftUI

private struct InventoryRepositoryKey: EnvironmentKey {
    /// Fuer SwiftUI-Vorschauen: ein Repository auf dem Arbeitsspeicher-Store.
    ///
    /// SwiftUI greift auf diesen Standardwert auch dann zu, wenn die App laengst ein
    /// echtes Repository gesetzt hat. Dabei entsteht ein zweiter Core-Data-Stack.
    /// Das ist unschaedlich, weil alle Stacks dasselbe Modell benutzen
    /// (siehe `PersistenceController.managedObjectModel`) – vorher war genau das
    /// die Ursache eines Absturzes beim ersten Start.
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
