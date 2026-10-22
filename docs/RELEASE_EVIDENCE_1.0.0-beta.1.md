# Trial release evidence — 1.0.0-beta.1

Date: 2026-10-21, America/El_Salvador.
Branch: `fix/android-release`.
State: verified and published as a GitHub prerelease on 2026-10-21 at 21:51
America/El_Salvador (`2026-10-22T03:51:04Z`).
Owner approved `docs/RELEASE_PLAN.md` with "lo apruebo" and separately authorized
backing up, replacing the debug installation, and restoring the physical device.

## Scope and review

- Dedicated release signing, version `1.0.0-beta.1+2`, universal production APK,
  GitHub prerelease, checksums, and Spanish installation instructions.
- No dependency, schema, migration, domain, repository, or widget behavior changes.
- Package ID remains `com.rvigil.cafe_pos`; minimum Android API remains 24.
- No pull request; no milestone status changes or integration into `main`.
- Signing material and device snapshots remain outside tracked source.
- `android/key.properties`, `*.jks`, and `*.keystore` are ignored.
- Signing key: private RSA 4096/JKS, 10,000 days. A restricted recovery archive
  is stored separately under the owner's Documents directory. An external copy
  remains the owner's operational responsibility; both current copies are local.

Public signing certificate SHA-256:
`33ac5c38e49bef605ed6e69a143211975c542aebd5cd6a8ab3c7d9f8d2f9c6fe`.

## Automated verification

| Check | Result |
| --- | --- |
| `./scripts/check.sh` (`flutter pub get`, formatting, analysis, `flutter test`) | Pass: 105 source files formatted, no analysis issues, all 72 tests passed. |
| Missing signing credentials | Pass: actual `flutter build apk --release` fails at `:app:checkReleaseSigning` with an actionable error. |
| Debug build without release credentials | Pass: production debug APK and plugin smoke APK build without `android/key.properties`. |
| Android integration suite | Pass: all 14 tests across the five existing test files on the physical device. |
| `flutter build apk --release` | Pass with 512 MB metaspace; final APK is 53,761,819 bytes. |
| `apksigner verify --verbose --print-certs` | Pass; matches the release certificate above. |
| `aapt dump badging` | Pass: package `com.rvigil.cafe_pos`, version `1.0.0-beta.1`, code 2, API 24 minimum, ARM32/ARM64/x86_64, no debuggable flag. |
| `git diff --check` | Pass during preparation; repeat before commit. |

Integration tests use the existing `flutter build apk --debug --target=...` then
`flutter drive --driver=test_driver/integration_test.dart --target=...
--use-application-binary=build/app/outputs/flutter-apk/app-debug.apk -d <device>`
workflow, one test file at a time. A temporary grouped runner was discarded
because the first group's integration teardown can finish the driver early;
its result is not used as evidence for the complete suite.

The standalone files passed: `plugin_smoke_test.dart` (1),
`database_catalog_test.dart` (3), `order_repository_test.dart` (4),
`history_reports_test.dart` (1), and `backup_restore_test.dart` (5).
Flutter's displayed counters also include setup/teardown entries.

Review finding resolved: AGP omits `validateSigningRelease` when no signing
properties exist. The custom check therefore depends from `preReleaseBuild`,
which exists even without a configured keystore. The actual negative release
build confirms unsigned output is blocked; debug builds remain independent.

First optimized build failed at `android_file_picker:lintVitalAnalyzeRelease`
with `Metaspace`. Increased Gradle's metaspace cap from 384 MB to 512 MB and
restarted the daemon, retaining the 1 GB heap and one-worker limit. No lint
checks were disabled.
Removed the generated JVM heap dump and ignored `*.hprof`; process memory
artifacts must not be committed or attached to a release.

## Physical Android verification

Device: Infinix X6873, Android 16/API 36, arm64, connected through wireless ADB.
Flutter device ID: `adb-143332555G110895-88cwLo._adb-tls-connect._tcp`.
No emulator, AVD, or QEMU was started. The production entry point is `lib/main.dart`.

