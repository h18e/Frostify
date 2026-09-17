import SwiftUI

extension ExpiryState {
    /// Farbe ist immer nur die Zugabe – Symbol und Text stehen daneben, damit die
    /// Ampel auch bei Farbenblindheit und in Graustufen lesbar bleibt.
    var color: Color {
        switch self {
        case .expired: return .red
        case .urgent: return .orange
        case .soon: return .yellow
        case .fine: return .green
        }
    }
}

/// Kleine Plakette mit Symbol, Farbe und Text – die Ampel in Listen und Detailansicht.
struct ExpiryBadge: View {
    let state: ExpiryState
    let daysRemaining: Int
    var compact: Bool = false

    var body: some View {
        Label {
            Text(compact ? shortText : ExpiryCalculator.remainingText(daysRemaining: daysRemaining))
                .font(.caption)
                .fontWeight(.medium)
        } icon: {
            Image(systemName: state.symbolName)
                .font(.caption)
        }
        .foregroundStyle(state.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(state.color.opacity(0.15), in: Capsule())
        .accessibilityLabel("\(state.displayName), \(ExpiryCalculator.remainingText(daysRemaining: daysRemaining))")
    }

    private var shortText: String {
        daysRemaining < 0 ? "\(-daysRemaining) T über" : "\(daysRemaining) T"
    }
}

/// Einheitlicher Platzhalter fuer leere Listen.
struct EmptyStateView: View {
    let title: String
    let message: String
    let symbolName: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbolName)
        } description: {
            Text(message)
        }
    }
}

#Preview("Ampel") {
    VStack(alignment: .leading, spacing: 12) {
        ExpiryBadge(state: .fine, daysRemaining: 120)
        ExpiryBadge(state: .soon, daysRemaining: 21)
        ExpiryBadge(state: .urgent, daysRemaining: 4)
        ExpiryBadge(state: .expired, daysRemaining: -6)
    }
    .padding()
}
