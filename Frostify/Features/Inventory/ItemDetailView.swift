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
        .navigationTitle(item.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Bearbeiten", systemImage: "pencil") { showEditor = true }
            }
        }
        .sheet(isPresented: $showConsume) {
            ConsumeSheet(item: item)
        }
        .sheet(isPresented: $showEditor) {
            ItemEditorView(target: .edit(item))
        }
        .confirmationDialog(
            "Ganzen Rest wegwerfen?",
            isPresented: $confirmDiscardAll,
            titleVisibility: .visible
        ) {
            Button("Wegwerfen", role: .destructive) {
                inventory.consumeAll(item, kind: .discarded)
                dismiss()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Der Eintrag wandert ins Archiv und zählt dort als Verlust.")
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
            LabeledContent("Empfohlen bis") {
                Text(item.resolvedBestBefore(using: table), style: .date)
            }
            if item.bestBeforeIsManual {
                Text("Von Hand gesetzt")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var detailsSection: some View {
        Section("Angaben") {
            LabeledContent("Kategorie") {
                Label(item.category.displayName, systemImage: item.category.symbolName)
            }
            LabeledContent("Eingefroren am") {
                Text(item.frozenDate, style: .date)
            }
            if item.initialQuantity > 0 {
                LabeledContent("Ursprünglich", value: QuantityFormatter.string(item.initialQuantity, unit: item.unit))
            }
            if item.hasPortions {
                LabeledContent("Portionen ursprünglich", value: "\(item.initialPortions)")
            }
            if !item.noteText.isEmpty {
                LabeledContent("Bemerkung", value: item.noteText)
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
                LabeledContent("Erfasst von", value: item.createdByName ?? "")
            }
        }
    }

    private var historySection: some View {
        Section("Verlauf") {
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
                            .foregroundStyle(event.kind == .discarded ? .red : .secondary)
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
                        Label("Löschen", systemImage: "trash")
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
                Label("Entnehmen", systemImage: "minus.circle.fill")
            }

            Button {
                inventory.consumeAll(item, kind: .consumed)
                dismiss()
            } label: {
                Label("Alles entnehmen", systemImage: "checkmark.circle")
            }

            Button(role: .destructive) {
                confirmDiscardAll = true
            } label: {
                Label("Weggeworfen", systemImage: "trash")
            }
        }
    }

    private var archiveSection: some View {
        Section {
            LabeledContent("Abgeschlossen") {
                Text(item.closedAt ?? Date(), style: .date)
            }
            if let reason = item.closeReason {
                LabeledContent("Grund", value: reason.displayName)
            }
            Button {
                inventory.reopen(item)
            } label: {
                Label("Wiederherstellen", systemImage: "arrow.uturn.backward")
            }
        } footer: {
            Text("Wiederherstellen nimmt die letzte Entnahme zurück und holt den Eintrag in den Bestand.")
        }
    }
}
