# SimpleTimer - Projektkonventionen

## Sprache & Schreibweise
- Kein deutsches Doppel-s (ß) verwenden — immer "ss" schreiben (z.B. "heisst" statt "heißt", "gross" statt "groß")

## Entwicklungsumgebung
- Xcode **15.4** (Build 15F31d)
- iOS Deployment Target: 17.0
- Bundle ID, Apple ID, Team IDs: siehe `.env`

## Workflow
- Nach jeder Aenderung: **committen, pushen, dann auf iPhone deployen**
- Build & Deploy: `./scripts/build-and-deploy.sh` (aktualisiert Build-Nummer, baut, installiert auf Geraet)
- Deploy-Target:
  - iPhone von Tom: `00008130-0004446200698D3A`

## Build-Nummern
- **Lokal**: `{TF+1}.{counter}` (z.B. `1.1`, `1.2`) — in der App als "Local" markiert
- **Xcode Cloud**: Nutzt eigenen Auto-Increment-Counter
- `.testflight-build-number` — letzte bekannte TF/Xcode-Cloud Build-Nummer (git-tracked, manuell aktualisieren nach TF-Upload)
- `.local-build-count` — lokaler Zaehler (git-ignored)
- **Wichtig**: Vor dem Setzen von `.testflight-build-number` immer pruefen: `fastlane run latest_testflight_build_number`

## Fastlane

### Abfragen
- **Aktuelle App Store Build-Nummer**: `fastlane run app_store_build_number live:true`
- **Aktuellen TestFlight Build**: `fastlane run latest_testflight_build_number`
- **Xcode Cloud Builds abfragen**: `ruby scripts/query-builds.rb [limit]` (CI Product ID aus `.env`)

### Release-Vorgang (App Store)
1. **Build in Xcode Cloud starten** (oder `fastlane beta` fuer lokalen Upload)
2. **Warten bis Build in TestFlight "Ready to Submit" ist**
3. **Version in App Store Connect erstellen + Metadata/Release Notes hochladen**:
   ```
   fastlane deliver --app_version "X.Y.Z" --skip_screenshots --skip_binary_upload --force
   ```
   Release Notes vorher in `fastlane/metadata/de-DE/release_notes.txt` schreiben.
4. **Build anhaengen und zur Review einreichen**:
   ```
   fastlane deliver --app_version "X.Y.Z" --build_number "N" --skip_screenshots --skip_binary_upload --skip_metadata --submit_for_review --automatic_release --force
   ```
5. **Nach dem Einreichen — Version bumpen**:
   - MARKETING_VERSION in `SimpleTimer.xcodeproj/project.pbxproj` erhoehen
   - `.testflight-build-number` auf die eingereichte Build-Nummer setzen
   - `.local-build-count` loeschen (reset)
   - Committen und pushen

## App Store Screenshots
- **Skript**: `./scripts/take-screenshots.sh` (komplett automatisiert)
- **Simulatoren**:
  - iPhone 14 Plus → **1284x2778** (App Store 6.7" Slot, NICHT iPhone 15 Pro Max!)
  - iPad Pro 13" (M4) → **2064x2752** (App Store 12.9" Slot)
- **Ablauf**: Seed → Notification-Dialog akzeptieren → Dark + Light Screenshots via UI-Tests
- **Output**: `appstore/screenshots/iphone/` und `appstore/screenshots/ipad/`
- **Benennung**: `01_timers` (light), `02_settings` (dark), `03_log` (dark), `04_timers_dark`
- **UI-Tests**: `SimpleTimerUITests/ScreenshotUITests.swift`
- **Wichtig**: App Store akzeptiert 1290x2796 (iPhone 15 Pro Max) NICHT fuer den 6.7" Slot

## Projektstruktur
- 3 Timer-Sektionen (konfigurierbar, mit benutzerdefinierten Namen)
- Timer-Modus (Countdown) und Stoppuhr-Modus (wenn auf 0:00 gesetzt)
- Live Activities + Notifications wenn Timer ablaeuft
- Widget-Extension: `SimpleTimerWidgets/`
- Sound-Dateien: `SimpleTimer/Sounds/*.caf`
- Lokalisierung: EN + DE via `Localizable.xcstrings`
