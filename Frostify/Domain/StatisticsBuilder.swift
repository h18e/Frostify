import Foundation

/// Eine einzelne Entnahme – die Grundeinheit der Auswertung.
///
/// Bewusst je Entnahme und **nicht** je Eintrag: Wer eine von zwei Portionen isst
/// und die zweite wegwirft, hat eine Portion gegessen und eine weggeworfen. Eine
/// Auswertung, die nur den abgeschlossenen Eintrag zaehlt, kann das nicht abbilden –
/// sie müsste sich für „gegessen" oder „weggeworfen" entscheiden und verlöre die
/// andere Hälfte.
struct ConsumptionSnapshot: Equatable, Sendable {
    var category: FoodCategory
    var date: Date
    var kind: ConsumptionKind
    /// Anteil des ursprünglichen Eintrags, den diese Entnahme ausmacht (0…1).
    ///
    /// Macht Mengen über Einheiten hinweg vergleichbar: 200 g von 400 g und
    /// 1 Beutel von 2 Beuteln sind beide 0,5.
    var share: Double

    init(category: FoodCategory, date: Date, kind: ConsumptionKind, share: Double) {
        self.category = category
        self.date = date
        self.kind = kind
        self.share = min(1, max(0, share))
    }
}

/// Ein abgeschlossener Eintrag – nur noch für die Lagerdauer gebraucht.
struct ClosedItemSnapshot: Equatable, Sendable {
    var category: FoodCategory
    var frozenAt: Date
    var closedAt: Date
}

struct CategoryStatistics: Identifiable, Equatable, Sendable {
    var category: FoodCategory
    var consumedCount: Int
    var discardedCount: Int
    var consumedShare: Double
    var discardedShare: Double
    var averageStorageDays: Int?

    var id: String { category.rawValue }

    var eventCount: Int { consumedCount + discardedCount }
    var totalShare: Double { consumedShare + discardedShare }

    /// Anteil der weggeworfenen Menge an der gesamten entnommenen Menge, 0…1.
    var discardRate: Double {
        totalShare > 0.0001 ? discardedShare / totalShare : 0
    }
}

struct InventoryStatistics: Equatable, Sendable {
    var consumedCount: Int
    var discardedCount: Int
    var consumedShare: Double
    var discardedShare: Double
    var closedCount: Int
    var averageStorageDays: Int?
    var perCategory: [CategoryStatistics]

    var eventCount: Int { consumedCount + discardedCount }
    var totalShare: Double { consumedShare + discardedShare }

    var discardRate: Double {
        totalShare > 0.0001 ? discardedShare / totalShare : 0
    }

    static let empty = InventoryStatistics(
        consumedCount: 0,
        discardedCount: 0,
        consumedShare: 0,
        discardedShare: 0,
        closedCount: 0,
        averageStorageDays: nil,
        perCategory: []
    )
}

/// Wertet aus, was den Tiefkühler verlassen hat: wie viel gegessen, wie viel
/// weggeworfen, und wo am meisten verloren geht.
enum StatisticsBuilder {
    /// Welchen Anteil des Eintrags macht eine Entnahme aus?
    ///
    /// Die Menge hat Vorrang, weil sie feiner auflöst. Nur wenn am Eintrag gar keine
    /// Menge steht, zählen die Portionen.
    static func share(
        quantityTaken: Double,
        initialQuantity: Double,
        portionsTaken: Int,
        initialPortions: Int
    ) -> Double {
        if initialQuantity > QuantityMath.epsilon {
            return min(1, max(0, quantityTaken / initialQuantity))
        }
        if initialPortions > 0 {
            return min(1, max(0, Double(portionsTaken) / Double(initialPortions)))
        }
        return 0
    }

    static func build(
        events: [ConsumptionSnapshot],
        closedItems: [ClosedItemSnapshot],
        calendar: Calendar = .current
    ) -> InventoryStatistics {
        guard !events.isEmpty || !closedItems.isEmpty else { return .empty }

        let categories = Set(events.map(\.category)).union(closedItems.map(\.category))
        let eventsByCategory = Dictionary(grouping: events, by: \.category)
        let closedByCategory = Dictionary(grouping: closedItems, by: \.category)

        let perCategory = categories
            .map { category -> CategoryStatistics in
                let categoryEvents = eventsByCategory[category] ?? []
                let consumed = categoryEvents.filter { $0.kind == .consumed }
                let discarded = categoryEvents.filter { $0.kind == .discarded }
                return CategoryStatistics(
                    category: category,
                    consumedCount: consumed.count,
                    discardedCount: discarded.count,
                    consumedShare: consumed.reduce(0) { $0 + $1.share },
                    discardedShare: discarded.reduce(0) { $0 + $1.share },
                    averageStorageDays: averageStorageDays(closedByCategory[category] ?? [], calendar: calendar)
                )
            }
            .sorted { lhs, rhs in
                // Wo am meisten verloren geht, steht oben – das ist die Zahl,
                // aus der sich etwas ableiten laesst.
                if lhs.discardedShare != rhs.discardedShare { return lhs.discardedShare > rhs.discardedShare }
                if lhs.totalShare != rhs.totalShare { return lhs.totalShare > rhs.totalShare }
                return lhs.category.displayName < rhs.category.displayName
            }

        let consumed = events.filter { $0.kind == .consumed }
        let discarded = events.filter { $0.kind == .discarded }

        return InventoryStatistics(
            consumedCount: consumed.count,
            discardedCount: discarded.count,
            consumedShare: consumed.reduce(0) { $0 + $1.share },
            discardedShare: discarded.reduce(0) { $0 + $1.share },
            closedCount: closedItems.count,
            averageStorageDays: averageStorageDays(closedItems, calendar: calendar),
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
