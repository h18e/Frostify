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
    /// Der gescannte Code wartet hier, bis das Scanner-Blatt wirklich zu ist.
    @State private var scannedBarcode: String?
    @State private var isLookingUp = false
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
                        symbol: "snowflake",
                        title: "Dr Tiefchüeler isch läär",
                        message: "Erfass dys erschte Produkt übers Plus obe rächts.",
                        actionTitle: "Produkt erfasse",
                        action: { editorTarget = .create(ItemDraft.new(table: table)) }
                    )
                    .frame(maxHeight: .infinity)
                    .screenBackground()
                } else {
                    list
                }
            }
            .overlay {
                if isLookingUp {
                    lookupOverlay
                }
            }
            .navigationTitle("Vorrat")
            .searchable(text: $searchText, prompt: "Name, Bemerkig oder Lagerort")
            .toolbar { toolbarContent }
            .sheet(item: $editorTarget) { target in
                ItemEditorView(target: target)
            }
            .sheet(item: $consumeTarget) { target in
                ConsumeSheet(item: target.item)
            }
            // Das Formular wird erst geoeffnet, wenn das Scanner-Blatt zu ist.
            // Zwei Blaetter gleichzeitig zu wechseln laesst iOS das zweite
            // stillschweigend fallen – man scannt, und es passiert nichts.
            .sheet(isPresented: $showScanner, onDismiss: {
                guard let barcode = scannedBarcode else { return }
                scannedBarcode = nil
                startEditorAfterScan(barcode: barcode)
            }) {
                BarcodeScannerView { barcode in
                    scannedBarcode = barcode
                    showScanner = false
                }
            }
            .confirmationDialog(
                "Iitrag würklech lösche?",
                isPresented: Binding(
                    get: { pendingDeletion != nil },
                    set: { if !$0 { pendingDeletion = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Lösche", role: .destructive) {
                    if let pendingDeletion { inventory.delete(pendingDeletion) }
                    pendingDeletion = nil
                }
                Button("Abbräche", role: .cancel) { pendingDeletion = nil }
            } message: {
                Text("Lösche nimmt dr Iitrag mitsamt em Verlouf wäg. Wenn du ne ufbrucht hesch, nimm statt däm „Aues usenäh“ – de blibt er im Archiv.")
            }
        }
    }

    private var list: some View {
        List {
            Section {
                ExpirySummaryCard(counts: stateCounts, activeFilter: $activeFilter)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                // Die Gruppierung steht bewusst sichtbar hier und nicht im Menü:
                // "Was habe ich eigentlich alles da" ist ein haeufiger Blick, der
                // keinen Umweg ueber ein Untermenue verdient.
                Picker("Gruppiere", selection: groupingBinding) {
                    ForEach(InventoryGrouping.allCases) { grouping in
                        Text(grouping.displayName).tag(grouping)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if filteredItems.isEmpty {
                Section {
                    Text(activeFilter == nil
                         ? "Kei Träffer für „\(searchText)“."
                         : "Kei Produkt i dere Ampustufe.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .listRowBackground(Theme.surface)
                }
            }

            ForEach(sections) { section in
                Section {
                    ForEach(section.items, id: \.objectID) { item in
                        NavigationLink {
                            ItemDetailView(item: item)
                        } label: {
                            ItemRowView(item: item, table: table)
                        }
                        .listRowBackground(Theme.surface)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                consumeTarget = ConsumeTarget(item: item)
                            } label: {
                                Label("Usenäh", systemImage: "minus.circle")
                            }
                            .tint(Theme.accent)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                pendingDeletion = item
                            } label: {
                                Label("Lösche", systemImage: "trash")
                            }
                            Button {
                                editorTarget = .edit(item)
                            } label: {
                                Label("Bearbeite", systemImage: "pencil")
                            }
                            .tint(Theme.surfaceElevated)
                        }
                    }
                } header: {
                    HStack(alignment: .firstTextBaseline) {
                        Text(section.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .textCase(nil)
                        Spacer(minLength: 8)
                        Text(section.subtitle)
                            .font(.caption)
                            .foregroundStyle(Theme.textTertiary)
                            .textCase(nil)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .themedList()
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("Sortiere nach", selection: sortingBinding) {
                    ForEach(InventorySorting.allCases) { sorting in
                        Text(sorting.displayName).tag(sorting)
                    }
                }
                if activeFilter != nil {
                    Button("Filter ufhebe", systemImage: "line.3.horizontal.decrease.circle") {
                        activeFilter = nil
                    }
                }
            } label: {
                Label("Sortierig", systemImage: "arrow.up.arrow.down")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Vo Hand erfasse", systemImage: "square.and.pencil") {
                    editorTarget = .create(ItemDraft.new(table: table))
                }
                Button("Barcode scanne", systemImage: "barcode.viewfinder") {
                    showScanner = true
                }
            } label: {
                Label("Erfasse", systemImage: "plus")
            }
        }
    }

    private var groupingBinding: Binding<InventoryGrouping> {
        Binding(get: { preferences.grouping }, set: { preferences.grouping = $0 })
    }

    private var sortingBinding: Binding<InventorySorting> {
        Binding(get: { preferences.sorting }, set: { preferences.sorting = $0 })
    }

    /// Drei Quellen, in dieser Reihenfolge:
    ///
    /// 1. **Der eigene Katalog.** Was ihr einmal erfasst habt, gilt – ohne Netz,
    ///    ohne Wartezeit, und mit euren eigenen Namen und Mengen.
    /// 2. **Open Food Facts**, nur bei unbekanntem Code und nur wenn erlaubt.
    /// 3. **Leeres Formular**, wenn beides nichts hergibt.
    ///
    /// In jedem Fall landet beim Sichern das Ergebnis im eigenen Katalog – ab dem
    /// zweiten Scan desselben Produkts wird also gar nichts mehr gefragt.
    private func startEditorAfterScan(barcode: String) {
        if let known = inventory.catalogProduct(forBarcode: barcode) {
            editorTarget = .create(ItemDraft(catalog: known, table: table))
            return
        }

        guard preferences.usesOpenFoodFacts else {
            editorTarget = .create(draft(forUnknown: barcode, origin: .scanUnknown))
            return
        }

        isLookingUp = true
        Task {
            let result = await OpenFoodFactsService.lookup(barcode: barcode)
            isLookingUp = false
            switch result {
            case .found(let suggestion):
                editorTarget = .create(ItemDraft(suggestion: suggestion, barcode: barcode, table: table))
            case .notFound:
                editorTarget = .create(draft(forUnknown: barcode, origin: .scanUnknown))
            case .unavailable:
                editorTarget = .create(draft(forUnknown: barcode, origin: .scanOffline))
            }
        }
    }

    private func draft(forUnknown barcode: String, origin: DraftOrigin) -> ItemDraft {
        var draft = ItemDraft.new(table: table)
        draft.barcode = barcode
        draft.origin = origin
        return draft
    }

    private var lookupOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Suech ds Produkt …")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(24)
        .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .shadow(radius: 12)
    }
}

/// `.sheet(item:)` verlangt einen identifizierbaren Wert. Statt uns auf eine
/// Identifiable-Konformitaet von NSManagedObject zu verlassen, kapseln wir den
/// Eintrag – das ist unabhaengig von der SDK-Version eindeutig.
struct ConsumeTarget: Identifiable {
    let item: Item
    var id: NSManagedObjectID { item.objectID }
}

#Preview("Vorrat") {
    InventoryListView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
        .environmentObject(AppPreferences.shared)
        .preferredColorScheme(.dark)
}
