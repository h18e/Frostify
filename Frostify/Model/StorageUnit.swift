import Foundation

/// Mengeneinheiten. Rohwerte sind persistiert und duerfen sich nicht aendern.
enum StorageUnit: String, CaseIterable, Identifiable, Sendable {
    case gram
    case kilogram
    case piece
    case bag
    case package
    case milliliter
    case liter

    var id: String { rawValue }

    /// Kurzform fuer Listen, z. B. "500 g".
    var shortName: String {
        switch self {
        case .gram: return "g"
        case .kilogram: return "kg"
        case .piece: return "Stk."
        case .bag: return "Beutel"
        case .package: return "Pack."
        case .milliliter: return "ml"
        case .liter: return "l"
        }
    }

    /// Ausgeschrieben fuer Auswahlmenues.
    var displayName: String {
        switch self {
        case .gram: return "Gramm"
        case .kilogram: return "Kilogramm"
        case .piece: return "Stück"
        case .bag: return "Beutel"
        case .package: return "Packung"
        case .milliliter: return "Milliliter"
        case .liter: return "Liter"
        }
    }

    /// Ganzzahlige Einheiten bekommen keine Nachkommastellen angezeigt.
    var allowsFractions: Bool {
        switch self {
        case .gram, .piece, .bag, .package, .milliliter: return false
        case .kilogram, .liter: return true
        }
    }

    /// Schrittweite fuer Stepper beim Entnehmen.
    var step: Double {
        switch self {
        case .gram, .milliliter: return 10
        case .kilogram, .liter: return 0.1
        case .piece, .bag, .package: return 1
        }
    }

    static func from(rawValue: String?) -> StorageUnit {
        guard let rawValue, let value = StorageUnit(rawValue: rawValue) else { return .piece }
        return value
    }
}

/// Formatiert Mengen einheitlich – eine einzige Stelle, damit die App ueberall gleich aussieht.
enum QuantityFormatter {
    static func string(_ value: Double, unit: StorageUnit) -> String {
        "\(numberString(value, unit: unit)) \(unit.shortName)"
    }

    static func numberString(_ value: Double, unit: StorageUnit) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_CH")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = unit.allowsFractions ? 2 : 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func portionsString(_ portions: Int) -> String {
        portions == 1 ? "1 Portion" : "\(portions) Portionen"
    }
}
