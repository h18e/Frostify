# Frostify – Spezifikation (Phase 1)

**Stand:** 2026-09-17 · **Status:** freigegeben und umgesetzt (siehe README.md, SETUP.md) · **Autor:** Claude Code für Raphi

Native iOS-App zur Verwaltung des Tiefkühler-Inhalts. Ziel: nichts geht vergessen,
nichts landet abgelaufen im Abfall. Die Daten werden mit Raphis Partnerin geteilt.

---

## 1. Bestätigte Anforderungen

| Thema | Entscheid |
|---|---|
| Datum | Nur **Einfrierdatum** wird erfasst. Daraus berechnet die App über einen kategorieabhängigen Richtwert ein **"empfohlen bis"**-Datum, das pro Eintrag überschreibbar ist. |
| Menge | **Zahl + Einheit** (g, kg, Stück, Beutel, Packung, ml, l) **plus Portionen** **plus freies Bemerkungsfeld** (z. B. "400 g Rindsteak = 2 Steaks"). |
| Kategorien | Feste Kategorienliste (steuert den Haltbarkeits-Richtwert) **plus freier Lagerort** pro Eintrag ("Schublade 2"). |
| Entnahme | **Teilentnahme mit Restmenge**; bei Rest 0 automatisch ins Archiv. "Alles entnehmen" mit einem Tipp. |
| Teilen | **CloudKit Sharing zwischen zwei Apple-IDs** (Einladungslink). |
| Erinnerungen | **Ja**, lokale Benachrichtigungen bei bald ablaufenden Produkten. |
| Barcode | **Ja**, eigener Katalog als erste Quelle; bei unbekanntem Code Rückfall auf Open Food Facts (abschaltbar, überträgt nur den Barcode). |
| Archiv & Statistik | **Ja**. |
| Einkaufsliste | **Nicht in v1** (bewusst verschoben). |
| Mindest-iOS | **iOS 26** – "das Beste, was ab iOS 26 passt". |
| Bundle ID | **`ch.hebera.frostify`** |

---

## 2. Datenmodell

Fünf Entitäten. `Freezer` ist bewusst die Wurzel, weil CloudKit immer einen
**Objektbaum ab genau einem Wurzel-Datensatz** teilt: Wird der Tiefkühler geteilt,
sind Inhalt, Katalog und Verlauf automatisch mitgeteilt.

### 2.1 Freezer (Tiefkühler)

| Feld | Typ | Bemerkung |
|---|---|---|
| id | UUID | |
| name | String | z. B. "Tiefkühler Küche" |
| createdAt | Date | |
| items | [Item] | 1:n |
| catalogEntries | [CatalogProduct] | 1:n |
| settings | FreezerSettings | 1:1, mitgeteilt (Richtwerte gelten für beide) |

### 2.2 Item (Eintrag)

| Feld | Typ | Bemerkung |
|---|---|---|
| id | UUID | |
| name | String | "Rindsteak" |
| category | String (Enum-Rawvalue) | siehe 2.5 |
| initialQuantity | Double | Menge beim Einfrieren |
| unit | String (Enum-Rawvalue) | g, kg, Stk, Beutel, Packung, ml, l |
| initialPortions | Int? | optional |
| note | String | freie Bemerkung ("2 Steaks im Beutel") |
| frozenAt | Date | Einfrierdatum |
| bestBefore | Date | berechnet oder manuell |
| bestBeforeIsManual | Bool | true ⇒ Richtwert-Änderung überschreibt nicht mehr |
| storageLocation | String? | freier Text, mit Vorschlägen aus bisherigen Werten |
| barcode | String? | verbindet mit CatalogProduct |
| createdByName | String | Gerätename, damit sichtbar ist, wer erfasst hat |
| createdAt / updatedAt | Date | |
| closedAt | Date? | gesetzt, wenn Rest 0 ⇒ Archiv |
| closeReason | String? | `consumed` / `discarded` |
| events | [ConsumptionEvent] | 1:n |

