import CoreData
import Foundation

/// Eine einzelne Entnahme. Diese Datensaetze werden nur angehaengt, nie geaendert –
/// deshalb koennen sich zwei gleichzeitige Entnahmen beim Abgleich nicht gegenseitig
/// ueberschreiben.
@objc(ConsumptionEvent)
final class ConsumptionEvent: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ConsumptionEvent> {
        NSFetchRequest<ConsumptionEvent>(entityName: "ConsumptionEvent")
    }

    @NSManaged var id: UUID?
    @NSManaged var date: Date?
    @NSManaged var quantityTaken: Double
    @NSManaged var portionsTaken: Int32
    @NSManaged var kindRaw: String?
    @NSManaged var byName: String?
    @NSManaged var item: Item?
}

extension ConsumptionEvent {
    var identifier: UUID { id ?? UUID() }

    var kind: ConsumptionKind {
        get { ConsumptionKind.from(rawValue: kindRaw) ?? .consumed }
        set { kindRaw = newValue.rawValue }
    }

    var eventDate: Date { date ?? Date() }

    var byNameText: String { byName ?? "" }

    /// "1 Portion · 200 g" – zeigt nur, was am Eintrag ueberhaupt erfasst ist.
    func summary(unit: StorageUnit) -> String {
        var parts: [String] = []
        if quantityTaken > 0 {
            parts.append(QuantityFormatter.string(quantityTaken, unit: unit))
        }
        if portionsTaken > 0 {
            parts.append(QuantityFormatter.portionsString(Int(portionsTaken)))
        }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }
}
