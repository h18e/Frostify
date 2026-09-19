# Frostify – aui Täxt i dr App

Automatisch us em Quellcode erzeugt mit `tools/list_texts.py`.
Platzhalter wie `\(days)` wärde zur Laufzyt dür Zahle ersetzt.

Wenn dir öppis nid passt: säg mer d Zile, i ändere's.

---

## Navigation & Start

`App/RootView.swift`

- Zile 19: **D Freigab het nid klappet: \(error.localizedDescription)**
- Zile 21: **Freigab aagnoh – dr gmeinsam Vorrat erschint grad.**
- Zile 25: **Teile**
- Zile 40: **Vorrat**
- Zile 46: **Istellige**
- Zile 65: **Date nid verfüegbar**
- Zile 66: **D lokali Datebank het sech nid la uftue.**

## Fählermäudige zum Teile

`App/ShareAcceptance.swift`

- Zile 60: **Dr teilt Bereich het sech nid la lade. Lueg, öb du i de iOS-Istellige bi iCloud aagmäudet bisch.**
- Zile 62: **Zum Teile muesch i de iOS-Istellige bi iCloud aagmäudet si.**
- Zile 64: **D Iiladig het sech nid la erstelle. Probier's speter nomau.**
- Zile 66: **Nume wär dr Tiefchüeler aagleit het, cha dr Link freischaute.**
- Zile 68: **iCloud het no kei Link glieferet. Lueg, öb du Netz hesch, u probier's nomau.**

## Ampu & Restlaufzyt

`Domain/ExpiryCalculator.swift`

- Zile 17: **Abglaufe**
- Zile 18: **Pressiert**
- Zile 19: **Bau bruche**
- Zile 20: **Guet**
- Zile 70: **sit \(-days) Täg abglaufe**
- Zile 71: **sit geschter abglaufe**
- Zile 72: **louft hüt ab**
- Zile 73: **no 1 Tag**
- Zile 74: **no \(days) Täg**
- Zile 77: **no guet 1 Monet**
- Zile 77: **no guet \(months) Mönet**

## Grund vo dr Usenahm

`Model/ConsumptionKind.swift`

- Zile 15: **Gässe**
- Zile 16: **Wäggschmisse**

## Kategorie

`Model/FoodCategory.swift`

- Zile 28: **Fleisch (Stück, Brate)**
- Zile 29: **Ghackts & Wurschtware**
- Zile 30: **Gflügu**
- Zile 31: **Fisch fett (Lachs, Thon)**
- Zile 32: **Fisch mager & Meerfrücht**
- Zile 33: **Gmües**
- Zile 34: **Frücht & Beeri**
- Zile 35: **Brot, Teig & Gebäck**
- Zile 36: **Fertiggricht & Sälbergchochts**
- Zile 37: **Suppe, Sauce & Fond**
- Zile 38: **Chrüter**
- Zile 39: **Butter & Nidle**
- Zile 40: **Dessert & Glace**
- Zile 41: **Angers**

## Einheite & Portione

`Model/StorageUnit.swift`

- Zile 21: **Sack**
- Zile 22: **Päckli**
- Zile 32: **Kilo**
- Zile 80: **1 Portion**

## Wuchetäg

`Model/Weekday.swift`

- Zile 11: **Sunntig**
- Zile 12: **Mänti**
- Zile 13: **Zischtig**
- Zile 14: **Mittwuch**
- Zile 15: **Dunschtig**
- Zile 16: **Fritig**
- Zile 17: **Samschtig**

## Platzhalter

`Model/Entities/Freezer.swift`

- Zile 13: **Freezer**
- Zile 29: **Tiefchüeler**

## Platzhalter

`Model/Entities/Item.swift`

- Zile 11: **Item**
- Zile 42: **Ohni Name**

## Platzhalter

`Model/Entities/CatalogProduct.swift`

- Zile 9: **CatalogProduct**
- Zile 32: **Ohni Name**

## Vorrat (Hauptliste)

`Features/Inventory/InventoryListView.swift`