**Restmenge wird nicht gespeichert, sondern berechnet:**
`remainingQuantity = initialQuantity − Σ events.quantityTaken` (analog für Portionen).

Begründung: Wenn ihr beide gleichzeitig offline etwas entnehmt, würde ein
gespeichertes Restfeld beim Sync von einem Gerät überschrieben – eine Entnahme
ginge stillschweigend verloren. Entnahmen als eigene, nur angehängte Datensätze
können sich nicht gegenseitig überschreiben; die Summe stimmt danach automatisch.

### 2.3 ConsumptionEvent (Entnahme)

| Feld | Typ | Bemerkung |
|---|---|---|
| id | UUID | |
| item | Item | n:1 |
| date | Date | |
| quantityTaken | Double | |
| portionsTaken | Int? | |
| kind | String | `consumed` (gegessen) / `discarded` (weggeworfen) |
| byName | String | Gerätename |

`discarded` ist der Datenpunkt, aus dem die Statistik später zeigt, wo ihr
tatsächlich Lebensmittel verliert.

### 2.4 CatalogProduct (Barcode-Katalog)

| Feld | Typ | Bemerkung |
|---|---|---|
| barcode | String | Schlüssel (EAN/UPC) |
| name | String | |
| category | String | |
| defaultUnit | String | |
| defaultQuantity | Double? | Vorschlag |
| defaultPortions | Int? | Vorschlag |
| defaultNote | String? | Vorschlag |
| useCount | Int | |
| lastUsedAt | Date | |

Wird beim Erfassen automatisch angelegt/aktualisiert – kein separater Pflegeaufwand.

### 2.5 Kategorien und Haltbarkeits-Richtwerte

Fest verdrahtete Liste (als Swift-Enum), Richtwert je Kategorie in `FreezerSettings`
überschreibbar und für beide gültig:

| Kategorie | Richtwert |
|---|---|
| Fleisch (Stücke, Braten) | 12 Monate |
| Hackfleisch & Wurstwaren | 3 Monate |
| Geflügel | 9 Monate |
| Fisch fett (Lachs, Thunfisch) | 3 Monate |
| Fisch mager & Meeresfrüchte | 6 Monate |
| Gemüse | 12 Monate |
| Früchte & Beeren | 12 Monate |
| Brot, Teig & Gebäck | 3 Monate |
| Fertiggerichte & Selbstgekochtes | 3 Monate |
| Suppen, Saucen & Fonds | 6 Monate |
| Kräuter | 6 Monate |
| Butter & Rahm | 6 Monate |
| Desserts & Glace | 6 Monate |
| Sonstiges | 6 Monate |

**Ampel** (zusätzlich immer mit Symbol und Text, nie nur Farbe – Barrierefreiheit):

| Zustand | Bedingung |
|---|---|
| 🟢 in Ordnung | mehr als 30 Tage bis "empfohlen bis" |
| 🟡 bald verbrauchen | 8–30 Tage |
| 🟠 dringend | 0–7 Tage |
| 🔴 überschritten | Datum vorbei |

---

## 3. Kernfunktionen / User Stories

### 3.1 Übersicht (Startbildschirm)
- Als Raphi sehe ich beim Öffnen sofort, was bald abläuft: oberste Zeile
  "3 Produkte laufen diese Woche ab" – antippbar als Filter.
- Liste aller aktiven Einträge, gruppiert nach **Ablauf**, **Kategorie** oder
  **Lagerort** – die Umschaltung steht sichtbar über der Liste, nicht in einem Menü.
  Jeder Abschnittskopf nennt Anzahl und Portionen. Sortierbar nach "empfohlen bis",
  Einfrierdatum, Name oder Kategorie.
- Jede Zeile: Name, Restmenge + Einheit, Restportionen, Ampel, Lagerort.
- Volltextsuche über Name, Bemerkung und Lagerort.
- Wischgesten: links → "Entnehmen", rechts → "Details".

### 3.2 Erfassen
- Plus-Knopf → Formular: Name, Kategorie, Menge + Einheit, Portionen, Bemerkung,
  Einfrierdatum (Vorgabe: heute), Lagerort, optional Barcode scannen.
