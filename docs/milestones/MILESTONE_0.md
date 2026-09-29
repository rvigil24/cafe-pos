# Milestone 0 — Evidence Record

## Status

- State: `COMPLETE`
- Owner: Ruben Vigil
- Branch: `milestone/0-flutter-bootstrap`
- Started: 2026-09-26
- Completed: 2026-09-29
- Approval: Plan approved on 2026-09-26; result tested and accepted by the owner on 2026-09-29

## Objective and output

Create a clean Flutter Android project in this repository without implementing POS features. The milestone output is a Material 3 landscape app that builds, passes its tests, and opens on an Android tablet emulator.

## Scope

### Included

- [x] Verify and record the Flutter, Dart, Android SDK, JDK, and emulator toolchain.
- [x] Create the Android-only Flutter project in the repository root.
- [x] Configure strict analysis, Material 3, and landscape orientation.
- [x] Select and compile the approved SQLite, UUID, timezone, formatting, path, and SAF packages.
- [x] Create the target source and test structure.
- [x] Add the minimal bootstrap screen and unit/widget smoke tests.
- [x] Build and launch the debug APK on an Android tablet emulator.

### Excluded

- Catalog, tables, orders, payments, history, reports, and backup behavior.
- Database schema application and production repositories.
- Authentication, networking, cloud services, and non-Android platforms.

## Acceptance and test mapping

| Requirement or criterion | Implementation | Automated test | Manual check |
| --- | --- | --- | --- |
| Clean Android Flutter bootstrap | Android-only Flutter scaffold | Widget smoke test | App launches on emulator |
| Material 3 | Root application theme | Widget theme assertion | Visual bootstrap screen |
| Tablet landscape | Two landscape orientations configured | Configuration review | Rotate emulator |
| Package compatibility | Approved dependencies resolve and compile | Package and Android integration smoke tests | Debug APK installation |
| Architecture skeleton | Required top-level source directories | Repository review | Not applicable |
| Airplane-mode bootstrap | No network dependency in runtime app | Not applicable | Relaunch with airplane mode |

## Plan

1. Provision and validate the user-space Flutter and Android toolchain.
2. Create the Android-only Flutter scaffold with application ID `com.rvigil.cafe_pos`.
3. Configure dependencies, strict analysis, Material 3, and orientation.
4. Create the architecture skeleton and minimal bootstrap screen.
5. Add widget, package, and Android integration smoke tests.
6. Run all workflow checks, launch on an emulator, review the diff, and record evidence.

## Decisions and risks

| Decision or risk | Resolution or mitigation |
| --- | --- |
| Android support floor | Use API 24, matching Flutter 3.47 supported platforms. Confirm the physical tablet is Android 7.0 or newer before release validation. |
| Android application ID | Use the owner-approved `com.rvigil.cafe_pos`. |
| SQLite | Use `sqflite`; keep WAL disabled initially and verify transaction rollback on Android. |
| Backup file access | Compile `file_picker` with Android SAF support; defer backup behavior to Milestone 5. |
| Consistent backup | Plan for an application lock, closed SQLite connection, temporary app-owned copy, validation, and SAF export. |
| Missing local toolchain | Installed and verified in user space after the owner accepted the Android SDK licenses. |
| Host memory pressure | Limit Gradle to a 1 GB heap and one worker; run the 1.5 GB emulator as a memory-capped user service and do not compile while it is running. |
| Repetitive validation commands | Provide repository scripts for fast checks plus full validation and app launch on a connected Android phone or tablet. The full script prebuilds its APK before using the device. |
| Wireless device setup | Provide one `./cafe pair` command that wraps ADB Wi-Fi pairing, connection discovery, and Flutter device verification. |

## Database and migration impact

- Migration: Not applicable; applying `001_initial_schema.sql` belongs to Milestone 1.
- Previous-version fixture: Not applicable.
- Rollback verification: SQLite package transaction rollback smoke test only.
- Data-preservation verification: Not applicable.

## Automated verification

