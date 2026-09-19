import Foundation

/// Was das Formular gerade bearbeitet.
///
/// Bewusst eine Struktur mit eigener `id` statt eines Enums: `.sheet(item:)`
/// erkennt Blätter an ihrer `id`. Wäre die für jedes neue Erfassen dieselbe
/// (z. B. der feste Text „create"), hielte SwiftUI das zweite Formular für
/// dasselbe wie das erste – und behielte dessen bereits aufgebauten Zustand.
/// Ein frisch gescannter Barcode käme dann nie im Formular an; es erschiene das
/// leere Formular von vorhin.
struct ItemEditorTarget: Identifiable {
    enum Mode {
        case create(ItemDraft)
        case edit(Item)
    }

    let mode: Mode
    let id = UUID()

    static func create(_ draft: ItemDraft) -> ItemEditorTarget {
        ItemEditorTarget(mode: .create(draft))
    }

    static func edit(_ item: Item) -> ItemEditorTarget {
        ItemEditorTarget(mode: .edit(item))
    }
}