Before any replacement, force-stopped the debug app, captured its private data
and previous APK outside the repository, and verified the SQLite snapshot with
`integrity_check`, `foreign_key_check`, and `user_version = 2`. A database copy
was also placed in Android Downloads for restoration through the release app.
No snapshot or device data is attached to the release.

| Action | Expected | Actual |
| --- | --- | --- |
| Install dedicated-key release after approved debug replacement | App installs and launches. | Pass: fresh production startup showed zero tables and no bundled catalog. The standalone test runner had already removed its test installation, so the explicit uninstall found no package; release installation succeeded. |
| Restore original database through Android picker | Original data preserved. | Pass: exported again from the final APK; every row in all seven business tables matches the original snapshot. Integrity, foreign keys, and schema version 2 verified. |
| Exercise catalog/order/payment/history/report flow | Normal production operation. | Pass: restored sanitized example, selected Espresso, created takeaway order 2 for 150 cents, received 200 cents cash, displayed 50 cents change, paid, and verified history plus today's report (150 cents, 1 order, 1 unit). |
| Force-stop/reopen | Persisted records survive. | Pass: restored table and data remained visible after process restart. |
| Export/restore using Android document storage | Valid database exported and restored. | Pass: selected `.db` through internal-storage Documents provider; exported test database validated integrity, foreign keys, two paid orders totaling 300 cents. |
| Same-key in-place update from build 1 to build 2 | Data preserved, final exact APK installed. | Pass: `adb install -r` of the exact final APK; subsequent SAF export preserved every row in all seven data tables. Installed metadata confirms version code 2. |

Cleanup retained the original backups, removed only this task's synthetic
Downloads fixtures/exports, and left the final signed production APK running
with the owner's original database. App-specific launch logs contain no fatal
errors or unhandled exceptions. One overlapping UI dump attempt caused an
Android `uiautomator` service error; repeating the UI steps sequentially passed.
It was not an application crash.

After the Gradle memory adjustment, reran `./scripts/check.sh` (72 tests,
formatting, and analysis passed) and `flutter build apk --debug` (passed).

## Publication

- Source: `00e7c3ee6e076b50f357708e81bfd9be84d19991`, resolved by annotated tag
  `v1.0.0-beta.1`; confirmed against the pushed remote tag and release target.
- URL: https://github.com/rvigil24/cafe-pos/releases/tag/v1.0.0-beta.1
- Assets: `cafe-pos-1.0.0-beta.1.apk`, `SHA256SUMS`, `INSTRUCCIONES.md`.
- APK SHA-256: `c5c26187b753b4ddbee1bad116a20ede8a36819f573035e8053915d0d0bca5c1`.
- Download verification: all three draft assets downloaded using
  `gh release download v1.0.0-beta.1 --dir build/release-artifacts/download-verification`
  and compared byte-for-byte to the local artifacts. SHA-256 also matches the
  GitHub API's asset digest. After publication, the final APK URL responds to
  an unauthenticated HTTP HEAD request with status 200 and 53,761,819 bytes.
- Publication: `gh release create` with `--verify-tag --draft --prerelease`,
  reviewed release notes and only the three intended assets, followed by
  `gh release edit v1.0.0-beta.1 --target 00e7c3ee6e076b50f357708e81bfd9be84d19991
  --verify-tag --draft=false --prerelease`. API confirms `isDraft = false` and
  `isPrerelease = true`.
- Delivery source commit: `00e7c3e` (`build(android): prepare signed beta release`).
  This subsequent publication record changes documentation only; the tag and
  published APK remain pinned to the verified delivery source.
- Branch `fix/android-release` is pushed to its matching upstream. `main` is
  unchanged pending owner acceptance of the delivered result.

## Operational limitations

- Physical verification uses the owner's connected phone; an additional cafe
  tablet compatibility check is recommended before actual business operation.
- Public download; local-only data, manual updates, manual external backups,
  and no authentication, as documented in the MVP.
- Development-to-release signature transition is one-time and requires verified
  backups. Future releases must use the same key and increasing version codes.
