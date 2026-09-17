import Foundation
import Testing
@testable import Frostify

@Suite("Mengen und Portionen")
struct QuantityMathTests {
    @Test("Restmenge ist Anfangsmenge minus Summe der Entnahmen")
    func remainingSubtracts() {
        #expect(QuantityMath.remainingQuantity(initial: 400, taken: 200) == 200)
    }

    @Test("Rundungsreste ergeben sauber null")
    func floatingPointNoise() {
        let taken = 0.1 + 0.2  // 0.30000000000000004
        #expect(QuantityMath.remainingQuantity(initial: 0.3, taken: taken) == 0)
    }

    @Test("Restmenge wird nie negativ")
    func neverNegative() {
        #expect(QuantityMath.remainingQuantity(initial: 100, taken: 250) == 0)
        #expect(QuantityMath.remainingPortions(initial: 2, taken: 5) == 0)
    }

    @Test("400 g auf 2 Portionen: eine Portion sind 200 g")
    func portionsToQuantity() {
        let quantity = QuantityMath.quantity(forPortions: 1, initialQuantity: 400, initialPortions: 2)
        #expect(quantity == 200)
    }

    @Test("200 g von 400 g bei 2 Portionen sind eine Portion")
    func quantityToPortions() {
        let portions = QuantityMath.portions(forQuantity: 200, initialQuantity: 400, initialPortions: 2)
        #expect(portions == 1)
    }

    @Test("Ohne Portionsangabe ergibt die Umrechnung null")
    func withoutPortions() {
        #expect(QuantityMath.portions(forQuantity: 200, initialQuantity: 400, initialPortions: 0) == 0)
        #expect(QuantityMath.quantity(forPortions: 3, initialQuantity: 400, initialPortions: 0) == 0)
    }

    @Test("Die Umrechnung überschreitet die Grenzen nicht")
    func conversionClamps() {
        #expect(QuantityMath.portions(forQuantity: 9999, initialQuantity: 400, initialPortions: 2) == 2)
        #expect(QuantityMath.quantity(forPortions: 99, initialQuantity: 400, initialPortions: 2) == 400)
    }

    @Test("Aufgebraucht heisst: weder Menge noch Portionen übrig")
    func emptyRequiresBoth() {
        #expect(QuantityMath.isEmpty(remainingQuantity: 0, remainingPortions: 1, hasPortions: true) == false)
        #expect(QuantityMath.isEmpty(remainingQuantity: 0, remainingPortions: 0, hasPortions: true) == true)
        #expect(QuantityMath.isEmpty(remainingQuantity: 0, remainingPortions: 3, hasPortions: false) == true)
        #expect(QuantityMath.isEmpty(remainingQuantity: 50, remainingPortions: 0, hasPortions: false) == false)
    }

    @Test("Begrenzen kappt oben und unten")
    func clamping() {
        #expect(QuantityMath.clamp(-5, max: 100) == 0)
        #expect(QuantityMath.clamp(150, max: 100) == 100)
        #expect(QuantityMath.clamp(42.5, max: 100) == 42.5)
    }
}
