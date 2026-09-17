import SwiftUI

/// Die Ampel als Plakette – Symbol, Farbe und Text zusammen.
struct ExpiryBadge: View {
    let state: ExpiryState
    let daysRemaining: Int
    var compact: Bool = false

    var body: some View {
        BadgeView(
            text: compact ? shortText : ExpiryCalculator.remainingText(daysRemaining: daysRemaining),
            color: state.color,
            systemImage: state.symbolName
        )
        .accessibilityLabel("\(state.displayName), \(ExpiryCalculator.remainingText(daysRemaining: daysRemaining))")
    }

    private var shortText: String {
        daysRemaining < 0 ? "\(-daysRemaining) T über" : "\(daysRemaining) T"
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
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .screenBackground()
    .preferredColorScheme(.dark)
}
