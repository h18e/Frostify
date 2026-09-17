import Foundation
import Testing
@testable import Frostify

@Suite("Statistik")
struct StatisticsBuilderTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    private func snapshot(_ category: FoodCategory, frozen: Date, closed: Date, reason: ConsumptionKind) -> ClosedItemSnapshot {
        ClosedItemSnapshot(category: category, frozenAt: frozen, closedAt: closed, closeReason: reason)
    }

    @Test("Ohne Einträge kommt eine leere Auswertung zurück")
    func emptyInput() {
        #expect(StatisticsBuilder.build(from: []) == .empty)
    }

    @Test("Lagerdauer zählt volle Tage")
    func storageDays() {
        let days = StatisticsBuilder.storageDays(from: date(2026, 1, 1), to: date(2026, 1, 31), calendar: calendar)
        #expect(days == 30)
    }

    @Test("Verlustquote ist der Anteil weggeworfener Einträge")
    func discardRate() {
        let items = [
            snapshot(.meat, frozen: date(2026, 1, 1), closed: date(2026, 2, 1), reason: .consumed),
            snapshot(.meat, frozen: date(2026, 1, 1), closed: date(2026, 2, 1), reason: .consumed),
            snapshot(.meat, frozen: date(2026, 1, 1), closed: date(2026, 2, 1), reason: .discarded),
            snapshot(.meat, frozen: date(2026, 1, 1), closed: date(2026, 2, 1), reason: .discarded)
        ]
        let result = StatisticsBuilder.build(from: items, calendar: calendar)
        #expect(result.closedCount == 4)
        #expect(result.discardedCount == 2)
        #expect(result.discardRate == 0.5)
    }

    @Test("Kategorien werden getrennt ausgewertet")
    func perCategory() {
        let items = [
            snapshot(.meat, frozen: date(2026, 1, 1), closed: date(2026, 2, 1), reason: .discarded),
            snapshot(.vegetables, frozen: date(2026, 1, 1), closed: date(2026, 2, 1), reason: .consumed)
        ]
        let result = StatisticsBuilder.build(from: items, calendar: calendar)
        #expect(result.perCategory.count == 2)

        let meat = result.perCategory.first { $0.category == .meat }
        #expect(meat?.discardedCount == 1)
        #expect(meat?.discardRate == 1.0)

        let vegetables = result.perCategory.first { $0.category == .vegetables }
        #expect(vegetables?.discardedCount == 0)
        #expect(vegetables?.discardRate == 0)
    }

    @Test("Kategorien mit den meisten Verlusten stehen oben")
    func sortedByLosses() {
        let items = [
            snapshot(.vegetables, frozen: date(2026, 1, 1), closed: date(2026, 2, 1), reason: .consumed),
            snapshot(.meat, frozen: date(2026, 1, 1), closed: date(2026, 2, 1), reason: .discarded),
            snapshot(.meat, frozen: date(2026, 1, 1), closed: date(2026, 2, 1), reason: .discarded)
        ]
        let result = StatisticsBuilder.build(from: items, calendar: calendar)
        #expect(result.perCategory.first?.category == .meat)
    }

    @Test("Durchschnittliche Lagerdauer wird gerundet")
    func averageStorageDays() {
        let items = [
            snapshot(.meat, frozen: date(2026, 1, 1), closed: date(2026, 1, 11), reason: .consumed),
            snapshot(.meat, frozen: date(2026, 1, 1), closed: date(2026, 1, 16), reason: .consumed)
        ]
        let result = StatisticsBuilder.build(from: items, calendar: calendar)
        #expect(result.averageStorageDays == 13)
    }
}
