import Foundation

/// Was das Formular gerade bearbeitet.
enum ItemEditorTarget: Identifiable {
    case create(ItemDraft)
    case edit(Item)

    var id: String {
        switch self {
        case .create: return "create"
        case .edit(let item): return item.identifier.uuidString
        }
    }
}
