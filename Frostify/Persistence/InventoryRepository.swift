import CoreData
import Foundation
import os

/// Alle schreibenden Zugriffe auf den Bestand laufen hier durch.
///
/// Der Rest der App kennt nur dieses Protokoll und fasst `NSManagedObjectContext`
/// nicht direkt an. Einzige bewusste Ausnahme sind die `@FetchRequest`-Listen in den
/// Views: sie aktualisieren sich bei eintreffenden Aenderungen von selbst, und dieser
/// Vorteil waegt schwerer als die reine Lehre.
protocol InventoryRepositoryProtocol: AnyObject {
    /// Richtwerte des aktuellen Tiefkuehlers. Legt bewusst nichts an – darf deshalb
    /// gefahrlos aus einer View heraus gelesen werden.
    var shelfLifeTable: ShelfLifeTable { get }

    /// Liefert den Tiefkuehler und legt ihn beim allerersten Start an.
    func currentFreezer() -> Freezer
    @discardableResult func createItem(from draft: ItemDraft) -> Item
    func update(_ item: Item, with draft: ItemDraft)
    func delete(_ item: Item)

    @discardableResult func consume(_ item: Item, quantity: Double, portions: Int, kind: ConsumptionKind) -> ConsumptionEvent
    @discardableResult func consumeAll(_ item: Item, kind: ConsumptionKind) -> ConsumptionEvent
    func reopen(_ item: Item)
    func deleteEvent(_ event: ConsumptionEvent)

    func catalogProduct(forBarcode barcode: String) -> CatalogProduct?
    func storageLocationSuggestions() -> [String]

    func updateShelfLife(_ table: ShelfLifeTable)
    func save()
}

final class InventoryRepository: InventoryRepositoryProtocol {
    private static let logger = Logger(subsystem: "ch.hebera.frostify", category: "Repository")

    private let persistence: PersistenceController
    private let authorName: () -> String

    private var context: NSManagedObjectContext { persistence.viewContext }

    init(persistence: PersistenceController, authorName: @escaping () -> String = { AppPreferences.shared.displayName }) {
        self.persistence = persistence
        self.authorName = authorName
    }

    var shelfLifeTable: ShelfLifeTable {
        existingFreezer()?.shelfLifeTable ?? ShelfLifeTable()
    }

    // MARK: - Tiefkuehler

    /// Die App zeigt genau einen Tiefkuehler.
    ///
    /// Nach der Annahme einer Freigabe existieren auf dem Geraet der Partnerin zwei:
    /// ihr eigener (leer) und der freigegebene. Gewaehlt wird der mit den meisten
    /// aktiven Eintraegen, bei Gleichstand der freigegebene – so landet sie nach der
    /// Annahme sofort im gemeinsamen Bestand, ohne eigene Eintraege zu verlieren.
    func currentFreezer() -> Freezer {
        existingFreezer() ?? createFreezer()
    }

    /// Wie `currentFreezer()`, aber ohne anzulegen.
    private func existingFreezer() -> Freezer? {
        let request = Freezer.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let all = (try? context.fetch(request)) ?? []

        if all.isEmpty { return nil }
        if all.count == 1 { return all[0] }

        return all.max { lhs, rhs in
            let lhsCount = lhs.activeItems.count
            let rhsCount = rhs.activeItems.count
            if lhsCount != rhsCount { return lhsCount < rhsCount }
            return !persistence.isShared(lhs) && persistence.isShared(rhs)
        } ?? all[0]
    }

    private func createFreezer() -> Freezer {
        let freezer = Freezer(context: context)
        freezer.id = UUID()
        freezer.name = "Tiefkühler"
        freezer.createdAt = Date()

        let settings = FreezerSettings(context: context)
        settings.id = UUID()
        settings.shelfLifeOverridesJSON = ""
        settings.freezer = freezer

        if let store = persistence.privateStore {
            context.assign(freezer, to: store)
            context.assign(settings, to: store)
        }
        save()
        return freezer
    }

    /// Neue Objekte muessen in denselben Store wie ihr Tiefkuehler – sonst lehnt
    /// Core Data die Beziehung zwischen zwei Stores ab.
    private func assign(_ object: NSManagedObject, like parent: NSManagedObject) {
        guard let store = persistence.store(for: parent) else { return }
        context.assign(object, to: store)
    }

    // MARK: - Eintraege

    @discardableResult
    func createItem(from draft: ItemDraft) -> Item {
        let freezer = currentFreezer()
        let item = Item(context: context)
        item.id = UUID()
        item.createdAt = Date()
        item.createdByName = authorName()
        item.freezer = freezer
        assign(item, like: freezer)
        apply(draft, to: item)
        upsertCatalogEntry(from: draft, in: freezer)
        save()
        return item
    }

    func update(_ item: Item, with draft: ItemDraft) {
        apply(draft, to: item)
        if let freezer = item.freezer {
            upsertCatalogEntry(from: draft, in: freezer)
        }
        save()
    }

