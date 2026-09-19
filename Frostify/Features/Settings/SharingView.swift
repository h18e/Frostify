import CloudKit
import SwiftUI

/// Tiefkuehler mit der Partnerin teilen.
struct SharingView: View {
    @Environment(\.inventory) private var inventory
    @StateObject private var service = CloudSharingService()

    @State private var share: CKShare?
    @State private var invitationTarget: InvitationTarget?
    @State private var linkTarget: LinkTarget?
    @State private var confirmStop = false
    @State private var reloadToken = 0

    private var freezer: Freezer { inventory.currentFreezer() }

    var body: some View {
        Form {
            statusSection

            if service.isOwner(of: freezer) {
                linkSection
                invitationSection
                if share != nil {
                    stopSection
                }
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
        .sheet(item: $invitationTarget, onDismiss: { reloadToken += 1 }) { target in
            CloudSharingSheet(
                share: target.share,
                container: service.cloudContainer,
                title: freezer.displayName,
                onFinish: { reloadToken += 1 },
                onFailed: { service.errorMessage = $0.localizedDescription }
            )
            .ignoresSafeArea()
        }
        .sheet(item: $linkTarget, onDismiss: { reloadToken += 1 }) { target in
            ActivityView(items: [target.url])
        }
        .confirmationDialog("Teile beände?", isPresented: $confirmStop, titleVisibility: .visible) {
            Button("Beände", role: .destructive) {
                Task {
                    await service.stopSharing(freezer)
                    reloadToken += 1
                }
            }
            Button("Abbräche", role: .cancel) {}
        } message: {
            Text("Dyni Partnerin gseht dr Tiefchüeler de nüm. Dyni Date blibe bi dir.")
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

    // MARK: - Abschnitte

    private var statusSection: some View {
        Section {
            LabeledContent("Tiefchüeler", value: freezer.displayName)
            LabeledContent("Status") {
                if share == nil {
                    Text(service.isOwner(of: freezer) ? "Nid teilt" : "Für di freiggä")
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Label("Teilt", systemImage: "person.2.fill")
                        .foregroundStyle(Theme.stateFine)
                }
            }
            if share != nil, service.isOwner(of: freezer) {
                LabeledContent("Link") {
                    Text(service.linkIsOpen(for: freezer) ? "Für aui, wo ne hei" : "Nume für Iiglademi")
                        .foregroundStyle(service.linkIsOpen(for: freezer) ? Theme.stateFine : Theme.stateSoon)
                }
            }
        }
    }

    /// Der Weg, der zum Weiterschicken taugt – deshalb steht er zuoberst.
    private var linkSection: some View {
        Section {
            Button {
                Task {
                    if let url = await service.prepareLink(for: freezer) {
                        linkTarget = LinkTarget(url: url)
                        reloadToken += 1
                    }
                }
            } label: {
                HStack {
                    Label("Link schicke", systemImage: "link")
                    if service.isPreparingLink {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(service.isPreparingLink)
        } footer: {
            Text("Schautet dr Link für aui frei, wo ne hei, u macht ds Teile-Blatt vo iOS uf. Das isch dr Wäg, wo funktioniert, wenn du dr Link eifach witerschicksch.")
        }
    }

    private var invitationSection: some View {
        Section {
            Button {
                Task {
                    if let share = await service.invitationShare(for: freezer) {
                        invitationTarget = InvitationTarget(share: share)
                    }
                }
            } label: {
                HStack {
                    Label("Iiladig verwaute", systemImage: "person.2.badge.gearshape")
                    if service.isPreparingInvitation {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(service.isPreparingInvitation)
        } footer: {
            Text("Apples Dialog: Lüt namentlech iilade, Rächt setze, Teilnähmer aaluege.")
        }
    }

    private var stopSection: some View {
        Section {
            Button(role: .destructive) {
                confirmStop = true
            } label: {
                Label("Teile beände", systemImage: "person.2.slash")
            }
        }
    }

    private var participantSection: some View {
        Section {
            Text("Dä Tiefchüeler isch dir freiggä worde. Änderige gseht dir beidi glych.")
                .foregroundStyle(Theme.textSecondary)
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
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private var explanationSection: some View {
        Section {
            Label("Beidi bruuche ne eigeti Apple-ID u ne iCloud-Aamäudig.", systemImage: "person.2")
            Label("Frostify muess uf em Handy vo dr Partnerin scho installiert si, bevor si dr Link atippt.", systemImage: "iphone")
            Label("Ohni Netz schaffet Frostify normau wyter u glycht speter ab.", systemImage: "wifi.slash")
            Label("Glychzytigi Verbrüch göh nid verlore – si wärde zämezeut.", systemImage: "arrow.triangle.merge")
        } header: {
            Text("Guet z wüsse")
        }
        .font(.footnote)
    }

    // MARK: - Hilfen

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

/// `.sheet(item:)` braucht identifizierbare Werte.
private struct InvitationTarget: Identifiable {
    let share: CKShare
    var id: String { share.recordID.recordName }
}

private struct LinkTarget: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
