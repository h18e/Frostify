#!/usr/bin/env python3
"""Listet alle sichtbaren Texte der App und schreibt sie nach TEXTE.md.

Zweck: eine vollstaendige, aus dem Quellcode erzeugte Uebersicht der Mundart-Texte,
damit einzelne Formulierungen gezielt angepasst werden koennen.

Nicht enthalten: der nur in Debug-Builds sichtbare Bereich "Entwicklung",
Log-Meldungen, SF-Symbol-Namen, Vorschau-Titel und technische Bezeichner.

Aufruf:  python3 tools/list_texts.py
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

SCREENS = [
    ('App/RootView.swift', 'Navigation & Start'),
    ('App/ShareAcceptance.swift', 'Fählermäudige zum Teile'),
    ('Domain/ExpiryCalculator.swift', 'Ampu & Restlaufzyt'),
    ('Model/ConsumptionKind.swift', 'Grund vo dr Usenahm'),
    ('Model/FoodCategory.swift', 'Kategorie'),
    ('Model/StorageUnit.swift', 'Einheite & Portione'),
    ('Model/Weekday.swift', 'Wuchetäg'),
    ('Model/Entities/Freezer.swift', 'Platzhalter'),
    ('Model/Entities/Item.swift', 'Platzhalter'),
    ('Model/Entities/CatalogProduct.swift', 'Platzhalter'),
    ('Features/Inventory/InventoryListView.swift', 'Vorrat (Hauptliste)'),
    ('Features/Inventory/ExpirySummaryCard.swift', 'Vorrat – Zämefassig obe'),
    ('Features/Inventory/InventorySections.swift', 'Vorrat – Gruppiere & Sortiere'),
    ('Features/Inventory/ItemDetailView.swift', 'Detailasicht vom ne Produkt'),
    ('Features/ItemEditor/ItemEditorView.swift', 'Erfasse & Bearbeite'),
    ('Features/Consume/ConsumeSheet.swift', 'Usenäh'),
    ('Features/Archive/ArchiveView.swift', 'Archiv'),
    ('Features/Archive/StatisticsView.swift', 'Statistik'),
    ('Features/Scanner/BarcodeScannerView.swift', 'Barcode-Scanner'),
    ('Features/Settings/SettingsView.swift', 'Istellige'),
    ('Features/Settings/SharingView.swift', 'Istellige → Teile'),
    ('Features/Settings/ShelfLifeSettingsView.swift', 'Istellige → Haltbarkeit'),
    ('Features/Settings/ReminderSettingsView.swift', 'Istellige → Erinnerige'),
    ('Services/NotificationScheduler.swift', 'Mitteilige aufs Handy'),
]

# Technische Zeichenketten und Woerter, die in jeder Sprache gleich heissen.
TECH = re.compile(
    r'^([a-z][a-zA-Z0-9]*(\.[a-zA-Z0-9]+)+|[a-z0-9_.\-]+|CFBundle\w+|[\s·–—%@]+'
    r'|de_CH|OK|Barcode|Status|System|Version|Über|Name|Kategorie|Lagerort|Produkt'
    r'|Grund|Statistik|Archiv|Einheit|Haltbarkeit|Verlustquote|Milliliter|Liter'
    r'|Gramm|Stück|Stk\.|Unbekannt|Erteilt|Über Link)$'
)
SKIP_LINE = ('logger.', 'Logger(', 'fatalError(', 'NSPredicate', 'NSSortDescriptor',
             'forResource', '#Preview')


def collect(rel: str) -> list[tuple[int, str]]:
    path = ROOT / 'Frostify' / rel
    seen: set[str] = set()
    hits: list[tuple[int, str]] = []
    in_debug = False

    for number, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
        if '#if DEBUG' in line:
            in_debug = True
        if '#endif' in line:
            in_debug = False
        if in_debug:
            continue
        stripped = line.strip()
        if stripped.startswith(('//', '///', '*')) or any(k in line for k in SKIP_LINE):
            continue
        for match in re.finditer(r'"([^"\\]*(?:\\.[^"\\]*)*)"', line):
            text = match.group(1)
            if len(text) < 2 or TECH.match(text) or text.startswith('\\('):
                continue
            if text in seen:
                continue
            seen.add(text)
            hits.append((number, text))
    return hits


def main() -> None:
    out = [
        "# Frostify – aui Täxt i dr App",
        "",
        "Automatisch us em Quellcode erzeugt mit `tools/list_texts.py`.",
        "Platzhalter wie `\\(days)` wärde zur Laufzyt dür Zahle ersetzt.",
        "",
        "Wenn dir öppis nid passt: säg mer d Zile, i ändere's.",
        "",
        "---",
        "",
    ]
    total = 0
    for rel, screen in SCREENS:
        hits = collect(rel)
        if not hits:
            continue
        out += [f"## {screen}", "", f"`{rel}`", ""]
        for number, text in hits:
            out.append(f"- Zile {number}: **{text}**")
            total += 1
        out.append("")

    out += [
        "---",
        "",
        f"**{total} Täxt total.**",
        "",
        "Nid uf Mundart, mit Absicht: dr Bereich „Entwicklung\" i de Istellige (nume i",
        "Debug-Builds sichtbar), Log-Mäudige und d Kommentär im Code. Die si für",
        "Entwickler da, nid für Benutzer.",
        "",
    ]
    (ROOT / 'TEXTE.md').write_text("\n".join(out) + "\n", encoding='utf-8')
    print(f"TEXTE.md geschrieben: {total} Texte")


if __name__ == '__main__':
    main()
