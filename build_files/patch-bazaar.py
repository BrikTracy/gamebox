#!/usr/bin/env python3
"""Buduje (w czasie budowania obrazu) dwie zmiany powiązane z Bazaar, sklepem Bazzite:

1. content.yaml: dopisuje sekcję "Emulacja" z katalogu GameBox zaraz za sekcją "Gaming".
   Dopisujemy do pliku z Bazzite zamiast go podmieniać, żeby aktualizacje listy Bazzite
   wchodziły dalej same.
2. Wpis .desktop Bazaar: dokłada kategorie System;PackageManager;, dzięki którym LineXinBar
   stawia sklep w kolumnie Software (Bazaar nie ma go na swojej liście znanych sklepów).

Błąd w (1) przerywa budowę, bo bez sklepu emulatory nie będą widoczne. Brak pliku .desktop
(2) to tylko ostrzeżenie.
"""
import argparse
import re
import sys
import tomllib
from pathlib import Path

MARK = "# --- GameBox: sekcja Emulacja ---"
TITLE = {"en": "Emulation", "pl": "Emulacja"}
SUBTITLE = {"en": "Retro and console games, picked for your hardware",
            "pl": "Gry retro i konsolowe, dobrane do Twojego sprzętu"}


def section_yaml(ids):
    lines = [MARK, "  - section:", "      title:"]
    lines += [f'        {k}: "{v}"' for k, v in TITLE.items()]
    lines += ["      subtitle:", "        string:"]
    lines += [f'          {k}: "{v}"' for k, v in SUBTITLE.items()]
    lines += ["      appids:", "        list:"]
    lines += [f"          - {i}" for i in ids]
    lines.append("")
    return "\n".join(lines) + "\n"


def patch_content(content: Path, catalog: Path):
    ids = [a["id"] for a in tomllib.loads(catalog.read_text())["app"]]
    text = content.read_text()
    if MARK in text:
        print("content.yaml: sekcja już jest, pomijam")
        return
    banners = [m.start() for m in re.finditer(r"^  - banner:", text, re.M)]
    if len(banners) < 2:
        sys.exit("BŁĄD: content.yaml z Bazzite ma inną strukturę niż zakładamy (mniej niż 2 banery). "
                 "Sprawdź plik w ublue-os/bazzite: system_files/desktop/shared/usr/share/ublue-os/bazaar/")
    pos = banners[1]  # za sekcją Gaming (pierwszy baner), przed Streaming (drugi baner)
    content.write_text(text[:pos] + section_yaml(ids) + "\n" + text[pos:])
    print(f"content.yaml: dodano sekcję Emulacja ({len(ids)} aplikacji)")


def patch_desktop(desktop: Path):
    if not desktop.exists():
        print(f"OSTRZEŻENIE: nie ma {desktop}: LineXinBar może nie pokazać Bazaar w kolumnie Software")
        return
    text = desktop.read_text()
    m = re.search(r"^Categories=(.*)$", text, re.M)
    if not m:
        desktop.write_text(text.rstrip("\n") + "\nCategories=System;PackageManager;\n")
        print("Bazaar .desktop: dodano Categories")
        return
    have = [c for c in m.group(1).split(";") if c]
    for need in ("System", "PackageManager"):
        if need not in have:
            have.append(need)
    desktop.write_text(text[:m.start()] + "Categories=" + ";".join(have) + ";" + text[m.end():])
    print("Bazaar .desktop: Categories =", ";".join(have))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--content", default="/usr/share/ublue-os/bazaar/content.yaml")
    ap.add_argument("--catalog", default="/usr/share/gamebox/catalog.toml")
    ap.add_argument("--desktop", default="/usr/share/applications/io.github.kolunmi.Bazaar.desktop")
    a = ap.parse_args()
    patch_content(Path(a.content), Path(a.catalog))
    patch_desktop(Path(a.desktop))
