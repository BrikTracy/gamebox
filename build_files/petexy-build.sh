#!/usr/bin/env bash
# Buduje RPM-y z repozytoriów Petexy. Dla LineXinBar dokumentacja (docs/packaging.md) podaje:
#   dnf builddep packaging/fedora/lxb-desktop.spec ; ./packaging/build.sh fedora  -> packaging/out/fedora/
# REQUIRED = build obrazu ma paść, jeśli to się nie zbuduje. OPTIONAL = ostrzeżenie i jedziemy dalej.
set -uo pipefail
dnf install -y git-core rpm-build rpmdevtools gcc gcc-c++ make clang pkgconf-pkg-config dnf5-plugins rust cargo
mkdir -p /out /src

REQUIRED=(LineXinBar)
OPTIONAL=(CEDM lxb-toolkit DistriBumpy ImagOnSole VideOnSole SongOnSole)

build_repo() {
  local repo="$1" required="$2"
  echo "=== $repo ==="
  git clone --depth 1 "https://github.com/Petexy/$repo" "/src/$repo" || { [ "$required" = 1 ] && exit 1; return 0; }
  ( set -e
    cd "/src/$repo"
    SPEC=packaging/fedora/lxb-desktop.spec
    [ -f "$SPEC" ] || SPEC=$(find packaging -name '*.spec' | head -n1)
    [ -n "${SPEC:-}" ] && dnf builddep -y "$SPEC"
    ./packaging/build.sh fedora --no-check
    OUTDIR=packaging/out/fedora
    [ -d "$OUTDIR" ] || OUTDIR=packaging/out
    find "$OUTDIR" -name '*.rpm' -not -name '*.src.rpm' -exec cp -v {} /out/ \;
    ls /out/*.rpm >/dev/null
  ) && return 0
  if [ "$required" = 1 ]; then echo "BŁĄD: $repo jest wymagane"; exit 1; fi
  echo "OSTRZEŻENIE: pominięto $repo (opcjonalne)"
}

for r in "${REQUIRED[@]}"; do build_repo "$r" 1; done
for r in "${OPTIONAL[@]}"; do build_repo "$r" 0; done
ls -la /out
