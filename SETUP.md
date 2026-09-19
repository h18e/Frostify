# Frostify einrichten

Schritt für Schritt von „Projekt heruntergeladen" bis „läuft auf beiden iPhones".
Jeder Schritt nennt den genauen Menüpfad. Wenn etwas nicht so aussieht wie
beschrieben, lieber nachfragen als raten.

**Voraussetzungen:** ein Mac mit Xcode 26 oder neuer, ein iPhone mit iOS 26 oder
neuer, und die Mitgliedschaft im Apple Developer Program (hast du).

---

## 1. Projekt auf den Mac holen

Zwei gleichwertige Wege – nimm den, bei dem du dich wohler fühlst.

### Weg A: mit Git

Öffne **Terminal** (⌘ + Leertaste, „Terminal" tippen, Enter) und gib ein:

```bash
mkdir -p ~/Developer          # legt einen Ordner "Developer" in deinem Benutzerordner an
cd ~/Developer                # wechselt in diesen Ordner ("change directory")
git clone https://github.com/h18e/Frostify.git
cd Frostify
git checkout claude/beautiful-archimedes-9oxwgn
```

Später holst du Änderungen mit:

```bash
cd ~/Developer/Frostify
git pull
```

### Weg B: als ZIP

1. Öffne https://github.com/h18e/Frostify im Browser
2. Oben links im Zweig-Auswahlmenü `claude/beautiful-archimedes-9oxwgn` wählen
3. Grüner Knopf **Code** → **Download ZIP**
4. ZIP in `~/Developer/` entpacken

> **Wichtig:** Lege den Projektordner **nicht** in iCloud Drive, Dropbox oder einen
> anderen synchronisierten Ordner. Cloud-Platzhalterdateien bringen Git und Xcode
> durcheinander, und zwar unbemerkt. `~/Developer/` ist der richtige Ort.

---

## 2. Team-ID eintragen

Damit dein Apple-Entwicklerkonto nicht in der Projektdatei landet (das würde bei
jedem `git pull` Konflikte geben), liegt es in einer eigenen, von Git ignorierten
Datei.

Im Terminal, im Projektordner:

```bash
cp Config/Signing.local.xcconfig.example Config/Signing.local.xcconfig
open -e Config/Signing.local.xcconfig     # öffnet die Datei in TextEdit
```

Ersetze `ABCDE12345` durch deine echte Team-ID und sichere mit ⌘S.

**Team-ID finden:** https://developer.apple.com/account → links **Membership details**
→ Zeile **Team ID** (zehn Zeichen, Buchstaben und Ziffern).

---

## 3. Projekt in Xcode öffnen

```bash
open Frostify.xcodeproj
```

Oder im Finder auf `Frostify.xcodeproj` doppelklicken.

Beim ersten Öffnen braucht Xcode einen Moment, um die Dateien zu indexieren.

---

## 4. Apple-Konto in Xcode hinterlegen

1. **Xcode → Settings…** (⌘ + ,)
2. Reiter **Accounts**
3. Unten links **+** → **Apple ID** → mit deiner Apple-ID anmelden

---

## 5. Signing und Capabilities prüfen

1. Im linken Navigator ganz oben auf das blaue Projektsymbol **Frostify** klicken
2. In der Spalte **TARGETS** auf **Frostify**
3. Reiter **Signing & Capabilities**

Dort sollte stehen:

| Feld | Erwartet |
|---|---|
| Automatically manage signing | angehakt |
| Team | dein Team (kommt aus Schritt 2) |
| Bundle Identifier | `ch.hebera.frostify` |

Weiter unten müssen zwei Capabilities aufgeführt sein – sie kommen aus
`Config/Frostify.entitlements`:

- **iCloud** mit angehaktem **CloudKit** und dem Container `iCloud.ch.hebera.frostify`
- **Push Notifications**

Wenn der Container **rot** ist oder fehlt, klicke bei iCloud auf das **+** unter
Containers und lege `iCloud.ch.hebera.frostify` an. Xcode erstellt ihn dann im
Entwicklerportal.

> Steht bei Team „None" oder erscheint „Signing requires a development team",
> stimmt Schritt 2 noch nicht. Prüfe, ob die Datei wirklich
> `Config/Signing.local.xcconfig` heisst (nicht `.example`).

---

## 6. Erster Start im Simulator

1. Oben in der Leiste neben dem Projektnamen ein iPhone-Modell wählen
   (z. B. „iPhone 17 Pro")
2. ⌘ + R

Erwartung: Die App startet mit leerem Bestand. Über **+** oben rechts →
**Manuell erfassen** kannst du sofort etwas anlegen.

Im Simulator gibt es keine Kamera – der Barcode-Scanner zeigt deshalb ein Feld
zum Eintippen eines Codes. Das reicht, um den Katalog zu testen.

**Erwartungsmanagement:** Das Projekt wurde ohne Compiler geschrieben. Es ist gut
möglich, dass Xcode beim ersten Bauen ein paar Fehler meldet. Das ist normal und
schnell behoben – schick mir den vollständigen Fehlertext (siehe Abschnitt 11).

---

## 7. CloudKit-Schema anlegen

Die Datenbankstruktur in iCloud entsteht nicht von selbst. Einmalig:

1. App im Simulator oder auf dem Gerät starten
2. Tab **Einstellungen** → ganz unten Abschnitt **Entwicklung**
3. **CloudKit-Schema anlegen** antippen

Kontrolle: https://icloud.developer.apple.com/dashboard → Container
`iCloud.ch.hebera.frostify` → **Schema → Record Types**. Dort müssen
`CD_Freezer`, `CD_Item`, `CD_ConsumptionEvent`, `CD_CatalogProduct` und
`CD_FreezerSettings` auftauchen.

> Der Abschnitt **Entwicklung** erscheint nur in Debug-Builds. In einer verteilten
> App ist er nicht vorhanden.

---

## 8. Auf dem eigenen iPhone starten

1. iPhone per Kabel anschliessen, am iPhone **Vertrauen** bestätigen
2. In Xcode oben das iPhone als Ziel wählen
3. ⌘ + R

Beim allerersten Mal: am iPhone **Einstellungen → Allgemein → VPN & Geräteverwaltung
→ Entwickler-App → deiner Apple-ID vertrauen**.

Wichtig: Am iPhone muss unter **Einstellungen → [dein Name]** eine iCloud-Anmeldung
aktiv sein, sonst gleicht nichts ab.

---

## 9. Test über zwei Geräte und zwei Apple-IDs

Das ist der Teil, der sich nur echt testen lässt.

**Auf deinem iPhone:**

1. Frostify öffnen, zwei, drei Produkte erfassen
2. Tab **Istellige** → **Teile**
3. **Link schicke** antippen ← *nicht* „Iiladig verwaute"
4. Das Teilen-Blatt von iOS geht auf. Schick den Link an deine Partnerin

> **Warum „Link schicke" und nicht der andere Knopf:** Eine frisch erstellte
> CloudKit-Freigabe steht auf „nur namentlich eingeladene Personen". Ein so
> verschickter Link ist technisch gültig, aber für niemanden freigeschaltet –
> beim Empfänger endet er mit *„Objekt nicht verfügbar. Die Person, der die Datei
> gehört, teilt diese nicht mehr…"*. **Link schicke** schaltet die Reichweite
> vorher ausdrücklich frei und speichert sie nach iCloud.
>
> **Iiladig verwaute** ist für den anderen Fall: Leute namentlich einladen,
> Rechte setzen, Teilnehmer ansehen, Freigabe beenden.
>
> Unter **Status → Link** siehst du jederzeit, ob der Link für alle offen ist
> („Für aui, wo ne hei") oder nicht („Nume für Iiglademi").

**Auf ihrem iPhone:**

1. Frostify muss installiert sein. Solange die App nicht im Store ist, geht das über
   Xcode (ihr iPhone anschliessen, ⌘R) oder über TestFlight (siehe RELEASE.md)
2. Sie muss mit **ihrer eigenen** Apple-ID bei iCloud angemeldet sein
3. Den Link antippen → iOS öffnet Frostify → sie bestätigt die Annahme
4. Nach ein paar Sekunden erscheint dein Bestand

**Gegenprobe – das eigentliche Ziel:**

| Test | Erwartung |
|---|---|
| Sie erfasst ein Produkt | Erscheint innerhalb von Sekunden auch bei dir |
| Du entnimmst 1 von 2 Portionen | Restmenge stimmt auf beiden Geräten |
| Beide im Flugmodus je eine Entnahme, dann online | **Beide** Entnahmen sind gezählt, keine geht verloren |
| Sie wirft etwas weg | Eintrag verschwindet bei beiden aus dem Bestand und steht im Archiv als Verlust |

Der dritte Test ist der wichtigste – genau dafür ist das Datenmodell so gebaut.

---

## 10. Tests laufen lassen

In Xcode: **⌘ + U**

Geprüft wird die Rechenlogik: Ablaufdatum und Ampelstufen, Restmengen und die
Umrechnung zwischen Menge und Portionen, die Haltbarkeits-Richtwerte und die
Statistik. Alle Tests müssen grün sein.

Zusätzlich gibt es eine Strukturprüfung, die ohne Xcode läuft:

```bash
python3 tools/verify_structure.py
```

---

## 11. Wenn etwas schiefgeht

**Bei Build-Fehlern** ist der Issue Navigator in Xcode oft eingeklappt und zeigt nur
die halbe Meldung. Vollständigen Text holen:

```bash
cd ~/Developer/Frostify
xcodebuild -project Frostify.xcodeproj -scheme Frostify -sdk iphonesimulator build > /tmp/build.log 2>&1
grep -E "error:" /tmp/build.log
```

Schick mir die Ausgabe von `grep` – vollständig, nicht als Screenshot.

**Wenn die App einfriert oder hängt:** In Xcode auf den Pause-Knopf (⏸) drücken,
dann **Debug Navigator** (⌘ + 7) öffnen und den Stacktrace des Hauptthreads
kopieren. Ohne diesen Beleg ist jede Ferndiagnose Raterei.

**Bei Abstürzen:** den vollständigen Text aus dem Konsolenbereich unten in Xcode,
inklusive der Zeile mit `Thread 1:` oder `Fatal error:`.

### Häufige Meldungen

| Meldung | Ursache und Lösung |
|---|---|
| `Signing requires a development team` | Schritt 2 fehlt oder die Datei heisst noch `.example` |
| `Unable to open base configuration reference file` | `Config/Signing.xcconfig` fehlt – Projekt nochmals sauber holen |
| `An App ID with identifier ... is not available` | Bundle Identifier ist vergeben. In `project.pbxproj` beide Vorkommen von `ch.hebera.frostify` auf etwas Eigenes ändern, ebenso den iCloud-Container |
| `CloudKit integration requires does not support unique constraints` | Am Modell wurde eine Eindeutigkeitsregel gesetzt – Frostify benutzt bewusst keine |
| Nichts gleicht ab | Beide Geräte bei iCloud angemeldet? Netz da? Schema aus Schritt 7 angelegt? |
| `Unable to initialize without an iCloud account (CKAccountStatusNoAccount)` | **Kein Fehler der App.** Der Simulator ist nicht bei iCloud angemeldet. Die App läuft lokal normal weiter. Zum Testen: im Simulator **Einstellungen → Beim iPhone anmelden**, oder gleich auf dem echten Gerät testen |
| `BUG IN CLIENT OF CLOUDKIT: … require the 'remote-notification' background mode` | Der Schlüssel fehlt in der Info.plist. Muss in `Config/Info.plist` stehen – als `INFOPLIST_KEY_*`-Build-Einstellung wird er stillschweigend verworfen |
| Nach dem Scannen ist das Formular leer | Der Hinweis zuoberst sagt warum: „Nöie Barcode" heisst, dass weder dein Katalog noch Open Food Facts den Code kennt – einmal eintippen, ab dem nächsten Scan ist alles da. „Kes Netz" heisst, dass die Abfrage nicht durchkam |
| Beim Scannen kommt nie ein Vorschlag aus dem Netz | Prüfe **Istellige → Ds Grät → Open Food Facts frage**. Steht der Schalter aus, wird nur der eigene Katalog benutzt |
| Im Simulator lässt sich nichts eintippen (kein Text, keine Mengen) | **Keine App-Frage.** Die Bildschirmtastatur des Simulators ist abgeschaltet: **I/O → Keyboard → Toggle Software Keyboard** (⌘K). Hilft das nicht, zusätzlich **Connect Hardware Keyboard** (⇧⌘K) aus- und einschalten. Die Einstellung springt gelegentlich von selbst um |
| `hapticpatternlibrary.plist konnte nicht geöffnet werden` | Simulator-Rauschen der Tastatur, hat mit Frostify nichts zu tun. Auf einem echten Gerät tritt es nicht auf |
| `Could not validate account info cache` | Begleitmeldung zu fehlender iCloud-Anmeldung, unkritisch |
| Freigabe-Link öffnet die App nicht | App muss auf dem Zielgerät installiert sein, bevor der Link angetippt wird |
| `Objekt nicht verfügbar. Die Person, der die Datei gehört, teilt diese nicht mehr oder dein Account ist nicht berechtigt, sie zu öffnen` | Der Link wurde über „Iiladig verwaute" verschickt und steht auf „nur eingeladene Personen". Lösung: in Frostify **Istellige → Teile → Link schicke** antippen und den Link neu verschicken. Der bestehende Link wird dabei freigeschaltet, die URL bleibt dieselbe |
| `The file "Frostify.xcodeproj" couldn't be opened` | Xcode zu alt – es braucht Xcode 26 oder neuer |

---

## 12. Git-Arbeitsweise

Du musst nichts committen – das mache ich in der Session. Dein einziger Befehl ist:

```bash
cd ~/Developer/Frostify
git pull
```

### Wenn `git pull` meldet, lokale Änderungen würden überschrieben

Das betrifft praktisch immer `Frostify.xcodeproj/project.pbxproj`. Ursache: Xcode
schreibt diese Datei beim Öffnen in seiner eigenen Formatierung neu. Für Git sieht
das aus wie eine echte Änderung, obwohl inhaltlich nichts anderes drinsteht.

**Erster Schritt – immer:** Änderung sichern und anschauen, statt blind zu verwerfen.

```bash
cd ~/Developer/Frostify
git diff Frostify.xcodeproj/project.pbxproj > ~/Desktop/frostify-local.diff
cat ~/Desktop/frostify-local.diff
```

Schick mir die Ausgabe. Wenn es reine Umformatierung ist, kannst du sie gefahrlos
verwerfen – gesichert ist sie ja:

```bash
git checkout -- Frostify.xcodeproj/project.pbxproj
git pull
```

**Der String Catalog** (`Frostify/Resources/Localizable.xcstrings`) ist aus dem Git
genommen und in `.gitignore` eingetragen: Xcode füllt ihn bei jedem Bauen neu, er
würde also dauerhaft Konflikte erzeugen. Falls er bei dir noch auf der Platte liegt
und als geändert auftaucht, kannst du ihn gefahrlos löschen – die App ist
einsprachig, die deutschen Texte stehen im Code.

**Wenn es sich wiederholt:** Dann weicht die Fassung im Git noch von der ab, die
dein Xcode schreibt. In dem Fall committest du Xcodes Fassung einmalig selbst –
danach ist Ruhe, weil Xcode dann nichts mehr zu ändern findet:

```bash
cd ~/Developer/Frostify
git add Frostify.xcodeproj/project.pbxproj
git commit -m "Projektdatei in Xcodes Formatierung"
git push
```

Sag mir Bescheid, wenn du das gemacht hast – dann setze ich darauf auf.

Ein Hinweis zur Beruhigung: Deine Team-ID landet dabei **nicht** im Git. Sie steht
in `Config/Signing.local.xcconfig`, die von `.gitignore` ausgenommen ist; in der
Projektdatei steht nur die Variable `$(FROSTIFY_DEVELOPMENT_TEAM)`.
