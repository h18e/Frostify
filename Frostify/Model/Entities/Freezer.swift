import CoreData
import Foundation

/// Der Tiefkuehler. Er ist bewusst die Wurzel des Datenmodells: CloudKit teilt immer
/// einen Objektbaum ab genau einem Wurzel-Datensatz. Wird der Freezer geteilt, sind
/// Inhalt, Katalog und Einstellungen automatisch mitgeteilt.
///
/// Die Oberflaeche zeigt laut Spezifikation nur einen Tiefkuehler; das Modell koennte
/// mehrere, ohne dass sich daran etwas aendern muesste.
@objc(Freezer)
final class Freezer: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Freezer> {
        NSFetchRequest<Freezer>(entityName: "Freezer")
    }

    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var createdAt: Date?
    @NSManaged var items: NSSet?
    @NSManaged var catalogEntries: NSSet?
    @NSManaged var settings: FreezerSettings?
}

extension Freezer {
    var identifier: UUID { id ?? UUID() }

    var displayName: String {
        let trimmed = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Tiefchüeler" : trimmed
    }

    var itemList: [Item] {
        (items as? Set<Item>).map(Array.init) ?? []
    }

    var activeItems: [Item] {
        itemList.filter { !$0.isClosed }
    }

    var closedItems: [Item] {
        itemList.filter(\.isClosed)
    }

    var catalogList: [CatalogProduct] {
        (catalogEntries as? Set<CatalogProduct>).map(Array.init) ?? []
    }

    /// Richtwerte inklusive der Abweichungen aus den Einstellungen.
    var shelfLifeTable: ShelfLifeTable {
        ShelfLifeTable(json: settings?.shelfLifeOverridesJSON)
    }
}

extension Freezer {
    @objc(addItemsObject:)
    @NSManaged func addToItems(_ value: Item)

    @objc(removeItemsObject:)
    @NSManaged func removeFromItems(_ value: Item)

    @objc(addItems:)
    @NSManaged func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged func removeFromItems(_ values: NSSet)

    @objc(addCatalogEntriesObject:)
    @NSManaged func addToCatalogEntries(_ value: CatalogProduct)

    @objc(removeCatalogEntriesObject:)
    @NSManaged func removeFromCatalogEntries(_ value: CatalogProduct)

    @objc(addCatalogEntries:)
    @NSManaged func addToCatalogEntries(_ values: NSSet)

    @objc(removeCatalogEntries:)
    @NSManaged func removeFromCatalogEntries(_ values: NSSet)
}
