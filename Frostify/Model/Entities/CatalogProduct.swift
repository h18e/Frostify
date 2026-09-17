import CoreData
import Foundation

/// Ein einmal gescanntes Produkt. Der Katalog entsteht beim Erfassen von selbst und
/// haengt am Tiefkuehler – ihr teilt ihn also, ohne dass jemand ihn pflegen muss.
@objc(CatalogProduct)
final class CatalogProduct: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CatalogProduct> {
        NSFetchRequest<CatalogProduct>(entityName: "CatalogProduct")
    }

    @NSManaged var id: UUID?
    @NSManaged var barcode: String?
    @NSManaged var name: String?
    @NSManaged var categoryRaw: String?
    @NSManaged var defaultUnitRaw: String?
    @NSManaged var defaultQuantity: Double
    @NSManaged var defaultPortions: Int32
    @NSManaged var defaultNote: String?
    @NSManaged var useCount: Int32
    @NSManaged var lastUsedAt: Date?
    @NSManaged var freezer: Freezer?
}

extension CatalogProduct {
    var identifier: UUID { id ?? UUID() }

    var barcodeText: String { barcode ?? "" }

    var displayName: String {
        let trimmed = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Ohne Namen" : trimmed
    }

    var category: FoodCategory {
        get { FoodCategory.from(rawValue: categoryRaw) }
        set { categoryRaw = newValue.rawValue }
    }

    var defaultUnit: StorageUnit {
        get { StorageUnit.from(rawValue: defaultUnitRaw) }
        set { defaultUnitRaw = newValue.rawValue }
    }

    var defaultNoteText: String { defaultNote ?? "" }
}
