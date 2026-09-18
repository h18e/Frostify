import SwiftUI

struct RootView: View {
    let loadError: Error?

    @Environment(\.inventory) private var inventory
    @State private var shareBanner: String?

    var body: some View {
        Group {
            if let loadError {
                StoreErrorView(error: loadError)
            } else {
                tabs
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .frostifyDidAcceptShare)) { notification in
            if let error = notification.userInfo?["error"] as? Error {
                shareBanner = "D Freigab het nid klappet: \(error.localizedDescription)"
            } else {
                shareBanner = "Freigab aagnoh – dr gmeinsam Vorrat erschint grad."
            }
        }
        .alert(
            "Teile",
            isPresented: Binding(
                get: { shareBanner != nil },
                set: { if !$0 { shareBanner = nil } }
            )
        ) {
            Button("OK", role: .cancel) { shareBanner = nil }
        } message: {
            Text(shareBanner ?? "")
        }
    }

    private var tabs: some View {
        TabView {
            InventoryListView()
                .tabItem { Label("Vorrat", systemImage: "snowflake") }

            ArchiveView()
                .tabItem { Label("Archiv", systemImage: "archivebox") }

            SettingsView()
                .tabItem { Label("Istellige", systemImage: "gearshape") }
        }
        .task {
            // Beim allerersten Start den Tiefkuehler anlegen, damit alle weiteren
            // Zugriffe darauf rein lesend bleiben koennen.
            _ = inventory.currentFreezer()
        }
    }
}

/// Wenn die Datenbank nicht geladen werden kann, ist das ein klar sichtbarer Zustand –
/// besser als eine Oberflaeche, die stumm leer bleibt.
private struct StoreErrorView: View {
    let error: Error

    var body: some View {
        VStack(spacing: 8) {
            EmptyStateView(
                symbol: "externaldrive.badge.xmark",
                title: "Date nid verfüegbar",
                message: "D lokali Datebank het sech nid la uftue."
            )
            Text(error.localizedDescription)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textTertiary)
                .padding(.horizontal, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackground()
    }
}

#Preview("Start") {
    RootView(loadError: nil)
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
        .environmentObject(AppPreferences.shared)
        .preferredColorScheme(.dark)
}
