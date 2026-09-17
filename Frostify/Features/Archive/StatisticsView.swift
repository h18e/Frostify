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
                    Text("Noch keine Entnahmen – die Statistik füllt sich, sobald ihr etwas aus dem Tiefkühler nehmt.")
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
            LabeledValueRow(label: "Entnahmen") {
                Text("\(stats.eventCount)")
                    .monospacedDigit()
                    .foregroundStyle(Theme.textPrimary)
            }
            LabeledValueRow(label: "Davon gegessen") {
                Text("\(stats.consumedCount)")
                    .monospacedDigit()
                    .foregroundStyle(Theme.stateFine)
            }
            LabeledValueRow(label: "Davon weggeworfen") {
                Text("\(stats.discardedCount)")
                    .monospacedDigit()
                    .foregroundStyle(Theme.stateExpired)
            }
            if let days = stats.averageStorageDays {
                LabeledValueRow(label: "Ø Lagerdauer") {
                    Text("\(days) Tage")
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
                secondaryText: "nach Menge gewichtet"
            )
            .padding(.vertical, 4)
        } header: {
            sectionHeader("Gesamt")
        } footer: {
            Text("Die Verlustquote gewichtet nach Menge: Eine von zwei Portionen zählt als halber Eintrag. So sind Gramm, Stück und Beutel vergleichbar.")
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
            Text("Oben steht, wo am meisten verloren geht. Kategorien mit hoher Quote lohnen einen kürzeren Richtwert unter Einstellungen → Haltbarkeits-Richtwerte.")
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)
        }
        .listRowBackground(Theme.surface)
    }

    private func secondaryText(_ entry: CategoryStatistics) -> String {
        var parts = ["\(entry.discardedCount) von \(entry.eventCount) Entnahmen"]
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
