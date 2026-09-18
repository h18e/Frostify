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
        .listRowBackground(Theme.surface)
        .themedList()
        .navigationTitle("Teile")
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
            "Teile nid möglech",
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
            LabeledContent("Tiefchüeler", value: freezer.displayName)
            LabeledContent("Status") {
                if share == nil {
                    Text(service.isOwner(of: freezer) ? "Nid teilt" : "Für di freiggä")
                        .foregroundStyle(.secondary)
                } else {
                    Label("Teilt", systemImage: "person.2.fill")
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
                        Text("D Iiladig wird vorbereitet …")
                    }
                } else {
                    Label(
                        share == nil ? "Tiefchüeler teile" : "D Iiladig verwaute",
                        systemImage: share == nil ? "person.badge.plus" : "person.2.badge.gearshape"
                    )
                }
            }
            .disabled(service.isWorking)
        } footer: {
            Text("Es geit dr Dialog vo Apple uf: dert wählsch, wie du dr Link verschicksch. Dyni Partnerin tippt ne aa, iOS macht Frostify uf, u ab de gseht dir beidi dr glych Vorrat.")
        }
    }

    private var participantSection: some View {
        Section {
            Text("Dä Tiefchüeler isch dir freiggä worde. Änderige gseht dir beidi glych.")
                .foregroundStyle(.secondary)
        } footer: {
            Text("D Freigab beände chasch übere Iiladigs-Link oder i de iCloud-Istellige under „Mit dir geteilt“.")
        }
    }

    private func participantsListSection(_ share: CKShare) -> some View {
        Section("Teilnähmer") {
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
            Label("Beidi bruuche ne eigeti Apple-ID u ne iCloud-Aamäudig.", systemImage: "person.2")
            Label("Ohni Netz schaffet Frostify normau wyter u glycht speter ab.", systemImage: "wifi.slash")
            Label("Glychzytigi Verbrüch göh nid verlore – si wärde zämezeut.", systemImage: "arrow.triangle.merge")
        } header: {
            Text("Guet z wüsse")
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
        return participant.role == .owner ? "Bsitzer" : "Iiglade Person"
    }

    private func statusText(for participant: CKShare.Participant) -> String {
        let role: String
        switch participant.role {
        case .owner: role = "Bsitzer"
        case .privateUser: role = "Iiglade"
        case .publicUser: role = "Über Link"
        default: role = "Unbekannt"
        }

        let status: String
        switch participant.acceptanceStatus {
        case .accepted: status = "aagnoh"
        case .pending: status = "pendänt"
        case .removed: status = "entfernt"
        default: status = "unbekannt"
        }

        let permission = participant.permission == .readWrite ? "darf ändere" : "nume läse"
        return "\(role) · \(status) · \(permission)"
    }
}