- "empfohlen bis" wird live aus Kategorie + Einfrierdatum berechnet und angezeigt;
  antippen und ändern macht es manuell.
- Scan-Weg, drei Quellen in dieser Reihenfolge:
  1. **Eigener Katalog** – was ihr einmal erfasst habt, gilt. Ohne Netz, ohne Wartezeit.
  2. **Open Food Facts**, nur bei unbekanntem Code und nur wenn in den Einstellungen
     erlaubt. Übertragen wird ausschliesslich der Barcode. Name, Marke, Menge und eine
     geratene Kategorie füllen das Formular vor.
  3. **Leeres Formular**, wenn beides nichts hergibt oder kein Netz da ist.

  In jedem Fall gilt: Was beim Sichern im Formular steht – inklusive deiner
  Korrekturen – landet im eigenen Katalog. Ab dem zweiten Scan desselben Produkts
  wird nichts mehr gefragt. Der Hinweis zuoberst im Formular sagt jeweils, woher die
  Angaben stammen.
- "Nochmals erfassen" an einem bestehenden Eintrag dupliziert ihn mit heutigem Datum.

### 3.3 Entnehmen
- Detailansicht zeigt Restmenge, Restportionen, Verlauf aller Entnahmen.
- "Entnehmen": Schieber/Stepper für Menge **oder** Portionen (die App rechnet die
  jeweils andere Grösse anteilig mit und zeigt beide an, bevor du bestätigst).
- Zwei Knöpfe: **Alles entnehmen** und **Weggeworfen** (beides ein Tipp).
- Rest 0 ⇒ Eintrag wandert ins Archiv, verschwindet aus der Übersicht.

### 3.4 Erinnerungen
- Wöchentliche Sammelmeldung (Vorgabe Sonntag 18:00, Zeitpunkt einstellbar):
  "4 Produkte laufen in den nächsten 14 Tagen ab."
- Optional zusätzlich: Einzelmeldung X Tage vor Ablauf (Vorgabe aus).
- Meldungen sind rein lokal (kein Server). Jedes Gerät plant sie selbst neu,
  wenn sich Daten ändern oder die App startet – so bekommt ihr sie beide.

### 3.5 Archiv & Statistik
- Archiv: Liste **einzelner Entnahmen**, nicht abgeschlossener Produkte. Wer eine
  von zwei Portionen isst und die zweite wegwirft, findet denselben Eintrag mit
  einer Zeile unter „Gegessen" und einer unter „Weggeworfen". Filterbar nach Grund,
  Zeitraum und Text; ein Schalter blendet Produkte aus, die noch im Bestand liegen.
  Wiederherstellen eines Eintrags ist in der Detailansicht möglich (Fehlbedienung).
- Archiv aufräumen: **„Archiv leere"** löscht aufgebrauchte Einträge mitsamt Verlauf,
  wahlweise alle oder nur die älter als ein Jahr. Einträge, die noch im Vorrat
  liegen, bleiben unberührt. Einzelne Zeilen lassen sich wegwischen: bei einem
  aufgebrauchten Produkt der ganze Eintrag, sonst nur diese eine Entnahme – dort
  kommt die Menge zurück in den Vorrat. Gelöscht wird über CloudKit bei beiden.
- Statistik: gezählt werden **einzelne Entnahmen**, nicht abgeschlossene Einträge.
  Jede Entnahme trägt ihren Anteil am Eintrag (200 g von 400 g = 0,5), wodurch
  Gramm, Stück und Beutel vergleichbar werden. Angezeigt werden Anzahl gegessener
  und weggeworfener Entnahmen, die nach Menge gewichtete Verlustquote und die
  durchschnittliche Lagerdauer – gesamt und je Kategorie.

### 3.6 Einstellungen
- **Teilen**: Tiefkühler mit Partnerin teilen, Teilnehmer sehen, Freigabe beenden.
- **Erinnerungen**: an/aus, Wochentag, Uhrzeit, Vorlaufzeit.
- **Haltbarkeits-Richtwerte**: Werte je Kategorie anpassen.
- **Anzeige**: Standard-Gruppierung und -Sortierung.
- **Über**: Version, Datenschutz, lokaler Modus (siehe 6.4).