| Command | Result | Notes |
| --- | --- | --- |
| `flutter doctor -v` | Pass with expected warning | Flutter 3.47.5, Dart 3.13.4, JDK 17.0.20.1+1, Android SDK 36, Build Tools 36.0.0, emulator 37.1.11.0, and accepted licenses verified. The final run reported no connected device because the emulator had been intentionally stopped after validation. |
| `flutter pub get` | Pass | All direct dependencies are current as of 2026-09-26. |
| `dart format --output=none --set-exit-if-changed .` | Pass | Seven Dart files checked. |
| `flutter analyze` | Pass | No issues found. |
| `flutter test` | Pass | Three tests passed. |
| `flutter test integration_test -d emulator-5554` | Pass | Android 16/API 36 test opened SQLite and verified transaction rollback. |
| `flutter build apk --debug` | Pass | Built `build/app/outputs/flutter-apk/app-debug.apk`. |
| `flutter run -d emulator-5554 --no-build --no-resident --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk` | Pass | Installed and launched the prebuilt APK without starting Gradle. |
| `bash -n cafe scripts/*.sh` | Pass | The unified command and all workflow scripts passed Bash syntax validation. |
| `./cafe check` | Pass | Dependencies, formatting, analysis, and three unit/widget tests passed through the unified command. |
| `./cafe pair` and `./cafe test` | Pass | The owner confirmed that Wi-Fi pairing and the complete validation workflow work on an Android phone. |

## Manual demonstration

- Environment/device: Android 16/API 36 `medium_tablet` AVD, 2560x1600, constrained to 1.5 GB RAM and 2 CPU cores.
- Owner verification device: Android phone connected through wireless debugging; exact model and OS version were not recorded.
- Initial setup: Fresh Android emulator; debug APK installed; airplane mode enabled for the offline relaunch.

| Step | Action | Expected result | Actual result |
| --- | --- | --- | --- |
| 1 | Launch the debug app on a tablet emulator. | Bootstrap screen opens without error. | Pass — `Cafe POS` and `Milestone 0 ready` rendered; no Flutter or Android runtime error was logged. |
| 2 | Rotate between both landscape directions. | App remains landscape and usable. | Pass — activity remained resumed in `land` at `ROTATION_0` and `ROTATION_180`. |
| 3 | Enable airplane mode and relaunch. | Bootstrap screen opens without network access. | Pass — `airplane_mode_on=1`; the same bootstrap screen rendered. |
| 4 | Pair an Android phone over Wi-Fi and run the unified validation command. | Pairing, build, tests, installation, and launch complete successfully. | Pass — confirmed by the owner on 2026-09-29. |

## Review

- [x] Diff matches approved scope.
- [x] Architecture boundaries are preserved.
- [x] Transactions and persistence invariants are correct where exercised.
- [x] Error, loading, empty, and in-progress states are covered where applicable.
- [x] Accessibility affected by the change was reviewed.
- [x] Dependencies and documentation are current.
- [x] No secrets, real data, generated noise, or unrelated changes are present.

### Findings

- The initial environment had no `flutter`, `dart`, `java`, or `adb` commands in `PATH`.
- Flutter 3.47.5, Dart 3.13.4, and Eclipse Temurin JDK 17.0.20.1+1 were installed in user space and verified.
- The default Flutter template allowed an 8 GB Gradle heap, and the API 36 emulator initially reserved 4 GB. Running both exhausted the 7.1 GB host and caused `systemd-oomd` to terminate VS Code.
- Gradle is now limited to a 1 GB heap, 384 MB metaspace, one worker, and in-process Kotlin compilation. The emulator was verified with 1.5 GB guest RAM and a 2.2 GB service-level hard limit.
- Build and emulator validation passed when executed sequentially. No Cafe POS, Flutter, or Android runtime crash was found.
- The workflow scripts now use a connected Android phone or tablet instead of starting an emulator. Device detection, missing-device errors, and the physical-phone workflow were verified.
- The `./cafe` entrypoint centralizes Wi-Fi pairing, device listing, fast checks, app launch, offline launch, and full validation. Pairing input validation and no-device behavior were verified locally, and the owner confirmed the connected-device flow.

## Commits

- `8f67ced feat: bootstrap Flutter Android application`
- `d09a4a9 docs: record milestone 0 evidence`

## Remaining limitations or blockers

- Physical tablet validation belongs to the final hardening milestone.
- On this 7.1 GB development host, Android compilation and the emulator must run sequentially to avoid global memory pressure.

## Completion decision

- [x] All applicable completion gates in `docs/DEVELOPMENT_WORKFLOW.md` pass.
- [x] Owner accepted the milestone.
- Final state: `COMPLETE`
