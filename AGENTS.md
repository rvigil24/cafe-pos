# Cafe POS — Codex instructions

## Objective

Build the Flutter Android MVP described in `docs/PRD.md`: an offline-first POS for a small cafe, operated from one Android tablet with local SQLite.

## Source of truth

Use the following precedence when documents differ:

1. Working and scope constraints: `AGENTS.md`
2. Product requirements and business rules: `docs/PRD.md`
3. Technical decisions: `docs/DECISIONS.md`
4. Architecture: `docs/ARCHITECTURE.md`
5. UI behavior: `docs/UI_SPEC.md`
6. Database implementation: `database/001_initial_schema.sql`
7. Verification: `docs/ACCEPTANCE_CRITERIA.md`
8. Delivery workflow: `docs/DEVELOPMENT_WORKFLOW.md`
9. Implementation order: `docs/IMPLEMENTATION_PLAN.md`

Lower-precedence documents must implement, not redefine, higher-precedence documents. If documents still conflict, stop and report the conflict before changing either one. Do not silently invent a requirement.

## Stack

- Flutter and Dart
- Flutter Material 3
- SQLite through a Flutter-compatible SQLite package selected and verified in Milestone 0
- Plain Dart use cases and repository interfaces
- Flutter built-in `ChangeNotifier`/`ValueNotifier` for initial presentation state
- `flutter_test` and `integration_test`

Do not add React, Vite, Capacitor, MUI, Redux, a backend, Docker, cloud services, or an ORM.

## Project structure

```text
lib/
  app/
  application/
  domain/
  features/
  infrastructure/
  shared/
test/
integration_test/
```

Widgets must not execute SQL. Domain and application code must not import Flutter UI packages or SQLite packages.

## Working rules

- Use Plan mode for milestones or changes that affect architecture.
- Follow `docs/DEVELOPMENT_WORKFLOW.md` for planning, approval, evidence, testing, review, commits, and milestone closure.
- Implement one verifiable milestone at a time.
- Prefer vertical slices that finish with working behavior.
- Keep business rules in use cases and domain code, not in widgets.
- Use repositories for persistence access.
- Use transactions whenever one operation changes multiple tables.
- Store money as integer cents, never floating-point values.
- Store timestamps as ISO-8601 UTC text with a `Z` suffix and display/report them in `America/El_Salvador`.
- Generate internal entity IDs in the application as UUIDs; keep `order_number` as a separate sequential business identifier allocated transactionally.
- Preserve product, category, table, and price snapshots in order history.
- Never physically delete paid sales.
- Reject every update to items or totals of `PAID` and `CANCELLED` orders in the application and repository implementations.
- Represent expected business failures with typed domain errors; do not expose SQLite exceptions to widgets.
- Keep test fakes under `test/`; production code must not contain test-only repository implementations.
- Do not expand the MVP without explicit approval.

## Expected commands

The repository must provide and keep these commands working:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
flutter run
```

Use `flutter test integration_test` when integration tests exist.

## Definition of done

A task is complete only when the checks applicable to its scope pass. A milestone requires every completion gate and the explicit owner acceptance defined in `docs/DEVELOPMENT_WORKFLOW.md`. For non-milestone work, apply the same gate proportionally and never claim completion with a failing required check or an unrelated diff.

## MVP exclusions

Do not implement multiple devices, synchronization, backend APIs, ingredient inventory, recipes, expenses, accounting, fiscal invoicing, printing, bank integrations, split payments, authentication, role-based access control, individual accounts, loyalty, reservations, delivery, or a kitchen display.
