import SwiftUI

struct ItemDetailView: View {
    @ObservedObject var item: Item

    @Environment(\.inventory) private var inventory
    @Environment(\.dismiss) private var dismiss

    @State private var showConsume = false
    @State private var showEditor = false
    @State private var confirmDiscardAll = false

    private var table: ShelfLifeTable { inventory.shelfLifeTable }

    var body: some View {
        List {
            statusSection
            detailsSection
            if !item.eventList.isEmpty {
                historySection
            }
            if !item.isClosed {
                actionSection
            } else {
                archiveSection
            }
        }
        .listStyle(.insetGrouped)
        .listRowBackground(Theme.surface)
        .themedList()
        .navigationTitle(item.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Bearbeite", systemImage: "pencil") { showEditor = true }
            }
        }
        .sheet(isPresented: $showConsume) {
            ConsumeSheet(item: item)
        }
        .sheet(isPresented: $showEditor) {
            ItemEditorView(target: .edit(item))
        }
        .confirmationDialog(
            "Dr ganz Rescht wägschmeisse?",
            isPresented: $confirmDiscardAll,
            titleVisibility: .visible
        ) {
            Button("Wägschmeisse", role: .destructive) {
                inventory.consumeAll(item, kind: .discarded)
                dismiss()
            }
            Button("Abbräche", role: .cancel) {}
        } message: {
            Text("Dr Iitrag wanderet is Archiv u zeut dert aus Verlust.")
        }
        .onChange(of: item.closedAt) { _, newValue in
            // Nach "Alles entnehmen" gehoert der Eintrag ins Archiv – die Detailansicht
            // schliesst sich, statt einen leeren Bestand anzuzeigen.
            if newValue != nil { dismiss() }
        }
    }

    private var statusSection: some View {
        Section {
            HStack {
                ExpiryBadge(
                    state: item.expiryState(using: table),
                    daysRemaining: item.daysRemaining(using: table)
                )
                Spacer()
                Text(item.quantitySummary)
                    .font(.headline)
            }
            LabeledContent("Empfohle bis") {
                Text(item.resolvedBestBefore(using: table), style: .date)
            }
            if item.bestBeforeIsManual {
                Text("Vo Hand gsetzt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var detailsSection: some View {
        Section("Angabe") {
            LabeledContent("Kategorie") {
                Label(item.category.displayName, systemImage: item.category.symbolName)
            }
            LabeledContent("Igfrore am") {
                Text(item.frozenDate, style: .date)
            }
            if item.initialQuantity > 0 {
                LabeledContent("Ursprünglech", value: QuantityFormatter.string(item.initialQuantity, unit: item.unit))
            }
            if item.hasPortions {
                LabeledContent("Portione ursprünglech", value: "\(item.initialPortions)")
            }
            if !item.noteText.isEmpty {
                LabeledContent("Bemerkig", value: item.noteText)
            }
            if !item.storageLocationText.isEmpty {
                LabeledContent("Lagerort", value: item.storageLocationText)
            }
            if let barcode = item.barcodeText {
                LabeledContent("Barcode") {
                    Text(barcode).font(.footnote.monospaced())
                }
            }
            if !(item.createdByName ?? "").isEmpty {
                LabeledContent("Erfasst vo", value: item.createdByName ?? "")
            }
        }
    }

    private var historySection: some View {
        Section("Verlouf") {
            ForEach(item.eventList, id: \.objectID) { event in
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.summary(unit: item.unit))
                            Text(event.eventDate, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: event.kind.symbolName)
                            .foregroundStyle(event.kind == .discarded ? Theme.stateExpired : Theme.textSecondary)
                    }
                    Spacer()
                    if !event.byNameText.isEmpty {
                        Text(event.byNameText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button(role: .destructive) {
                        inventory.deleteEvent(event)
                    } label: {
                        Label("Lösche", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var actionSection: some View {
        Section {
            Button {
                showConsume = true
            } label: {
                Label("Usenäh", systemImage: "minus.circle.fill")
            }

            Button {
                inventory.consumeAll(item, kind: .consumed)
                dismiss()
            } label: {
                Label("Aues usenäh", systemImage: "checkmark.circle")
            }

            Button(role: .destructive) {
                confirmDiscardAll = true
            } label: {
                Label("Wäggschmisse", systemImage: "trash")
            }
        }
    }

    private var archiveSection: some View {
        Section {
            LabeledContent("Abgschlosse") {
                Text(item.closedAt ?? Date(), style: .date)
            }
            if let reason = item.closeReason {
                LabeledContent("Grund", value: reason.displayName)
            }
            Button {
                inventory.reopen(item)
            } label: {
                Label("Zrügghole", systemImage: "arrow.uturn.backward")
            }
        } footer: {
            Text("Zrügghole nimmt di letscht Usenahm zrügg u hout dr Iitrag i Vorrat.")
        }
    }
}
