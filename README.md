# Frostify

Native iOS-App zur Verwaltung des Tiefkühler-Inhalts. Ziel: nichts geht vergessen,
nichts landet abgelaufen im Abfall. Der Bestand wird über iCloud mit einer zweiten
Person geteilt.

- **Spezifikation:** [SPEC.md](SPEC.md)
- **Ersteinrichtung:** [SETUP.md](SETUP.md) ← hier anfangen
- **Vor einer Veröffentlichung:** [RELEASE.md](RELEASE.md)
- **Datenschutz:** [PRIVACY.md](PRIVACY.md)

## Überblick

| | |
|---|---|
| Zielsystem | iOS 26 und neuer |
| Oberfläche | SwiftUI |
| Daten & Abgleich | Core Data über `NSPersistentCloudKitContainer` |
| Teilen | CloudKit Sharing zwischen zwei Apple-IDs |
| Barcode | VisionKit, eigener Katalog, kein externer Dienst |
| Erinnerungen | Lokale Mitteilungen, kein Server |
| Abhängigkeiten | keine externen Pakete |

## Aufbau

```
Frostify/
├── App/            Einstieg, Szenen, Annahme von Freigaben, Environment
├── Model/          Core-Data-Modell, Entitätsklassen, Kategorien, Einheiten
├── Domain/         Reine Logik ohne Core Data – hier liegen die Unit-Tests an
├── Persistence/    Stores, Repository, CloudKit-Freigabe
├── Features/       Bildschirme: Bestand, Erfassen, Entnehmen, Scanner, Archiv, Einstellungen
├── Services/       Erinnerungen, lokale Einstellungen
└── Resources/      Asset-Katalog, String Catalog
```

### Schichtenregel

- **Views** kennen ViewModels und `@FetchRequest`. Letzteres ist die bewusste Ausnahme
  zur reinen Lehre: Listen aktualisieren sich damit von selbst, sobald ein Abgleich
  Änderungen hereinbringt.
- **Domain** ist frei von Core Data und SwiftUI. Alles, was gerechnet wird
  – Ablaufdatum, Ampelstufe, Restmengen, Statistik – liegt hier und ist getestet.
- **Persistence** kapselt Core Data und CloudKit hinter `InventoryRepositoryProtocol`.
  Kein Feature-Code fasst einen `NSManagedObjectContext` direkt an.

## Zwei Entscheidungen, die den Rest erklären

**Die Restmenge wird nicht gespeichert.** Sie ergibt sich aus Anfangsmenge minus der
Summe aller Entnahmen. Ein gespeichertes Restfeld würde beim Abgleich von einem der
beiden Geräte überschrieben, wenn ihr gleichzeitig offline etwas entnehmt – eine
Entnahme ginge stillschweigend verloren. Entnahmen sind eigene, nur angehängte
Datensätze und können sich nicht gegenseitig überschreiben.

**Core Data statt SwiftData.** Bei der Oberfläche ist das Neueste auch das Beste, bei
der Persistenz nicht: Das Teilen zwischen zwei Apple-IDs ist der riskanteste Teil des
Projekts, und genau dort ist SwiftData dünn dokumentiert und unter iOS 26 mit
gemeldeten Regressionen behaftet. `NSPersistentCloudKitContainer` ist derselbe
Unterbau, für private und geteilte Datenbanken ausgelegt und uneingeschränkt
verfügbar. Die Persistenz liegt hinter einem Protokoll, ein späterer Wechsel bleibt
möglich.

## Prüfen ohne Xcode

```bash
python3 tools/verify_structure.py
```

Prüft Klammernbilanz aller Swift-Dateien, Wohlgeformtheit von XML und JSON, die
Auflösbarkeit aller Objekt-IDs in `project.pbxproj`, die Gegenbeziehungen im
Core-Data-Modell, den Abgleich zwischen Modell und `@NSManaged`-Eigenschaften sowie
Feldnamen in Prädikaten und Key-Paths.

Das ersetzt **keinen** Compiler. Den Build-Nachweis liefert Xcode mit ⌘B, die Tests
laufen mit ⌘U.

## Was bewusst nicht drin ist

Foto pro Eintrag, mehrere Tiefkühler in der Oberfläche, Einkaufsliste, Widget,
Apple Watch. Alles in [SPEC.md](SPEC.md) unter „Getroffene Entscheidungen" begründet.
