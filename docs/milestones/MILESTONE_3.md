# Milestone 3 — Evidence Record

## Status

- State: `COMPLETE`
- Owner: Ruben Vigil
- Branch: `milestone/3-complete-payment-flow`
- Remote branch: `origin/milestone/3-complete-payment-flow`
- Started: 2026-10-05
- Completed: 2026-10-05
- Approval: Plan and the manual credit-card scope expansion approved by the
  owner on 2026-10-05. Milestone result accepted by the owner on 2026-10-05.

## Objective and output

Deliver the complete product → order → payment flow. Cash, manually verified
transfer, and manually recorded credit card must persist atomically with the
order transition to `PAID`, free a dine-in table, and prevent duplicate payment.

## Scope

### Included

- [x] Transactional payment use case and transaction-scoped repositories.
- [x] Cash received amount, validation, and change.
- [x] Manually verified transfer with optional reference.
- [x] Manually recorded credit card with confirmation only and no additional
  field or card data.
- [x] Duplicate-payment protection in presentation, application, and SQLite.
- [x] Read-only paid order behavior and immediate table release.
- [x] Version-2 migration preserving existing version-1 data.

### Excluded

- Card processing, cardholder data, bank integration, split payments, tips,
  discounts, printing, history, reports, backup, and restore.

## Acceptance and test mapping

| Requirement or criterion | Implementation | Automated test | Manual check |
| --- | --- | --- | --- |
| Cash requires received amount at least equal to total and calculates change | Payment use case validates integer cents and exposes calculated change | Application and widget tests | Pass — total 2.50, received 5.00, change 2.50 |
| Empty orders cannot be paid; zero-priced lines can | Payment validates item presence independently from total | Application tests | Covered automatically with explicit fixtures |
| Transfer requires manual confirmation and permits an optional reference | Controller and use case require confirmation; reference is trimmed | Application, widget, and SQLite integration tests | Pass — order #2 with reference `TR2` |
| Credit card is manually confirmed and stores no additional card data | Card UI contains only confirmation; application discards reference and SQLite requires it to be null | Application, widget, migration, and SQLite integration tests | Pass — final UI showed no input and paid order #1 |
| Every paid order has one payment for the current total | Recalculation plus unique payment repository | Application and SQLite integration tests | Pass for all three methods |
| Payment insert and `PAID` transition commit or roll back together | One transaction-runner callback performs both writes | Injected-failure SQLite integration test | Covered automatically; injected status failure left no payment |
| Repeated attempts cannot create duplicate payments | Submission guard, transactional revalidation, and `UNIQUE(order_id)` | Controller, application, and SQLite integration tests | Paid orders disappeared from open-order UI |
| Payment frees the table and leaves the order immutable | `PAID` order is excluded from Home and repository mutations require `OPEN` | Existing immutability plus payment integration tests | Pass — `Mesa1` returned to `Libre` |
| Migration 2 preserves populated version-1 data and rolls back on failure | Append-only table rebuild with copied rows and recreated indexes | Android migration integration tests | Covered automatically on physical Android |

## Plan

1. Add migration 2 and update the approved product documentation.
2. Add payment domain types, typed failures, repository contracts, and use case.
3. Add transaction-scoped SQLite payment persistence and paid transition.
4. Add payment controller, Material 3 page, and order-flow navigation.
5. Add application, repository, widget, and Android integration coverage.
6. Run all gates and demonstrate all three payment methods on the physical
   Android device.

## Decisions and risks

| Decision or risk | Resolution or mitigation |
| --- | --- |
| The shipped v1 `CHECK` permits only cash and transfer | Keep migration 1 immutable; migration 2 rebuilds `payments` and preserves rows. |
| A payment and paid status could diverge | Perform both writes through one application transaction runner callback. |
| Repeated taps or stale screens could duplicate payment | Disable UI submission, revalidate in the transaction, and retain `UNIQUE(order_id)`. |
| Zero-total and empty orders are different | Validate item presence rather than rejecting a zero total. |
| Manual card records could invite sensitive data entry | Show no additional field and explicitly state that card details must not be entered. |
| Android emulation exhausts the host | Use only the connected physical device; never start AVD or QEMU. |

## Database and migration impact

