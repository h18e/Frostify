import CoreData
import Foundation
import UserNotifications
import os

/// Plant die lokalen Erinnerungen.
///
/// Bewusst ohne Server: Es sind lokale Mitteilungen, die jedes Geraet selbst plant.
/// Dadurch bekommt ihr beide eure Erinnerung, auch wenn nur eine Person etwas erfasst.
///
/// Die Sammelmeldung wird als **vier einzelne** Termine geplant statt als ein
/// wiederholender: Nur so kann der Text fuer jeden Termin die dann tatsaechlich
/// faelligen Produkte nennen. Bei jedem App-Start wird neu geplant.
@MainActor
final class NotificationScheduler {
    private static let logger = Logger(subsystem: "ch.hebera.frostify", category: "Notifications")
    private static let digestPrefix = "frostify.digest."
    private static let itemPrefix = "frostify.item."
    /// iOS erlaubt maximal 64 anstehende Mitteilungen pro App.
    private static let maxItemReminders = 40
    private static let plannedDigests = 4

    private let persistence: PersistenceController
    private let repository: InventoryRepositoryProtocol
    private let preferences: AppPreferences
    private let center: UNUserNotificationCenter

    private var pendingRefresh: Task<Void, Never>?
    private var saveObserver: NSObjectProtocol?

    /// Bewusst `nonisolated`: Der Aufruf kommt aus `FrostifyApp.init()`, und der ist
    /// nicht MainActor-markiert. Der Initialisierer beruehrt keinen isolierten Zustand.
    ///
    /// Der Beobachter ist absichtlich blockbasiert statt `#selector`: `@objc`-Methoden
    /// setzen eine NSObject-Unterklasse voraus, und die brauchen wir hier sonst nicht.
    nonisolated init(
        persistence: PersistenceController,
        repository: InventoryRepositoryProtocol,
        preferences: AppPreferences,
        center: UNUserNotificationCenter = .current()
    ) {
        self.persistence = persistence
        self.repository = repository
        self.preferences = preferences
        self.center = center

        saveObserver = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: persistence.viewContext,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.scheduleDebouncedRefresh() }
        }
    }

    deinit {
        if let saveObserver {
            NotificationCenter.default.removeObserver(saveObserver)
        }
    }

    /// Beim Erfassen folgen oft mehrere Speicherungen kurz hintereinander – deshalb
    /// wird nur die letzte tatsaechlich neu geplant.
    private func scheduleDebouncedRefresh() {
        pendingRefresh?.cancel()
        pendingRefresh = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    // MARK: - Planen

    func refresh() async {
        await removeAllFrostifyRequests()

        guard preferences.remindersEnabled else { return }
        guard await ensureAuthorization() else { return }

        let table = repository.shelfLifeTable
        let items = activeItems()

        scheduleDigests(items: items, table: table)
        if preferences.perItemRemindersEnabled {
            scheduleItemReminders(items: items, table: table)
        }
    }

    /// Fragt die Berechtigung an, falls noch nicht geschehen.
    @discardableResult
    func ensureAuthorization() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                Self.logger.error("Berechtigung fehlgeschlagen: \(error.localizedDescription)")
                return false
            }
        default:
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Intern

    private func activeItems() -> [Item] {
        let request = Item.fetchRequest()
        request.predicate = NSPredicate(format: "closedAt == nil")
        return (try? persistence.viewContext.fetch(request)) ?? []
    }

    private func scheduleDigests(items: [Item], table: ShelfLifeTable) {
        let calendar = Calendar.current
        let horizon = preferences.reminderHorizonDays

        for offset in 0..<Self.plannedDigests {
            guard let fireDate = nextDigestDate(weekOffset: offset, calendar: calendar) else { continue }
            guard let horizonEnd = calendar.date(byAdding: .day, value: horizon, to: fireDate) else { continue }

            let due = items.filter { item in
                let bestBefore = item.resolvedBestBefore(using: table)
                return bestBefore <= horizonEnd
            }
            guard !due.isEmpty else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Frostify"
            content.body = digestBody(count: due.count, horizon: horizon, names: due.prefix(3).map(\.displayName))
            content.sound = .default

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let request = UNNotificationRequest(
                identifier: "\(Self.digestPrefix)\(offset)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            center.add(request) { error in
                if let error { Self.logger.error("Sammelmeldung nicht geplant: \(error.localizedDescription)") }
            }
        }
    }

    private func digestBody(count: Int, horizon: Int, names: [String]) -> String {
        let lead = count == 1
            ? "1 Produkt louft i de nächschte \(horizon) Täg ab"
            : "\(count) Produkt loufe i de nächschte \(horizon) Täg ab"
        guard !names.isEmpty else { return lead + "." }
        let suffix = count > names.count ? " u wyteri" : ""
        return "\(lead): \(names.joined(separator: ", "))\(suffix)."
    }

    /// Naechster Termin fuer die Sammelmeldung, `weekOffset` Wochen in der Zukunft.
    private func nextDigestDate(weekOffset: Int, calendar: Calendar) -> Date? {
        var components = DateComponents()
        components.weekday = preferences.reminderWeekday
        components.hour = preferences.reminderHour
        components.minute = preferences.reminderMinute

        guard let first = calendar.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTime
        ) else { return nil }

        return calendar.date(byAdding: .weekOfYear, value: weekOffset, to: first)
    }

    private func scheduleItemReminders(items: [Item], table: ShelfLifeTable) {
        let calendar = Calendar.current
        let lead = preferences.perItemLeadDays

        let upcoming = items
            .compactMap { item -> (Item, Date)? in
                let bestBefore = item.resolvedBestBefore(using: table)
                guard let raw = calendar.date(byAdding: .day, value: -lead, to: bestBefore) else { return nil }
                var components = calendar.dateComponents([.year, .month, .day], from: raw)
                components.hour = 9
                components.minute = 0
                guard let fireDate = calendar.date(from: components), fireDate > Date() else { return nil }
                return (item, fireDate)
            }
            .sorted { $0.1 < $1.1 }
            .prefix(Self.maxItemReminders)

        for (item, fireDate) in upcoming {
            let content = UNMutableNotificationContent()
            content.title = "Bau fäuig"
            content.body = "\(item.displayName) louft i \(lead) Täg ab."
            content.sound = .default

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let request = UNNotificationRequest(
                identifier: "\(Self.itemPrefix)\(item.identifier.uuidString)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            center.add(request) { error in
                if let error { Self.logger.error("Einzelmeldung nicht geplant: \(error.localizedDescription)") }
            }
        }
    }

    private func removeAllFrostifyRequests() async {
        let pending = await center.pendingNotificationRequests()
        let identifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.digestPrefix) || $0.hasPrefix(Self.itemPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
