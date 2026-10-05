# GameBox (Bazzite + LineXinBar + zintegrowane emulatory)

Bazzite zostaje w całości (KDE, Steam, Lutris, Bazaar, sterowniki). Dokładamy: LineXinBar (tryb konsoli na TV),
jeden katalog emulatorów spięty ze sklepem, ISO z wbudowanymi emulatorami i dobór do sprzętu.

## Jak dostać ISO
1. Wgraj zawartość folderu do pustego repo na GitHubie (gałąź `main`).
2. Settings → Actions → General → Workflow permissions: **Read and write**.
3. Actions → `build-image` (buduje obrazy `gamebox` i `gamebox-nvidia`). Poczekaj na koniec.
4. Pakiety `gamebox` i `gamebox-nvidia` w ghcr.io ustaw jako **publiczne** (Package settings → Visibility), inaczej
   zainstalowany system nie pobierze aktualizacji.
5. Actions → `build-iso` → Run workflow → ISO w artefaktach. Wypal na pendrive (Ventoy / balenaEtcher / Fedora Media Writer).

## Jak to jest połączone
Wszystko wychodzi z jednego pliku: `system_files/usr/share/gamebox/catalog.toml`.

| Kto czyta katalog | Co z tego ma użytkownik |
|---|---|
| ISO (`iso/prepare-installer.sh`) | Emulatory `tier = "bundled"` są **w płycie**, instalacja bez internetu (metoda Bazzite) |
| Bazaar (`build_files/patch-bazaar.py`) | Sekcja **Emulacja** w sklepie Bazzite, obok jego własnej listy |
| LineXinBar | RetroArch: biblioteka gier z okładkami. Każdy inny Flatpak z kategorią Game: wiersz w kolumnie Games. Bazaar i „Emulatory GameBox”: kolumna Software |
| `gamebox-emu` | `list`, `install`, `remove`, `doctor`, okno wyboru (`gui`) |
| Pierwszy start | Usuwa to, czego ten sprzęt nie uciągnie (np. PCSX2 bez AVX2) |

### Instalowanie i zarządzanie
- Sklep **Bazaar** → sekcja *Emulacja* (albo cały Flathub: **każda** aplikacja z kategorią Game pojawi się w LineXinBar sama).
- „**Emulatory GameBox**” (menu KDE i kolumna Software w LineXinBar): zaznacz co ma być, odznacz co usunąć.
- Terminal: `gamebox-emu list`, `gamebox-emu install pcsx2`, `gamebox-emu doctor --online`.

### Dodanie własnego emulatora lub aplikacji
Dopisz blok `[[app]]` do `catalog.toml` (id z Flathuba, nazwa, opis, `tier`, wymagania). Po następnym buildzie trafi do
Bazaara, ISO, `gamebox-emu` i doboru sprzętowego. Bez przebudowy: zainstaluj z Bazaara, LineXinBar i tak go zobaczy.

### Gry, ROM-y, BIOS-y
- Gry: `~/Emulation/roms/<konsola>` (foldery tworzą się same, nazwy zgodne z tym, co rozpoznaje LineXinBar: `psx`, `ps2`, `psp`, `nes`, `snes`, `gba`, `megadrive`, `dreamcast`...). Ścieżka jest ustawiana w LineXinBar automatycznie, nie nadpisujemy wyboru użytkownika.
- BIOS-ów **nie ma** w systemie (prawa autorskie). RetroArch: LineXinBar sam zapyta o BIOS, gdy gra się nie uruchomi, i go skopiuje. PCSX2 i DuckStation: wrzuć pliki do `~/Emulation/bios` (lub `gamebox-bios /ścieżka/do/folderu`).

### Stare laptopy
`gamebox-hwdetect` przy każdym starcie ocenia sprzęt (CPU, AVX2, RAM, GPU, HDMI bez ekranu laptopa) → `gamebox-info`.
Przy pierwszym starcie usuwane są emulatory, które tam nie mają sensu: PCSX2 bez AVX2 (to oficjalne minimum PCSX2), RPCS3 i Cemu
poniżej klasy HIGH lub bez AVX2, Dolphin i PCSX2 na klasie LOW. Na słabym sprzęcie zostają RetroArch, DuckStation, mGBA, PPSSPP, melonDS, Flycast, Snes9x, ScummVM.
Użytkownik może doinstalować dowolny z nich ręcznie (z ostrzeżeniem).

## Stan faktyczny. Przeczytaj przed ISO
**Czego NIE sprawdzono: całość nie została zbudowana end-to-end** (build obrazu i ISO wymaga GitHub Actions). Pierwszy build może wymagać poprawek.

Sprawdzone podczas pisania: repozytoria Petexy i ich skrypty pakowania istnieją; identyfikatory Flatpaków pochodzą z listy
Bazzite lub zostały sprawdzone na Flathubie; łatka Bazaar została przetestowana na prawdziwym pliku Bazzite (YAML poprawny);
`prepare-installer.sh` działa na prawdziwym instalatorze Bazzite; skrypty przeszły shellcheck, a logika (`gamebox-emu`, `firstboot`, `userinit`)
testy na atrapach z różnymi profilami sprzętu.

Znane ryzyka i braki:
- **Sekcja Emulacja w Bazaar** jest dopisana bez banera (u Bazzite każda sekcja ma baner). Czy Bazaar to akceptuje, wyjdzie przy pierwszym uruchomieniu.
- **ISO**: kopia metody Bazzite z dwiema łatkami (nazwa obrazu, brak wymuszania podpisu). Używa akcji Titanoboa z gałęzi `revamp-pr`, przypiętej do SHA. ISO będzie duże (kilkanaście GB); jeśli GitHub odrzuci artefakt, trzeba je zbudować lokalnie.
- **Rdzenie RetroArch** LineXinBar pobiera z internetu przy pierwszym użyciu (buildbot.libretro.com). Offline ich nie będzie, dopóki nie zostaną pobrane.
- **Tryb TV**: wykrywanie telewizora tylko podpowiada wybór sesji LineXinBar przy logowaniu. Automatycznego przełączenia nie ma.
- **Ekran logowania**: Bazzite 44 w KDE ma nowy Plasma Login Manager (nie SDDM). Sprawdź po instalacji, czy sesja LineXinBar jest na liście.
- **LineXinBar** jest we wczesnej fazie rozwoju (autor testował głównie jeden GPU AMD). Jego integracja zna RetroArch, Steam, Epic (Heroic) i RPCS3; inne emulatory to wiersze launchera bez własnej biblioteki gier.
- Ścieżki BIOS w Flatpakach PCSX2/DuckStation są oparte na typowym układzie i nie były sprawdzone na działającym systemie.
- Założenie, że Cemu wymaga AVX2, jest ostrożnym przybliżeniem (PCSX2 potwierdzone, RPCS3 działa bez AVX2, ale słabo).
- NVIDIA GeForce 400–700 (Fermi/Kepler): zostań na wariancie `gamebox`, nie `gamebox-nvidia`.
- Przy nowej wersji Fedory w Bazzite podbij `FEDORA_VERSION` w `Containerfile`, a po zmianach w instalatorze Bazzite `BAZZITE_REF` w `iso/prepare-installer.sh`.