- Zile 54: **Dr Tiefchüeler isch läär**
- Zile 55: **Erfass dys erschte Produkt übers Plus obe rächts.**
- Zile 56: **Produkt erfasse**
- Zile 65: **Vorrat**
- Zile 66: **Name, Bemerkig oder Lagerort**
- Zile 81: **Iitrag würklech lösche?**
- Zile 88: **Lösche**
- Zile 92: **Abbräche**
- Zile 94: **Lösche nimmt dr Iitrag mitsamt em Verlouf wäg. Wenn du ne ufbrucht hesch, nimm statt däm „Aues usenäh“ – de blibt er im Archiv.**
- Zile 110: **Gruppiere**
- Zile 124: **Kei Träffer für „\(searchText)“.**
- Zile 125: **Kei Produkt i dere Ampustufe.**
- Zile 145: **Usenäh**
- Zile 158: **Bearbeite**
- Zile 186: **Sortiere nach**
- Zile 192: **Filter ufhebe**
- Zile 197: **Sortierig**
- Zile 203: **Vo Hand erfasse**
- Zile 206: **Barcode scanne**
- Zile 210: **Erfasse**

## Vorrat – Zämefassig obe

`Features/Inventory/ExpirySummaryCard.swift`

- Zile 47: **Filter ufhebe**
- Zile 47: **Nume die zeige**
- Zile 59: **1 Produkt isch abglaufe**
- Zile 64: **1 Produkt louft die Wuche ab**
- Zile 69: **1 Produkt louft im nächschte Monet ab**
- Zile 71: **Aues im grüene Bereich**

## Vorrat – Gruppiere & Sortiere

`Features/Inventory/InventorySections.swift`

- Zile 12: **Ablouf**
- Zile 37: **Empfohle bis**
- Zile 38: **Igfrore am**
- Zile 112: **state-\(state.rawValue)**
- Zile 119: **cat-\(category.rawValue)**
- Zile 125: **Ohni Lagerort**
- Zile 128: **loc-\($0.key)**
- Zile 139: **1 Iitrag**
- Zile 141: ** · \(QuantityFormatter.portionsString(portions))**

## Detailasicht vom ne Produkt

`Features/Inventory/ItemDetailView.swift`

- Zile 35: **Bearbeite**
- Zile 45: **Dr ganz Rescht wägschmeisse?**
- Zile 49: **Wägschmeisse**
- Zile 53: **Abbräche**
- Zile 55: **Dr Iitrag wanderet is Archiv u zeut dert aus Verlust.**
- Zile 75: **Empfohle bis**
- Zile 79: **Vo Hand gsetzt**
- Zile 87: **Angabe**
- Zile 91: **Igfrore am**
- Zile 95: **Ursprünglech**
- Zile 98: **Portione ursprünglech**
- Zile 101: **Bemerkig**
- Zile 112: **Erfasst vo**
- Zile 118: **Verlouf**
- Zile 143: **Lösche**
- Zile 155: **Usenäh**
- Zile 162: **Aues usenäh**
- Zile 168: **Wäggschmisse**
- Zile 175: **Abgschlosse**
- Zile 184: **Zrügghole**
- Zile 187: **Zrügghole nimmt dr letscht Verbruch zrügg u hout dr Iitrag i Vorrat.**

## Erfasse & Bearbeite

`Features/ItemEditor/ItemEditorView.swift`

- Zile 44: **Iitrag bearbeite**
- Zile 44: **Nöie Iitrag**
- Zile 48: **Abbräche**
- Zile 51: **Sichere**
- Zile 89: **Bemerkig**
- Zile 97: **Mängi**
- Zile 114: **Portione**
- Zile 116: **kei Angab**
- Zile 123: **Bispiu: 400 g Rindsteak, 2 Portione, Bemerkig „2 Steaks im Sack“. Bim Usenäh rächnet d App zwüsche Mängi u Portione um.**
- Zile 129: **Igfrore am**
- Zile 134: **Empfohle bis**
- Zile 137: **Uf Richtwärt zrügsetze**
- Zile 147: **Vo Hand gsetzt – dr Richtwärt vo dr Kategorie wird nüm aagwändet.**
- Zile 148: **Richtwärt für \(draft.category.displayName): \(table.months(for: draft.category)) Mönet.**
- Zile 154: **z. B. Schublade 2**
- Zile 175: **Hauft bim Finde, ohni dr ganz Tiefchüeler uszrume.**
- Zile 185: **Wägnäh**
- Zile 193: **Bim Sichere merkt sech Frostify Name, Kategorie, Einheit u Mängi zu däm Code. Bim nächschte Scan isch aues scho usgfüut.**

