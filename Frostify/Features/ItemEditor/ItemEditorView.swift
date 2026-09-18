import SwiftUI

/// Erfassen und Bearbeiten in einem Formular.
struct ItemEditorView: View {
    let target: ItemEditorTarget

    @Environment(\.inventory) private var inventory
    @Environment(\.dismiss) private var dismiss

    @State private var draft: ItemDraft
    @State private var locationSuggestions: [String] = []
    @FocusState private var nameFocused: Bool

    init(target: ItemEditorTarget) {
        self.target = target
        switch target {
        case .create(let draft):
            _draft = State(initialValue: draft)
        case .edit(let item):
            _draft = State(initialValue: ItemDraft(item: item, table: ShelfLifeTable()))
        }
    }

    private var table: ShelfLifeTable { inventory.shelfLifeTable }

    private var isEditing: Bool {
        if case .edit = target { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                productSection
                quantitySection
                dateSection
                storageSection
                if let barcode = draft.barcode, !barcode.isEmpty {
                    barcodeSection(barcode)
                }
            }
            .listRowBackground(Theme.surface)
            .themedList()
            .navigationTitle(isEditing ? "Iitrag bearbeite" : "Nöie Iitrag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbräche") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichere") { save() }
                        .disabled(!draft.isValid)
                }
            }
            .task {
                locationSuggestions = inventory.storageLocationSuggestions()
                if case .edit(let item) = target {
                    // Die Richtwerte stehen erst mit dem Repository fest, deshalb hier nachziehen.
                    draft = ItemDraft(item: item, table: table)
                }
                if !isEditing { nameFocused = true }
            }
        }
    }

    // MARK: - Abschnitte

    private var productSection: some View {
        Section("Produkt") {
            TextField("Name", text: $draft.name)
                .focused($nameFocused)
                .textInputAutocapitalization(.sentences)

            Picker("Kategorie", selection: $draft.category) {
                ForEach(FoodCategory.allCases) { category in
                    Label(category.displayName, systemImage: category.symbolName)
                        .tag(category)
                }
            }
            .onChange(of: draft.category) { oldValue, newValue in
                // Einheit nur mitziehen, solange sie noch auf der Vorgabe der alten
                // Kategorie steht – eine bewusst gewaehlte Einheit bleibt stehen.
                if draft.unit == oldValue.defaultUnit {
                    draft.unit = newValue.defaultUnit
                }
                draft.recalculateBestBefore(using: table)
            }

            TextField("Bemerkig", text: $draft.note, axis: .vertical)
                .lineLimit(1...4)
        }
    }

    private var quantitySection: some View {
        Section {
            HStack {
                Text("Mängi")
                Spacer()
                TextField("0", value: $draft.quantity, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 110)
                Picker("Einheit", selection: $draft.unit) {
                    ForEach(StorageUnit.allCases) { unit in
                        Text(unit.shortName).tag(unit)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }

            Stepper(value: $draft.portions, in: 0...99) {
                HStack {
                    Text("Portione")
                    Spacer()
                    Text(draft.portions == 0 ? "kei Angab" : "\(draft.portions)")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Mängi")
        } footer: {
            Text("Bispiu: 400 g Rindsteak, 2 Portione, Bemerkig „2 Steaks im Sack“. Bim Usenäh rächnet d App zwüsche Mängi u Portione um.")
        }
    }

    private var dateSection: some View {
        Section {
            DatePicker("Igfrore am", selection: $draft.frozenAt, displayedComponents: .date)
                .onChange(of: draft.frozenAt) { _, _ in
                    draft.recalculateBestBefore(using: table)
                }

            DatePicker("Empfohle bis", selection: bestBeforeBinding, displayedComponents: .date)

            if draft.bestBeforeIsManual {
                Button("Uf Richtwärt zrügsetze", systemImage: "arrow.uturn.backward") {
                    draft.bestBeforeIsManual = false
                    draft.recalculateBestBefore(using: table)
                }
                .font(.footnote)
            }
        } header: {
            Text("Haltbarkeit")
        } footer: {
            Text(draft.bestBeforeIsManual
                 ? "Vo Hand gsetzt – dr Richtwärt vo dr Kategorie wird nüm aagwändet."
                 : "Richtwärt für \(draft.category.displayName): \(table.months(for: draft.category)) Mönet.")
        }
    }

    private var storageSection: some View {
        Section {
            TextField("z. B. Schublade 2", text: $draft.storageLocation)
                .textInputAutocapitalization(.sentences)

            if !locationSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(locationSuggestions, id: \.self) { suggestion in
                            Button(suggestion) {
                                draft.storageLocation = suggestion
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                            .font(.footnote)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        } header: {
            Text("Lagerort")
        } footer: {
            Text("Hauft bim Finde, ohni dr ganz Tiefchüeler uszrume.")
        }
    }

    private func barcodeSection(_ barcode: String) -> some View {
        Section {
            HStack {
                Label(barcode, systemImage: "barcode")
                    .font(.footnote.monospaced())
                Spacer()
                Button("Wägnäh", role: .destructive) {
                    draft.barcode = nil
                }
                .font(.footnote)
            }
        } header: {
            Text("Barcode")
        } footer: {
            Text("Bim Sichere merkt sech Frostify Name, Kategorie, Einheit u Mängi zu däm Code. Bim nächschte Scan isch aues scho usgfüut.")
        }
    }

    // MARK: - Verhalten

    /// Jede Aenderung am Datum durch dich markiert es als von Hand gesetzt – danach
    /// zieht der Kategorie-Richtwert nicht mehr nach.
    private var bestBeforeBinding: Binding<Date> {
        Binding(
            get: { draft.bestBefore },
            set: { newValue in
                draft.bestBefore = newValue
                draft.bestBeforeIsManual = true
            }
        )
    }

    private func save() {
        guard draft.isValid else { return }
        switch target {
        case .create:
            inventory.createItem(from: draft)
        case .edit(let item):
            inventory.update(item, with: draft)
        }
        dismiss()
    }
}

#Preview("Erfasse") {
    ItemEditorView(target: .create(ItemDraft.new(category: .meat)))
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
