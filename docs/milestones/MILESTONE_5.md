# Milestone 5 — Evidence Record

## Status

- State: `IN_PROGRESS`
- Owner: Ruben Vigil
- Branch: `milestone/5-backup-restore-hardening`
- Remote branch: `origin/milestone/5-backup-restore-hardening`
- Started: 2026-10-20
- Completed:
- Approval: Plan approved by the owner on 2026-10-20; connectivity-toggle verification removed from scope by explicit owner direction on the same date.

## Objective and output

Deliver backup, restore, and final MVP hardening. The working demonstration
exports a consistent database through Android storage, rejects an invalid
candidate without changing live data, restores a valid backup after creating a
preventive backup, and verifies that history and reports still match.

## Scope

### Included

- [x] Consistent SQLite export through Android Storage Access Framework.
- [x] Version, schema, integrity, and foreign-key validation before restore.
- [x] Preventive backup, safe replacement, supported migration, and rollback.
- [x] Business-name setting required by the PRD.
- [x] Restart, APK-update, migration, accessibility, and error-state hardening.
- [x] Sanitized example backup, tablet checklist, release notes, upgrade procedure, and candidate APK evidence.

### Excluded

- Cloud or scheduled backup, synchronization, encryption, Play Store release,
  production signing, and any post-MVP feature.

## Acceptance and test mapping

| Requirement or criterion | Implementation | Automated test | Manual check |
| --- | --- | --- | --- |
| Export a consistent backup through Android storage | `SqliteBackupRepository`, `FilePickerBackupStorage` | Android export/restore integration test | Exported with DocumentsUI to Downloads |
| Include catalog, tables, orders, payments, and settings | Closed snapshot plus full database copy | Android integration verifies all seven table groups | Valid exported file selected through DocumentsUI |
| Reject incompatible or corrupt input without replacing live data | `BackupValidator` validates header, version, schema, indexes, settings, integrity, and foreign keys | Corrupt, future-version, and incomplete-schema cases pass on Android | Automated on the physical target; invalid SAF selection remains in checklist |
| Check compatibility using `PRAGMA user_version` | `BackupValidator` supports versions 1 through 2 | Future version rejected; version 1 migrated to 2 | Covered on physical target |
| Create a preventive backup before a valid restore | App-support preventive copy before replacement | Preventive copy contents asserted | Restore completed through DocumentsUI |
| Preserve totals and history after restore | Whole SQLite database replacement and post-validation | Catalog/order/payment/settings counts and restored values asserted | Valid SAF restore returned successfully |
| Survive restart and update | Persisted local SQLite | Existing migration and repository suites | App restart, APK update, and full device reboot preserved `RebootProof` |
| Run migrations once and roll back failed migrations | Migration runner plus restore rollback | Version-1 migration and injected post-replacement failure pass | Covered on physical target |
| Cover affected UI states and accessibility | Settings controller/page with confirmation, progress, errors, semantics, and scroll | Four widget tests, including short landscape viewport | 2720×1224 landscape controls and semantics inspected |

## Plan

1. Add application-wide database coordination and exercise it with tests.
2. Implement validated export and failure-safe restore.
3. Add Settings presentation for business name, export, and restore.
4. Add automated coverage and sanitize an example backup.
5. Produce operational documentation and candidate APK evidence.
6. Run every gate and demonstrate the milestone on the physical Android device.

## Decisions and risks

| Decision or risk | Resolution or mitigation |
| --- | --- |
| Android emulation is forbidden by repository rules | Use only the connected physical device. |
| Closing SQLite while another operation starts can corrupt or fail work | Route live repository and transaction operations through one database gate. |
| Process interruption during replacement can lose the active database | Validate a preventive copy and use same-filesystem staging plus rollback. |
| A future schema could be opened accidentally | Reject versions outside the supported migration range before replacement. |
| SAF cancellation or plugin errors are normal user-facing outcomes | Treat cancellation separately and translate failures to typed errors. |
| The example backup could expose real data | Generate it from deterministic fictitious fixtures only. |

