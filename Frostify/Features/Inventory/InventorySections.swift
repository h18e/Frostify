import Foundation

enum InventoryGrouping: String, CaseIterable, Identifiable {
    case expiry
    case category
    case location

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .expiry: return "Ablouf"
        case .category: return "Kategorie"
        case .location: return "Lagerort"
        }
    }

    var symbolName: String {
        switch self {
        case .expiry: return "clock"
        case .category: return "square.grid.2x2"
        case .location: return "tray.2"
        }
    }
}

enum InventorySorting: String, CaseIterable, Identifiable {
    case bestBefore
    case frozenAt
    case name
    case category

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bestBefore: return "Empfohle bis"
        case .frozenAt: return "Igfrore am"
        case .name: return "Name"
        case .category: return "Kategorie"
        }
    }
}

struct InventorySection: Identifiable {
    let id: String
    let title: String
    /// Kurzer Zusatz im Abschnittskopf, z. B. „3 Einträge".
    let subtitle: String
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
        case .category:
            return items.sorted { lhs, rhs in
                if lhs.category != rhs.category {
                    return lhs.category.colorIndex < rhs.category.colorIndex
                }
                return lhs.resolvedBestBefore(using: table) < rhs.resolvedBestBefore(using: table)
            }
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
                    return section(id: "state-\(state.rawValue)", title: state.displayName, items: group)
                }

        case .category:
            let grouped = Dictionary(grouping: sorted) { $0.category }
            return FoodCategory.allCases.compactMap { category in
                guard let group = grouped[category], !group.isEmpty else { return nil }
                return section(id: "cat-\(category.rawValue)", title: category.displayName, items: group)
            }

        case .location:
            let grouped = Dictionary(grouping: sorted) { item -> String in
                let location = item.storageLocationText.trimmingCharacters(in: .whitespacesAndNewlines)
                return location.isEmpty ? "Ohni Lagerort" : location
            }
            return grouped
                .map { section(id: "loc-\($0.key)", title: $0.key, items: $0.value) }
                .sorted { lhs, rhs in
                    if lhs.title == "Ohni Lagerort" { return false }
                    if rhs.title == "Ohni Lagerort" { return true }
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
        }
    }

    private static func section(id: String, title: String, items: [Item]) -> InventorySection {
        let portions = items.reduce(0) { $0 + $1.remainingPortions }
        var subtitle = items.count == 1 ? "1 Iitrag" : "\(items.count) Iiträg"
        if portions > 0 {
            subtitle += " · \(QuantityFormatter.portionsString(portions))"
        }
        return InventorySection(id: id, title: title, subtitle: subtitle, items: items)
    }
}
