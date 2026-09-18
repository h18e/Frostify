import SwiftUI

/// Teilentnahme: Menge und Portionen haengen aneinander, die App rechnet die jeweils
/// andere Groesse mit und zeigt beide, bevor du bestaetigst.
struct ConsumeSheet: View {
    @ObservedObject var item: Item

    @Environment(\.inventory) private var inventory
    @Environment(\.dismiss) private var dismiss

    @State private var quantity: Double
    @State private var portions: Int
    @State private var kind: ConsumptionKind = .consumed

    init(item: Item) {
        self.item = item
        if item.hasPortions, item.remainingPortions > 0 {
            let startPortions = 1
            _portions = State(initialValue: startPortions)
            _quantity = State(initialValue: QuantityMath.clamp(
                QuantityMath.quantity(
                    forPortions: startPortions,
                    initialQuantity: item.initialQuantity,
                    initialPortions: Int(item.initialPortions)
                ),
                max: item.remainingQuantity
            ))
        } else {
            _portions = State(initialValue: 0)
            _quantity = State(initialValue: item.remainingQuantity)
        }
    }

    private var canConfirm: Bool {
        quantity > 0 || portions > 0
    }

    private var remainingAfter: (quantity: Double, portions: Int) {
        (
            QuantityMath.remainingQuantity(initial: item.remainingQuantity, taken: quantity),
            QuantityMath.remainingPortions(initial: item.remainingPortions, taken: portions)
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Vorhande", value: item.quantitySummary)
                    if !item.noteText.isEmpty {
                        LabeledContent("Bemerkig", value: item.noteText)
                    }
                } header: {
                    Text(item.displayName)
                }

                if item.hasPortions {
                    Section("Portione usenäh") {
                        Stepper(value: portionsBinding, in: 0...item.remainingPortions) {
                            HStack {
                                Text("Portione")
                                Spacer()
                                Text("\(portions) vo \(item.remainingPortions)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if item.initialQuantity > 0 {
                    Section("Mängi usenäh") {
                        Stepper(value: quantityBinding, in: 0...item.remainingQuantity, step: item.unit.step) {
                            HStack {
                                Text("Mängi")
                                Spacer()
                                Text(QuantityFormatter.string(quantity, unit: item.unit))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Slider(value: quantityBinding, in: 0...max(item.remainingQuantity, 0.001)) {
                            Text("Mängi")
                        }
                        .accessibilityValue(QuantityFormatter.string(quantity, unit: item.unit))
                    }
                }

                Section {
                    Picker("Grund", selection: $kind) {
                        ForEach(ConsumptionKind.allCases) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(kind == .discarded
                         ? "Was du wägschmeisst, zeut i dr Statistik aus Verlust – genau das zeigt speter, wo sech d Richtwärt loh."
                         : "Nachhär no da: \(remainingSummary)")
                }

                Section {
                    Button {
                        confirm(quantity: quantity, portions: portions)
                    } label: {
                        Label("Usenäh", systemImage: "minus.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canConfirm)

                    Button {
                        confirm(quantity: item.remainingQuantity, portions: item.remainingPortions)
                    } label: {
                        Label("Aues usenäh", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .listRowBackground(Theme.surface)
            .themedList()
            .navigationTitle("Usenäh")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbräche") { dismiss() }
                }
            }
        }
    }

    private var remainingSummary: String {
        var parts: [String] = []
        if item.initialQuantity > 0 {
            parts.append(QuantityFormatter.string(remainingAfter.quantity, unit: item.unit))
        }
        if item.hasPortions {
            parts.append(QuantityFormatter.portionsString(remainingAfter.portions))
        }
        let text = parts.isEmpty ? "nüt" : parts.joined(separator: " · ")
        let empty = QuantityMath.isEmpty(
            remainingQuantity: remainingAfter.quantity,
            remainingPortions: remainingAfter.portions,
            hasPortions: item.hasPortions
        )
        return empty ? "\(text) – dr Iitrag wanderet is Archiv" : text
    }

    // Die beiden Bindungen setzen jeweils **beide** Werte direkt. Dadurch kann sich
    // die Umrechnung nicht gegenseitig aufschaukeln, wie es bei zwei onChange-Beobachtern
    // passieren wuerde.
    private var portionsBinding: Binding<Int> {
        Binding(
            get: { portions },
            set: { newValue in
                portions = newValue
                quantity = QuantityMath.clamp(
                    QuantityMath.quantity(
                        forPortions: newValue,
                        initialQuantity: item.initialQuantity,
                        initialPortions: Int(item.initialPortions)
                    ),
                    max: item.remainingQuantity
                )
            }
        )
    }

    private var quantityBinding: Binding<Double> {
        Binding(
            get: { quantity },
            set: { newValue in
                quantity = QuantityMath.clamp(newValue, max: item.remainingQuantity)
                portions = min(
                    item.remainingPortions,
                    QuantityMath.portions(
                        forQuantity: quantity,
                        initialQuantity: item.initialQuantity,
                        initialPortions: Int(item.initialPortions)
                    )
                )
            }
        )
    }

    private func confirm(quantity: Double, portions: Int) {
        inventory.consume(item, quantity: quantity, portions: portions, kind: kind)
        dismiss()
    }
}