## Database and migration impact

- Migration: No new schema migration planned; schema version remains 2.
- Previous-version fixture: Restore a populated version-1 database and migrate it to version 2.
- Rollback verification: Inject failures before and after replacement and verify restoration of the original database.
- Data-preservation verification: Compare catalog, orders, payments, settings, history, and report totals after restore.

## Automated verification

| Command | Result | Notes |
| --- | --- | --- |
| Baseline before implementation | Pass | Clean synchronized `main` at `402e761`; lockfile unchanged, 89 files formatted, analysis, 61 tests, and debug APK passed on 2026-10-08. Android execution was deferred until approval. |
| `flutter pub get` | Pass | Dependencies resolved; lockfile unchanged. |
| `dart format --output=none --set-exit-if-changed .` | Pass | 102 files, 0 changed. |
| `flutter analyze` | Pass | No issues found. |
| `flutter test` | Pass | 66 tests. |
| `flutter test integration_test -d adb-143332555G110895-88cwLo._adb-tls-connect._tcp` | Pass | 14 tests on the physical Infinix X6873, including five backup/restore cases. |
| `flutter build apk --debug` | Pass | Production-entry candidate SHA-256: `1257d99e3cd376959db0738b5521c3fffe63e31436e77019f069147a6bb7f28d`. |
| `flutter run -d adb-143332555G110895-88cwLo._adb-tls-connect._tcp --no-build --no-resident --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk` | Pass | Candidate installed and launched on the physical target. |
| Example backup validation | Pass | SQLite integrity `ok`, foreign keys clean, `user_version=2`, expected counts `1/1/1/1/1/1/3`; SHA-256 `f4380a74288b002d21fbcb5a54c63e57813f1b79973463daa1dd94018b7864d2`. |

## Manual demonstration

- Environment/device: Infinix X6873, Android 16/API 36, physical device.
- Initial setup: production application in landscape with local SQLite; Android DocumentsUI used for SAF operations. A temporary business name (`CafeUpgrade`) was used only to prove update/restart persistence.

| Step | Action | Expected result | Actual result |
| --- | --- | --- | --- |
| 1 | Export through Android storage. | A validated SQLite backup is created. | Pass: DocumentsUI opened with a generated `.db` name and saved the file in Downloads. |
| 2 | Select an invalid backup. | Restore is rejected and current data remains. | Pass in the Android integration suite for corrupt, future-version, and incomplete-schema files; direct SAF selection remains on the owner checklist. |
| 3 | Restore a valid backup. | A preventive backup is created and restored history/totals match. | Pass: the exported file was selected in DocumentsUI and the app resumed; automated Android assertions verified the preventive copy and restored data. |
| 4 | Install the candidate over the existing app and restart the device. | Existing data remains after update and reboot. | Pass: `adb install -r` and force-stop/relaunch preserved local data; after a full device reboot, the production-entry APK opened and retained `RebootProof`. |

## Review

- [x] Diff matches approved scope.
- [x] Architecture boundaries are preserved.
- [x] Transactions and persistence invariants are correct.
- [x] Error, loading, empty, and in-progress states are covered where applicable.
- [x] Accessibility affected by the change was reviewed.
- [x] Dependencies and documentation are current.
- [x] No secrets, real data, generated noise, or unrelated changes are present.

### Findings

- No unresolved code finding. Domain/application remain independent of Flutter UI and SQLite; widgets contain no SQL; the dependency set is unchanged.

## Commits

- `3f5c223` — `feat(backup): add failure-safe SQLite restore`
- `fe2d847` — `feat(settings): add business and backup controls`
- `578b2bc` — `docs: add MVP recovery and release artifacts`
- `8836722` — `docs: record milestone 5 verification`

## Remaining limitations or blockers

- Owner acceptance has not yet been requested or recorded.

## Completion decision

- [ ] All applicable completion gates in `docs/DEVELOPMENT_WORKFLOW.md` pass.
- [ ] Owner accepted the milestone.
- Final state: `IN_PROGRESS`
