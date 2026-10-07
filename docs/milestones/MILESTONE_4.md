# Milestone 4 — Evidence Record

## Status

- State: `COMPLETE`
- Owner: Ruben Vigil
- Branch: `milestone/4-history-reports`
- Remote branch: `origin/milestone/4-history-reports`
- Started: 2026-10-06
- Completed: 2026-10-06
- Approval: Plan approved by the owner on 2026-10-06. Milestone result
  accepted by the owner on 2026-10-06.

## Objective and output

Deliver read-only sales history and timezone-correct reports. A newly completed
payment must appear with the correct sale date and values in both areas.

## Scope

### Included

- [x] Sales history ordered by `paid_at`, exact order-number search, date and
  payment-method filters, and read-only details.
- [x] Today, yesterday, this week, this month, and inclusive custom report
  periods in `America/El_Salvador`.
- [x] Net sales, paid-order count, average ticket, units, best-selling products,
  and totals by category, local hour, and payment method.
- [x] Loading, empty, recoverable-error, in-progress, and accessible result
  states for the new screens.
- [x] Android SQLite integration coverage with explicit fixture values.

### Excluded

- Backup, restore, export, pagination, taxes, discounts, refunds, paid-sale
  editing, and third-party chart packages.

## Acceptance and test mapping

| Requirement or criterion | Implementation | Automated test | Manual check |
| --- | --- | --- | --- |
| History lists persisted sales by descending `paid_at` and opens read-only details | Sales repository, use cases, controller, and pages | Application, widget, and Android integration tests | Pass — order #1 and its item/payment details appeared on device |
| Search and combined date/payment filters use `paid_at` | Exact order-number search and half-open UTC filter | Application and Android integration tests | Covered automatically with explicit boundaries and filters |
| Reports exclude non-paid orders and use payment amounts | Report repository restricted to matching paid orders and payments | Android integration fixture | Pass — physical Today report included only the new paid order |
| Units and snapshot groupings are correct | Quantity sums and order-item snapshots | Application and Android integration tests | Pass — Espresso and Café snapshots displayed |
| Average ticket and all required groupings match explicit values | Integer aggregations with deterministic ordering | Application and Android integration tests | Pass — net 1.50, one order, average 1.50, one unit |
| Presets and custom dates use the cafe timezone | Local calendar service producing half-open UTC ranges | Plain Dart boundary tests | Today used the El Salvador payment date |
| New screens cover required states and accessibility | Material 3 controllers/pages with semantics and retry behavior | Widget tests | Pass — physical semantic hierarchy exposed navigation, sale, and metric values |
| A new payment appears in history and reports | Production flow plus refreshed read models | Android integration and physical-device demonstration | Pass — cash payment for order #1 appeared in both sections |

## Plan

1. Add and test cafe-calendar period boundaries.
2. Add domain read models, repository contracts, and application use cases.
3. Implement SQLite history queries and the Sales presentation slice.
4. Implement consistent SQLite report aggregation and the Reports slice.
5. Wire navigation and dependencies, then add widget and Android integration
   coverage.
6. Run all gates and demonstrate payment to history/report on the physical
   Android device.

## Decisions and risks

| Decision or risk | Resolution or mitigation |
| --- | --- |
| Device or SQLite local time could differ from the cafe | Convert explicit local periods with the timezone package and group hours in `America/El_Salvador`. |
| Inclusive end dates are easy to query incorrectly | Convert the following local midnight to the exclusive UTC end. |
| Joins can duplicate payment amounts across order lines | Keep order-level and item-level aggregations separate inside one read transaction. |
| Multiple report queries could observe different states | Load one report inside a SQLite read transaction. |
| Historical catalog data could be replaced by current names | Aggregate only persisted product/category/table snapshots. |
| Average ticket requires a cent value | Round the integer ratio to the nearest cent without floating point. |
| Android emulation exhausts the host | Use only the connected physical Android device. |

## Database and migration impact

- Migration: Not applicable. The version-2 schema and existing indexes contain
  every field needed by the read-only queries.
- Previous-version fixture: Not applicable because the schema is unchanged.
- Rollback verification: Not applicable; the feature performs no database
  writes.
- Data-preservation verification: Existing migration and payment suites remain
  required, plus history/report reads over existing paid data.

