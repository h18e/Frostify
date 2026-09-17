import Foundation

/// Haltbarkeits-Richtwerte je Kategorie, inklusive der Abweichungen, die ihr in den
/// Einstellungen setzt. Die Abweichungen liegen am Tiefkuehler und gelten damit fuer
/// beide Teilnehmer.
struct ShelfLifeTable: Equatable, Sendable {
    private var overrides: [String: Int]

    init(overrides: [String: Int] = [:]) {
        self.overrides = overrides
    }

    /// Liest die in Core Data als JSON abgelegten Abweichungen.
    /// Ungueltiger Inhalt fuehrt bewusst zu den Standardwerten statt zu einem Absturz.
    init(json: String?) {
        guard let json, !json.isEmpty,
              let data = json.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data)
        else {
            self.overrides = [:]
            return
        }
        self.overrides = decoded
    }

    var json: String {
        guard let data = try? JSONEncoder().encode(overrides),
              let string = String(data: data, encoding: .utf8)
        else { return "" }
        return string
    }

    func months(for category: FoodCategory) -> Int {
        overrides[category.rawValue] ?? category.defaultShelfLifeMonths
    }

    func isOverridden(_ category: FoodCategory) -> Bool {
        overrides[category.rawValue] != nil
    }

    mutating func set(months: Int, for category: FoodCategory) {
        if months == category.defaultShelfLifeMonths {
            overrides.removeValue(forKey: category.rawValue)
        } else {
            overrides[category.rawValue] = max(1, min(60, months))
        }
    }

    mutating func reset(_ category: FoodCategory) {
        overrides.removeValue(forKey: category.rawValue)
    }

    mutating func resetAll() {
        overrides.removeAll()
    }
}
