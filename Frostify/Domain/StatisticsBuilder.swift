import Foundation

/// Eingabe fuer die Statistik – bewusst ein einfacher Wert ohne Core-Data-Bezug,
/// damit die Auswertung ohne Datenbank getestet werden kann.
struct ClosedItemSnapshot: Equatable, Sendable {
    var category: FoodCategory
    var frozenAt: Date
    var closedAt: Date
    var closeReason: ConsumptionKind
    var initialQuantity: Double
    var unit: StorageUnit
    var discardedQuantity: Double

    init(
        category: FoodCategory,
        frozenAt: Date,
        closedAt: Date,
        closeReason: ConsumptionKind,
        initialQuantity: Double = 0,
        unit: StorageUnit = .piece,
        discardedQuantity: Double = 0
    ) {
        self.category = category
        self.frozenAt = frozenAt
        self.closedAt = closedAt
        self.closeReason = closeReason
        self.initialQuantity = initialQuantity
        self.unit = unit
        self.discardedQuantity = discardedQuantity
    }
}

struct CategoryStatistics: Identifiable, Equatable, Sendable {
    var category: FoodCategory
    var closedCount: Int
    var discardedCount: Int
    var averageStorageDays: Int?

    var id: String { category.rawValue }

    /// Anteil weggeworfener Eintraege, 0…1.
    var discardRate: Double {
        closedCount > 0 ? Double(discardedCount) / Double(closedCount) : 0
    }
}

struct InventoryStatistics: Equatable, Sendable {
    var closedCount: Int
    var discardedCount: Int
    var averageStorageDays: Int?
    var perCategory: [CategoryStatistics]

    var discardRate: Double {
        closedCount > 0 ? Double(discardedCount) / Double(closedCount) : 0
    }

    static let empty = InventoryStatistics(
        closedCount: 0, discardedCount: 0, averageStorageDays: nil, perCategory: []
    )
}

/// Wertet abgeschlossene Eintraege aus: wie lange lagert ihr was, und wo geht am
/// meisten verloren. Die Zahlen sind die Grundlage, um die Haltbarkeits-Richtwerte
/// spaeter gezielt zu justieren.
enum StatisticsBuilder {
    static func build(from snapshots: [ClosedItemSnapshot], calendar: Calendar = .current) -> InventoryStatistics {
        guard !snapshots.isEmpty else { return .empty }

        let grouped = Dictionary(grouping: snapshots, by: \.category)
        let perCategory = grouped
            .map { category, items in
                CategoryStatistics(
                    category: category,
                    closedCount: items.count,
                    discardedCount: items.filter { $0.closeReason == .discarded }.count,
                    averageStorageDays: averageStorageDays(items, calendar: calendar)
                )
            }
            .sorted { lhs, rhs in
                if lhs.discardedCount != rhs.discardedCount { return lhs.discardedCount > rhs.discardedCount }
                return lhs.category.displayName < rhs.category.displayName
            }

        return InventoryStatistics(
            closedCount: snapshots.count,
            discardedCount: snapshots.filter { $0.closeReason == .discarded }.count,
            averageStorageDays: averageStorageDays(snapshots, calendar: calendar),
            perCategory: perCategory
        )
    }

    static func storageDays(from frozenAt: Date, to closedAt: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: frozenAt)
        let end = calendar.startOfDay(for: closedAt)
        return max(0, calendar.dateComponents([.day], from: start, to: end).day ?? 0)
    }

    private static func averageStorageDays(_ items: [ClosedItemSnapshot], calendar: Calendar) -> Int? {
        guard !items.isEmpty else { return nil }
        let total = items.reduce(0) { $0 + storageDays(from: $1.frozenAt, to: $1.closedAt, calendar: calendar) }
        return Int((Double(total) / Double(items.count)).rounded())
    }
}
