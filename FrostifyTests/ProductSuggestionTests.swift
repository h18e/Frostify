import Foundation
import Testing
@testable import Frostify

@Suite("Produktvorschläge aus einer Datenbank")
struct ProductSuggestionTests {

    // MARK: - Mengenangaben

    @Test("Gramm und Kilo werden gelesen")
    func simpleQuantities() {
        #expect(QuantityTextParser.parse("500 g")?.value == 500)
        #expect(QuantityTextParser.parse("500 g")?.unit == .gram)
        #expect(QuantityTextParser.parse("1,5 kg")?.value == 1.5)
        #expect(QuantityTextParser.parse("1,5 kg")?.unit == .kilogram)
    }

    @Test("Ohne Leerzeichen geht es auch")
    func withoutSpace() {
        #expect(QuantityTextParser.parse("250g")?.value == 250)
        #expect(QuantityTextParser.parse("250g")?.unit == .gram)
    }

    @Test("Mehrfachpackungen werden multipliziert")
    func multiplePacks() {
        let result = QuantityTextParser.parse("2 x 125 g")
        #expect(result?.value == 250)
        #expect(result?.unit == .gram)
    }

    @Test("Zentiliter und Deziliter werden in Milliliter umgerechnet")
    func volumeConversion() {
        #expect(QuantityTextParser.parse("75 cl")?.value == 750)
        #expect(QuantityTextParser.parse("75 cl")?.unit == .milliliter)
        #expect(QuantityTextParser.parse("5 dl")?.value == 500)
    }

    @Test("Stückzahlen werden erkannt")
    func pieces() {
        #expect(QuantityTextParser.parse("4 Stück")?.unit == .piece)
        #expect(QuantityTextParser.parse("6 pcs")?.unit == .piece)
    }

    @Test("Unlesbares ergibt nichts statt einer falschen Zahl", arguments: [
        "", "ca. 300 g", "ohne Angabe", "g 500", "12 Dosen"
    ])
    func unparseable(text: String) {
        #expect(QuantityTextParser.parse(text) == nil)
    }

    @Test("Fehlende Angabe ergibt nichts")
    func missingQuantity() {
        #expect(QuantityTextParser.parse(nil) == nil)
    }

    // MARK: - Kategorie raten

    @Test("Sprachpräfixe stören nicht")
    func languagePrefix() {
        #expect(FoodCategoryGuesser.category(fromTags: ["en:frozen-vegetables"]) == .vegetables)
        #expect(FoodCategoryGuesser.category(fromTags: ["de:gemuese"]) == .vegetables)
    }

    @Test("Spezielles gewinnt vor Allgemeinem")
    func specificBeatsGeneral() {
        // "ice-cream" enthält "cream" – trotzdem Dessert und nicht Butter & Nidle.
        #expect(FoodCategoryGuesser.category(fromTags: ["en:ice-cream"]) == .desserts)
        // "pizza-dough" enthält "pizza" – trotzdem Teig und nicht Fertiggericht.
        #expect(FoodCategoryGuesser.category(fromTags: ["en:pizza-dough"]) == .bread)
        #expect(FoodCategoryGuesser.category(fromTags: ["en:frozen-pizzas"]) == .readyMeals)
    }

    @Test("Fisch wird nach Fettgehalt getrennt")
    func fishCategories() {
        #expect(FoodCategoryGuesser.category(fromTags: ["en:salmon-fillets"]) == .fattyFish)
        #expect(FoodCategoryGuesser.category(fromTags: ["en:shrimps"]) == .leanFish)
    }

    @Test("Wurstwaren landen bei Hackfleisch & Wurstwaren")
    func sausages() {
        #expect(FoodCategoryGuesser.category(fromTags: ["fr:saucisses"]) == .mincedMeat)
    }

    @Test("Ohne brauchbares Schlagwort wird nicht geraten", arguments: [
        [String](), ["en:frozen-foods"], ["de:tiefkuehlkost"]
    ])
    func noGuess(tags: [String]) {
        #expect(FoodCategoryGuesser.category(fromTags: tags) == nil)
    }

    // MARK: - Anzeigename

    @Test("Die Marke kommt dazu, wenn sie nicht schon im Namen steht")
    func brandIsAppended() {
        let suggestion = ProductSuggestion(name: "Erbsli", brand: "Findus")
        #expect(suggestion.displayName == "Erbsli, Findus")
    }

    @Test("Eine Marke im Namen wird nicht wiederholt")
    func brandNotDuplicated() {
        let suggestion = ProductSuggestion(name: "Findus Erbsli", brand: "Findus")
        #expect(suggestion.displayName == "Findus Erbsli")
    }

    @Test("Ohne Marke bleibt der Name, wie er ist")
    func withoutBrand() {
        let suggestion = ProductSuggestion(name: "Erbsli", brand: nil)
        #expect(suggestion.displayName == "Erbsli")
    }
}
