# GW-7 Studio (gw7_flutter)

Control surface for the **Roland GW-7** arranger keyboard — runs on Android
(USB MIDI) and as a web app (Web MIDI over a Bluetooth bridge). Selects any of
the GW-7's 657 factory tones (606 tones + 51 drum kits, 23 category banks),
controls quick effects (CC), the master volume, favourite presets and the
backing-track transport.

## Features

- **Stage tab** — favourite presets (starred on Presets) + master volume rail.
- **Presets tab** — 23 category banks, 657 tones, LCD showing bank/no and
  channel · tone name, ★ to pin favourites.
- **Effects tab** — quick CC controllers: ATTACK CC73, RELEASE CC72, REVERB
  CC91, CHORUS CC93, EXPR CC11, PAN CC10 (0–127, sent live).
- **Utils tab** — backing-track styles by category + transport (START / STOP /
  CONTINUE / INTRO / FILL / ENDING).
- **State persistence** — the app saves its state locally and re-syncs it to
  the keyboard automatically on connect; the **SYNC** button re-sends everything.

Send path per tone: `B0 <ch> 00 <cc00>` (bank MSB) · `B0 <ch> 20 <cc32>`
(bank LSB) · `C0 <ch> <pc-1>` (program change). Channel is 4 by default.

> 📖 **User guides (with screenshots):**
> - 🇬🇧 English — [`docs/USER_GUIDE.md`](docs/USER_GUIDE.md)
> - 🇪🇸 Español — [`docs/GUIA_DE_USO.md`](docs/GUIA_DE_USO.md)

> **Disclaimer:** This is an independent, unofficial project. It is not
> affiliated with, endorsed by, or sponsored by Roland Corporation. "GW-7" is a
> trademark of Roland, used nominatively to identify the device this tool
> interoperates with. The tone-selection data is derived from public MIDI
> specification documents. No Roland firmware, software, or copyrighted
> material is included in this repository. Reverse-engineering for
> interoperability purposes only. Use at your own risk.

## Running the app

### Android (USB MIDI)

1. Plug the GW-7 into the tablet/phone with a USB-OTG cable.
2. Open the app and tap **Connect** (picks the first serial MIDI device).
3. Pick a bank tab, tap a tone → CC0/CC32/PC sent on the selected channel.

### Web (Bluetooth bridge)

1. Power on the **"Roland GW7"** BLE-MIDI bridge (ESP32, see
   `bridge_firmware.cpp`) connected to the keyboard's MIDI IN.
2. Open `https://benlop27.github.io/gw7-suite/` in Chrome/Edge and grant MIDI
   access. The app auto-connects to the bridge; the status pill turns green
   with **"Connected · Roland GW7 Bluetooth"**.
3. On macOS, the bridge must first be made visible as a MIDI port
   (Audio MIDI Setup → Bluetooth). On Android tablets, pair the bridge in
   Bluetooth settings — Chrome on Android supports Web MIDI.

## Build & test

```bash
flutter analyze
flutter test
flutter build apk --debug
```

APK output: `build/app/outputs/flutter-apk/app-debug.apk`.

Requires the Android SDK + JDK 21. See the repo-root `README.md` for the full
toolchain (env vars) and the catalog regeneration pipeline
(`make_gw7_catalog.py` → `assets/gw7_midi_catalog.json`).

## Release signing

`android/app/build.gradle.kts` reads `android/key.properties` if present
(keystore path, store password, key alias, key password). Without it, release
builds fall back to the debug signing key — fine for sideloading, not for store
distribution. Never commit `key.properties` or `.jks` files (gitignored).

## CI — GitHub Actions

`.github/workflows/build-apk.yml` runs `analyze` + `test` + `build apk --release`
on push to `main` and manual dispatch. Behavior:

- **Every run** uploads `app-release.apk` as the `gw7-midi-apk` artifact.
- **Tag push `v*`** also publishes the APK as a GitHub Release with auto-generated notes.
- If the repo secrets below exist, the release APK is signed with the real
  keystore; otherwise it's signed with the debug key.

Set these secrets in the repo to get a properly signed release APK:
`KEYSTORE_BASE64` (keystore base64-encoded), `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.

`.github/workflows/deploy-web-manager.yml` builds the Flutter **web** app and
deploys it to GitHub Pages on push to `main` (when `lib/**`, `web/**`,
`assets/**` change) or manual dispatch:

```
https://benlop27.github.io/gw7-suite/
```

## E2E tests (Cypress)

Smoke tests run against the deployed site (see `cypress.config.js`):

```bash
npm install
npx cypress run
```

## Layout

```
lib/
  main.dart                  app entry + Oscillator-Dark theme + top bar/status
  stage_screen.dart          Stage tab: favourites + master volume
  preset_screen.dart         Presets tab: LCD, bank tabs, tone grid
  effects_screen.dart        Effects tab: quick CC sliders
  utils_screen.dart          Utils tab: backing track + transport
  models/tone_catalog.dart   catalog JSON loader
  models/app_state.dart      persisted app state (preset, effects, volume, favs)
  models/gw7_styles.dart     backing-track style list
  services/midi_service.dart MidiService — scan/connect/send (USB + Web MIDI)
  services/app_controller.dart AppController — state, persistence, sync-to-keyboard
  services/web_debug.dart    web-only debug hook (window.gw7Debug)
test/                         wire-format + catalog integrity tests
assets/gw7_midi_catalog.json  bundled catalog
bridge_firmware.cpp           ESP32 BLE-MIDI → Serial2 bridge firmware
docs/GUIA_DE_USO.md           user guide, Spanish (screenshots)
docs/USER_GUIDE.md            user guide, English (screenshots)
docs/screenshots/             screenshots used by the guide
cypress/                      E2E smoke tests
```
