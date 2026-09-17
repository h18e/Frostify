import SwiftUI

/// Auswertung der abgeschlossenen Eintraege: wie lange lagert ihr was, und wo geht
/// am meisten verloren. Daraus lassen sich die Haltbarkeits-Richtwerte justieren.
struct StatisticsView: View {
    let items: [Item]

    private var statistics: InventoryStatistics {
        StatisticsBuilder.build(from: items.compactMap(Self.snapshot))
    }

    var body: some View {
        List {
            if statistics.closedCount == 0 {
                Section {
                    Text("Noch keine abgeschlossenen Einträge – die Statistik füllt sich, sobald ihr Produkte aufbraucht.")
                        .foregroundStyle(.secondary)
                }
            } else {
                overallSection
                categorySection
            }
        }
        .navigationTitle("Statistik")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var overallSection: some View {
        Section("Gesamt") {
            LabeledContent("Abgeschlossen", value: "\(statistics.closedCount)")
            LabeledContent("Davon weggeworfen", value: "\(statistics.discardedCount)")
            if let days = statistics.averageStorageDays {
                LabeledContent("Durchschnittliche Lagerdauer", value: "\(days) Tage")
            }
            Gauge(value: statistics.discardRate) {
                Text("Verlustquote")
            } currentValueLabel: {
                Text(percent(statistics.discardRate))
            }
            .tint(statistics.discardRate > 0.2 ? .red : .green)
        }
    }

    private var categorySection: some View {
        Section {
            ForEach(statistics.perCategory) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(entry.category.displayName, systemImage: entry.category.symbolName)
                            .font(.subheadline)
                        Spacer()
                        Text("\(entry.discardedCount)/\(entry.closedCount)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: entry.discardRate) {
                        EmptyView()
                    }
                    .tint(entry.discardRate > 0.2 ? .red : .green)
                    .accessibilityLabel("Verlustquote \(entry.category.displayName)")
                    .accessibilityValue(percent(entry.discardRate))

                    if let days = entry.averageStorageDays {
                        Text("Ø \(days) Tage gelagert")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Nach Kategorie")
        } footer: {
            Text("Die Zahl rechts zeigt weggeworfene von insgesamt abgeschlossenen Einträgen. Kategorien mit hoher Verlustquote lohnen einen kürzeren Richtwert in den Einstellungen.")
        }
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded())) %"
    }

    private static func snapshot(_ item: Item) -> ClosedItemSnapshot? {
        guard let closedAt = item.closedAt, let reason = item.closeReason else { return nil }
        let discarded = item.eventList
            .filter { $0.kind == .discarded }
            .reduce(0) { $0 + $1.quantityTaken }
        return ClosedItemSnapshot(
            category: item.category,
            frozenAt: item.frozenDate,
            closedAt: closedAt,
            closeReason: reason,
            initialQuantity: item.initialQuantity,
            unit: item.unit,
            discardedQuantity: discarded
        )
    }
}
