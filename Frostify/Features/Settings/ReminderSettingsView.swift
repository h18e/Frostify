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
                Toggle("Wöchentliche Sammelmeldung", isOn: remindersEnabledBinding)

                if preferences.remindersEnabled {
                    Picker("Wochentag", selection: weekdayBinding) {
                        ForEach(1...7, id: \.self) { weekday in
                            Text(Calendar.current.weekdaySymbols[weekday - 1]).tag(weekday)
                        }
                    }
                    DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .onChange(of: reminderTime) { _, newValue in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                            preferences.reminderHour = components.hour ?? 18
                            preferences.reminderMinute = components.minute ?? 0
                            refresh()
                        }
                    Stepper(value: horizonBinding, in: 1...60, step: 1) {
                        HStack {
                            Text("Vorschau")
                            Spacer()
                            Text("\(preferences.reminderHorizonDays) Tage")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Sammelmeldung")
            } footer: {
                Text(preferences.remindersEnabled
                     ? "Eine Meldung pro Woche (\(preferences.reminderTimeDescription)) mit allem, was in den nächsten \(preferences.reminderHorizonDays) Tagen abläuft."
                     : "Ohne Erinnerungen musst du selbst daran denken, in die App zu schauen.")
            }

            Section {
                Toggle("Einzelmeldung pro Produkt", isOn: perItemBinding)
                if preferences.perItemRemindersEnabled {
                    Stepper(value: leadBinding, in: 1...30) {
                        HStack {
                            Text("Vorlauf")
                            Spacer()
                            Text("\(preferences.perItemLeadDays) Tage")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } footer: {
                Text("Zusätzlich zur Sammelmeldung, je Produkt eine eigene Mitteilung. Standardmässig aus, damit es nicht zu viele werden.")
            }

            Section {
                LabeledContent("Berechtigung", value: statusText)
                if authorizationStatus == .denied {
                    Text("In den iOS-Einstellungen unter Mitteilungen → Frostify wieder erlauben.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("System")
            }
        }
        .navigationTitle("Erinnerungen")
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
        case .denied: return "Verweigert"
        case .notDetermined: return "Noch nicht gefragt"
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
