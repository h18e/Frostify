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
            .navigationTitle(isEditing ? "Eintrag bearbeiten" : "Neuer Eintrag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") { save() }
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

            TextField("Bemerkung", text: $draft.note, axis: .vertical)
                .lineLimit(1...4)
        }
    }

    private var quantitySection: some View {
        Section {
            HStack {
                Text("Menge")
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
                    Text("Portionen")
                    Spacer()
                    Text(draft.portions == 0 ? "keine Angabe" : "\(draft.portions)")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Menge")
        } footer: {
            Text("Beispiel: 400 g Rindsteak, 2 Portionen, Bemerkung „2 Steaks im Beutel“. Beim Entnehmen rechnet die App zwischen Menge und Portionen um.")
        }
    }

    private var dateSection: some View {
        Section {
            DatePicker("Eingefroren am", selection: $draft.frozenAt, displayedComponents: .date)
                .onChange(of: draft.frozenAt) { _, _ in
                    draft.recalculateBestBefore(using: table)
                }

            DatePicker("Empfohlen bis", selection: bestBeforeBinding, displayedComponents: .date)

            if draft.bestBeforeIsManual {
                Button("Auf Richtwert zurücksetzen", systemImage: "arrow.uturn.backward") {
                    draft.bestBeforeIsManual = false
                    draft.recalculateBestBefore(using: table)
                }
                .font(.footnote)
            }
        } header: {
            Text("Haltbarkeit")
        } footer: {
            Text(draft.bestBeforeIsManual
                 ? "Von Hand gesetzt – der Richtwert der Kategorie wird nicht mehr angewendet."
                 : "Richtwert für \(draft.category.displayName): \(table.months(for: draft.category)) Monate.")
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
            Text("Hilft beim Finden, ohne den ganzen Tiefkühler auszuräumen.")
        }
    }

    private func barcodeSection(_ barcode: String) -> some View {
        Section {
            HStack {
                Label(barcode, systemImage: "barcode")
                    .font(.footnote.monospaced())
                Spacer()
                Button("Entfernen", role: .destructive) {
                    draft.barcode = nil
                }
                .font(.footnote)
            }
        } header: {
            Text("Barcode")
        } footer: {
            Text("Beim Sichern merkt sich Frostify Name, Kategorie, Einheit und Menge zu diesem Code. Beim nächsten Scan ist alles vorausgefüllt.")
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

#Preview("Erfassen") {
    ItemEditorView(target: .create(ItemDraft.new(category: .meat)))
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
