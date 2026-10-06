# Cafe POS

Offline-first point-of-sale application for a small cafe, built for one Android tablet with Flutter and local SQLite.

## Product summary

The application manages products, tables, open orders, cash or manually verified transfer payments, sales history, reports, and local backups. It works without a backend, cloud service, or internet connection.

## Documentation

Read the project sources in this order:

1. `AGENTS.md` — repository rules.
2. `docs/PRD.md` — product scope and business rules.
3. `docs/DECISIONS.md` — technical decisions and trade-offs.
4. `docs/ARCHITECTURE.md` — application layers and responsibilities.
5. `docs/UI_SPEC.md` — tablet UI behavior.
6. `database/001_initial_schema.sql` — initial SQLite schema.
7. `docs/ACCEPTANCE_CRITERIA.md` — verifiable product criteria.
8. `docs/DEVELOPMENT_WORKFLOW.md` — delivery workflow and completion gate.
9. `docs/IMPLEMENTATION_PLAN.md` — milestone order and scope.
10. `prompts/START_HERE.md` — optional Codex prompt shortcuts.

## Verified toolchain

| Tool | Version |
| --- | --- |
| Flutter | 3.47.5 stable |
| Dart | 3.13.4 |
| Java | Eclipse Temurin 17.0.20.1+1 |
| Android SDK | API 36, Build Tools 36.0.0, Platform Tools 37.0.1 |
| Android emulator | 37.1.11.0; Android 16/API 36 tablet image |

The Android application ID is `com.rvigil.cafe_pos` and the minimum supported Android version is API 24 (Android 7.0).

## Dependencies selected in Milestone 0

- `sqflite` for SQLite access and transactions.
- `uuid` for internal entity IDs.
- `timezone` for explicit `America/El_Salvador` calendar behavior.
- `intl` for date and money presentation.
- `path` and `path_provider` for safe app-owned file paths.
- `file_picker` for Android Storage Access Framework import and export.

No global state-management, networking, authentication, analytics, backend, or cloud package is used.

## Development scripts

Use the single project command from the repository root:

```bash
./cafe pair       # Pair and connect the phone over Wi-Fi
./cafe run        # Build and launch Cafe POS
./cafe check      # Format, analysis, and fast tests without a phone
./cafe test       # Run the complete validation suite
./cafe seed       # Add missing dummy tables, categories, and products
./cafe offline    # Build and launch after enabling airplane mode
./cafe devices    # Show detected Android and Flutter devices
```

`./cafe seed` runs only on the selected Android device. It preserves existing
application data and creates missing development records without deleting or
overwriting matching names. Repeating it is safe: once all seed records exist,
it creates nothing. The command restores the normal debug APK afterward; run
`./cafe run` to open the seeded application.

For Wi-Fi setup, enable `Developer options > Wireless debugging` on an Android 11 or newer phone and run `./cafe pair`. The command asks for the pairing address and six-digit code shown by Android, then discovers or requests the connection address and verifies Flutter connectivity. Pairing normally needs to be completed only once.

USB also works: enable USB debugging, connect the phone, and accept its authorization prompt. Device selection is automatic when exactly one phone or tablet is available. If several devices are connected, select one with `CAFE_POS_DEVICE=<adb-serial>`.

Use `./cafe offline` only with USB. Enabling airplane mode would terminate a Wi-Fi debugging connection.

The integration-test APK is built before it is installed, then exercised with `flutter drive` as a prebuilt binary. This avoids running the Android emulator and Gradle together on the development machine. `check.sh` does not require an Android device.

The lower-level commands wrapped by these scripts are:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test
flutter build apk --debug
flutter run
```

Follow `docs/DEVELOPMENT_WORKFLOW.md` and the active milestone evidence record when running and recording these commands.

The Android Gradle process is limited to a 1 GB heap and one worker so local builds remain reliable on the development machine. For a prebuilt APK, `flutter run` can avoid a second Gradle build:

```bash
flutter run --no-build --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk
```
