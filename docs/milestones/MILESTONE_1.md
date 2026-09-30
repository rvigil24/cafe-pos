# Milestone 1 — Evidence Record

## Status

- State: `COMPLETE`
- Owner: Ruben Vigil
- Branch: `milestone/1-database-catalog`
- Remote branch: `origin/milestone/1-database-catalog`
- Started: 2026-09-29
- Completed: 2026-09-29
- Approval: Plan approved on 2026-09-29; final test/run and corrected modal verified and accepted by the owner on 2026-09-29

## Objective and output

Configure the first SQLite migration and deliver persistent category and product management. The working demonstration creates and edits catalog data, restarts the application, and shows that the catalog remains available.

## Scope

### Included

- [x] Configure the SQLite connection, foreign keys, and atomic migrations.
- [x] Apply `database/001_initial_schema.sql` with `PRAGMA user_version` as the authoritative version.
- [x] Implement category, product, table, and settings repository contracts and SQLite implementations.
- [x] Implement category and product management without physical deletion.
- [x] Validate decimal price input and persist money as integer cents.
- [x] Cover catalog screen loading, empty, error, progress, success, and deactivation-confirmation states.
- [x] Add domain, application, widget, repository, migration, and persistence tests.

### Excluded

- Table-management UI, orders, payments, sales, reports, and backup behavior.
- Physical deletion of catalog records.
- New dependencies or changes to the approved package set.

## Acceptance and test mapping

| Requirement or criterion | Implementation | Automated test | Manual check |
| --- | --- | --- | --- |
| Create a category and product with a price stored in cents | Catalog use cases and SQLite repositories | Domain, repository, and integration tests | Create and reopen a priced product |
| Edit, reorder, and deactivate categories | Category use cases and repository | Use-case and repository tests | Reorder and deactivate a category |
| Category activation controls sellable catalog visibility without changing product flags | Sellable-catalog repository query | Repository integration test | Deactivate and reactivate a category |
| Edit and deactivate products; sort active products alphabetically | Product use cases and repository query | Use-case and repository tests | Edit and inspect product order |
| Toggle availability independently from product activation | Product availability use case | Use-case and repository tests | Toggle available/sold-out |
| Reject empty, negative, and invalid prices | Exact cents parser and typed validation error | Unit and widget tests | Submit invalid price values |
| Persist canonical UUIDs and UTC timestamps | Application factories and repository mapping | Unit and repository tests | Inspect persisted catalog after restart |
| Migrations do not repeat and failed migration rolls back schema plus version | SQLite migration runner | Android integration tests | Relaunch application |
| Catalog persists across application restarts | Persistent database provider | Android integration test | Close and reopen application |
| Required screen states and accessibility behavior | Catalog controller and Material 3 screen | Controller and widget tests | Review touch targets, labels, and errors |

## Plan

1. Add domain entities, typed errors, repository contracts, and exact money parsing.
2. Add the database provider and atomic migration runner, then verify fresh install, repeated startup, and rollback.
3. Implement SQLite category, product, table, and settings repositories with typed error translation.
4. Add catalog use cases and presentation state.
5. Build the category and product management screen as a persistent vertical slice.
6. Run focused tests after each slice and the full validation suite before review.
7. Demonstrate persistence on Android and update this evidence record.

## Decisions and risks

| Decision or risk | Resolution or mitigation |
| --- | --- |
| Price input has no specified currency symbol | Owner approved non-negative decimal input using a dot and at most two decimals; values are converted exactly to cents. |
| `sqflite` requires a Flutter platform for real repository tests | Keep plain Dart rules under `flutter test` and exercise SQLite repositories and migrations on Android through `integration_test`. |
| Initial migration contains `PRAGMA foreign_keys` | Enable foreign keys when each connection is configured and verify them explicitly; migration execution remains atomic. |
| Catalog records may be referenced by future sales | Use activation flags only; do not expose or execute physical deletion. |
| Table UI belongs to the next milestone | Implement and test only the table repository foundation in this milestone. |
| Existing package set is already locked and Android-verified | Add no dependency; continue with `sqflite 2.4.4` from `pubspec.lock`. |

## Database and migration impact

- Migration: Apply `database/001_initial_schema.sql` as schema version 1.
- Previous-version fixture: A version-0 database has no Cafe POS production schema because Milestone 0 did not create one.
- Rollback verification: Inject a failing migration after a schema write and assert that its schema changes and `user_version` are unchanged.
- Data-preservation verification: Seed catalog data, close and reopen the database, and assert that repeated startup preserves it without rerunning migration 1.

## Automated verification

