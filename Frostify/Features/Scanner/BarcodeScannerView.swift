import AVFoundation
import SwiftUI
import VisionKit

/// Barcode-Scan ueber VisionKit – ohne Drittanbieter und ohne Netz.
///
/// Der Scan liefert nur den Code. Was dahinter steckt, weiss ausschliesslich euer
/// eigener Katalog: einmal benannt, beim naechsten Mal vorausgefuellt.
struct BarcodeScannerView: View {
    let onScan: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cameraAuthorized: Bool?
    @State private var manualCode = ""

    private var scannerUsable: Bool {
        DataScannerViewController.isSupported && (cameraAuthorized ?? false)
    }

    var body: some View {
        NavigationStack {
            Group {
                if scannerUsable {
                    DataScannerRepresentable(onScan: handle)
                        .ignoresSafeArea(edges: .bottom)
                        .overlay(alignment: .bottom) { hint }
                } else {
                    fallback
                }
            }
            .navigationTitle("Barcode scanne")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbräche") { dismiss() }
                }
            }
            .task { await resolveCameraAccess() }
        }
    }

    private var hint: some View {
        Text("Code is Bud haute – Frostify erkennt ne automatisch.")
            .font(.footnote)
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            .padding(.bottom, 24)
    }

    private var fallback: some View {
        Form {
            Section {
                Text(fallbackMessage)
                    .foregroundStyle(.secondary)
            }
            Section {
                TextField("Code iigäh", text: $manualCode)
                    .keyboardType(.numberPad)
                    .font(.body.monospaced())
                Button("Übernäh") {
                    handle(manualCode.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                .disabled(manualCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: {
                Text("Vo Hand")
            } footer: {
                Text("Dr Simulator het kei Kamera – da chasch e Code trotzdäm iitippe u dr Katalog teschte.")
            }
        }
        .listRowBackground(Theme.surface)
        .themedList()
    }

    private var fallbackMessage: String {
        if cameraAuthorized == false {
            return "Frostify darf d Kamera nid bruche. Das chasch i de iOS-Istellige under Dateschutz → Kamera ändere."
        }
        if !DataScannerViewController.isSupported {
            return "Ds Grät unterstützt dr Scanner nid."
        }
        return "Dr Scanner isch grad nid verfüegbar."
    }

    private func handle(_ code: String) {
        guard !code.isEmpty else { return }
        onScan(code)
        dismiss()
    }

    private func resolveCameraAccess() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraAuthorized = true
        case .notDetermined:
            cameraAuthorized = await AVCaptureDevice.requestAccess(for: .video)
        default:
            cameraAuthorized = false
        }
    }
}

/// Duenne Bruecke zum UIKit-Scanner.
private struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce, .code128, .code39])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        guard !context.coordinator.isScanning else { return }
        context.coordinator.isScanning = (try? controller.startScanning()) != nil
    }

    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) {
        controller.stopScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(onScan: onScan) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String) -> Void
        private var hasDelivered = false
        var isScanning = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ scanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            deliver(from: addedItems)
        }

        func dataScanner(_ scanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            deliver(from: [item])
        }

        /// Nur der erste Treffer zaehlt – sonst feuert der Scanner den Callback laufend nach.
        private func deliver(from items: [RecognizedItem]) {
            guard !hasDelivered else { return }
            for case .barcode(let barcode) in items {
                guard let payload = barcode.payloadStringValue, !payload.isEmpty else { continue }
                hasDelivered = true
                onScan(payload)
                return
            }
        }
    }
}