## Usenäh

`Features/Consume/ConsumeSheet.swift`

- Zile 49: **Vorhande**
- Zile 51: **Bemerkig**
- Zile 58: **Portione usenäh**
- Zile 61: **Portione**
- Zile 71: **Mängi usenäh**
- Zile 74: **Mängi**
- Zile 97: **Was du wägschmeisst, zeut i dr Statistik aus Verlust – genau das zeigt speter, wo sech d Richtwärt loh.**
- Zile 98: **Nachhär no da: \(remainingSummary)**
- Zile 105: **Usenäh**
- Zile 114: **Aues usenäh**
- Zile 126: **Abbräche**
- Zile 140: **nüt**

## Archiv

`Features/Archive/ArchiveView.swift`

- Zile 48: **No nüt usegnoh**
- Zile 49: **Sobaud du öppis usem Tiefchüeler nimmsch oder wägschmeisst, erschint's da.**
- Zile 58: **Name oder Kategorie**
- Zile 75: **Aui**
- Zile 76: **Gässe**
- Zile 77: **Wäggschmisse**
- Zile 81: **Zitruum**
- Zile 87: **Nume ufbruchti Produkt**
- Zile 93: **Kei Verbrüch i dere Uswau.**
- Zile 123: **1 Verbruch**
- Zile 156: **nach \(storageDays) Täg**
- Zile 170: **no im Vorrat**
- Zile 198: **30 Täg**
- Zile 199: **12 Mönet**
- Zile 200: **Aues**

## Statistik

`Features/Archive/StatisticsView.swift`

- Zile 59: **No kei Verbrüch – d Statistik füut sech, sobaud dir öppis usem Tiefchüeler nämet.**
- Zile 77: **Verbrüch**
- Zile 82: **Dervo gässe**
- Zile 87: **Dervo wäggschmisse**
- Zile 93: **Ø Lagerduur**
- Zile 106: **nach Mängi gwichtet**
- Zile 110: **Total**
- Zile 112: **D Verlustquote gwichtet nach Mängi: Ei vo zwo Portione zeut aus haube Iitrag. So si Gramm, Stück u Sack vergliechbar.**
- Zile 133: **Nach Kategorie**
- Zile 135: **Obe steit, wo am meischte verlore geit. Kategorie mit hocher Quote lohne ne chürzere Richtwärt under Istellige → Haltbarkeits-Richtwärt.**
- Zile 145: **Ø \(days) T**

## Barcode-Scanner

`Features/Scanner/BarcodeScannerView.swift`

- Zile 31: **Barcode scanne**
- Zile 35: **Abbräche**
- Zile 43: **Code is Bud haute – Frostify erkennt ne automatisch.**
- Zile 57: **Code iigäh**
- Zile 60: **Übernäh**
- Zile 65: **Vo Hand**
- Zile 67: **Dr Simulator het kei Kamera – da chasch e Code trotzdäm iitippe u dr Katalog teschte.**
- Zile 76: **Frostify darf d Kamera nid bruche. Das chasch i de iOS-Istellige under Dateschutz → Kamera ändere.**
- Zile 79: **Ds Grät unterstützt dr Scanner nid.**
- Zile 81: **Dr Scanner isch grad nid verfüegbar.**

## Istellige

`Features/Settings/SettingsView.swift`

- Zile 14: **Dy Name**
- Zile 19: **Wird a de erfasste Iiträg u Verbrüch vermerkt, damit dir gseht, wär was gmacht het.**
- Zile 22: **Zäme**
- Zile 26: **Teile**
- Zile 31: **Haltbarkeits-Richtwärt**
- Zile 35: **Ds Grät**
- Zile 39: **Erinnerige**
- Zile 47: **Gruppierig**
- Zile 55: **Sortierig**
- Zile 67: **Istellige**
- Zile 76: **Dyni Date ligge i dym private iCloud-Bereich. Frostify het kei eigete Server.**

## Istellige → Teile

`Features/Settings/SharingView.swift`