| Command | Result | Notes |
| --- | --- | --- |
| Baseline before implementation | Pass | Clean `main`; format, analysis, 3 tests, debug APK, and Android SQLite integration test passed on 2026-09-29. |
| `flutter pub get` | Pass | Approved dependencies resolved; no dependency was added. |
| `dart format --output=none --set-exit-if-changed .` | Pass | 34 Dart files checked with no changes. |
| `flutter analyze` | Pass | No issues found. |
| `flutter test` | Pass | 17 domain, application, controller, widget, package, and validation tests passed. |
| `flutter test integration_test -d adb-143332555G110895-88cwLo._adb-tls-connect._tcp` | Pass | 3 tests passed on the Android device: plugin rollback smoke test plus fresh migration/repositories/persistence and failed-migration rollback. |
| `flutter build apk --debug` | Pass | Built `build/app/outputs/flutter-apk/app-debug.apk` after the final keyboard fix. |
| `flutter run -d adb-143332555G110895-88cwLo._adb-tls-connect._tcp --no-build --no-resident --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk` | Pass | Installed and opened the production entry point. |
| Architecture boundary searches and `git diff --check` | Pass | No Flutter/SQLite imports in domain or application, no SQL in features, and no whitespace errors. |

## Manual demonstration

- Environment/device: Infinix X6873, Android 16/API 36, connected through wireless debugging and held in landscape orientation.
- Initial setup: Debug APK installed with a fresh production database. Per owner direction, no Android emulator is to run on this development machine because it causes system crashes; process inspection confirmed no AVD/QEMU process remained active.

| Step | Action | Expected result | Actual result |
| --- | --- | --- | --- |
| 1 | Launch with a fresh application database. | Empty catalog appears without an error. | Pass — the empty categories and catalog guidance rendered in landscape. |
| 2 | Create category `Bebidas`. | The saved category is selected and ready for products. | Pass — category appeared immediately with success feedback. Edit, reorder, deactivate, and reactivate branches also pass widget and Android repository tests. |
| 3 | Create product `Cafe` at `2.50`, then mark it sold out. | The product and its independent availability state are saved. | Pass — the product card displayed `2.50 · Agotado`. Edit and activation branches also pass automated tests. |
| 4 | Submit malformed and over-precision prices. | Each invalid value is rejected with a field-associated message. | Pass — widget test verifies the visible validation message; unit tests also cover empty, negative, malformed, comma-decimal, over-precision, and SQLite overflow values. |
| 5 | Force-stop and relaunch the application. | Catalog contents and state are preserved. | Pass — `Bebidas`, `Cafe`, `2.50`, and `Agotado` remained after two force-stop/relaunch cycles. |
| 6 | Open catalog forms with the software keyboard in landscape. | Controls remain usable without a render overflow or compressed input. | Pass after correction — forms switch to a compact keyboard state that preserves a minimum 48 px input height and restores the unchanged modal title/actions when the keyboard closes. The owner confirmed on 2026-09-29 that both the test and run workflows pass and the modal issue is resolved. |

## Review

- [x] Diff matches approved scope.
- [x] Architecture boundaries are preserved.
- [x] Transactions and persistence invariants are correct.
- [x] Error, loading, empty, and in-progress states are covered where applicable.
- [x] Accessibility affected by the change was reviewed.
- [x] Dependencies and documentation are current.
- [x] No secrets, real data, generated noise, or unrelated changes are present.

### Findings

- Fresh schema installation, repeated startup, foreign-key configuration, seeded settings, repository CRUD, sellable catalog visibility, canonical timestamps, persistence, and failed-migration rollback pass against SQLite on Android.
- Category ordering uses one SQLite transaction. Table deactivation checks for an open order and returns a typed `OccupiedTableError` from the repository foundation.
- Physical-device review found a keyboard-related render overflow that widget tests had not originally exposed. Commit `f071d7d` makes both forms scrollable, prevents the background scaffold from resizing, and adds a reduced-height regression test. The corrected build was visually rechecked on the device.
- A follow-up review found that the overflow-free form still compressed its input while the keyboard was visible. Commit `7ffe711` adds an adaptive compact state, keyboard next/done actions, and an explicit regression assertion that the field remains at least 48 px high. The owner verified the final behavior through the project test and run workflows.
- A later local APK build triggered `systemd-oomd`, which killed the VS Code scope under memory pressure. No emulator was active, no repository data was lost, and no Gradle or emulator process remained. Heavy validation must not be launched again from this constrained VS Code session.
- `flutter emulators --launch cafe_pos_tablet_api_36` returned without starting a discoverable emulator process. The owner subsequently directed that Android emulation not be used on this machine; all final Android validation used the physical device.

## Commits

- `863880e feat(database): add initial migration and repositories`
- `f01e28d feat(catalog): add persistent product management`
- `f071d7d fix(catalog): keep forms usable with keyboard`
- `7ffe711 fix(catalog): preserve form height above keyboard`
- `aa90be1 docs: record milestone 1 evidence`
- `ada2117 docs: record final keyboard verification`
- `aabf446 docs: record milestone 1 acceptance`

## Remaining limitations or blockers

- Android emulation is intentionally disabled for this machine by owner direction; future local device checks should use the connected physical device. Web can be used for presentation-only UI work, but it cannot replace Android SQLite/plugin verification.

## Completion decision

- [x] All applicable completion gates in `docs/DEVELOPMENT_WORKFLOW.md` pass.
- [x] Owner accepted the milestone.
- Final state: `COMPLETE`
