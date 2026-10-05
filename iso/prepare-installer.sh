#!/usr/bin/env bash
# Przygotowuje katalog installer/ (metoda Titanoboa, tak jak buduje ISO sam Bazzite), dopasowany do GameBox.
# Dlaczego tak: tylko ta metoda wbudowuje Flatpaki w ISO i instaluje je offline (kickstart rsync-uje
# /var/lib/flatpak z płyty na dysk). bootc-image-builder tego nie umie.
#
# Użycie: iso/prepare-installer.sh [katalog_docelowy]
set -euo pipefail

# Wersja Bazzite, na której to sprawdzono (przypięta, żeby zmiana u nich nie zepsuła nam builda).
BAZZITE_REF="${BAZZITE_REF:-85dc43349836fca29b21c62d79acd42dfbe8f337}"
OUT="${1:-installer}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

git -C "$tmp" init -q bz
git -C "$tmp/bz" fetch -q --depth 1 https://github.com/ublue-os/bazzite "$BAZZITE_REF"
git -C "$tmp/bz" checkout -q FETCH_HEAD
rm -rf "$OUT"
cp -a "$tmp/bz/installer" "$OUT"

HOOK="$OUT/titanoboa_hook_postrootfs.sh"

# 1) Hooki szukają obrazu do zainstalowania po nazwie 'bazzite*' (jest w dwóch plikach). U nas: gamebox / gamebox-nvidia.
for f in "$OUT"/titanoboa_hook_*.sh; do
  grep -q "'bazzite\*'" "$f" || continue
  sed -i "s/'bazzite\*'/'*gamebox*'/" "$f"
  echo "łatka nazwy obrazu: $(basename "$f")"
done
grep -q "'\*gamebox\*'" "$HOOK" || { echo "BŁĄD: hook Bazzite wygląda inaczej niż zakładamy (wzorzec nazwy obrazu)"; exit 1; }
if grep -rq "'bazzite\*'" "$OUT"/*.sh; then echo "BŁĄD: został wzorzec 'bazzite*' - Bazzite zmienił instalator, trzeba to przejrzeć"; exit 1; fi

# 2) Hook wymusza obrazy podpisane kluczem Bazzite przy 'bootc switch'. GameBox nie jest nim podpisany.
grep -q -- '--enforce-container-sigpolicy' "$HOOK" || { echo "BŁĄD: hook Bazzite wygląda inaczej niż zakładamy (sigpolicy)"; exit 1; }
sed -i 's/ --enforce-container-sigpolicy//' "$HOOK"

# 3) Flatpaki do ISO = domyślne Bazzite (nic nie usuwamy) + emulatory z naszego katalogu.
#    Bazzite instaluje je jednym poleceniem: xargs flatpak install < lista. Nasze pozycje podajemy jako same
#    identyfikatory, a pierwszym słowem listy jest 'flathub' (zdalne repo), dzięki czemu Flatpak sam dobiera
#    właściwą gałąź. Zgadywanie gałęzi (np. /stable) przy złym trafieniu wywaliłoby cały build ISO.
LIST="$OUT/kde_flatpaks/flatpaks"
[ -s "$LIST" ] || { echo "BŁĄD: brak listy Flatpaków Bazzite w $LIST"; exit 1; }
{ echo flathub; cat "$LIST"; python3 "$ROOT/system_files/usr/bin/gamebox-emu" bundled-ids; } \
  | awk 'NF && !seen[$0]++' > "$LIST.new"
mv "$LIST.new" "$LIST"
echo "Pozycji na liście Flatpaków ISO: $(( $(wc -l < "$LIST") - 1 )) (Bazzite + GameBox)"
echo "Instalator gotowy w: $OUT (Bazzite @ ${BAZZITE_REF:0:8})"
