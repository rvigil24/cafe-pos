# Milestone 2 — Evidence Record

## Status

- State: `IN_PROGRESS`
- Owner: Ruben Vigil
- Branch: `milestone/2-tables-open-orders`
- Remote branch: Pending
- Started: 2026-10-03
- Completed:
- Approval: Plan approved and milestone result accepted by the owner on 2026-10-03

## Objective and output

Deliver table management plus persistent open `DINE_IN` and `TAKEAWAY`
orders. The working demonstration creates an order, changes its products,
quantities, and notes, leaves the order, and reopens it with the same saved
state without taking payment.

## Scope

### Included

- [x] Create, rename, reorder, activate, and deactivate tables.
- [x] Show active tables and open takeaway orders on Home.
- [x] Create `DINE_IN` and `TAKEAWAY` orders transactionally.
- [x] Allocate the sequential order number in the order-creation transaction.
- [x] Add products, change quantities, remove lines, and save line notes.
- [x] Persist each order change and preserve catalog and table snapshots.
- [x] Reopen persisted orders after leaving the editor or restarting the app.
- [x] Cancel open orders with explicit confirmation, reason, and timestamp.
- [x] Reject mutations to `PAID` and `CANCELLED` orders in application and infrastructure.

### Excluded

- Payment collection, payment persistence, and change calculation.
- Sales history, reports, backup, and restore.
- Authentication, printing, networking, synchronization, and other MVP exclusions.
- New dependencies or database schema changes.

## Acceptance and test mapping

| Requirement or criterion | Implementation | Automated test | Manual check |
| --- | --- | --- | --- |
| Create `DINE_IN` for a free table and reject a second open order | Transactional create-order use case and unique partial index | Application, SQLite integration, widget | Pass — created order #1 from Home |
| Create `TAKEAWAY` without a table | Transactional create-order use case and Home action | Application, SQLite integration, widget | Pass — created and reopened order #2 |
| Manage tables and reject occupied-table deactivation | Table use cases, SQLite repository, and Settings UI | Application, SQLite integration, widget | Pass — created table; occupied rejection covered on Android and in widget UI |
| Preserve table-name snapshot | Order creation captures the current table name | SQLite integration | Pass through persisted order heading and integration rename fixture |
| Allocate UUIDs and sequential order numbers atomically | Application UUID generation plus transactional settings allocation | Application and SQLite rollback tests | Pass — orders #1 and #2 displayed |
| Add, remove, and change quantities and totals | Transactional order-item writes and total update | Application, SQLite integration, widget | Pass — two coffees totaled 5.00 |
| Keep one line per product with its original snapshots and line note | Existing-line increment plus immutable snapshots | Application and SQLite integration | Pass — one quantity-two line with `Sin_azucar` |
| Keep unavailable persisted lines visible and forbid increases | Sellability revalidation only for increases | Application, SQLite integration, widget | Pass in Android integration and widget regression |
| Preserve open orders after restart | SQLite remains the source of truth | SQLite integration | Pass — force-stop/relaunch restored takeaway #2 at 2.50 |
| Cancel with reason and timestamp and free the table | Transactional cancellation with canonical UTC timestamp | Application, SQLite integration, widget | Pass — order #1 cancelled and `Mesa1` became free |
| Reject paid or cancelled order mutation | Checks in use cases and every item/total repository mutation | Application and SQLite integration tests | Not applicable manually |
| Required UI states and accessibility behavior | Controllers, semantic labels, textual state, disabled actions, and confirmations | Controller and widget tests | Pass — physical landscape review and keyboard checks |

## Plan

1. Add order domain entities, typed errors, repository contracts, and the plain-Dart transaction runner contract.
2. Implement transaction-scoped SQLite repositories and verify commit and rollback behavior.
3. Complete table-management application behavior and UI.
4. Implement transactional order creation and Home lists.
5. Implement the persistent order editor, snapshots, quantities, notes, totals, and cancellation.
6. Run focused tests after every vertical slice and the full validation suite before review.
7. Demonstrate create/reopen/cancel behavior on the connected physical Android device.

## Decisions and risks

| Decision or risk | Resolution or mitigation |
| --- | --- |
| Existing schema already contains all Milestone 2 tables and constraints | Keep `user_version = 1`; add no migration and verify populated data remains intact. |
| Multi-table order writes must use one SQLite transaction | Add the architecture-defined plain-Dart transaction runner and transaction-scoped repositories. |
| Concurrent/repeated order creation | Revalidate inside the transaction and retain unique order-number and one-open-order-per-table constraints as final defenses. |
| Persisted product later becomes unavailable | Keep the line visible; allow decrease/removal but reject any increase. |
| Android emulator exhausts host memory | Use only the connected physical Android device; never start AVD or QEMU. |
| Existing catalog must not regress during app-shell work | Retain focused catalog widget tests and run the complete regression suite. |

## Database and migration impact

