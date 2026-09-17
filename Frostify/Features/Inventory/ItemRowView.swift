import SwiftUI

struct ItemRowView: View {
    @ObservedObject var item: Item
    let table: ShelfLifeTable

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CategoryIcon(category: item.category)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(item.quantitySummary)
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                }

                if !item.noteText.isEmpty {
                    Text(item.noteText)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    ExpiryBadge(
                        state: item.expiryState(using: table),
                        daysRemaining: item.daysRemaining(using: table)
                    )
                    if !item.storageLocationText.isEmpty {
                        Label(item.storageLocationText, systemImage: "tray")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                            .lineLimit(1)
                    }
                }
                .padding(.top, 1)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Zeile") {
    let context = PersistenceController.preview.viewContext
    let items = (try? context.fetch(Item.fetchRequest())) ?? []
    List {
        ForEach(items, id: \.objectID) { item in
            ItemRowView(item: item, table: ShelfLifeTable())
                .listRowBackground(Theme.surface)
        }
    }
    .themedList()
    .preferredColorScheme(.dark)
}
