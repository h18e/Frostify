import SwiftUI
import UserNotifications

struct ReminderSettingsView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @Environment(\.notificationScheduler) private var scheduler

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var reminderTime = Date()

    var body: some View {
        Form {
            Section {
                Toggle("Mäudig jedi Wuche", isOn: remindersEnabledBinding)

                if preferences.remindersEnabled {
                    Picker("Wuchetag", selection: weekdayBinding) {
                        ForEach(1...7, id: \.self) { weekday in
                            Text(Weekday.name(weekday)).tag(weekday)
                        }
                    }
                    DatePicker("Zit", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderTime) { _, newValue in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            preferences.reminderHour = components.hour ?? 18
                            preferences.reminderMinute = components.minute ?? 0
                            refresh()
                        }
                    Stepper(value: horizonBinding, in: 1...60, step: 1) {
                        HStack {
                            Text("Vorschou")
                            Spacer()
                            Text("\(preferences.reminderHorizonDays) Täg")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Wuche-Mäudig")
            } footer: {
                Text(preferences.remindersEnabled
                     ? "Ei Mäudig pro Wuche (\(preferences.reminderTimeDescription)) mit auem, wo i de nächschte \(preferences.reminderHorizonDays) Täg ablouft."
                     : "Ohni Erinnerige muesch säuber dra dänke, i d App z luege.")
            }

            Section {
                Toggle("Eigeti Mäudig pro Produkt", isOn: perItemBinding)
                if preferences.perItemRemindersEnabled {
                    Stepper(value: leadBinding, in: 1...30) {
                        HStack {
                            Text("Vorlouf")
                            Spacer()
                            Text("\(preferences.perItemLeadDays) Täg")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } footer: {
                Text("Zuesätzlech zur Wuche-Mäudig, pro Produkt e eigeti Mitteilig. Standardmässig us, damit's nid z viu wärde.")
            }

            Section {
                LabeledContent("Berächtigung", value: statusText)
                if authorizationStatus == .denied {
                    Text("I de iOS-Istellige under Mitteilige → Frostify wieder erloube.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("System")
            }
        }
        .listRowBackground(Theme.surface)
        .themedList()
        .navigationTitle("Erinnerige")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            var components = DateComponents()
            components.hour = preferences.reminderHour
            components.minute = preferences.reminderMinute
            reminderTime = Calendar.current.date(from: components) ?? Date()
            authorizationStatus = await scheduler?.authorizationStatus() ?? .notDetermined
        }
    }

    private var statusText: String {
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral: return "Erteilt"
        case .denied: return "Verweigeret"
        case .notDetermined: return "No nid gfragt"
        @unknown default: return "Unbekannt"
        }
    }

    private var remindersEnabledBinding: Binding<Bool> {
        Binding(
            get: { preferences.remindersEnabled },
            set: { newValue in
                preferences.remindersEnabled = newValue
                refresh()
            }
        )
    }

    private var weekdayBinding: Binding<Int> {
        Binding(
            get: { preferences.reminderWeekday },
            set: { preferences.reminderWeekday = $0; refresh() }
        )
    }

    private var horizonBinding: Binding<Int> {
        Binding(
            get: { preferences.reminderHorizonDays },
            set: { preferences.reminderHorizonDays = $0; refresh() }
        )
    }

    private var perItemBinding: Binding<Bool> {
        Binding(
            get: { preferences.perItemRemindersEnabled },
            set: { preferences.perItemRemindersEnabled = $0; refresh() }
        )
    }

    private var leadBinding: Binding<Int> {
        Binding(
            get: { preferences.perItemLeadDays },
            set: { preferences.perItemLeadDays = $0; refresh() }
        )
    }

    private func refresh() {
        Task {
            await scheduler?.refresh()
            authorizationStatus = await scheduler?.authorizationStatus() ?? .notDetermined
        }
    }
}