    private func apply(_ draft: ItemDraft, to item: Item) {
        item.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        item.category = draft.category
        item.initialQuantity = QuantityMath.rounded(draft.quantity)
        item.unit = draft.unit
        item.initialPortions = Int32(max(0, draft.portions))
        item.note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        item.frozenAt = draft.frozenAt
        item.bestBefore = draft.bestBefore
        item.bestBeforeIsManual = draft.bestBeforeIsManual
        item.storageLocation = draft.storageLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        item.barcode = draft.barcode ?? ""
        item.updatedAt = Date()
    }

    func delete(_ item: Item) {
        context.delete(item)
        save()
    }

    // MARK: - Entnehmen

    @discardableResult
    func consume(_ item: Item, quantity: Double, portions: Int, kind: ConsumptionKind) -> ConsumptionEvent {
        let event = ConsumptionEvent(context: context)
        event.id = UUID()
        event.date = Date()
        event.quantityTaken = QuantityMath.clamp(quantity, max: item.remainingQuantity)
        event.portionsTaken = Int32(min(max(0, portions), item.remainingPortions))
        event.kind = kind
        event.byName = authorName()
        event.item = item
        assign(event, like: item)

        item.updatedAt = Date()
        closeIfEmpty(item, kind: kind)
        save()
        return event
    }

    @discardableResult
    func consumeAll(_ item: Item, kind: ConsumptionKind) -> ConsumptionEvent {
        consume(item, quantity: item.remainingQuantity, portions: item.remainingPortions, kind: kind)
    }

    /// Holt einen Eintrag aus dem Archiv zurueck, indem die letzte Entnahme entfernt wird.
    /// Genau das macht die haeufigste Fehlbedienung rueckgaengig: ein versehentliches
    /// "Alles entnehmen".
    func reopen(_ item: Item) {
        if let latest = item.eventList.first {
            context.delete(latest)
        }
        item.closedAt = nil
        item.closeReason = nil
        item.updatedAt = Date()
        save()
    }

    func deleteEvent(_ event: ConsumptionEvent) {
        let item = event.item
        context.delete(event)
        if let item {
            item.updatedAt = Date()
            if !item.isEmpty {
                item.closedAt = nil
                item.closeReason = nil
            }
        }
        save()
    }

    private func closeIfEmpty(_ item: Item, kind: ConsumptionKind) {
        guard item.isEmpty else { return }
        item.closedAt = Date()
        // Weggeworfen gewinnt: wurde ein Rest entsorgt, zaehlt der Eintrag in der
        // Statistik als Verlust, auch wenn vorher schon Portionen gegessen wurden.
        let hadDiscard = item.eventList.contains { $0.kind == .discarded }
        item.closeReason = (kind == .discarded || hadDiscard) ? .discarded : .consumed
    }

    // MARK: - Katalog

    func catalogProduct(forBarcode barcode: String) -> CatalogProduct? {
        guard !barcode.isEmpty else { return nil }
        let request = CatalogProduct.fetchRequest()
        request.predicate = NSPredicate(format: "barcode ==[c] %@", barcode)
        request.fetchLimit = 1
        return (try? context.fetch(request))?.first
    }

    private func upsertCatalogEntry(from draft: ItemDraft, in freezer: Freezer) {
        guard let barcode = draft.barcode, !barcode.isEmpty else { return }

        let entry: CatalogProduct
        if let existing = catalogProduct(forBarcode: barcode) {
            entry = existing
        } else {
            let created = CatalogProduct(context: context)
            created.id = UUID()
            created.barcode = barcode
            created.useCount = 0
            created.freezer = freezer
            assign(created, like: freezer)
            entry = created
        }

        entry.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.category = draft.category
        entry.defaultUnit = draft.unit
        entry.defaultQuantity = QuantityMath.rounded(draft.quantity)
        entry.defaultPortions = Int32(max(0, draft.portions))
        entry.defaultNote = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.useCount += 1
        entry.lastUsedAt = Date()
    }

    // MARK: - Lagerorte

    /// Bisher benutzte Lagerorte, haeufigste zuerst – als Vorschlaege im Formular.
    func storageLocationSuggestions() -> [String] {
        let request = Item.fetchRequest()
        request.predicate = NSPredicate(format: "storageLocation != nil AND storageLocation != %@", "")
        let items = (try? context.fetch(request)) ?? []
        let counts = items.reduce(into: [String: Int]()) { result, item in
            let location = item.storageLocationText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !location.isEmpty else { return }
            result[location, default: 0] += 1
        }
        return counts
            .sorted { lhs, rhs in
                lhs.value != rhs.value ? lhs.value > rhs.value : lhs.key < rhs.key
            }
            .prefix(8)
            .map(\.key)
    }

    // MARK: - Einstellungen

    func updateShelfLife(_ table: ShelfLifeTable) {
        let freezer = currentFreezer()
        let settings: FreezerSettings
        if let existing = freezer.settings {
            settings = existing
        } else {
            let created = FreezerSettings(context: context)
            created.id = UUID()
            created.freezer = freezer
            assign(created, like: freezer)
            settings = created
        }
        settings.shelfLifeTable = table
        save()
    }

    func save() {
        persistence.save()
    }
}
