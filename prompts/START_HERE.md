# First prompts for Codex

Use the first prompt from the root of a clean Flutter repository in Plan mode.

```text
Read AGENTS.md and all documents referenced by it. This repository will implement the Cafe POS Flutter MVP described in docs/PRD.md.

This turn is only for planning Milestone 0 from docs/IMPLEMENTATION_PLAN.md. Do not write implementation code yet.

Before proposing the plan:
1. inspect the current repository;
2. verify that it is a clean Flutter project, not a React/Vite/Capacitor project;
3. run flutter doctor -v or inspect the available Flutter and Android toolchain;
4. verify current official documentation and compatibility for Flutter, Android, the selected SQLite package, and the backup/file-storage package;
5. do not add functionality outside the MVP.

The plan must include:
- files and folders to create or modify;
- dependencies and why they are needed;
- the SQLite package decision and migration approach;
- the state-management approach for the first milestone;
- the commands for formatting, analysis, tests, and Android build;
- the strategy for keeping domain/application code independent from Flutter UI and SQLite;
- how to prove that the minimal app opens on Android;
- risks or decisions that require my approval.

Stop after presenting the plan and wait for my approval.
```

## Second prompt after approval

```text
Implement only Milestone 0 according to the approved plan and AGENTS.md.

Do not implement products, tables, orders, payments, reports, or backup features yet. Run formatting, flutter analyze, flutter test, and flutter build apk --debug. If Android validation is unavailable, state exactly what remains unverified.

At the end, summarize:
- files created or modified;
- commands executed and their results;
- decisions made;
- work remaining before Milestone 1.
```

## Reusable prompt for later milestones

```text
Plan only Milestone N from docs/IMPLEMENTATION_PLAN.md.

Read AGENTS.md, the related requirements, the current code, and docs/ACCEPTANCE_CRITERIA.md. Map every task to explicit acceptance criteria. Include affected files, migrations, tests, verification commands, and risks. Do not implement yet and do not advance work from later milestones.
```
