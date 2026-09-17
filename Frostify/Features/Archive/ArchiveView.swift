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
                        title: "Archiv ist leer",
                        message: "Sobald du etwas ganz entnimmst oder wegwirfst, erscheint es hier.",
                        symbolName: "archivebox"
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Archiv")
            .searchable(text: $searchText, prompt: "Name oder Kategorie")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        StatisticsView(items: Array(closedItems))
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

            if filtered.isEmpty {
                Section {
                    Text("Keine Einträge in dieser Auswahl.")
                        .foregroundStyle(.secondary)
                }
            }

            Section("\(filtered.count) Einträge") {
                ForEach(filtered, id: \.objectID) { item in
                    NavigationLink {
                        ItemDetailView(item: item)
                    } label: {
                        ArchiveRow(item: item)
                    }
                }
            }
        }
    }
}

private struct ArchiveRow: View {
    @ObservedObject var item: Item

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.closeReason?.symbolName ?? "checkmark.circle")
                .foregroundStyle(item.closeReason == .discarded ? .red : .green)
                .frame(width: 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .fontWeight(.medium)
                Text(item.category.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(item.closedAt ?? Date(), style: .date)
                    Text("·")
                    Text("\(StatisticsBuilder.storageDays(from: item.frozenDate, to: item.closedAt ?? Date())) Tage gelagert")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
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
