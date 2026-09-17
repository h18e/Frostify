import Foundation

/// Warum etwas den Tiefkuehler verlassen hat.
///
/// `discarded` ist der Datenpunkt, aus dem die Statistik zeigt, wo tatsaechlich
/// Lebensmittel verloren gehen – deshalb ist er bewusst von `consumed` getrennt.
enum ConsumptionKind: String, CaseIterable, Identifiable, Sendable {
    case consumed
    case discarded

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .consumed: return "Gegessen"
        case .discarded: return "Weggeworfen"
        }
    }

    var symbolName: String {
        switch self {
        case .consumed: return "checkmark.circle"
        case .discarded: return "trash"
        }
    }

    static func from(rawValue: String?) -> ConsumptionKind? {
        guard let rawValue, !rawValue.isEmpty else { return nil }
        return ConsumptionKind(rawValue: rawValue)
    }
}
