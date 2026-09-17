import SwiftUI

struct ItemRowView: View {
    @ObservedObject var item: Item
    let table: ShelfLifeTable

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.category.symbolName)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.displayName)
                    .font(.body)
                    .fontWeight(.medium)

                Text(item.quantitySummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !item.noteText.isEmpty {
                    Text(item.noteText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 6) {
                    ExpiryBadge(
                        state: item.expiryState(using: table),
                        daysRemaining: item.daysRemaining(using: table)
                    )
                    if !item.storageLocationText.isEmpty {
                        Label(item.storageLocationText, systemImage: "tray")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Zeile") {
    let context = PersistenceController.preview.viewContext
    let items = (try? context.fetch(Item.fetchRequest())) ?? []
    List {
        ForEach(items, id: \.objectID) { item in
            ItemRowView(item: item, table: ShelfLifeTable())
        }
    }
}
