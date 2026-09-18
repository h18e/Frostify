import Foundation

/// Ampelstufe eines Eintrags. Die Reihenfolge ist so gewaehlt, dass `sorted()`
/// die dringendsten Eintraege nach vorne bringt.
enum ExpiryState: Int, CaseIterable, Comparable, Sendable {
    case expired = 0
    case urgent = 1
    case soon = 2
    case fine = 3

    static func < (lhs: ExpiryState, rhs: ExpiryState) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .expired: return "Abglaufe"
        case .urgent: return "Pressiert"
        case .soon: return "Bau bruche"
        case .fine: return "Guet"
        }
    }

    /// Farbe ist nie der einzige Traeger der Information – dazu gehoert immer dieses Symbol.
    var symbolName: String {
        switch self {
        case .expired: return "exclamationmark.octagon.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        case .soon: return "clock.fill"
        case .fine: return "checkmark.circle.fill"
        }
    }
}

/// Berechnet aus Einfrierdatum und Kategorie-Richtwert das "empfohlen bis"-Datum
/// und daraus die Ampelstufe.
///
/// Bewusst frei von Core Data und SwiftUI, damit die Logik ohne Geraet testbar bleibt.
enum ExpiryCalculator {
    /// 0–7 Tage: dringend. Fest verdrahtet laut Spezifikation.
    static let urgentThresholdDays = 7
    /// 8–30 Tage: bald verbrauchen.
    static let soonThresholdDays = 30

    static func bestBefore(frozenAt: Date, shelfLifeMonths: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .month, value: shelfLifeMonths, to: frozenAt) ?? frozenAt
    }

    /// Verbleibende Tage, auf Tagesgrenzen gerechnet. "Heute abgelaufen" ergibt 0, nicht -1.
    static func daysRemaining(until bestBefore: Date, now: Date = Date(), calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: now)
        let due = calendar.startOfDay(for: bestBefore)
        return calendar.dateComponents([.day], from: today, to: due).day ?? 0
    }

    static func state(until bestBefore: Date, now: Date = Date(), calendar: Calendar = .current) -> ExpiryState {
        state(daysRemaining: daysRemaining(until: bestBefore, now: now, calendar: calendar))
    }

    static func state(daysRemaining days: Int) -> ExpiryState {
        if days < 0 { return .expired }
        if days <= urgentThresholdDays { return .urgent }
        if days <= soonThresholdDays { return .soon }
        return .fine
    }

    /// Kurztext fuer die Listenzeile, z. B. "noch 5 Tage" oder "seit 3 Tagen überschritten".
    static func remainingText(daysRemaining days: Int) -> String {
        switch days {
        case ..<(-1): return "sit \(-days) Täg abglaufe"
        case -1: return "sit geschter abglaufe"
        case 0: return "louft hüt ab"
        case 1: return "no 1 Tag"
        case 2...60: return "no \(days) Täg"
        default:
            let months = days / 30
            return months <= 1 ? "no guet 1 Monet" : "no guet \(months) Mönet"
        }
    }
}
