# GameBox = Bazzite (KDE zostaje) + LineXinBar (Petexy) + katalog emulatorów zintegrowany ze sklepem Bazaar
#           + antimicrox + autodetekcja sprzętu
# Obraz bazowy: ghcr.io/ublue-os/bazzite (AMD/Intel) albo ghcr.io/ublue-os/bazzite-nvidia
# FEDORA_VERSION musi być taka sama jak w obrazie bazowym (Bazzite 44 = Fedora 44),
# bo RPM-y LineXinBar są budowane osobno i linkują się z bibliotekami tej wersji.
ARG FEDORA_VERSION=44
ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite
ARG BASE_TAG=stable

# ---------- etap 1: budowa pakietów RPM z repozytoriów Petexy ----------
FROM registry.fedoraproject.org/fedora:${FEDORA_VERSION} AS petexy-builder
COPY build_files/petexy-build.sh /petexy-build.sh
RUN bash /petexy-build.sh

# ---------- etap 2: właściwy obraz ----------
FROM ${BASE_IMAGE}:${BASE_TAG}
COPY --from=petexy-builder /out/ /tmp/rpms/
COPY system_files/ /
COPY build_files/ /tmp/build_files/
RUN bash /tmp/build_files/build.sh && ostree container commit
