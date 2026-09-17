import Foundation
import Testing
@testable import Frostify

@Suite("Ablaufberechnung")
struct ExpiryCalculatorTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich") ?? .gmt
        return calendar
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    @Test("Richtwert wird als Monate auf das Einfrierdatum addiert")
    func bestBeforeAddsMonths() {
        let frozen = date(2026, 1, 15)
        let result = ExpiryCalculator.bestBefore(frozenAt: frozen, shelfLifeMonths: 3, calendar: calendar)
        #expect(calendar.dateComponents([.year, .month, .day], from: result) ==
                calendar.dateComponents([.year, .month, .day], from: date(2026, 4, 15)))
    }

    @Test("Monatsende wird sauber behandelt")
    func bestBeforeHandlesEndOfMonth() {
        let frozen = date(2026, 1, 31)
        let result = ExpiryCalculator.bestBefore(frozenAt: frozen, shelfLifeMonths: 1, calendar: calendar)
        let components = calendar.dateComponents([.year, .month], from: result)
        #expect(components.year == 2026)
        #expect(components.month == 2)
    }

    @Test("Verbleibende Tage rechnen auf Tagesgrenzen, nicht auf die Uhrzeit")
    func daysRemainingUsesStartOfDay() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 23, minute: 59)) ?? Date()
        let due = calendar.date(from: DateComponents(year: 2026, month: 3, day: 2, hour: 0, minute: 1)) ?? Date()
        #expect(ExpiryCalculator.daysRemaining(until: due, now: now, calendar: calendar) == 1)
    }

    @Test("Heute ablaufend ergibt null Tage, nicht minus eins")
    func todayIsZero() {
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 8)) ?? Date()
        let due = calendar.date(from: DateComponents(year: 2026, month: 3, day: 1, hour: 20)) ?? Date()
        #expect(ExpiryCalculator.daysRemaining(until: due, now: now, calendar: calendar) == 0)
    }

    @Test("Ampelstufen an den festgelegten Grenzen", arguments: [
        (-1, ExpiryState.expired),
        (0, ExpiryState.urgent),
        (7, ExpiryState.urgent),
        (8, ExpiryState.soon),
        (30, ExpiryState.soon),
        (31, ExpiryState.fine)
    ])
    func stateThresholds(days: Int, expected: ExpiryState) {
        #expect(ExpiryCalculator.state(daysRemaining: days) == expected)
    }

    @Test("Ampelstufen sortieren die dringendsten nach vorne")
    func stateOrdering() {
        let sorted = [ExpiryState.fine, .expired, .soon, .urgent].sorted()
        #expect(sorted == [.expired, .urgent, .soon, .fine])
    }

    @Test("Kurztexte sind sprachlich korrekt")
    func remainingTexts() {
        #expect(ExpiryCalculator.remainingText(daysRemaining: 0) == "läuft heute ab")
        #expect(ExpiryCalculator.remainingText(daysRemaining: 1) == "noch 1 Tag")
        #expect(ExpiryCalculator.remainingText(daysRemaining: 5) == "noch 5 Tage")
        #expect(ExpiryCalculator.remainingText(daysRemaining: -1) == "seit gestern überschritten")
        #expect(ExpiryCalculator.remainingText(daysRemaining: -4) == "seit 4 Tagen überschritten")
    }
}
