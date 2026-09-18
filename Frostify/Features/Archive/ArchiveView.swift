import CoreData
import SwiftUI

/// Alles, was den Tiefkühler verlassen hat – als Liste **einzelner Entnahmen**.
///
/// Bewusst nicht je Produkt: Wer eine von zwei Portionen isst und die zweite
/// wegwirft, hat eine Portion gegessen und eine weggeworfen. Eine Liste je Produkt
/// müsste sich für eines von beidem entscheiden; aus einem Eintrag werden hier
/// deshalb zwei Zeilen. Damit stimmen Archiv und Statistik auch überein – beide
/// zählen dasselbe.
struct ArchiveView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ConsumptionEvent.date, ascending: false)],
        animation: .default
    )
    private var events: FetchedResults<ConsumptionEvent>

    @State private var kindFilter: ConsumptionKind?
    @State private var timeframe: ArchiveTimeframe = .lastYear
    @State private var onlyClosed = false
    @State private var searchText = ""

    private var filtered: [ConsumptionEvent] {
        let cutoff = timeframe.cutoffDate
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return events.filter { event in
            guard let item = event.item else { return false }
            if let cutoff, event.eventDate < cutoff { return false }
            if let kindFilter, event.kind != kindFilter { return false }
            if onlyClosed, !item.isClosed { return false }
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
                if events.isEmpty {
                    EmptyStateView(
                        symbol: "archivebox",
                        title: "No nüt usegnoh",
                        message: "Sobaud du öppis usem Tiefchüeler nimmsch oder wägschmeisst, erschint's da."
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
                    Text("Aui").tag(ConsumptionKind?.none)
                    Text("Gässe").tag(ConsumptionKind?.some(.consumed))
                    Text("Wäggschmisse").tag(ConsumptionKind?.some(.discarded))
                }
                .pickerStyle(.segmented)

                Picker("Zitruum", selection: $timeframe) {
                    ForEach(ArchiveTimeframe.allCases) { frame in
                        Text(frame.displayName).tag(frame)
                    }
                }

                Toggle("Nume ufbruchti Produkt", isOn: $onlyClosed)
            }
            .listRowBackground(Theme.surface)

            if filtered.isEmpty {
                Section {
                    Text("Kei Usenahme i dere Uswau.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .listRowBackground(Theme.surface)
            }

            Section {
                ForEach(filtered, id: \.objectID) { event in
                    if let item = event.item {
                        NavigationLink {
                            ItemDetailView(item: item)
                        } label: {
                            ConsumptionRow(event: event, item: item)
                        }
                    }
                }
            } header: {
                Text(headerText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .textCase(nil)
            }
            .listRowBackground(Theme.surface)
        }
        .listStyle(.insetGrouped)
        .themedList()
    }

    private var headerText: String {
        filtered.count == 1 ? "1 Usenahm" : "\(filtered.count) Usenahme"
    }
}

/// Eine Zeile je Entnahme.
private struct ConsumptionRow: View {
    @ObservedObject var event: ConsumptionEvent
    @ObservedObject var item: Item

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CategoryIcon(category: item.category, size: 30)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.displayName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(event.summary(unit: item.unit))
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                }

                Text(item.category.displayName)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)

                HStack(spacing: 6) {
                    Text(event.eventDate, style: .date)
                    Text("·")
                    Text("nach \(storageDays) Täg")
                }
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)

                HStack(spacing: 6) {
                    BadgeView(
                        text: event.kind.displayName,
                        color: event.kind == .discarded ? Theme.stateExpired : Theme.stateFine,
                        systemImage: event.kind.symbolName
                    )
                    // Das Produkt liegt noch im Tiefkuehler – hier steht nur dieser
                    // eine entnommene Anteil, nicht der ganze Eintrag.
                    if !item.isClosed {
                        BadgeView(text: "no im Vorrat", color: Theme.textSecondary)
                    }
                    if !event.byNameText.isEmpty {
                        Text(event.byNameText)
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
                .padding(.top, 1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var storageDays: Int {
        StatisticsBuilder.storageDays(from: item.frozenDate, to: event.eventDate)
    }
}

enum ArchiveTimeframe: String, CaseIterable, Identifiable {
    case lastMonth
    case lastYear
    case all

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lastMonth: return "30 Täg"
        case .lastYear: return "12 Mönet"
        case .all: return "Aues"
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
        .preferredColorScheme(.dark)
}
