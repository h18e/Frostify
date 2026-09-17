import CoreData
import Foundation

/// Ein Eintrag im Tiefkuehler.
///
/// Die Restmenge ist bewusst kein gespeichertes Feld, sondern wird aus `initialQuantity`
/// minus der Summe der Entnahmen berechnet – siehe `QuantityMath` fuer die Begruendung.
@objc(Item)
final class Item: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<Item> {
        NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var categoryRaw: String?
    @NSManaged var unitRaw: String?
    @NSManaged var initialQuantity: Double
    @NSManaged var initialPortions: Int32
    @NSManaged var note: String?
    @NSManaged var frozenAt: Date?
    @NSManaged var bestBefore: Date?
    @NSManaged var bestBeforeIsManual: Bool
    @NSManaged var storageLocation: String?
    @NSManaged var barcode: String?
    @NSManaged var createdByName: String?
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var closedAt: Date?
    @NSManaged var closeReasonRaw: String?
    @NSManaged var events: NSSet?
    @NSManaged var freezer: Freezer?
}

// MARK: - Bequeme, typsichere Zugriffe

extension Item {
    var identifier: UUID { id ?? UUID() }

    var displayName: String {
        let trimmed = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Ohne Namen" : trimmed
    }

    var category: FoodCategory {
        get { FoodCategory.from(rawValue: categoryRaw) }
        set { categoryRaw = newValue.rawValue }
    }

    var unit: StorageUnit {
        get { StorageUnit.from(rawValue: unitRaw) }
        set { unitRaw = newValue.rawValue }
    }

    var noteText: String { note ?? "" }

    var storageLocationText: String { storageLocation ?? "" }

    var barcodeText: String? {
        guard let barcode, !barcode.isEmpty else { return nil }
        return barcode
    }

    /// `true`, wenn am Eintrag ueberhaupt Portionen erfasst sind.
    var hasPortions: Bool { initialPortions > 0 }

    var isClosed: Bool { closedAt != nil }

    var closeReason: ConsumptionKind? {
        get { ConsumptionKind.from(rawValue: closeReasonRaw) }
        set { closeReasonRaw = newValue?.rawValue ?? "" }
    }
}

// MARK: - Entnahmen und Restmengen

extension Item {
    /// Entnahmen, neueste zuerst.
    var eventList: [ConsumptionEvent] {
        let all = (events as? Set<ConsumptionEvent>).map(Array.init) ?? []
        return all.sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
    }

    var takenQuantity: Double {
        eventList.reduce(0) { $0 + $1.quantityTaken }
    }

    var takenPortions: Int {
        eventList.reduce(0) { $0 + Int($1.portionsTaken) }
    }

    var remainingQuantity: Double {
        QuantityMath.remainingQuantity(initial: initialQuantity, taken: takenQuantity)
    }

    var remainingPortions: Int {
        QuantityMath.remainingPortions(initial: Int(initialPortions), taken: takenPortions)
    }

    /// Nichts mehr uebrig – der Eintrag gehoert danach ins Archiv.
    var isEmpty: Bool {
        QuantityMath.isEmpty(
            remainingQuantity: remainingQuantity,
            remainingPortions: remainingPortions,
            hasPortions: hasPortions
        )
    }

    /// Zusammenfassung fuer die Listenzeile, z. B. "350 g · 1 Portion".
    var quantitySummary: String {
        var parts: [String] = []
        if initialQuantity > 0 {
            parts.append(QuantityFormatter.string(remainingQuantity, unit: unit))
        }
        if hasPortions {
            parts.append(QuantityFormatter.portionsString(remainingPortions))
        }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }
}

// MARK: - Ablauf

extension Item {
    var frozenDate: Date { frozenAt ?? createdAt ?? Date() }

    /// Das "empfohlen bis"-Datum. Fehlt es (z. B. bei Daten aus einer fruehen Version),
    /// wird es aus Kategorie-Richtwert und Einfrierdatum hergeleitet.
    func resolvedBestBefore(using table: ShelfLifeTable) -> Date {
        bestBefore ?? ExpiryCalculator.bestBefore(
            frozenAt: frozenDate,
            shelfLifeMonths: table.months(for: category)
        )
    }

    func daysRemaining(using table: ShelfLifeTable, now: Date = Date()) -> Int {
        ExpiryCalculator.daysRemaining(until: resolvedBestBefore(using: table), now: now)
    }

    func expiryState(using table: ShelfLifeTable, now: Date = Date()) -> ExpiryState {
        ExpiryCalculator.state(daysRemaining: daysRemaining(using: table, now: now))
    }
}

extension Item {
    @objc(addEventsObject:)
    @NSManaged func addToEvents(_ value: ConsumptionEvent)

    @objc(removeEventsObject:)
    @NSManaged func removeFromEvents(_ value: ConsumptionEvent)

    @objc(addEvents:)
    @NSManaged func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged func removeFromEvents(_ values: NSSet)
}
