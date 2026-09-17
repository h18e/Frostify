import Foundation

enum InventoryGrouping: String, CaseIterable, Identifiable {
    case expiry
    case category
    case location

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .expiry: return "Ablauf"
        case .category: return "Kategorie"
        case .location: return "Lagerort"
        }
    }
}

enum InventorySorting: String, CaseIterable, Identifiable {
    case bestBefore
    case frozenAt
    case name

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bestBefore: return "Empfohlen bis"
        case .frozenAt: return "Einfrierdatum"
        case .name: return "Name"
        }
    }
}

struct InventorySection: Identifiable {
    let id: String
    let title: String
    let items: [Item]
}

/// Baut aus der flachen Ergebnisliste die Abschnitte der Uebersicht.
///
/// Bewusst im Speicher statt ueber `sectionIdentifier` der FetchRequest: die Gruppierung
/// nach Ampelstufe haengt vom aktuellen Datum ab, das keine Datenbankabfrage kennt.
enum InventorySectionBuilder {
    static func filter(_ items: [Item], searchText: String, state: ExpiryState?, table: ShelfLifeTable, now: Date = Date()) -> [Item] {
        var result = items

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { item in
                item.displayName.lowercased().contains(query)
                    || item.noteText.lowercased().contains(query)
                    || item.storageLocationText.lowercased().contains(query)
                    || item.category.displayName.lowercased().contains(query)
            }
        }

        if let state {
            result = result.filter { $0.expiryState(using: table, now: now) == state }
        }

        return result
    }

    static func sort(_ items: [Item], by sorting: InventorySorting, table: ShelfLifeTable) -> [Item] {
        switch sorting {
        case .bestBefore:
            return items.sorted { $0.resolvedBestBefore(using: table) < $1.resolvedBestBefore(using: table) }
        case .frozenAt:
            return items.sorted { $0.frozenDate > $1.frozenDate }
        case .name:
            return items.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
        }
    }

    static func sections(
        for items: [Item],
        grouping: InventoryGrouping,
        sorting: InventorySorting,
        table: ShelfLifeTable,
        now: Date = Date()
    ) -> [InventorySection] {
        let sorted = sort(items, by: sorting, table: table)

        switch grouping {
        case .expiry:
            let grouped = Dictionary(grouping: sorted) { $0.expiryState(using: table, now: now) }
            return ExpiryState.allCases
                .sorted()
                .compactMap { state in
                    guard let group = grouped[state], !group.isEmpty else { return nil }
                    return InventorySection(id: "state-\(state.rawValue)", title: state.displayName, items: group)
                }

        case .category:
            let grouped = Dictionary(grouping: sorted) { $0.category }
            return FoodCategory.allCases.compactMap { category in
                guard let group = grouped[category], !group.isEmpty else { return nil }
                return InventorySection(id: "cat-\(category.rawValue)", title: category.displayName, items: group)
            }

        case .location:
            let grouped = Dictionary(grouping: sorted) { item -> String in
                let location = item.storageLocationText.trimmingCharacters(in: .whitespacesAndNewlines)
                return location.isEmpty ? "Ohne Lagerort" : location
            }
            return grouped
                .map { InventorySection(id: "loc-\($0.key)", title: $0.key, items: $0.value) }
                .sorted { lhs, rhs in
                    if lhs.title == "Ohne Lagerort" { return false }
                    if rhs.title == "Ohne Lagerort" { return true }
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
        }
    }
}
