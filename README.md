# gw7_midi — GW-7 Presets (Android)

Flutter port of the GW-7 preset manager for Android tablets/phones. Selects any
of the GW-7's 657 factory tones (606 tones + 51 drum kits, 23 category banks)
over USB MIDI.

Send path per tone: `B0 <ch> 00 <cc00>` (bank MSB) · `B0 <ch> 20 <cc32>`
(bank LSB) · `C0 <ch> <pc-1>` (program change).

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

## Layout

```
lib/
  main.dart                 app entry + Oscillator-Dark theme
  preset_screen.dart        UI: topbar, LCD, bank tabs, tone grid
  models/tone_catalog.dart  catalog JSON loader
  services/midi_service.dart MidiService — scan/connect/send via flutter_midi_command
test/widget_test.dart       wire-format + catalog integrity tests
assets/gw7_midi_catalog.json bundled catalog
```
