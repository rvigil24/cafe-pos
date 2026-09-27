# Implementation Plan

Each milestone must end with a working demonstration and its verification commands. Do not implement multiple milestones in one Codex task.

## Milestone 0 — Flutter bootstrap

Objective: create a clean Flutter Android project without implementing the POS yet.

- Verify Flutter, Dart, Android SDK, JDK, and emulator setup.
- Create the project with `flutter create --platforms=android`.
- Configure strict analysis, formatting, and test commands.
- Confirm the Material 3 theme and tablet orientation strategy.
- Select and verify the SQLite package and backup/file-storage packages.
- Create the target `lib/` structure.
- Add a minimal screen and a smoke test.

Output: the Flutter app builds, tests pass, and the minimal Android app opens.

## Milestone 1 — Database and catalog

- Configure SQLite connection and migrations.
- Apply `database/001_initial_schema.sql` as the first migration.
- Implement category, product, table, and settings repositories.
- Build CRUD for categories and products.
- Add repository and money-validation tests.

Output: the catalog persists across app restarts.

## Milestone 2 — Tables and open orders

- Implement table management.
- Build Home with tables and open orders.
- Create `DINE_IN` and `TAKEAWAY` orders.
- Add products, change quantities, and save notes.
- Persist every order change.
- Cancel open orders with explicit confirmation and reason.

Output: the tablet operator can create and reopen a real order without paying it.

## Milestone 3 — Complete payment flow

- Implement the transactional payment use case.
- Add cash payment, amount received, and change.
- Add manually verified transfer with optional reference.
- Protect against duplicate payment in the UI and database.
- Free the table and make the order read-only after payment.

Output: the full product → order → payment flow works.

## Milestone 4 — History and reports

- Build sales history, search, and details.
- Add date and payment filters.
- Implement dashboard queries and aggregations.
- Add period selection using the cafe timezone.
- Test reports with small datasets and explicit expected values.

Output: a new payment appears correctly in history and reports.

## Milestone 5 — Backup, restore, and hardening

- Export a consistent backup through Android file storage.
- Validate backup version, integrity, and schema.
- Create a preventive backup and restore valid data.
- Test airplane mode, restarts, updates, and migrations.
- Review touch accessibility and error states.
- Produce a candidate APK.

Output: the MVP is installable and recoverable after device failure.

## Recommended workflow for every milestone

1. Ask Codex for a plan limited to the milestone.
2. Review affected files and acceptance criteria.
3. Ask Codex to implement small tasks.
4. Run the formatter, analyzer, tests, and build.
5. Review the diff and perform a manual test.
6. Commit before starting the next milestone.
