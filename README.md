# Cafe POS — Flutter starter pack for Codex

This package contains the product requirements, architecture, database schema, implementation plan, acceptance criteria, and Codex prompts for a small cafe POS application.

## Product summary

The product is an offline-first Android tablet application for a small cafe. It manages products, tables, open orders, cash or manual-transfer payments, sales history, reports, and local backups.

The first release uses Flutter and Dart with local SQLite. It does not require an internet connection, backend, cloud service, or multiple devices.

## Read in this order

1. `AGENTS.md` — rules Codex must follow.
2. `docs/PRD.md` — product scope and business rules.
3. `docs/DECISIONS.md` — important technical decisions and trade-offs.
4. `docs/ARCHITECTURE.md` — Flutter layers and project structure.
5. `docs/UI_SPEC.md` — tablet screens and interaction requirements.
6. `database/001_initial_schema.sql` — initial SQLite schema.
7. `docs/ACCEPTANCE_CRITERIA.md` — verifiable completion criteria.
8. `docs/IMPLEMENTATION_PLAN.md` — implementation milestones.
9. `docs/TOOLS.md` — development environment and dependencies.
10. `prompts/START_HERE.md` — first prompts for Codex.

## Decisions already made

- Platform: Android tablet.
- Initial operation: one tablet and one local database.
- Framework: Flutter.
- Language: Dart.
- UI: Flutter Material 3 widgets.
- Persistence: SQLite on the device.
- Order workflow: customers pay after consuming.
- Payment methods: cash and manually verified transfer.
- Receipts: no fiscal or printed receipts in the MVP.
- Scope: sales only; no expenses, ingredient inventory, or production costs.
- Connectivity: the application must work in airplane mode.

## Start with a clean Flutter project

From this repository root, run:

```bash
flutter create --platforms=android .
```

This preserves the documentation in place and creates the Flutter project in the same repository. Open the repository root with Codex, switch to Plan mode, and use `prompts/START_HERE.md`.

Do not migrate a React/Vite/Capacitor scaffold. This package intentionally starts with a clean Flutter project.