- Migration: Not applicable; `database/001_initial_schema.sql` already contains the required schema.
- Previous-version fixture: Existing version-1 database populated with catalog data.
- Rollback verification: Inject failures after the first write in order creation and item mutation and verify every related write rolls back.
- Data-preservation verification: Reopen the version-1 database and confirm existing catalog plus open orders remain available.

## Automated verification

| Command | Result | Notes |
| --- | --- | --- |
| Baseline before implementation | Pass | Clean `main`; dependencies, format, analysis, 17 tests, debug APK, 3 Android integration tests, and physical-device launch passed on 2026-10-03. |
| `flutter pub get` | Pass | Dependency resolution completed repeatedly; `pubspec.yaml` and `pubspec.lock` hashes remain unchanged. |
| `dart format --output=none --set-exit-if-changed .` | Pass | 56 Dart files checked with no changes. |
| `flutter analyze` | Pass | No issues found. |
| `flutter test` | Pass | 34 domain, application, controller, widget, package, and validation tests passed. |
| `flutter test integration_test -d adb-143332555G110895-88cwLo._adb-tls-connect._tcp` | Pass | 6 tests passed on Android: plugin rollback, migrations/catalog, order persistence, snapshots, unavailable products, transaction rollback, occupied tables, and terminal-state immutability. |
| `flutter build apk --debug` | Pass | Built `build/app/outputs/flutter-apk/app-debug.apk`. |
| `flutter run -d adb-143332555G110895-88cwLo._adb-tls-connect._tcp --no-build --no-resident --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk` | Pass | Installed and opened the production entry point. |
| Architecture searches and `git diff --check` | Pass | No Flutter/SQLite imports in domain or application, no SQL in features, and no whitespace errors. |

## Manual demonstration

- Environment/device: Infinix X6873, Android 16/API 36, connected through wireless debugging and held in landscape orientation.
- Initial setup: Fresh app data after integration tests; created sanitized `Mesa1`, `Bebidas`, and `Cafe` at 2.50 through the production UI. No emulator, AVD, or QEMU was started.

| Step | Action | Expected result | Actual result |
| --- | --- | --- | --- |
| 1 | Create `Mesa1` and open a `DINE_IN` order. | The table becomes occupied and the order receives the next number. | Pass — order #1 opened for `Mesa1`. |
| 2 | Add `Cafe` twice and save note `Sin_azucar`. | One line per product and the correct total are persisted immediately. | Pass — one quantity-two line, note, and total 5.00 displayed as saved. |
| 3 | Leave and reopen the order. | Lines, notes, snapshots, and total remain intact. | Pass — order #1 reopened with quantity two, note, and total 5.00. |
| 4 | Exercise unavailable persisted-product behavior. | The line remains visible and can decrease but cannot increase. | Pass in the Android SQLite integration test and widget regression; not repeated in the sanitized manual data flow. |
| 5 | Cancel order #1 with reason `Prueba`. | The reason and timestamp persist and the table becomes free. | Pass — Home immediately showed `Mesa1` as `Libre`; persistence is asserted against SQLite. |
| 6 | Create takeaway order #2, add `Cafe`, force-stop, and relaunch. | The order appears separately on Home without a table and survives restart. | Pass — Home restored takeaway order #2 with total 2.50. It was cancelled with reason `Limpieza` after the demonstration. |

## Review

- [x] Diff matches approved scope.
- [x] Architecture boundaries are preserved.
- [x] Transactions and persistence invariants are correct.
- [x] Error, loading, empty, and in-progress states are covered where applicable.
- [x] Accessibility affected by the change was reviewed.
- [x] Dependencies and documentation are current.
- [x] No secrets, real data, generated noise, or unrelated changes are present.

### Findings

- Physical review found that table dialogs initially overflowed above the landscape software keyboard and the root navigation rail resized with it. The app shell and shared dialog now keep their layout stable, with a widget regression for the 48 dp input height.
- Physical review then found the existing product dialog could overflow after its keyboard closed inside the new application shell. The product dialog is now always scrollable and has a short-landscape regression test.
- Physical review of the order-note keyboard found the editor's right column still resized behind the compact dialog. The order scaffold now remains stable; both the widget regression and final device screenshot were overflow-free.
- Android integration tests install a test APK and leave production app data fresh. The final production APK was reinstalled and the complete sanitized manual flow was repeated afterward.

## Commits

- `0447e7f feat(orders): add transactional open order persistence`
- `425f28c feat(pos): add tables and open order workflow`
- `283afdf docs: record milestone 2 evidence`

## Remaining limitations or blockers

- Remote publication and fast-forward integration are pending.
- Payments remain intentionally excluded until Milestone 3.

## Completion decision

- [ ] All applicable completion gates in `docs/DEVELOPMENT_WORKFLOW.md` pass.
- [x] Owner accepted the milestone.
- Final state: `IN_PROGRESS`
