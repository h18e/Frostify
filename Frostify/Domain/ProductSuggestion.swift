import Foundation

/// Ein Vorschlag aus einer externen Produktdatenbank.
///
/// Bewusst ein einfacher Wert ohne Netz- oder Core-Data-Bezug: So lässt sich die
/// Auswertung der Antwort testen, ohne eine Verbindung zu brauchen.
struct ProductSuggestion: Equatable, Sendable {
    var name: String
    // Ausdrueckliche Vorgaben, damit der Wert auch nur mit dem Namen erzeugt
    // werden kann – die Datenbank liefert selten alles.
    var brand: String? = nil
    var quantity: Double? = nil
    var unit: StorageUnit? = nil
    var category: FoodCategory? = nil

    /// Name für den Eintrag. Die Marke kommt nur dazu, wenn sie nicht ohnehin
    /// schon im Namen steht – bei Open Food Facts ist das oft der Fall.
    var displayName: String {
        guard let brand, !brand.isEmpty else { return name }
        if name.localizedCaseInsensitiveContains(brand) { return name }
        return "\(name), \(brand)"
    }
}

/// Liest Mengenangaben, wie sie in Produktdatenbanken stehen: „500 g", „1,5 kg",
/// „2 x 125 g", „75 cl".
enum QuantityTextParser {
    private static let pattern = "^\\s*(?:(\\d+(?:[.,]\\d+)?)\\s*[x×*]\\s*)?(\\d+(?:[.,]\\d+)?)\\s*([\\p{L}]+)"

    static func parse(_ text: String?) -> (value: Double, unit: StorageUnit)? {
        guard let text, !text.isEmpty else { return nil }
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }

        func group(_ index: Int) -> String? {
            guard let r = Range(match.range(at: index), in: text) else { return nil }
            return String(text[r])
        }

        guard let amountText = group(2), let unitText = group(3) else { return nil }
        guard let amount = number(from: amountText) else { return nil }

        // „2 x 125 g" ergibt 250 g.
        let multiplier = group(1).flatMap(number(from:)) ?? 1
        let total = amount * multiplier

        switch unitText.lowercased() {
        case "g", "gr", "gram", "grams", "gramm", "gramme", "grammes", "grammi":
            return (total, .gram)
        case "kg", "kilo", "kilos", "kilogramm", "kilogramme", "kilogram":
            return (total, .kilogram)
        case "ml", "milliliter", "millilitre", "millilitres":
            return (total, .milliliter)
        case "cl", "centiliter", "centilitre":
            return (total * 10, .milliliter)
        case "dl", "deziliter", "decilitre":
            return (total * 100, .milliliter)
        case "l", "lt", "liter", "litre", "litres", "litri":
            return (total, .liter)
        case "st", "stk", "stück", "stueck", "stk.", "pc", "pcs", "piece", "pieces", "pièce", "pièces":
            return (total, .piece)
        default:
            return nil
        }
    }

    private static func number(from text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }
}

/// Rät die Kategorie aus den Schlagworten einer Produktdatenbank.
///
/// Bewusst nur ein Vorschlag: Die Schlagworte sind mehrsprachig, uneinheitlich
/// gepflegt und passen nicht immer zu unseren vierzehn Kategorien. Wer erfasst,
/// sieht die geratene Kategorie im Formular und kann sie in einem Griff ändern –
/// und diese Korrektur landet im eigenen Katalog.
enum FoodCategoryGuesser {
    /// Reihenfolge ist wichtig: Spezielles vor Allgemeinem. „ice-cream" muss vor
    /// „cream" greifen, „dough" vor „pizza".
    private static let rules: [(needles: [String], category: FoodCategory)] = [
        (["ice-cream", "icecream", "glace", "sorbet", "dessert", "glacee"], .desserts),
        (["dough", "pate-a-pizza", "teig", "bread", "pain", "brot", "pastr", "viennoiserie", "gebaeck", "baguette", "gipfel", "croissant"], .bread),
        (["pizza", "prepared-meal", "ready-meal", "plat-prepare", "fertiggericht", "lasagne", "gratin", "menu"], .readyMeals),
        (["soup", "soupe", "suppe", "sauce", "bouillon", "broth", "fond"], .soups),
        (["minced", "hache", "hackfleisch", "sausage", "saucisse", "wurst", "salami", "charcuterie", "speck", "bacon", "schinken", "jambon"], .mincedMeat),
        (["poultry", "chicken", "poulet", "huhn", "turkey", "dinde", "truthahn", "ente", "canard"], .poultry),
        (["salmon", "saumon", "lachs", "tuna", "thon", "thunfisch", "mackerel", "maquereau", "hering", "herring", "sardine"], .fattyFish),
        (["seafood", "shrimp", "crevette", "garnele", "crustace", "mollusc", "fish", "poisson", "fisch", "cabillaud", "kabeljau"], .leanFish),
        (["meat", "viande", "fleisch", "beef", "boeuf", "rind", "pork", "porc", "schwein", "veal", "veau", "kalb", "lamb", "agneau"], .meat),
        (["vegetable", "legume", "gemuese", "gemuse", "pea", "erbse", "spinach", "epinard", "spinat", "carotte", "karotte", "broccoli", "bohnen", "haricot", "mais"], .vegetables),
        (["fruit", "berry", "berries", "baie", "beere", "himbeer", "raspberry", "erdbeer", "strawberry", "heidelbeer", "blueberry", "mango", "ananas"], .fruit),
        (["herb", "herbe", "kraut", "kräuter", "persil", "petersilie", "basilic", "basilikum", "spice", "epice"], .herbs),
        (["butter", "beurre", "cream", "creme", "rahm", "nidle", "sahne"], .dairy)
    ]

    static func category(fromTags tags: [String]) -> FoodCategory? {
        // Sprachpräfixe wie „en:" oder „de:" stören beim Vergleich.
        let cleaned = tags.map { tag -> String in
            let withoutPrefix = tag.contains(":") ? String(tag.split(separator: ":", maxSplits: 1).last ?? "") : tag
            return withoutPrefix.lowercased()
        }
        guard !cleaned.isEmpty else { return nil }

        for rule in rules {
            for needle in rule.needles where cleaned.contains(where: { $0.contains(needle) }) {
                return rule.category
            }
        }
        return nil
    }
}
