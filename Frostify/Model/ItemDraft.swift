import Foundation

/// Woher die Angaben im Formular stammen. Steuert nur den Hinweis zuoberst –
/// sichtbar zu machen, warum ein Formular leer oder schon ausgefuellt ist.
enum DraftOrigin: Equatable {
    case manual
    /// Aus dem eigenen Katalog vorausgefuellt.
    case catalog
    /// Vorschlag von Open Food Facts.
    case openFoodFacts
    /// Gescannt, aber weder im Katalog noch bei Open Food Facts bekannt.
    case scanUnknown
    /// Gescannt, aber Open Food Facts war nicht erreichbar.
    case scanOffline
}

/// Bearbeitungsstand eines Eintrags im Formular – bewusst ein einfacher Wert, damit
/// Abbrechen wirklich nichts veraendert und die Vorschau ohne Datenbank funktioniert.
struct ItemDraft: Equatable {
    var name: String = ""
    var category: FoodCategory = .other
    var quantity: Double = 0
    var unit: StorageUnit = .gram
    var portions: Int = 0
    var note: String = ""
    var frozenAt: Date = Date()
    var bestBefore: Date = Date()
    var bestBeforeIsManual: Bool = false
    var storageLocation: String = ""
    var barcode: String?
    var origin: DraftOrigin = .manual

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && quantity > 0
    }

    /// Neuer Eintrag mit den Vorgaben der Kategorie.
    static func new(category: FoodCategory = .other, table: ShelfLifeTable = ShelfLifeTable()) -> ItemDraft {
        var draft = ItemDraft()
        draft.category = category
        draft.unit = category.defaultUnit
        draft.frozenAt = Date()
        draft.bestBefore = ExpiryCalculator.bestBefore(
            frozenAt: draft.frozenAt,
            shelfLifeMonths: table.months(for: category)
        )
        return draft
    }

    init() {}

    /// Uebernimmt einen bestehenden Eintrag zum Bearbeiten.
    init(item: Item, table: ShelfLifeTable) {
        name = item.name ?? ""
        category = item.category
        quantity = item.initialQuantity
        unit = item.unit
        portions = Int(item.initialPortions)
        note = item.noteText
        frozenAt = item.frozenDate
        bestBefore = item.resolvedBestBefore(using: table)
        bestBeforeIsManual = item.bestBeforeIsManual
        storageLocation = item.storageLocationText
        barcode = item.barcodeText
    }

    /// Uebernimmt einen Vorschlag aus einer externen Produktdatenbank.
    ///
    /// Menge und Kategorie sind dort oft ungenau oder fehlen ganz – was nicht
    /// geliefert wird, bleibt auf der Vorgabe, und alles laesst sich im Formular
    /// aendern. Beim Sichern landet das Ergebnis im eigenen Katalog.
    init(suggestion: ProductSuggestion, barcode: String, table: ShelfLifeTable) {
        let category = suggestion.category ?? .other
        name = suggestion.displayName
        self.category = category
        unit = suggestion.unit ?? category.defaultUnit
        quantity = suggestion.quantity ?? 0
        portions = 0
        note = ""
        frozenAt = Date()
        bestBefore = ExpiryCalculator.bestBefore(
            frozenAt: frozenAt,
            shelfLifeMonths: table.months(for: category)
        )
        storageLocation = ""
        self.barcode = barcode
        origin = .openFoodFacts
    }

    /// Uebernimmt die Vorschlaege aus dem Barcode-Katalog.
    init(catalog: CatalogProduct, table: ShelfLifeTable) {
        name = catalog.displayName
        category = catalog.category
        quantity = catalog.defaultQuantity
        unit = catalog.defaultUnit
        portions = Int(catalog.defaultPortions)
        note = catalog.defaultNoteText
        frozenAt = Date()
        bestBefore = ExpiryCalculator.bestBefore(
            frozenAt: frozenAt,
            shelfLifeMonths: table.months(for: category)
        )
        barcode = catalog.barcodeText
        origin = .catalog
    }

    /// Zieht das "empfohlen bis"-Datum nach, solange es nicht von Hand gesetzt wurde.
    mutating func recalculateBestBefore(using table: ShelfLifeTable) {
        guard !bestBeforeIsManual else { return }
        bestBefore = ExpiryCalculator.bestBefore(
            frozenAt: frozenAt,
            shelfLifeMonths: table.months(for: category)
        )
    }
}
