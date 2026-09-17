import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.inventory) private var inventory

    @State private var displayName = ""
    @State private var schemaMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Dein Name", text: $displayName)
                        .onSubmit { preferences.displayName = displayName }
                } header: {
                    Text("Name")
                } footer: {
                    Text("Wird an erfassten Einträgen und Entnahmen vermerkt, damit ihr seht, wer was gemacht hat.")
                }

                Section("Gemeinsam") {
                    NavigationLink {
                        SharingView()
                    } label: {
                        Label("Teilen", systemImage: "person.2")
                    }
                    NavigationLink {
                        ShelfLifeSettingsView()
                    } label: {
                        Label("Haltbarkeits-Richtwerte", systemImage: "calendar.badge.clock")
                    }
                }

                Section("Dieses Gerät") {
                    NavigationLink {
                        ReminderSettingsView()
                    } label: {
                        Label("Erinnerungen", systemImage: "bell")
                    }

                    Picker(selection: groupingBinding) {
                        ForEach(InventoryGrouping.allCases) { grouping in
                            Text(grouping.displayName).tag(grouping)
                        }
                    } label: {
                        Label("Gruppierung", systemImage: "rectangle.3.group")
                    }

                    Picker(selection: sortingBinding) {
                        ForEach(InventorySorting.allCases) { sorting in
                            Text(sorting.displayName).tag(sorting)
                        }
                    } label: {
                        Label("Sortierung", systemImage: "arrow.up.arrow.down")
                    }
                }

                aboutSection

                #if DEBUG
                developmentSection
                #endif
            }
            .listRowBackground(Theme.surface)
            .themedList()
            .navigationTitle("Einstellungen")
            .task { displayName = preferences.displayName }
            .onDisappear { preferences.displayName = displayName }
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Version", value: Self.versionString)
            Label("Deine Daten liegen in deinem privaten iCloud-Bereich. Frostify hat keinen eigenen Server.", systemImage: "lock")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } header: {
            Text("Über")
        }
    }

    #if DEBUG
    private var developmentSection: some View {
        Section {
            Button("CloudKit-Schema anlegen", systemImage: "icloud.and.arrow.up") {
                do {
                    try PersistenceController.shared.initializeCloudKitSchema()
                    schemaMessage = "Schema in der Development-Umgebung angelegt."
                } catch {
                    schemaMessage = error.localizedDescription
                }
            }
            if let schemaMessage {
                Text(schemaMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Entwicklung")
        } footer: {
            Text("Einmal nach dem ersten Start ausführen. Danach erscheinen die Record-Typen im CloudKit-Dashboard und lassen sich vor einer Verteilung nach Production übertragen.")
        }
    }
    #endif

    private static var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    private var groupingBinding: Binding<InventoryGrouping> {
        Binding(get: { preferences.grouping }, set: { preferences.grouping = $0 })
    }

    private var sortingBinding: Binding<InventorySorting> {
        Binding(get: { preferences.sorting }, set: { preferences.sorting = $0 })
    }
}

#Preview("Einstellungen") {
    SettingsView()
        .environmentObject(AppPreferences.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