- Migration: `002_add_credit_card_payment_method.sql`, raising `user_version`
  from 1 to 2.
- Previous-version fixture: populated v1 database containing existing orders
  and cash/transfer payments.
- Rollback verification: injected migration failure plus injected failure
  between payment insertion and order update.
- Data-preservation verification: confirm existing payment values, constraints,
  indexes, catalog, and orders remain intact after migration.

## Automated verification

| Command | Result | Notes |
| --- | --- | --- |
| Baseline before implementation | Partial pass | Clean `main`; dependency hashes unchanged, 56 files formatted, analysis, 34 tests, and debug APK passed. Android integration and launch deferred to avoid database writes before plan approval. |
| `flutter pub get` | Pass | Dependency resolution completed; no dependency or lockfile change. |
| `dart format --output=none --set-exit-if-changed .` | Pass | 64 Dart files checked with no changes. |
| `flutter analyze` | Pass | No issues found. |
| `flutter test` | Pass | 44 application, controller, widget, package, and regression tests passed. |
| `flutter test integration_test -d adb-143332555G110895-88cwLo._adb-tls-connect._tcp` | Pass | 8 tests passed on Android, including populated migration, payment rollback, duplicates, table release, and card with no reference. |
| `flutter build apk --debug` | Pass | Rebuilt production `app-debug.apk` after integration testing. |
| `flutter run -d adb-143332555G110895-88cwLo._adb-tls-connect._tcp --no-build --no-resident --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk` | Pass | Production entry point installed and opened after the v2 migration. |
| Architecture searches and `git diff --check` | Pass | No Flutter/SQLite imports in domain or application, no SQL in features, and no whitespace errors. |

## Manual demonstration

- Environment/device: Infinix X6873, Android 16/API 36, physical device.
- Initial setup: Sanitized `Bebidas`, `Cafe` at 2.50, and `Mesa1` were created
  through the production UI. Integration-test installs reset the application;
  the final card-only recheck recreated only the sanitized category and product.

| Step | Action | Expected result | Actual result |
| --- | --- | --- | --- |
| 1 | Pay a dine-in order in cash with excess received. | Correct change, one payment, `PAID`, and table free. | Pass — order #1 showed change 2.50 and `Mesa1` became `Libre`. |
| 2 | Pay a takeaway order by confirmed transfer. | Optional reference persists and the order becomes `PAID`. | Pass — unchecked confirmation first showed validation; confirmed order #2 with `TR2` then disappeared from open orders. |
| 3 | Pay an order by confirmed credit card. | Confirmation only, no additional field, and the order becomes `PAID`. | Pass — final production APK showed no input for card, required confirmation, and completed order #1 after the clean reinstall. |
| 4 | Attempt to submit payment repeatedly. | Only one payment exists and the paid order is read-only. | Pass — action was disabled in progress, paid orders were no longer open, and controller/SQLite tests confirmed one persisted payment. |

## Review

- [x] Diff matches approved scope.
- [x] Architecture boundaries are preserved.
- [x] Transactions and persistence invariants are correct.
- [x] Error, loading, empty, and in-progress states are covered where applicable.
- [x] Accessibility affected by the change was reviewed.
- [x] Dependencies and documentation are current.
- [x] No secrets, real data, generated noise, or unrelated changes are present.

### Findings

- The first manual card draft exposed the generic optional reference used by
  transfer. The owner clarified that cards need no additional field. The final
  UI removes it, the use case discards any residual value, SQLite enforces
  `reference IS NULL`, and all three layers have regression coverage.
- Running integration tests last replaces the debug APK artifact with a test
  build. The production debug APK was rebuilt before the final install and
  launch demonstration.

## Commits

- `f1aa8fa feat(database): add manual credit card payment method`
- `2751a51 feat(payments): add transactional payment persistence`
- `a5a5c68 feat(payments): add tablet payment flow`
- `946f2ad docs: record milestone 3 evidence`
- `ad1882d docs: record milestone 3 review branch`

## Remaining limitations or blockers

- No blockers or deferred Milestone 3 requirements remain.

## Completion decision

- [x] All applicable completion gates in `docs/DEVELOPMENT_WORKFLOW.md` pass.
- [x] Owner accepted the milestone on 2026-10-05.
- Final state: `COMPLETE`
