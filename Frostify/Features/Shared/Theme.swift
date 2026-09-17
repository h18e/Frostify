import SwiftUI

/// Farb- und Stilwerte der App.
///
/// Übernommen aus Räpplispauter, damit sich die beiden Apps gleich anfühlen:
/// **Dark Mode als einziges Erscheinungsbild**, tiefer fast schwarzer Hintergrund,
/// leicht aufgehellte Karten, sparsam gesetzte Akzentfarbe.
///
/// Eine bewusste Abweichung: Die Akzentfarbe ist nicht das Räpplispauter-Grün,
/// sondern das Türkis aus dessen Kategorienpalette. Grün ist in Frostify für die
/// Ampelstufe „in Ordnung" reserviert – dieselbe Farbe zusätzlich als Akzent zu
/// setzen, würde die Ampel verwässern.
enum Theme {

    // MARK: - Flächen

    static let background = Color(red: 0.055, green: 0.059, blue: 0.071)
    static let surface = Color(red: 0.094, green: 0.101, blue: 0.121)
    static let surfaceElevated = Color(red: 0.129, green: 0.137, blue: 0.161)
    static let separator = Color.white.opacity(0.08)

    // MARK: - Text

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.38)

    // MARK: - Akzente

    /// Markenfarbe (auch als AccentColor im Asset-Katalog hinterlegt).
    static let accent = Color(red: 0.361, green: 0.792, blue: 0.827)

    // MARK: - Ampel

    /// Mehr als 30 Tage.
    static let stateFine = Color(red: 0.396, green: 0.831, blue: 0.596)
    /// 8 bis 30 Tage.
    static let stateSoon = Color(red: 0.902, green: 0.796, blue: 0.404)
    /// 0 bis 7 Tage.
    static let stateUrgent = Color(red: 0.976, green: 0.643, blue: 0.376)
    /// Überschritten.
    static let stateExpired = Color(red: 0.965, green: 0.447, blue: 0.447)

    static let cornerRadius: CGFloat = 16

    // MARK: - Kategorien

    /// Farben für die Kategorien. Dieselbe Palette wie in Räpplispauter, damit
    /// benachbarte Einträge sich gut unterscheiden lassen.
    private static let categoryPalette: [Color] = [
        Color(red: 0.443, green: 0.663, blue: 0.976),   // Blau
        Color(red: 0.976, green: 0.643, blue: 0.376),   // Orange
        Color(red: 0.482, green: 0.827, blue: 0.529),   // Grün
        Color(red: 0.596, green: 0.612, blue: 0.949),   // Indigo
        Color(red: 0.929, green: 0.510, blue: 0.522),   // Rot
        Color(red: 0.361, green: 0.792, blue: 0.827),   // Türkis
        Color(red: 0.878, green: 0.588, blue: 0.925),   // Violett
        Color(red: 0.902, green: 0.796, blue: 0.404)    // Gelb
    ]

    static func categoryColor(_ index: Int) -> Color {
        guard !categoryPalette.isEmpty else { return accent }
        let safe = ((index % categoryPalette.count) + categoryPalette.count) % categoryPalette.count
        return categoryPalette[safe]
    }
}

extension FoodCategory {
    /// Platz in der Farbpalette. Fest an der Reihenfolge von `allCases`, damit
    /// eine Kategorie ihre Farbe behält.
    var colorIndex: Int {
        FoodCategory.allCases.firstIndex(of: self) ?? 0
    }

    var color: Color { Theme.categoryColor(colorIndex) }
}

extension ExpiryState {
    /// Farbe ist immer nur die Zugabe – Symbol und Text stehen daneben, damit die
    /// Ampel auch bei Farbenblindheit und in Graustufen lesbar bleibt.
    var color: Color {
        switch self {
        case .expired: return Theme.stateExpired
        case .urgent: return Theme.stateUrgent
        case .soon: return Theme.stateSoon
        case .fine: return Theme.stateFine
        }
    }
}

// MARK: - Bausteine für den Seitenaufbau

/// Karten-Hintergrund im App-Stil.
struct CardBackground: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(Theme.separator, lineWidth: 1)
            )
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View {
        modifier(CardBackground(padding: padding))
    }

    /// Einheitlicher, dunkler Bildschirmhintergrund.
    func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }

    /// Listen und Formulare auf den dunklen Hintergrund stellen.
    ///
    /// iOS malt sonst seinen eigenen, etwas helleren Systemhintergrund darunter –
    /// die Flächen wirken dann uneinheitlich.
    func themedList() -> some View {
        self
            .scrollContentBackground(.hidden)
            .screenBackground()
    }
}
