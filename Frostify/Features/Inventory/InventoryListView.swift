import CoreData
import SwiftUI

/// Der Startbildschirm: alles, was im Tiefkuehler liegt.
struct InventoryListView: View {
    @Environment(\.inventory) private var inventory
    @EnvironmentObject private var preferences: AppPreferences

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.bestBefore, ascending: true)],
        predicate: NSPredicate(format: "closedAt == nil"),
        animation: .default
    )
    private var activeItems: FetchedResults<Item>

    @State private var searchText = ""
    @State private var activeFilter: ExpiryState?
    @State private var editorTarget: ItemEditorTarget?
    @State private var consumeTarget: ConsumeTarget?
    @State private var showScanner = false
    @State private var pendingDeletion: Item?

    private var table: ShelfLifeTable { inventory.shelfLifeTable }

    private var filteredItems: [Item] {
        InventorySectionBuilder.filter(
            Array(activeItems),
            searchText: searchText,
            state: activeFilter,
            table: table
        )
    }

    private var sections: [InventorySection] {
        InventorySectionBuilder.sections(
            for: filteredItems,
            grouping: preferences.grouping,
            sorting: preferences.sorting,
            table: table
        )
    }

    private var stateCounts: [ExpiryState: Int] {
        Dictionary(grouping: Array(activeItems)) { $0.expiryState(using: table) }
            .mapValues(\.count)
    }

    var body: some View {
        NavigationStack {
            Group {
                if activeItems.isEmpty {
                    EmptyStateView(
                        title: "Tiefkühler ist leer",
                        message: "Erfasse dein erstes Produkt über das Plus oben rechts.",
                        symbolName: "snowflake"
                    )
                } else {
                    list
                }
            }
            .navigationTitle("Bestand")
            .searchable(text: $searchText, prompt: "Name, Bemerkung oder Lagerort")
            .toolbar { toolbarContent }
            .sheet(item: $editorTarget) { target in
                ItemEditorView(target: target)
            }
            .sheet(item: $consumeTarget) { target in
                ConsumeSheet(item: target.item)
            }
            .sheet(isPresented: $showScanner) {
                BarcodeScannerView { barcode in
                    showScanner = false
                    startEditorAfterScan(barcode: barcode)
                }
            }
            .confirmationDialog(
                "Eintrag wirklich löschen?",
                isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive) {
                    if let pendingDeletion { inventory.delete(pendingDeletion) }
                    pendingDeletion = nil
                }
                Button("Abbrechen", role: .cancel) { pendingDeletion = nil }
            } message: {
                Text("Löschen entfernt den Eintrag mitsamt Verlauf. Wenn du ihn aufgebraucht hast, nimm stattdessen „Alles entnehmen“ – dann bleibt er im Archiv.")
            }
        }
    }

    private var list: some View {
        List {
            Section {
                ExpirySummaryCard(counts: stateCounts, activeFilter: $activeFilter)
                    .listRowSeparator(.hidden)
            }

            if filteredItems.isEmpty {
                Section {
                    Text(activeFilter == nil
                         ? "Keine Treffer für „\(searchText)“."
                         : "Keine Produkte in dieser Ampelstufe.")
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(sections) { section in
                Section(section.title) {
                    ForEach(section.items, id: \.objectID) { item in
                        NavigationLink {
                            ItemDetailView(item: item)
                        } label: {
                            ItemRowView(item: item, table: table)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                consumeTarget = ConsumeTarget(item: item)
                            } label: {
                                Label("Entnehmen", systemImage: "minus.circle")
                            }
                            .tint(.accentColor)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                pendingDeletion = item
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                            Button {
                                editorTarget = .edit(item)
                            } label: {
                                Label("Bearbeiten", systemImage: "pencil")
                            }
                            .tint(.indigo)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("Gruppieren nach", selection: groupingBinding) {
                    ForEach(InventoryGrouping.allCases) { grouping in
                        Text(grouping.displayName).tag(grouping)
                    }
                }
                Picker("Sortieren nach", selection: sortingBinding) {
                    ForEach(InventorySorting.allCases) { sorting in
                        Text(sorting.displayName).tag(sorting)
                    }
                }
                if activeFilter != nil {
                    Button("Filter aufheben", systemImage: "line.3.horizontal.decrease.circle") {
                        activeFilter = nil
                    }
                }
            } label: {
                Label("Ansicht", systemImage: "line.3.horizontal.decrease.circle")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Manuell erfassen", systemImage: "square.and.pencil") {
                    editorTarget = .create(ItemDraft.new(table: table))
                }
                Button("Barcode scannen", systemImage: "barcode.viewfinder") {
                    showScanner = true
                }
            } label: {
                Label("Erfassen", systemImage: "plus")
            }
        }
    }

    private var groupingBinding: Binding<InventoryGrouping> {
        Binding(get: { preferences.grouping }, set: { preferences.grouping = $0 })
    }

    private var sortingBinding: Binding<InventorySorting> {
        Binding(get: { preferences.sorting }, set: { preferences.sorting = $0 })
    }

    /// Bekannter Barcode fuellt das Formular vor, unbekannter startet ein leeres mit
    /// gemerktem Code – der Katalogeintrag entsteht dann beim Speichern von selbst.
    private func startEditorAfterScan(barcode: String) {
        if let known = inventory.catalogProduct(forBarcode: barcode) {
            editorTarget = .create(ItemDraft(catalog: known, table: table))
        } else {
            var draft = ItemDraft.new(table: table)
            draft.barcode = barcode
            editorTarget = .create(draft)
        }
    }
}

/// `.sheet(item:)` verlangt einen identifizierbaren Wert. Statt uns auf eine
/// Identifiable-Konformitaet von NSManagedObject zu verlassen, kapseln wir den
/// Eintrag – das ist unabhaengig von der SDK-Version eindeutig.
struct ConsumeTarget: Identifiable {
    let item: Item
    var id: NSManagedObjectID { item.objectID }
}

#Preview("Bestand") {
    InventoryListView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
        .environmentObject(AppPreferences.shared)
}
