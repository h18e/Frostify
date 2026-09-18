import CoreData
import SwiftUI

/// Auswertung dessen, was den Tiefkühler verlassen hat.
///
/// Gezählt werden **einzelne Entnahmen**, nicht abgeschlossene Einträge. Wer eine
/// von zwei Portionen isst und die zweite wegwirft, taucht damit in beiden Zahlen
/// auf. Vorher zählte nur der abgeschlossene Eintrag – die gegessene Hälfte war
/// nirgends sichtbar.
struct StatisticsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.frozenAt, ascending: false)],
        animation: .default
    )
    private var allItems: FetchedResults<Item>

    private var statistics: InventoryStatistics {
        var events: [ConsumptionSnapshot] = []
        var closed: [ClosedItemSnapshot] = []

        for item in allItems {
            for event in item.eventList {
                events.append(
                    ConsumptionSnapshot(
                        category: item.category,
                        date: event.eventDate,
                        kind: event.kind,
                        share: StatisticsBuilder.share(
                            quantityTaken: event.quantityTaken,
                            initialQuantity: item.initialQuantity,
                            portionsTaken: Int(event.portionsTaken),
                            initialPortions: Int(item.initialPortions)
                        )
                    )
                )
            }
            if let closedAt = item.closedAt {
                closed.append(
                    ClosedItemSnapshot(
                        category: item.category,
                        frozenAt: item.frozenDate,
                        closedAt: closedAt
                    )
                )
            }
        }

        return StatisticsBuilder.build(events: events, closedItems: closed)
    }

    var body: some View {
        content(statistics)
    }

    private func content(_ stats: InventoryStatistics) -> some View {
        List {
            if stats.eventCount == 0 {
                Section {
                    Text("No kei Verbrüch – d Statistik füut sech, sobaud dir öppis usem Tiefchüeler nämet.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .listRowBackground(Theme.surface)
            } else {
                overallSection(stats)
                categorySection(stats)
            }
        }
        .listStyle(.insetGrouped)
        .themedList()
        .navigationTitle("Statistik")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func overallSection(_ stats: InventoryStatistics) -> some View {
        Section {
            LabeledValueRow(label: "Verbrüch") {
                Text("\(stats.eventCount)")
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
            }
            LabeledValueRow(label: "Dervo gässe") {
                Text("\(stats.consumedCount)")
                    .monospacedDigit()
                    .foregroundStyle(Theme.stateFine)
            }
            LabeledValueRow(label: "Dervo wäggschmisse") {
                Text("\(stats.discardedCount)")
                    .monospacedDigit()
                    .foregroundStyle(Theme.stateExpired)
            }
            if let days = stats.averageStorageDays {
                LabeledValueRow(label: "Ø Lagerduur") {
                    Text("\(days) Täg")
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                }
            }

            BarRow(
                title: "Verlustquote",
                symbolName: "trash",
                color: stats.discardRate > 0.2 ? Theme.stateExpired : Theme.stateFine,
                fraction: stats.discardRate,
                primaryText: percent(stats.discardRate),
                secondaryText: "nach Mängi gwichtet"
            )
            .padding(.vertical, 4)
        } header: {
            sectionHeader("Total")
        } footer: {
            Text("D Verlustquote gwichtet nach Mängi: Ei vo zwo Portione zeut aus haube Iitrag. So si Gramm, Stück u Sack vergliechbar.")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
        }
        .listRowBackground(Theme.surface)
    }

    private func categorySection(_ stats: InventoryStatistics) -> some View {
        Section {
            ForEach(stats.perCategory) { entry in
                BarRow(
                    title: entry.category.displayName,
                    symbolName: entry.category.symbolName,
                    color: entry.discardRate > 0.2 ? Theme.stateExpired : entry.category.color,
                    fraction: entry.discardRate,
                    primaryText: percent(entry.discardRate),
                    secondaryText: secondaryText(entry)
                )
                .padding(.vertical, 4)
            }
        } header: {
            sectionHeader("Nach Kategorie")
        } footer: {
            Text("Obe steit, wo am meischte verlore geit. Kategorie mit hocher Quote lohne ne chürzere Richtwärt under Istellige → Haltbarkeits-Richtwärt.")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
        }
        .listRowBackground(Theme.surface)
    }

    private func secondaryText(_ entry: CategoryStatistics) -> String {
        var parts = ["\(entry.discardedCount) vo \(entry.eventCount) Verbrüch"]
        if let days = entry.averageStorageDays {
            parts.append("Ø \(days) T")
        }
        return parts.joined(separator: " · ")
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.textSecondary)
            .textCase(nil)
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded())) %"
    }
}

#Preview("Statistik") {
    NavigationStack {
        StatisticsView()
            .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
    }
    .preferredColorScheme(.dark)
}
