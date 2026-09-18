import CoreData
import Foundation

extension PersistenceController {
    /// Rein im Arbeitsspeicher, mit Beispieldaten – nur fuer SwiftUI-Vorschauen.
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.viewContext

        let freezer = Freezer(context: context)
        freezer.id = UUID()
        freezer.name = "Tiefchüeler Chuchi"
        freezer.createdAt = Date()

        let settings = FreezerSettings(context: context)
        settings.id = UUID()
        settings.shelfLifeOverridesJSON = ""
        settings.freezer = freezer

        func makeItem(
            _ name: String,
            _ category: FoodCategory,
            quantity: Double,
            unit: StorageUnit,
            portions: Int,
            note: String,
            daysAgo: Int,
            location: String
        ) -> Item {
            let item = Item(context: context)
            item.id = UUID()
            item.name = name
            item.category = category
            item.initialQuantity = quantity
            item.unit = unit
            item.initialPortions = Int32(portions)
            item.note = note
            item.storageLocation = location
            item.frozenAt = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())
            item.bestBefore = ExpiryCalculator.bestBefore(
                frozenAt: item.frozenDate,
                shelfLifeMonths: category.defaultShelfLifeMonths
            )
            item.createdAt = Date()
            item.updatedAt = Date()
            item.createdByName = "Raphi"
            item.freezer = freezer
            return item
        }

        _ = makeItem("Rindsteak", .meat, quantity: 400, unit: .gram, portions: 2,
                     note: "2 Steaks im Sack", daysAgo: 20, location: "Schublade 2")
        _ = makeItem("Ghackts", .mincedMeat, quantity: 500, unit: .gram, portions: 0,
                     note: "", daysAgo: 85, location: "Schublade 1")
        _ = makeItem("Erbsen", .vegetables, quantity: 3, unit: .bag, portions: 0,
                     note: "", daysAgo: 10, location: "Obers Fach")
        let lasagne = makeItem("Lasagne", .readyMeals, quantity: 1, unit: .package, portions: 4,
                               note: "Sälbergmacht", daysAgo: 60, location: "Schublade 3")

        let event = ConsumptionEvent(context: context)
        event.id = UUID()
        event.date = Calendar.current.date(byAdding: .day, value: -3, to: Date())
        event.quantityTaken = 0.5
        event.portionsTaken = 2
        event.kind = .consumed
        event.byName = "Raphi"
        event.item = lasagne

        try? context.save()
        return controller
    }()
}
