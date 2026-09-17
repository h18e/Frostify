import CoreData
import SwiftUI

/// Alles, was den Tiefkuehler verlassen hat.
struct ArchiveView: View {
    @Environment(\.inventory) private var inventory

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.closedAt, ascending: false)],
        predicate: NSPredicate(format: "closedAt != nil"),
        animation: .default
    )
    private var closedItems: FetchedResults<Item>

    @State private var kindFilter: ConsumptionKind?
    @State private var timeframe: ArchiveTimeframe = .lastYear
    @State private var searchText = ""

    private var table: ShelfLifeTable { inventory.shelfLifeTable }

    private var filtered: [Item] {
        let cutoff = timeframe.cutoffDate
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return closedItems.filter { item in
            if let cutoff, (item.closedAt ?? .distantPast) < cutoff { return false }
            if let kindFilter, item.closeReason != kindFilter { return false }
            if !query.isEmpty {
                let haystack = [item.displayName, item.noteText, item.category.displayName]
                    .joined(separator: " ")
                    .lowercased()
                if !haystack.contains(query) { return false }
            }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if closedItems.isEmpty {
                    EmptyStateView(
                        symbol: "archivebox",
                        title: "Archiv ist leer",
                        message: "Sobald du etwas ganz entnimmst oder wegwirfst, erscheint es hier."
                    )
                    .frame(maxHeight: .infinity)
                    .screenBackground()
                } else {
                    list
                }
            }
            .navigationTitle("Archiv")
            .searchable(text: $searchText, prompt: "Name oder Kategorie")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        StatisticsView()
                    } label: {
                        Label("Statistik", systemImage: "chart.bar")
                    }
                }
            }
        }
    }

    private var list: some View {
        List {
            Section {
                Picker("Grund", selection: $kindFilter) {
                    Text("Alle").tag(ConsumptionKind?.none)
                    Text("Gegessen").tag(ConsumptionKind?.some(.consumed))
                    Text("Weggeworfen").tag(ConsumptionKind?.some(.discarded))
                }
                .pickerStyle(.segmented)

                Picker("Zeitraum", selection: $timeframe) {
                    ForEach(ArchiveTimeframe.allCases) { frame in
                        Text(frame.displayName).tag(frame)
                    }
                }
            }
            .listRowBackground(Theme.surface)

            if filtered.isEmpty {
                Section {
                    Text("Keine Einträge in dieser Auswahl.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .listRowBackground(Theme.surface)
            }

            Section {
                ForEach(filtered, id: \.objectID) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        ArchiveRow(item: item)
                    }
                }
            } header: {
                Text(filtered.count == 1 ? "1 Eintrag" : "\(filtered.count) Einträge")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .textCase(nil)
            }
            .listRowBackground(Theme.surface)
        }
        .listStyle(.insetGrouped)
        .themedList()
    }
}

private struct ArchiveRow: View {
    @ObservedObject var item: Item

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CategoryIcon(category: item.category, size: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(item.category.displayName)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                HStack(spacing: 6) {
                    Text(item.closedAt ?? Date(), style: .date)
                    Text("·")
                    Text("\(StatisticsBuilder.storageDays(from: item.frozenDate, to: item.closedAt ?? Date())) Tage gelagert")
                }
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)

                HStack(spacing: 6) {
                    BadgeView(
                        text: item.closeReason?.displayName ?? "Abgeschlossen",
                        color: item.closeReason == .discarded ? Theme.stateExpired : Theme.stateFine,
                        systemImage: item.closeReason?.symbolName
                    )
                    // Ein Eintrag kann beides sein: teilweise gegessen, Rest entsorgt.
                    // Das steht hier, damit die Plakette oben nicht die halbe Wahrheit erzaehlt.
                    if isMixed {
                        BadgeView(text: "teilweise gegessen", color: Theme.textSecondary)
                    }
                }
                .padding(.top, 1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var isMixed: Bool {
        let kinds = Set(item.eventList.map(\.kind))
        return kinds.count > 1
    }
}

enum ArchiveTimeframe: String, CaseIterable, Identifiable {
    case lastMonth
    case lastYear
    case all

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lastMonth: return "30 Tage"
        case .lastYear: return "12 Monate"
        case .all: return "Alles"
        }
    }

    var cutoffDate: Date? {
        switch self {
        case .lastMonth: return Calendar.current.date(byAdding: .day, value: -30, to: Date())
        case .lastYear: return Calendar.current.date(byAdding: .month, value: -12, to: Date())
        case .all: return nil
        }
    }
}

#Preview("Archiv") {
    ArchiveView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