## Automated verification

| Command | Result | Notes |
| --- | --- | --- |
| Baseline before implementation | Pass | Clean synchronized `main` at `0b66b81`; lockfile unchanged, 67 files formatted, analysis, 46 tests, and debug APK passed. Android execution deferred until after plan approval. |
| `flutter pub get` | Pass | Dependencies resolved; `pubspec.lock` hash remained `a82977a346ad55706cdfeb79ae2b02623af04577bbd397d0c4a39fdec8e51eb8`. |
| `dart format --output=none --set-exit-if-changed .` | Pass | 89 Dart files checked with no changes before the viewport regression test; the final focused format check also passed. |
| `flutter analyze` | Pass | No issues found after the final navigation fix. |
| `flutter test` | Pass | 61 application, controller, widget, navigation, package, and regression tests passed. |
| `flutter test integration_test -d adb-143332555G110895-88cwLo._adb-tls-connect._tcp` | Pass | 9 tests passed on Android across migrations, repositories, payments, history, and reports. The expanded payment-to-report fixture was then re-run successfully. |
| `flutter build apk --debug` | Pass | Production debug APK rebuilt after integration and seeder builds. |
| `flutter run -d adb-143332555G110895-88cwLo._adb-tls-connect._tcp --no-build --no-resident --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk` | Pass | Production entry point installed and opened on the physical device after the final navigation fix. |
| Architecture searches and `git diff --check` | Pass | No Flutter/SQLite imports in domain or application, no SQL in features, and no whitespace errors. |

## Manual demonstration

- Environment/device: Infinix X6873, Android 16/API 36, physical device.
- Initial setup: Development seeder created 8 sanitized tables, 4 categories,
  and 12 products without replacing existing matching records.
- Cleanup/restoration: The production debug APK was restored and left open.
  Sanitized order #1 and the seeded catalog remain on the device for owner
  review; no reset was performed.

| Step | Action | Expected result | Actual result |
| --- | --- | --- | --- |
| 1 | Create takeaway order #1, add Espresso at 1.50, and pay 2.00 cash. | Payment succeeds with 0.50 change and the order leaves Home. | Pass — production UI returned Home after confirming payment. |
| 2 | Open Sales and select order #1. | The new sale appears first with its `paid_at` date, total, method, line, and read-only payment detail. | Pass — showed 06/10/2026 7:48 PM, 1.50, Efectivo, and 1 × Espresso. Automated Android coverage verified exact search and combined filters. |
| 3 | Open Reports for Today. | Every metric and grouping includes the payment exactly once. | Pass — net 1.50, 1 paid order, average 1.50, 1 unit, Espresso 1, Café 1.50, and cash 1.50. |

## Review

- [x] Diff matches approved scope.
- [x] Architecture boundaries are preserved.
- [x] Transactions and persistence invariants are correct.
- [x] Error, loading, empty, and in-progress states are covered where applicable.
- [x] Accessibility affected by the change was reviewed.
- [x] Dependencies and documentation are current.
- [x] No secrets, real data, generated noise, or unrelated changes are present.

### Findings

- The first production launch exposed a 24-pixel vertical overflow because six
  labeled navigation destinations exceeded the physical device's 360 dp
  landscape height. The rail is now scrollable, a short-viewport widget
  regression test passes, and the rebuilt APK launched without the exception.
- Online dependency resolution stalled once without changing the lockfile. The
  process was stopped, cached resolution passed, and a later exact
  `flutter pub get` completed successfully.

## Commits

- `a22a3b9 feat(reports): add sales history and report queries`
- `e034fd8 feat(reports): add tablet sales and report screens`
- `7b629aa test(reports): verify payments reach history and reports`
- `a53900a fix(navigation): support short landscape viewports`
- `801020b docs: record milestone 4 evidence`
- `8485923 docs: record milestone 4 review branch`
- `31a61c2 docs: record milestone 4 device cleanup state`

## Remaining limitations or blockers

- No blockers or deferred Milestone 4 requirements remain.

## Completion decision

- [x] All applicable completion gates in `docs/DEVELOPMENT_WORKFLOW.md` pass.
- [x] Owner accepted the milestone on 2026-10-06.
- Final state: `COMPLETE`
