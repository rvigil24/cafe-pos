# Cafe POS — Codex instructions

## Objective

Build the Flutter Android MVP described in `docs/PRD.md`: an offline-first POS for a small cafe, operated from one Android tablet with local SQLite.

## Source of truth

- Product requirements: `docs/PRD.md`
- Technical decisions: `docs/DECISIONS.md`
- Architecture: `docs/ARCHITECTURE.md`
- UI behavior: `docs/UI_SPEC.md`
- Database schema: `database/001_initial_schema.sql`
- Acceptance criteria: `docs/ACCEPTANCE_CRITERIA.md`
- Implementation order: `docs/IMPLEMENTATION_PLAN.md`

If documents conflict, stop and report the conflict. Do not silently invent a requirement.

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
- Implement one verifiable milestone at a time.
- Prefer vertical slices that finish with working behavior.
- Keep business rules in use cases and domain code, not in widgets.
- Use repositories for persistence access.
- Use transactions whenever one operation changes multiple tables.
- Store money as integer cents, never floating-point values.
- Store timestamps in UTC and display/report them in `America/El_Salvador`.
- Preserve product, category, table, and price snapshots in order history.
- Never physically delete paid sales.
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

A task is complete only when:

1. Its acceptance criteria pass.
2. Relevant tests were added or updated.
3. Formatting, analysis, tests, and build pass.
4. Database migrations were tested against existing data when applicable.
5. Affected documentation is updated.
6. The final diff contains no unrelated framework or scope changes.

## MVP exclusions

Do not implement multiple devices, synchronization, backend APIs, ingredient inventory, recipes, expenses, accounting, fiscal invoicing, printing, bank integrations, split payments, authentication, role-based access control, individual accounts, loyalty, reservations, delivery, or a kitchen display.
