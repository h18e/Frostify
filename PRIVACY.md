# Datenschutzerklärung – Frostify

**Entwurf.** Vor einer Veröffentlichung im App Store muss dieser Text unter einer
erreichbaren URL liegen; App Store Connect verlangt das zwingend. Rechtlich geprüft
ist er nicht.

Stand: 19. September 2026

## Verantwortlich

Frostify ist ein privates Projekt. Kontakt: *(Support-Adresse eintragen)*

## Welche Daten die App verarbeitet

Frostify speichert ausschliesslich das, was du selbst erfasst:

- Bezeichnung, Kategorie, Menge, Einheit und Portionen eines Lebensmittels
- Freie Bemerkung und Lagerort
- Einfrierdatum und das „empfohlen bis"-Datum
- Barcodes, die du scannst, samt den Angaben, die du ihnen einmal zugeordnet hast
- Entnahmen mit Zeitpunkt, Menge und Grund
- Ein frei wählbarer Anzeigename, damit erkennbar ist, wer etwas erfasst hat

## Wo diese Daten liegen

Auf deinem Gerät und in **deinem privaten iCloud-Bereich**. Frostify betreibt keinen
eigenen Server. Die Entwickler der App haben keinen Zugriff auf deine Daten und
erhalten davon keine Kenntnis.

Für den iCloud-Anteil gilt die Datenschutzerklärung von Apple:
https://www.apple.com/legal/privacy/

## Teilen mit einer zweiten Person

Wenn du deinen Tiefkühler teilst, erhält die von dir eingeladene Person Lese- und
Schreibzugriff auf genau diesen Tiefkühler samt Inhalt, Barcode-Katalog und Verlauf.
Der Austausch läuft über Apples CloudKit-Freigabe. Du kannst die Freigabe jederzeit
beenden.

## Kamera

Die Kamera wird ausschliesslich zum Erkennen von Barcodes benutzt. Es werden keine
Bilder gespeichert und keine Bilddaten übertragen. Die Erkennung läuft auf dem Gerät.

## Abfrage bei Open Food Facts

Scannst du einen Barcode, den dein eigener Katalog noch nicht kennt, fragt Frostify
die offene Produktdatenbank **Open Food Facts** (`world.openfoodfacts.org`) nach
diesem Produkt.

- Übertragen wird **ausschliesslich der Barcode**. Keine Namen, keine Mengen, keine
  Angaben aus deinem Tiefkühler, keine Kennung deines Geräts oder deiner Apple-ID.
- Die Anfrage läuft über eine verschlüsselte Verbindung (HTTPS). Wie bei jedem
  Aufruf im Internet sieht der Dienst dabei technisch deine IP-Adresse.
- Frostify gibt sich mit Name und Version zu erkennen, wie es Open Food Facts von
  Anwendungen erwartet.
- Die Antwort wird nur lokal verwendet, um das Erfassungsformular vorauszufüllen.
  Es wird nichts an Open Food Facts zurückgemeldet oder dort gespeichert.
- Für ein Produkt geschieht das **höchstens einmal**: Sobald du es gesichert hast,
  steht es in deinem eigenen Katalog und wird beim nächsten Scan von dort genommen.

Die Abfrage lässt sich in den Einstellungen unter **Ds Grät → Open Food Facts
frage** abschalten. Dann bleibt das Formular bei unbekannten Codes leer, und es
verlässt gar nichts das Gerät.

Datenschutzerklärung von Open Food Facts: https://world.openfoodfacts.org/privacy

## Mitteilungen

Erinnerungen an bald ablaufende Produkte sind lokale Mitteilungen, die dein Gerät
selbst plant. Dafür verlässt kein Datum dein Gerät.

## Keine Weitergabe an Dritte

Frostify enthält keine Werbung, keine Analysedienste, keine Tracker und keine
Bibliotheken von Drittanbietern. Die einzige Verbindung nach aussen ist die oben
beschriebene Barcode-Abfrage bei Open Food Facts – sie ist abschaltbar und
überträgt nur den Barcode.

## Deine Rechte

Du kannst jederzeit einzelne Einträge oder die gesamte App löschen. Beim Löschen der
App über iOS werden die lokalen Daten entfernt; die iCloud-Daten löschst du unter
**Einstellungen → [dein Name] → iCloud → Speicher verwalten → Frostify**.
