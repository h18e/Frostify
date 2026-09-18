import SwiftUI

/// Haltbarkeits-Richtwerte je Kategorie. Sie haengen am Tiefkuehler und gelten
/// deshalb fuer beide Teilnehmer.
struct ShelfLifeSettingsView: View {
    @Environment(\.inventory) private var inventory
    @State private var table = ShelfLifeTable()

    var body: some View {
        Form {
            Section {
                ForEach(FoodCategory.allCases) { category in
                    Stepper(value: binding(for: category), in: 1...60) {
                        VStack(alignment: .leading, spacing: 2) {
                            Label(category.displayName, systemImage: category.symbolName)
                            HStack(spacing: 4) {
                                Text("\(table.months(for: category)) Mönet")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if table.isOverridden(category) {
                                    Text("· aapasst")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Richtwärt")
            } footer: {
                Text("Us em Igfrier-Datum u em Richtwärt rächnet Frostify ds „empfohle bis“-Datum. Scho erfassti Iiträg bhaute ihres Datum – e gänderete Richtwärt wirkt uf nöii Iiträg.")
            }

            Section {
                Button("Aui uf Standard zrügsetze", systemImage: "arrow.uturn.backward") {
                    table.resetAll()
                    inventory.updateShelfLife(table)
                }
            }
        }
        .listRowBackground(Theme.surface)
        .themedList()
        .navigationTitle("Haltbarkeit")
        .navigationBarTitleDisplayMode(.inline)
        .task { table = inventory.shelfLifeTable }
    }

    private func binding(for category: FoodCategory) -> Binding<Int> {
        Binding(
            get: { table.months(for: category) },
            set: { newValue in
                table.set(months: newValue, for: category)
                inventory.updateShelfLife(table)
            }
        )
    }
}
