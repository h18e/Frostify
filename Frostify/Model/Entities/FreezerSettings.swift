import CoreData
import Foundation

/// Einstellungen, die fuer **beide** Teilnehmer gelten und deshalb am Tiefkuehler haengen.
///
/// Bewusst nur die Haltbarkeits-Richtwerte: Erinnerungszeitpunkte und Anzeigevorlieben
/// sind Geraetesache und liegen lokal in `AppPreferences`.
@objc(FreezerSettings)
final class FreezerSettings: NSManagedObject {
    @nonobjc class func fetchRequest() -> NSFetchRequest<FreezerSettings> {
        NSFetchRequest<FreezerSettings>(entityName: "FreezerSettings")
    }

    @NSManaged var id: UUID?
    @NSManaged var shelfLifeOverridesJSON: String?
    @NSManaged var freezer: Freezer?
}

extension FreezerSettings {
    var shelfLifeTable: ShelfLifeTable {
        get { ShelfLifeTable(json: shelfLifeOverridesJSON) }
        set { shelfLifeOverridesJSON = newValue.json }
    }
}
