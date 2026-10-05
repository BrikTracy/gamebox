#!/usr/bin/env bash
set -euo pipefail

# 1) Paczki Petexy (LineXinBar + podpaczki lxb-retroarch / lxb-heroic / lxb-rpcs3, opcjonalnie reszta)
if ls /tmp/rpms/*.rpm >/dev/null 2>&1; then
  if command -v dnf5 >/dev/null 2>&1; then
    dnf5 -y install /tmp/rpms/*.rpm
  else
    rpm-ostree install /tmp/rpms/*.rpm
  fi
fi

# 2) CEDM ma NIE przejmować logowania (sam ostrzega, że nie jest gotowy). Domyślny login z Bazzite zostaje nietknięty.
systemctl disable cedm.service 2>/dev/null || true
DM=$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)
case "$DM" in
  *cedm*) echo "BŁĄD: CEDM przejął display-manager.service - przerywam, żeby nie zepsuć logowania"; exit 1 ;;
esac

# 3) Nasze skrypty i usługi
chmod +x /usr/bin/gamebox-* /usr/libexec/gamebox-*
systemctl enable gamebox-hwdetect.service gamebox-firstboot.service

# 4) Sklep Bazaar: sekcja "Emulacja" z katalogu + kategoria, żeby LineXinBar pokazał go w kolumnie Software
python3 /tmp/build_files/patch-bazaar.py

# 5) Kontrola końcowa: obraz, w którym brakuje sedna, ma się NIE zbudować, zamiast cicho działać gorzej.
fail=0
chk() { if ! eval "$2"; then echo "BŁĄD KONTROLI: $1"; fail=1; fi; }
chk "sesja LineXinBar (lxb.desktop) nie została zainstalowana" 'test -f /usr/share/wayland-sessions/lxb.desktop'
chk "brak lxb-retroarch: LineXinBar nie pokaże biblioteki gier"  'command -v lxb-retroarch >/dev/null'
chk "katalog GameBox pusty"                                        '[ "$(python3 /usr/bin/gamebox-emu bundled-ids | wc -l)" -gt 0 ]'
chk "sekcja Emulacja nie trafiła do Bazaar"                        'grep -q "GameBox: sekcja Emulacja" /usr/share/ublue-os/bazaar/content.yaml'
[ "$fail" = 0 ] || exit 1

# 6) Sprzątanie
rm -rf /tmp/rpms /tmp/build_files
