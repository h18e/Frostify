import Foundation

/// Feste Kategorienliste.
///
/// Wichtig: Die Rohwerte werden in Core Data und in CloudKit gespeichert und duerfen
/// sich nie aendern – sonst verlieren bestehende Eintraege ihre Kategorie. Anzeigetexte
/// duerfen jederzeit angepasst werden.
enum FoodCategory: String, CaseIterable, Identifiable, Sendable {
    case meat
    case mincedMeat
    case poultry
    case fattyFish
    case leanFish
    case vegetables
    case fruit
    case bread
    case readyMeals
    case soups
    case herbs
    case dairy
    case desserts
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .meat: return "Fleisch (Stücke, Braten)"
        case .mincedMeat: return "Hackfleisch & Wurstwaren"
        case .poultry: return "Geflügel"
        case .fattyFish: return "Fisch fett (Lachs, Thon)"
        case .leanFish: return "Fisch mager & Meeresfrüchte"
        case .vegetables: return "Gemüse"
        case .fruit: return "Früchte & Beeren"
        case .bread: return "Brot, Teig & Gebäck"
        case .readyMeals: return "Fertiggerichte & Selbstgekochtes"
        case .soups: return "Suppen, Saucen & Fonds"
        case .herbs: return "Kräuter"
        case .dairy: return "Butter & Rahm"
        case .desserts: return "Desserts & Glace"
        case .other: return "Sonstiges"
        }
    }

    /// SF-Symbol fuer Listen und Filter.
    var symbolName: String {
        switch self {
        case .meat: return "fork.knife"
        case .mincedMeat: return "circle.grid.2x2"
        case .poultry: return "bird"
        case .fattyFish, .leanFish: return "fish"
        case .vegetables: return "carrot"
        case .fruit: return "apple.logo"
        case .bread: return "birthday.cake"
        case .readyMeals: return "takeoutbag.and.cup.and.straw"
        case .soups: return "cup.and.saucer"
        case .herbs: return "leaf"
        case .dairy: return "drop"
        case .desserts: return "snowflake"
        case .other: return "shippingbox"
        }
    }

    /// Richtwert der Lagerdauer im Tiefkuehler, in Monaten.
    /// Kann pro Haushalt in den Einstellungen ueberschrieben werden (siehe `ShelfLifeTable`).
    var defaultShelfLifeMonths: Int {
        switch self {
        case .meat: return 12
        case .mincedMeat: return 3
        case .poultry: return 9
        case .fattyFish: return 3
        case .leanFish: return 6
        case .vegetables: return 12
        case .fruit: return 12
        case .bread: return 3
        case .readyMeals: return 3
        case .soups: return 6
        case .herbs: return 6
        case .dairy: return 6
        case .desserts: return 6
        case .other: return 6
        }
    }

    /// Voreingestellte Einheit beim Erfassen – spart bei den haeufigen Faellen einen Griff.
    var defaultUnit: StorageUnit {
        switch self {
        case .meat, .mincedMeat, .poultry, .fattyFish, .leanFish, .vegetables, .fruit, .herbs, .dairy:
            return .gram
        case .bread, .readyMeals, .desserts, .other:
            return .piece
        case .soups:
            return .milliliter
        }
    }

    static func from(rawValue: String?) -> FoodCategory {
        guard let rawValue, let value = FoodCategory(rawValue: rawValue) else { return .other }
        return value
    }
}
