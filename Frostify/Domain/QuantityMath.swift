import Foundation

/// Rechnet Restmengen und anteilige Portionen aus.
///
/// Die Restmenge wird bewusst **nicht** gespeichert, sondern immer aus der Anfangsmenge
/// minus der Summe aller Entnahmen berechnet. Grund: Wenn zwei Geraete offline je eine
/// Entnahme erfassen, wuerde ein gespeichertes Restfeld beim Abgleich von einem der
/// beiden ueberschrieben – eine Entnahme ginge stillschweigend verloren. Entnahmen sind
/// eigene, nur angehaengte Datensaetze und koennen sich nicht gegenseitig ueberschreiben.
enum QuantityMath {
    /// Alles darunter gilt als null – faengt Rundungsreste von Fliesskommazahlen ab.
    static let epsilon = 0.0005

    static func rounded(_ value: Double) -> Double {
        (value * 1000).rounded() / 1000
    }

    static func remainingQuantity(initial: Double, taken: Double) -> Double {
        let rest = rounded(initial - taken)
        return rest < epsilon ? 0 : rest
    }

    static func remainingPortions(initial: Int, taken: Int) -> Int {
        max(0, initial - taken)
    }

    /// Zu einer Menge die anteilige Portionenzahl – fuer die verknuepfte Anzeige im Entnahme-Dialog.
    /// Ohne Portionsangabe am Eintrag ist das Ergebnis 0.
    static func portions(forQuantity quantity: Double, initialQuantity: Double, initialPortions: Int) -> Int {
        guard initialPortions > 0, initialQuantity > epsilon else { return 0 }
        let share = quantity / initialQuantity * Double(initialPortions)
        return min(initialPortions, max(0, Int(share.rounded())))
    }

    /// Umgekehrte Richtung: zu einer Portionenzahl die anteilige Menge.
    static func quantity(forPortions portions: Int, initialQuantity: Double, initialPortions: Int) -> Double {
        guard initialPortions > 0 else { return 0 }
        let share = Double(portions) / Double(initialPortions) * initialQuantity
        return rounded(min(initialQuantity, max(0, share)))
    }

    /// Ein Eintrag ist aufgebraucht, wenn weder Menge noch Portionen uebrig sind.
    /// Eintraege ohne Portionsangabe entscheiden allein ueber die Menge.
    static func isEmpty(remainingQuantity: Double, remainingPortions: Int, hasPortions: Bool) -> Bool {
        if hasPortions && remainingPortions > 0 { return false }
        return remainingQuantity < epsilon
    }

    /// Begrenzt eine Eingabe auf den tatsaechlich vorhandenen Rest.
    static func clamp(_ value: Double, max limit: Double) -> Double {
        rounded(min(max(0, value), limit))
    }
}
