import Foundation
import SwiftUI
import UIKit

/// Geraetelokale Einstellungen.
///
/// Bewusst **nicht** in CloudKit: Erinnerungen sind lokale Benachrichtigungen, die jedes
/// Geraet selbst plant, und Anzeigevorlieben sind Geschmackssache. Gemeinsam gilt nur,
/// was am Tiefkuehler haengt – die Haltbarkeits-Richtwerte.
final class AppPreferences: ObservableObject {
    static let shared = AppPreferences()

    private enum Key {
        static let displayName = "frostify.displayName"
        static let remindersEnabled = "frostify.remindersEnabled"
        static let reminderWeekday = "frostify.reminderWeekday"
        static let reminderHour = "frostify.reminderHour"
        static let reminderMinute = "frostify.reminderMinute"
        static let reminderHorizonDays = "frostify.reminderHorizonDays"
        static let perItemRemindersEnabled = "frostify.perItemRemindersEnabled"
        static let perItemLeadDays = "frostify.perItemLeadDays"
        static let usesOpenFoodFacts = "frostify.usesOpenFoodFacts"
        static let grouping = "frostify.grouping"
        static let sorting = "frostify.sorting"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.remindersEnabled: true,
            Key.reminderWeekday: 1,      // 1 = Sonntag (Calendar-Zaehlweise)
            Key.reminderHour: 18,
            Key.reminderMinute: 0,
            Key.reminderHorizonDays: 14,
            Key.perItemRemindersEnabled: false,
            Key.perItemLeadDays: 3,
            Key.usesOpenFoodFacts: true
        ])
    }

    private func set<T>(_ value: T, for key: String) {
        objectWillChange.send()
        defaults.set(value, forKey: key)
    }

    /// Wird an jedem erfassten Eintrag und jeder Entnahme vermerkt, damit ihr seht,
    /// wer was gemacht hat. `UIDevice.name` liefert ohne Sonderberechtigung nur den
    /// Geraetetyp, deshalb ist der Name frei aenderbar.
    var displayName: String {
        get {
            let stored = defaults.string(forKey: Key.displayName) ?? ""
            return stored.isEmpty ? UIDevice.current.name : stored
        }
        set { set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), for: Key.displayName) }
    }

    var remindersEnabled: Bool {
        get { defaults.bool(forKey: Key.remindersEnabled) }
        set { set(newValue, for: Key.remindersEnabled) }
    }

    /// 1 = Sonntag … 7 = Samstag.
    var reminderWeekday: Int {
        get { defaults.integer(forKey: Key.reminderWeekday) }
        set { set(min(7, max(1, newValue)), for: Key.reminderWeekday) }
    }

    var reminderHour: Int {
        get { defaults.integer(forKey: Key.reminderHour) }
        set { set(min(23, max(0, newValue)), for: Key.reminderHour) }
    }

    var reminderMinute: Int {
        get { defaults.integer(forKey: Key.reminderMinute) }
        set { set(min(59, max(0, newValue)), for: Key.reminderMinute) }
    }

    /// Wie weit die woechentliche Sammelmeldung nach vorne schaut.
    var reminderHorizonDays: Int {
        get { defaults.integer(forKey: Key.reminderHorizonDays) }
        set { set(min(60, max(1, newValue)), for: Key.reminderHorizonDays) }
    }

    var perItemRemindersEnabled: Bool {
        get { defaults.bool(forKey: Key.perItemRemindersEnabled) }
        set { set(newValue, for: Key.perItemRemindersEnabled) }
    }

    var perItemLeadDays: Int {
        get { defaults.integer(forKey: Key.perItemLeadDays) }
        set { set(min(30, max(1, newValue)), for: Key.perItemLeadDays) }
    }

    /// Darf beim Scannen eines unbekannten Codes Open Food Facts gefragt werden?
    ///
    /// Der eigene Katalog wird immer zuerst durchsucht; diese Einstellung
    /// betrifft nur den Rueckfall ins Netz.
    var usesOpenFoodFacts: Bool {
        get { defaults.bool(forKey: Key.usesOpenFoodFacts) }
        set { set(newValue, for: Key.usesOpenFoodFacts) }
    }

    var grouping: InventoryGrouping {
        get { InventoryGrouping(rawValue: defaults.string(forKey: Key.grouping) ?? "") ?? .expiry }
        set { set(newValue.rawValue, for: Key.grouping) }
    }

    var sorting: InventorySorting {
        get { InventorySorting(rawValue: defaults.string(forKey: Key.sorting) ?? "") ?? .bestBefore }
        set { set(newValue.rawValue, for: Key.sorting) }
    }

    var reminderTimeDescription: String {
        return String(format: "%@, %02d:%02d Uhr", Weekday.name(reminderWeekday), reminderHour, reminderMinute)
    }
}
