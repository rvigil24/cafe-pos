# Implementation Plan

Each milestone must follow `docs/DEVELOPMENT_WORKFLOW.md`, end with its stated working demonstration, and satisfy the workflow completion gate. Do not implement multiple milestones in one Codex task.

## Milestone 0 — Flutter bootstrap

Objective: create a clean Flutter Android project without implementing the POS yet.

- Verify Flutter, Dart, Android SDK, JDK, and emulator setup.
- Record the verified toolchain versions in `README.md`; do not guess or preselect versions.
- Create the project in this repository root with `flutter create --platforms=android .`.
- Configure strict analysis, formatting, and test commands.
- Confirm the Material 3 theme and tablet orientation strategy.
- Select and verify only the maintained packages needed for SQLite transactions, UUIDs, dates/timezone, file paths, and Android Storage Access Framework backups.
- Do not add packages for global state management, networking, analytics, authentication, or cloud services.
- Create the target `lib/` structure.
- Add a minimal screen and a smoke test.

Output: the Flutter app builds, tests pass, and the minimal Android app opens.

## Milestone 1 — Database and catalog

- Configure SQLite connection and migrations.
- Apply `database/001_initial_schema.sql` as the first migration.
- Use `PRAGMA user_version` as the authoritative migration version and test rollback plus repeated startup.
- Implement category, product, table, and settings repositories.
- Build CRUD for categories and products.
- Add repository and money-validation tests.

Output: the catalog persists across app restarts.

## Milestone 2 — Tables and open orders

- Implement table management.
- Build Home with tables and open orders.
- Create `DINE_IN` and `TAKEAWAY` orders.
- Allocate the sequential order number in the same transaction that creates the order.
- Add products, change quantities, and save notes.
- Persist every order change.
- Cancel open orders with explicit confirmation and reason.

Output: the tablet operator can create and reopen a real order without paying it.

## Milestone 3 — Complete payment flow

- Implement the transactional payment use case.
- Use the application transaction runner so payment insertion and order status update share one SQLite transaction.
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
- Query by `paid_at` using half-open UTC ranges converted from local calendar periods.
- Test reports with small datasets and explicit expected values.

Output: a new payment appears correctly in history and reports.

## Milestone 5 — Backup, restore, and hardening

- Export a consistent backup through Android file storage.
- Validate backup version, integrity, and schema.
- Create a preventive backup and restore valid data.
- Test airplane mode, restarts, updates, and migrations.
- Review touch accessibility and error states.
- Produce a sanitized example backup, a manual tablet test checklist, release notes, and an upgrade procedure.
- Produce a candidate APK.

Output: the MVP is installable and recoverable after device failure.

## Workflow

`docs/DEVELOPMENT_WORKFLOW.md` is the single authoritative process for planning, approval, implementation, testing, review, evidence, commits, and completion. Create each milestone record from `docs/milestones/TEMPLATE.md` when implementation begins.
