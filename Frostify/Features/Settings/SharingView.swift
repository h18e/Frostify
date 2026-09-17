import CloudKit
import SwiftUI

/// Tiefkuehler mit der Partnerin teilen.
struct SharingView: View {
    @Environment(\.inventory) private var inventory
    @StateObject private var service = CloudSharingService()

    @State private var share: CKShare?
    @State private var showSharingController = false
    @State private var reloadToken = 0

    private var freezer: Freezer { inventory.currentFreezer() }

    var body: some View {
        Form {
            statusSection

            if service.isOwner(of: freezer) {
                ownerSection
            } else {
                participantSection
            }

            if let share, !share.participants.isEmpty {
                participantsListSection(share)
            }

            explanationSection
        }
        .navigationTitle("Teilen")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: reloadToken) {
            share = service.existingShare(for: freezer)
        }
        .sheet(isPresented: $showSharingController, onDismiss: { reloadToken += 1 }) {
            if let share {
                CloudSharingSheet(
                    share: share,
                    container: service.cloudContainer,
                    title: freezer.displayName
                ) {
                    reloadToken += 1
                }
                .ignoresSafeArea()
            }
        }
        .alert(
            "Teilen nicht möglich",
            isPresented: Binding(
                get: { service.errorMessage != nil },
                set: { if !$0 { service.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { service.errorMessage = nil }
        } message: {
            Text(service.errorMessage ?? "")
        }
    }

    private var statusSection: some View {
        Section {
            LabeledContent("Tiefkühler", value: freezer.displayName)
            LabeledContent("Status") {
                if share == nil {
                    Text(service.isOwner(of: freezer) ? "Nicht geteilt" : "Für dich freigegeben")
                        .foregroundStyle(.secondary)
                } else {
                    Label("Geteilt", systemImage: "person.2.fill")
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private var ownerSection: some View {
        Section {
            Button {
                Task {
                    share = await service.shareOrCreate(for: freezer)
                    if share != nil { showSharingController = true }
                }
            } label: {
                if service.isWorking {
                    HStack {
                        ProgressView()
                        Text("Einladung wird vorbereitet …")
                    }
                } else {
                    Label(
                        share == nil ? "Tiefkühler teilen" : "Einladung verwalten",
                        systemImage: share == nil ? "person.badge.plus" : "person.2.badge.gearshape"
                    )
                }
            }
            .disabled(service.isWorking)
        } footer: {
            Text("Es öffnet sich Apples Dialog: dort wählst du, wie du den Link verschickst. Deine Partnerin tippt ihn an, iOS öffnet Frostify, und ab dann seht ihr beide denselben Bestand.")
        }
    }

    private var participantSection: some View {
        Section {
            Text("Dieser Tiefkühler wurde dir freigegeben. Änderungen siehst du und die andere Person gleichermassen.")
                .foregroundStyle(.secondary)
        } footer: {
            Text("Die Freigabe beenden kannst du über den Einladungslink oder in den iCloud-Einstellungen unter „Geteilt mit dir“.")
        }
    }

    private func participantsListSection(_ share: CKShare) -> some View {
        Section("Teilnehmer") {
            ForEach(share.participants, id: \.userIdentity.userRecordID) { participant in
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName(for: participant))
                    Text(statusText(for: participant))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var explanationSection: some View {
        Section {
            Label("Beide brauchen eine eigene Apple-ID und eine iCloud-Anmeldung.", systemImage: "person.2")
            Label("Ohne Netz arbeitet Frostify normal weiter und gleicht später ab.", systemImage: "wifi.slash")
            Label("Gleichzeitige Entnahmen gehen nicht verloren – sie werden zusammengezählt.", systemImage: "arrow.triangle.merge")
        } header: {
            Text("Gut zu wissen")
        }
        .font(.footnote)
    }

    private func displayName(for participant: CKShare.Participant) -> String {
        if let components = participant.userIdentity.nameComponents {
            let name = PersonNameComponentsFormatter.localizedString(from: components, style: .default)
            if !name.isEmpty { return name }
        }
        if let email = participant.userIdentity.lookupInfo?.emailAddress, !email.isEmpty {
            return email
        }
        if let phone = participant.userIdentity.lookupInfo?.phoneNumber, !phone.isEmpty {
            return phone
        }
        return participant.role == .owner ? "Besitzer" : "Eingeladene Person"
    }

    private func statusText(for participant: CKShare.Participant) -> String {
        let role: String
        switch participant.role {
        case .owner: role = "Besitzer"
        case .privateUser: role = "Eingeladen"
        case .publicUser: role = "Über Link"
        default: role = "Unbekannt"
        }

        let status: String
        switch participant.acceptanceStatus {
        case .accepted: status = "angenommen"
        case .pending: status = "ausstehend"
        case .removed: status = "entfernt"
        default: status = "unbekannt"
        }

        let permission = participant.permission == .readWrite ? "darf ändern" : "nur lesen"
        return "\(role) · \(status) · \(permission)"
    }
}
