import Foundation
import Testing
@testable import Frostify

@Suite("Haltbarkeits-Richtwerte")
struct ShelfLifeTableTests {
    @Test("Ohne Abweichung gilt der Standardwert der Kategorie")
    func defaultsApply() {
        let table = ShelfLifeTable()
        #expect(table.months(for: .mincedMeat) == 3)
        #expect(table.months(for: .vegetables) == 12)
        #expect(table.isOverridden(.mincedMeat) == false)
    }

    @Test("Abweichung überschreibt den Standardwert")
    func overrideApplies() {
        var table = ShelfLifeTable()
        table.set(months: 5, for: .mincedMeat)
        #expect(table.months(for: .mincedMeat) == 5)
        #expect(table.isOverridden(.mincedMeat))
    }

    @Test("Der Standardwert wird nicht als Abweichung gespeichert")
    func settingDefaultRemovesOverride() {
        var table = ShelfLifeTable()
        table.set(months: 5, for: .mincedMeat)
        table.set(months: 3, for: .mincedMeat)
        #expect(table.isOverridden(.mincedMeat) == false)
    }

    @Test("Abweichungen überstehen den Weg durch JSON")
    func roundTripsThroughJSON() {
        var table = ShelfLifeTable()
        table.set(months: 5, for: .mincedMeat)
        table.set(months: 24, for: .vegetables)

        let restored = ShelfLifeTable(json: table.json)
        #expect(restored.months(for: .mincedMeat) == 5)
        #expect(restored.months(for: .vegetables) == 24)
        #expect(restored == table)
    }

    @Test("Kaputter JSON-Inhalt führt zu den Standardwerten, nicht zum Absturz")
    func brokenJSONFallsBack() {
        let table = ShelfLifeTable(json: "{ das ist kein JSON")
        #expect(table.months(for: .meat) == FoodCategory.meat.defaultShelfLifeMonths)
    }

    @Test("Werte werden auf einen sinnvollen Bereich begrenzt")
    func valuesAreClamped() {
        var table = ShelfLifeTable()
        table.set(months: 500, for: .meat)
        #expect(table.months(for: .meat) == 60)
        table.set(months: -3, for: .fruit)
        #expect(table.months(for: .fruit) == 1)
    }

    @Test("Zurücksetzen entfernt alle Abweichungen")
    func resetAll() {
        var table = ShelfLifeTable()
        table.set(months: 5, for: .mincedMeat)
        table.resetAll()
        #expect(table.isOverridden(.mincedMeat) == false)
    }
}
