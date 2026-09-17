import Foundation
import Testing
@testable import Frostify

@Suite("Statistik")
struct StatisticsBuilderTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    private func event(_ category: FoodCategory, _ kind: ConsumptionKind, share: Double) -> ConsumptionSnapshot {
        ConsumptionSnapshot(category: category, date: date(2026, 2, 1), kind: kind, share: share)
    }

    private func closed(_ category: FoodCategory, frozen: Date, closed: Date) -> ClosedItemSnapshot {
        ClosedItemSnapshot(category: category, frozenAt: frozen, closedAt: closed)
    }

    // MARK: - Anteilsberechnung

    @Test("Die Menge bestimmt den Anteil einer Entnahme")
    func shareFromQuantity() {
        let share = StatisticsBuilder.share(
            quantityTaken: 200, initialQuantity: 400, portionsTaken: 0, initialPortions: 0
        )
        #expect(share == 0.5)
    }

    @Test("Ohne Menge zählen die Portionen")
    func shareFromPortions() {
        let share = StatisticsBuilder.share(
            quantityTaken: 0, initialQuantity: 0, portionsTaken: 1, initialPortions: 4
        )
        #expect(share == 0.25)
    }

    @Test("Ohne Menge und ohne Portionen ist der Anteil null")
    func shareWithoutBasis() {
        #expect(StatisticsBuilder.share(quantityTaken: 5, initialQuantity: 0, portionsTaken: 0, initialPortions: 0) == 0)
    }

    @Test("Der Anteil bleibt zwischen null und eins")
    func shareIsClamped() {
        #expect(StatisticsBuilder.share(quantityTaken: 900, initialQuantity: 400, portionsTaken: 0, initialPortions: 0) == 1)
        #expect(StatisticsBuilder.share(quantityTaken: -50, initialQuantity: 400, portionsTaken: 0, initialPortions: 0) == 0)
    }

    // MARK: - Der gemeldete Fehler

    @Test("Eine gegessene Teilentnahme erscheint sofort, auch ohne abgeschlossenen Eintrag")
    func partialConsumptionIsCounted() {
        let events = [event(.meat, .consumed, share: 0.5)]
        let result = StatisticsBuilder.build(events: events, closedItems: [], calendar: calendar)

        #expect(result.consumedCount == 1)
        #expect(result.consumedShare == 0.5)
        #expect(result.discardRate == 0)
    }

    @Test("Halb gegessen, Rest weggeworfen ergibt fünfzig Prozent Verlust")
    func halfEatenHalfDiscarded() {
        let events = [
            event(.meat, .consumed, share: 0.5),
            event(.meat, .discarded, share: 0.5)
        ]
        let result = StatisticsBuilder.build(events: events, closedItems: [], calendar: calendar)

        #expect(result.consumedCount == 1)
        #expect(result.discardedCount == 1)
        #expect(result.discardRate == 0.5)

        let meat = result.perCategory.first { $0.category == .meat }
        #expect(meat?.consumedShare == 0.5)
        #expect(meat?.discardedShare == 0.5)
        #expect(meat?.discardRate == 0.5)
    }

    @Test("Drei von vier Portionen gegessen ergibt fünfundzwanzig Prozent Verlust")
    func quarterDiscarded() {
        let events = [
            event(.readyMeals, .consumed, share: 0.25),
            event(.readyMeals, .consumed, share: 0.5),
            event(.readyMeals, .discarded, share: 0.25)
        ]
        let result = StatisticsBuilder.build(events: events, closedItems: [], calendar: calendar)
        #expect(result.discardRate == 0.25)
        #expect(result.consumedCount == 2)
        #expect(result.eventCount == 3)
    }

    // MARK: - Allgemein

    @Test("Ohne Daten kommt eine leere Auswertung zurück")
    func emptyInput() {
        #expect(StatisticsBuilder.build(events: [], closedItems: [], calendar: calendar) == .empty)
    }

    @Test("Lagerdauer zählt volle Tage")
    func storageDays() {
        let days = StatisticsBuilder.storageDays(from: date(2026, 1, 1), to: date(2026, 1, 31), calendar: calendar)
        #expect(days == 30)
    }

    @Test("Durchschnittliche Lagerdauer wird gerundet")
    func averageStorageDays() {
        let items = [
            closed(.meat, frozen: date(2026, 1, 1), closed: date(2026, 1, 11)),
            closed(.meat, frozen: date(2026, 1, 1), closed: date(2026, 1, 16))
        ]
        let result = StatisticsBuilder.build(events: [], closedItems: items, calendar: calendar)
        #expect(result.averageStorageDays == 13)
        #expect(result.closedCount == 2)
    }

    @Test("Kategorien werden getrennt ausgewertet")
    func perCategory() {
        let events = [
            event(.meat, .discarded, share: 1.0),
            event(.vegetables, .consumed, share: 1.0)
        ]
        let result = StatisticsBuilder.build(events: events, closedItems: [], calendar: calendar)
        #expect(result.perCategory.count == 2)
        #expect(result.perCategory.first { $0.category == .meat }?.discardRate == 1.0)
        #expect(result.perCategory.first { $0.category == .vegetables }?.discardRate == 0)
    }

    @Test("Kategorien mit dem grössten Verlust stehen oben")
    func sortedByLosses() {
        let events = [
            event(.vegetables, .discarded, share: 0.2),
            event(.meat, .discarded, share: 0.9)
        ]
        let result = StatisticsBuilder.build(events: events, closedItems: [], calendar: calendar)
        #expect(result.perCategory.first?.category == .meat)
    }

    @Test("Eine Kategorie ohne Entnahmen, aber mit abgeschlossenem Eintrag erscheint trotzdem")
    func categoryFromClosedItemOnly() {
        let result = StatisticsBuilder.build(
            events: [],
            closedItems: [closed(.herbs, frozen: date(2026, 1, 1), closed: date(2026, 1, 8))],
            calendar: calendar
        )
        let herbs = result.perCategory.first { $0.category == .herbs }
        #expect(herbs != nil)
        #expect(herbs?.eventCount == 0)
        #expect(herbs?.averageStorageDays == 7)
    }
}
