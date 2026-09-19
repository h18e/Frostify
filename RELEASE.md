# Frostify – Checkliste vor einer Veröffentlichung

Alles hier kann nur ein Mensch erledigen: es braucht Zugang zu App Store Connect,
zum CloudKit-Dashboard oder eine gestalterische Entscheidung. Status bitte laufend
nachführen.

| Status | Punkt | Was genau |
|---|---|---|
| ☐ | **App-Icon** | 1024 × 1024 px PNG, **kein Alphakanal**, randlos (keine eigenen runden Ecken), Farbraum sRGB. In Xcode: `Frostify/Resources/Assets.xcassets` → `AppIcon` → Bild hineinziehen. Ein Alphakanal ist der häufigste Ablehnungsgrund bei App Store Connect. |
| ☐ | **CloudKit-Schema nach Production** | https://icloud.developer.apple.com/dashboard → Container `iCloud.ch.hebera.frostify` → **Deploy Schema to Production**. Ohne diesen Schritt scheitert das Teilen in jeder verteilten App, ohne dass eine Code-Änderung hilft. |
| ☐ | **aps-environment auf production** | In `Config/Frostify.entitlements` steht `development`. Für TestFlight und Store muss dort `production` stehen. |
| ☐ | **Debug-Abschnitt prüfen** | Der Bereich „Entwicklung" in den Einstellungen (CloudKit-Schema anlegen) ist mit `#if DEBUG` geklammert und erscheint in Release-Builds nicht. Einmal in einem Release-Build gegenprüfen. |
| ☐ | **Versionsnummer** | `MARKETING_VERSION` und `CURRENT_PROJECT_VERSION` in `project.pbxproj` setzen. Jede Einreichung braucht eine neue Build-Nummer. |
| ☐ | **Datenschutzerklärung veröffentlichen** | Entwurf liegt in `PRIVACY.md`. Braucht eine erreichbare URL – App Store Connect verlangt sie zwingend. |
| ☐ | **Support-URL** | Kann eine schlichte Seite mit einer Kontaktmöglichkeit sein. Ebenfalls Pflichtfeld. |
| ☐ | **Drittanbieter im Fragebogen angeben** | Frostify fragt beim Scannen unbekannter Barcodes Open Food Facts ab (nur der Barcode, abschaltbar). Das gehört in die App-Datenschutzangaben und ist in `PRIVACY.md` beschrieben. |
| ☐ | **App-Datenschutzangaben** | In App Store Connect unter **App Privacy**. Frostify sammelt nichts für sich; die Daten liegen im privaten iCloud-Bereich des Nutzers. Trotzdem muss der Fragebogen ausgefüllt werden. |
| ☐ | **Screenshots** | Pro erforderlicher Gerätegrösse. Am einfachsten aus dem Simulator mit ⌘S. |
| ☐ | **Beschreibung, Schlüsselwörter, Kategorie** | Kategorie „Essen & Trinken" oder „Dienstprogramme". |
| ☐ | **Altersfreigabe** | Fragebogen in App Store Connect. |
| ☐ | **Export-Compliance** | Frostify benutzt nur die Standardverschlüsselung von iOS und CloudKit. In der Regel: „Verwendet keine nicht-exemptierte Verschlüsselung". |
| ☐ | **Test über zwei echte Apple-IDs** | Siehe SETUP.md Abschnitt 9 – insbesondere der Offline-Test mit zwei gleichzeitigen Entnahmen. |
| ☐ | **TestFlight-Durchlauf** | Erst über TestFlight installieren, dann das Teilen nochmals testen: In Produktion greift ein anderes CloudKit-Schema als in der Entwicklung. |

## Bekannte Grenzen dieser Version

- Die Oberfläche verwaltet genau **einen** Tiefkühler. Das Datenmodell könnte mehrere.
- **Wiederherstellen** im Archiv nimmt die *letzte* Entnahme zurück. Bei einem Eintrag
  mit mehreren Teilentnahmen wird also nur die jüngste rückgängig gemacht.
- Die wöchentliche Sammelmeldung wird als vier Einzeltermine im Voraus geplant und
  bei jedem App-Start neu berechnet. Wer die App über einen Monat nicht öffnet,
  bekommt danach keine Meldung mehr, bis er sie wieder öffnet.
- Einzelmeldungen pro Produkt sind auf 40 begrenzt (iOS erlaubt insgesamt 64
  anstehende Mitteilungen pro App).
- `UIDevice.name` liefert ohne Sonderberechtigung nur den Gerätetyp. Der in den
  Einstellungen gesetzte Name ist deshalb frei wählbar und rein informativ.
