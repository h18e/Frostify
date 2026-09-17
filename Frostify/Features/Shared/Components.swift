import SwiftUI

/// Kleine farbige Markierung, z. B. die Ampelstufe oder „teilweise weggeworfen".
struct BadgeView: View {
    let text: String
    var color: Color = Theme.accent
    var systemImage: String?

    var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.bold))
            }
            Text(text)
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.16), in: Capsule())
        .foregroundStyle(color)
    }
}

/// Zeile mit Beschriftung links und Wert rechts.
struct LabeledValueRow<Value: View>: View {
    let label: String
    @ViewBuilder var value: Value

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 12)
            value
        }
    }
}

/// Leerer Zustand mit Symbol, Text und optionaler Aktion.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    var message: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Theme.textTertiary)
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textSecondary)
            }
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .padding(.top, 4)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}

/// Waagrechter Balken für die Auswertung.
///
/// Bewusst ohne Chart-Framework, damit die Darstellung im Dark Mode exakt
/// kontrollierbar bleibt – dieselbe Entscheidung wie in Räpplispauter.
struct BarRow: View {
    let title: String
    var symbolName: String?
    var color: Color = Theme.accent
    let fraction: Double
    let primaryText: String
    var secondaryText: String?

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                if let symbolName {
                    Image(systemName: symbolName)
                        .font(.footnote)
                        .foregroundStyle(color)
                        .frame(width: 18)
                }
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(primaryText)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                    if let secondaryText {
                        Text(secondaryText)
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.07))
                    Capsule()
                        .fill(color)
                        .frame(width: max(4, geometry.size.width * min(max(fraction, 0), 1)))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Rundes Kategoriensymbol, wie die Ausgaben-Zeile in Räpplispauter.
struct CategoryIcon: View {
    let category: FoodCategory
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            Circle()
                .fill(category.color.opacity(0.18))
            Image(systemName: category.symbolName)
                .font(.footnote)
                .foregroundStyle(category.color)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