---

## 4. Sync- und Sharing-Konzept

**Container:** ein CloudKit-Container, zwei Datenbank-Bereiche parallel geladen:
- `.private` – dein eigener Tiefkühler (Besitzer)
- `.shared` – Tiefkühler, die dir jemand freigegeben hat (bei deiner Partnerin)

**Ablauf der Freigabe:**
1. Du öffnest Einstellungen → Teilen → Einladung erstellen.
2. Die App erzeugt einen `CKShare` auf dem `Freezer`-Datensatz, setzt
   `publicPermission = .readWrite` und sichert die Änderung mit
   `persistUpdatedShare`; der **zurückgegebene** Share liefert die gültige URL.
   *(Ohne diese Schritte gilt die Freigabe nur für namentlich eingeladene Personen –
   ein weitergeleiteter Link läuft ins Leere. Deshalb gibt es zwei getrennte Wege:
   „Link schicke" schaltet frei und öffnet das Teilen-Blatt von iOS, „Iiladig
   verwaute" öffnet Apples Dialog zum namentlichen Einladen.)*
3. Du schickst den Link per iMessage/WhatsApp.
4. Sie tippt ihn an, iOS öffnet Frostify, die Annahme wird in
   `windowScene(_:userDidAcceptCloudKitShareWith:)` verarbeitet. *(Bei einer
   SwiftUI-App reicht die alte AppDelegate-Variante nicht – die Annahme verpufft
   sonst lautlos.)*
5. Ab da sehen und bearbeiten beide denselben Bestand.

**Offline:** Vollständig. Die lokale Datenbank ist die Arbeitsgrundlage; der Abgleich
läuft im Hintergrund, sobald Netz da ist. Push-Benachrichtigungen von CloudKit sorgen
dafür, dass Änderungen der Partnerin in Sekunden ankommen, wenn beide online sind.

**Konflikte:** Feldweise "letzte Änderung gewinnt"
(`NSMergeByPropertyObjectTrumpMergePolicy`). Der kritische Fall – gleichzeitige
Entnahmen – ist durch das Event-Modell (2.2) strukturell entschärft, nicht durch
Konfliktregeln.

**Vor der Verteilung:** CloudKit hat getrennte Development- und Production-Umgebungen.
Vor TestFlight/Store muss im CloudKit-Dashboard **"Deploy Schema to Production"**
ausgeführt werden, sonst scheitert das Teilen in der verteilten App ohne jede
Code-Änderung.

---

## 5. Tech-Stack

| Baustein | Wahl | Begründung |
|---|---|---|
| UI | SwiftUI, Zielsystem **iOS 26+** | Aktuelle API-Generation, keine Altlasten-Kompromisse. |
| Persistenz & Sync | **Core Data + `NSPersistentCloudKitContainer`** | Siehe unten. |
| Nebenläufigkeit | Swift Concurrency (`async/await`, `@Observable`) | Aktueller Standard. |
| Barcode | **VisionKit `DataScannerViewController`** | Apple-eigen, kein Drittanbieter, funktioniert offline. |
| Benachrichtigungen | `UNUserNotificationCenter`, lokal | Kein Server nötig. |
| Tests | Swift Testing | Für Ablauf-, Mengen- und Statistiklogik. |
| Abhängigkeiten | **keine externen Pakete** | Weniger, was bei OS-Updates bricht. |

### Warum Core Data und nicht SwiftData?

Du hast gesagt "das Beste, was ab iOS 26 passt". Bei der Oberfläche ist das eindeutig
SwiftUI. Bei der Persistenz ist "das Beste" nicht das Neueste, und ich will das
belegen statt behaupten: Das Teilen zwischen zwei Apple-IDs ist der mit Abstand
riskanteste Teil dieses Projekts, und genau dort ist SwiftData schwach. Apples
CloudKit-Sharing ist für SwiftData kaum dokumentiert; in den Entwicklerforen sind für
iOS 26 zudem mehrere konkrete Regressionen gemeldet (SwiftData-CloudKit-Sync bleibt
stehen, Sharing-Links öffnen Drittanbieter-Apps nicht, `CKShareRequestAccessOperation`
ist im SDK vorhanden, aber ohne Funktion).

`NSPersistentCloudKitContainer` ist derselbe Unterbau, ist für private **und**
geteilte Datenbanken ausgelegt, hat dafür dokumentierte APIs – und ist unter iOS 26
uneingeschränkt verfügbar und nicht abgekündigt. Der Preis sind etwa 200 Zeilen mehr
Rahmen-Code, den ich schreibe, nicht du.

*Das ist ein Architekturentscheid mit Verfallsdatum: Sollte Apple das Sharing für
SwiftData nachziehen, ist der Wechsel möglich, weil die gesamte Persistenz hinter
einem eigenen Protokoll liegt (siehe 6).*

---

## 6. Architektur

### 6.1 Ordnerstruktur

```
Frostify/
├── App/
│   ├── FrostifyApp.swift          # Einstieg, Szenen
│   └── ShareAcceptance.swift      # Annahme von CloudKit-Einladungen
├── Model/
│   ├── Frostify.xcdatamodeld      # Core-Data-Modell
│   ├── Entities/                  # Freezer, Item, ConsumptionEvent, CatalogProduct
│   ├── Category.swift             # Kategorien + Richtwerte
│   └── MeasurementUnit.swift      # Einheiten + Umrechnung
├── Persistence/
│   ├── PersistenceController.swift    # Container, private + shared Store
│   ├── CloudSharingService.swift      # CKShare erstellen/verwalten
│   └── InventoryRepository.swift      # Protokoll + Core-Data-Umsetzung
├── Domain/                            # reine Logik, ohne Core Data, voll testbar
│   ├── ExpiryCalculator.swift         # Ablaufdatum + Ampelstufe
│   ├── QuantityMath.swift             # Restmengen, anteilige Portionen
│   └── StatisticsBuilder.swift
├── Features/
│   ├── Inventory/                     # Übersicht, Filter, Zeilen
│   ├── ItemEditor/                    # Erfassen und Bearbeiten
│   ├── Consume/                       # Entnahme-Dialog
│   ├── Scanner/                       # Barcode + Katalog
│   ├── Archive/                       # Archiv und Statistik
│   └── Settings/                      # Teilen, Erinnerungen, Richtwerte
├── Services/
│   └── NotificationScheduler.swift
└── Resources/
    ├── Localizable.xcstrings          # String Catalog
    └── Assets.xcassets
```

### 6.2 Schichtenregel

- **Views** kennen nur ViewModels und `@FetchRequest` (für Listen – so aktualisiert
  sich die Oberfläche bei eintreffenden Sync-Änderungen von selbst).
- **Domain** enthält reine Funktionen ohne Core-Data-Bezug: Ablaufberechnung,
  Mengenarithmetik, Statistik. Das ist die Schicht, die Unit-Tests bekommt.
- **Persistence** kapselt Core Data und CloudKit hinter `InventoryRepository`.
  Kein Feature-Code greift direkt auf `NSManagedObjectContext` zu.

### 6.3 Gestaltung und Sprache

- Apple HIG, **Dark Mode als einziges Erscheinungsbild**, Dynamic Type, SF Symbols,
  VoiceOver-Beschriftungen. Farb- und Flächensystem aus Räpplispauter übernommen
  (`Theme.swift`, `Components.swift`); Akzentfarbe ist das Türkis aus dessen
  Kategorienpalette, damit Grün der Ampelstufe „in Ordnung" vorbehalten bleibt.
- App-Sprache: **Berndeutsch**, Du-Form. Die Texte stehen als Literale im Code und
  dienen SwiftUI zugleich als Übersetzungsschlüssel. Mundart hat keine amtliche
  Rechtschreibung; verwendet wird durchgehend L-Vokalisierung (`aues`, `fäuig`),
  `-ig` statt `-ung` (`Bemerkig`, `Istellige`) und `nid`/`nüt`/`no`. Ein String Catalog liegt nicht im Git, weil Xcode ihn bei
  jedem Bauen neu schreibt; er kommt dazu, sobald eine zweite Sprache ansteht.
- Farben nie als einziger Träger einer Information – die Ampel hat immer Symbol und Text.

### 6.4 iCloud von Anfang an

Das Apple Developer Program ist vorhanden, iCloud und CloudKit stehen also ab dem
ersten Tag zur Verfügung. Ein separater "lokaler Modus" als Überbrückung entfällt
damit – das spart einen Sonderfall, den sonst jede Datenzugriffsstelle mittragen
müsste. Ohne iCloud-Anmeldung läuft die App trotzdem: Core Data arbeitet dann rein
lokal weiter und gleicht ab, sobald eine Anmeldung vorliegt.

## 7. Begleitende Dokumente

Werden ab Phase 2 mitgeführt und bei jeder relevanten Änderung nachgezogen:

| Datei | Inhalt |
|---|---|
| `README.md` | Aufbau des Projekts |
| `SETUP.md` | Schritt-für-Schritt-Ersteinrichtung (Xcode, Signing, iCloud) |
| `RELEASE.md` | Checkliste dessen, was nur du erledigen kannst, vor einer Veröffentlichung |
| `PRIVACY.md` | Entwurf Datenschutzerklärung, sobald Veröffentlichung absehbar |

---

## 8. Getroffene Entscheidungen

Alle in der Erstfassung offenen Punkte sind entschieden:

| # | Punkt | Entscheid |
|---|---|---|
| 1 | Apple Developer Program | **Vorhanden** – CloudKit und Sharing ab Tag 1, kein lokaler Überbrückungsmodus |
| 2 | Bundle Identifier | **`ch.hebera.frostify`** |
| 3 | Foto pro Eintrag | **Nein** |
| 4 | Mehrere Tiefkühler | **Einer.** Das Datenmodell behält `Freezer` als Wurzel (nötig für CloudKit-Sharing), die Oberfläche zeigt aber keine Verwaltung mehrerer Tiefkühler |
| 5 | Ampel-Schwellen | **Fest:** 🟢 > 30 Tage · 🟡 8–30 Tage · 🟠 0–7 Tage · 🔴 überschritten |
| 6 | Widget / Sperrbildschirm / Apple Watch | **Nein** |
| 7 | Einkaufs-/Nachfüllliste | **Nein** |
| 8 | App-Icon | Raphi liefert es am Schluss. Bis dahin schlichter Platzhalter; der finale Austausch steht als Punkt in `RELEASE.md` (1024×1024 px PNG, ohne Alphakanal, randlos, sRGB) |

## 9. Ehrliche Einschränkung

Diese Umgebung ist Linux – hier läuft kein macOS und kein Xcode. Ich kann den Code
schreiben und strukturell prüfen (Klammernbilanz, Wohlgeformtheit der Projektdatei,
Abgleich verwendeter gegen deklarierte Lokalisierungsschlüssel), aber **nicht
kompilieren**. Der Build-Nachweis liegt bei dir. Bei einem Projekt dieser Grösse sind
beim ersten Öffnen in Xcode ein paar Compile-Fehler wahrscheinlich – die arbeiten wir
dann anhand der exakten Fehlertexte ab.

---

## 10. Freigabe

Mit "Freigabe", "Umsetzen" oder "Starte jetzt" beginne ich mit Phase 2. Sinnvolle
Reihenfolge:

1. Xcode-Projekt, Datenmodell, Persistenzschicht (lokal), Domain-Logik + Tests
2. Übersicht, Erfassen, Entnehmen, Archiv
3. Barcode-Scanner und Katalog
4. Benachrichtigungen, Statistik, Einstellungen
5. CloudKit-Sync und Sharing
6. `SETUP.md` / `RELEASE.md` und die Anleitung zum Test über zwei Geräte
