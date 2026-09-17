import SwiftUI

/// Die oberste Zeile der Uebersicht: was laeuft als Naechstes ab.
/// Antippen filtert die Liste – das ist der schnellste Weg von "App auf" zu "was muss weg".
struct ExpirySummaryCard: View {
    let counts: [ExpiryState: Int]
    @Binding var activeFilter: ExpiryState?

    private var urgentTotal: Int {
        (counts[.expired] ?? 0) + (counts[.urgent] ?? 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(headline)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 8) {
                ForEach(ExpiryState.allCases.sorted(), id: \.rawValue) { state in
                    let count = counts[state] ?? 0
                    if count > 0 {
                        Button {
                            activeFilter = (activeFilter == state) ? nil : state
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: state.symbolName)
                                    .font(.caption2.weight(.bold))
                                Text("\(count)")
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                state.color.opacity(activeFilter == state ? 0.32 : 0.16),
                                in: Capsule()
                            )
                            .foregroundStyle(state.color)
                            .overlay(
                                Capsule()
                                    .strokeBorder(state.color, lineWidth: activeFilter == state ? 1.5 : 0)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(count) \(state.displayName)")
                        .accessibilityHint(activeFilter == state ? "Filter aufheben" : "Nur diese anzeigen")
                    }
                }
            }
        }
        .card()
    }

    private var headline: String {
        let expired = counts[.expired] ?? 0
        if expired > 0 {
            return expired == 1
                ? "1 Produkt ist überschritten"
                : "\(expired) Produkte sind überschritten"
        }
        if urgentTotal > 0 {
            return urgentTotal == 1
                ? "1 Produkt läuft diese Woche ab"
                : "\(urgentTotal) Produkte laufen diese Woche ab"
        }
        let soon = counts[.soon] ?? 0
        if soon > 0 {
            return soon == 1 ? "1 Produkt läuft im nächsten Monat ab" : "\(soon) Produkte laufen im nächsten Monat ab"
        }
        return "Alles im grünen Bereich"
    }
}

#Preview("Zusammenfassung") {
    ExpirySummaryCard(
        counts: [.expired: 1, .urgent: 2, .soon: 4, .fine: 11],
        activeFilter: .constant(nil)
    )
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .screenBackground()
    .preferredColorScheme(.dark)
}
