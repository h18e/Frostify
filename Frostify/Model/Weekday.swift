import Foundation

/// Wochentage auf Berndeutsch.
///
/// `Calendar.weekdaySymbols` liefert die Namen in der Systemsprache, also
/// hochdeutsch. Weil die App durchgehend Mundart spricht, stehen sie hier fest.
enum Weekday {
    /// Index 0 = Sunntig … 6 = Samschtig, passend zur Zaehlweise von `Calendar`
    /// (dort 1 = Sonntag).
    static let names = [
        "Sunntig",
        "Mänti",
        "Zischtig",
        "Mittwuch",
        "Dunschtig",
        "Fritig",
        "Samschtig"
    ]

    /// `calendarWeekday` ist die Zaehlweise von `Calendar`: 1 = Sunntig … 7 = Samschtig.
    static func name(_ calendarWeekday: Int) -> String {
        names[min(names.count - 1, max(0, calendarWeekday - 1))]
    }
}