- Zile 39: **Teile**
- Zile 57: **Teile beände?**
- Zile 58: **Beände**
- Zile 64: **Abbräche**
- Zile 66: **Dyni Partnerin gseht dr Tiefchüeler de nüm. Dyni Date blibe bi dir.**
- Zile 69: **Teile nid möglech**
- Zile 85: **Tiefchüeler**
- Zile 88: **Nid teilt**
- Zile 88: **Für di freiggä**
- Zile 91: **Teilt**
- Zile 96: **Link**
- Zile 97: **Für aui, wo ne hei**
- Zile 97: **Nume für Iiglademi**
- Zile 116: **Link schicke**
- Zile 125: **Schautet dr Link für aui frei, wo ne hei, u macht ds Teile-Blatt vo iOS uf. Das isch dr Wäg, wo funktioniert, wenn du dr Link eifach witerschicksch.**
- Zile 139: **Iiladig verwaute**
- Zile 148: **Apples Dialog: Lüt namentlech iilade, Rächt setze, Teilnähmer aaluege.**
- Zile 157: **Teile beände**
- Zile 164: **Dä Tiefchüeler isch dir freiggä worde. Änderige gseht dir beidi glych.**
- Zile 167: **D Freigab beände chasch übere Iiladigs-Link oder i de iCloud-Istellige under „Mit dir geteilt“.**
- Zile 172: **Teilnähmer**
- Zile 186: **Beidi bruuche ne eigeti Apple-ID u ne iCloud-Aamäudig.**
- Zile 187: **Frostify muess uf em Handy vo dr Partnerin scho installiert si, bevor si dr Link atippt.**
- Zile 188: **Ohni Netz schaffet Frostify normau wyter u glycht speter ab.**
- Zile 189: **Glychzytigi Verbrüch göh nid verlore – si wärde zämezeut.**
- Zile 191: **Guet z wüsse**
- Zile 209: **Bsitzer**
- Zile 209: **Iiglade Person**
- Zile 216: **Iiglade**
- Zile 224: **pendänt**
- Zile 229: **darf ändere**
- Zile 229: **nume läse**

## Istellige → Haltbarkeit

`Features/Settings/ShelfLifeSettingsView.swift`

- Zile 21: **· aapasst**
- Zile 30: **Richtwärt**
- Zile 32: **Us em Igfrier-Datum u em Richtwärt rächnet Frostify ds „empfohle bis“-Datum. Scho erfassti Iiträg bhaute ihres Datum – e gänderete Richtwärt wirkt uf nöii Iiträg.**
- Zile 36: **Aui uf Standard zrügsetze**

## Istellige → Erinnerige

`Features/Settings/ReminderSettingsView.swift`

- Zile 14: **Mäudig jedi Wuche**
- Zile 17: **Wuchetag**
- Zile 22: **Zit**
- Zile 31: **Vorschou**
- Zile 39: **Wuche-Mäudig**
- Zile 42: **Ei Mäudig pro Wuche (\(preferences.reminderTimeDescription)) mit auem, wo i de nächschte \(preferences.reminderHorizonDays) Täg ablouft.**
- Zile 43: **Ohni Erinnerige muesch säuber dra dänke, i d App z luege.**
- Zile 47: **Eigeti Mäudig pro Produkt**
- Zile 51: **Vorlouf**
- Zile 59: **Zuesätzlech zur Wuche-Mäudig, pro Produkt e eigeti Mitteilig. Standardmässig us, damit's nid z viu wärde.**
- Zile 63: **Berächtigung**
- Zile 65: **I de iOS-Istellige under Mitteilige → Frostify wieder erloube.**
- Zile 75: **Erinnerige**
- Zile 89: **Verweigeret**
- Zile 90: **No nid gfragt**

## Mitteilige aufs Handy

`Services/NotificationScheduler.swift`

- Zile 136: **Frostify**
- Zile 154: **1 Produkt louft i de nächschte \(horizon) Täg ab**
- Zile 157: ** u wyteri**
- Zile 158: **))\(suffix).**
- Zile 196: **Bau fäuig**

---

**245 Täxt total.**

Nid uf Mundart, mit Absicht: dr Bereich „Entwicklung" i de Istellige (nume i
Debug-Builds sichtbar), Log-Mäudige und d Kommentär im Code. Die si für
Entwickler da, nid für Benutzer.

