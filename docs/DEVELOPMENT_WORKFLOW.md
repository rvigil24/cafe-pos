# Development Workflow

This document is the authoritative delivery process for every Cafe POS milestone. `AGENTS.md` defines repository-wide constraints, `docs/IMPLEMENTATION_PLAN.md` defines milestone scope, and this document defines how work is planned, implemented, verified, reviewed, recorded, and closed.

## 1. Milestone states

Each milestone has exactly one of these states:

- `NOT_STARTED`: no implementation work has begun.
- `PLANNED`: the plan has been reviewed and explicitly approved.
- `IN_PROGRESS`: implementation or verification is underway.
- `BLOCKED`: a required decision, dependency, environment, or verification is unavailable.
- `COMPLETE`: every applicable completion gate in this document passes and the owner has accepted the result.

Incomplete or unavailable verification keeps the milestone `IN_PROGRESS` or `BLOCKED`; it must not be reported as complete.

## 2. Evidence record

At implementation start, copy `docs/milestones/TEMPLATE.md` to `docs/milestones/MILESTONE_N.md`. That file is the durable record for:

- approved scope and exclusions;
- requirement-to-test mapping;
- decisions and risks;
- commands and results;
- manual test evidence;
- review findings;
- remaining limitations;
- final approval, commit references, and remote branch.

Keep the record concise and update it during the milestone, not retrospectively after details are lost. Do not place secrets, personal data, or real customer data in evidence.

## 3. Phase A — Intake and baseline

Before planning:

1. Read `AGENTS.md` and the sources it identifies, in precedence order.
2. Select exactly one milestone from `docs/IMPLEMENTATION_PLAN.md`.
3. Inspect the repository and confirm the previous milestone is complete.
4. Run `git status --short`; resolve or explicitly account for every pre-existing change.
5. Run the currently applicable validation commands to establish a baseline.
6. Map milestone tasks to explicit criteria in `docs/ACCEPTANCE_CRITERIA.md`.
7. Stop and report any conflict, missing product decision, or unsafe assumption.

Do not combine work from different milestones merely because adjacent code is convenient to change.

## 4. Phase B — Plan and approval

Use Plan mode for a milestone or any architecture-changing task. The plan must state:

- objective, output, and explicit non-goals;
- acceptance criteria covered;
- vertical slices and implementation order;
- files and layers affected;
- dependencies, with compatibility and maintenance evidence;
- database changes and migration strategy;
- transaction boundaries and failure behavior;
- automated and manual tests;
- verification commands and target devices;
- documentation changes;
- risks, open decisions, and rollback approach.

Planning does not authorize implementation. Wait for explicit owner approval before changing application code, dependencies, or the database schema.

## 5. Phase C — Branch and commits

Use one branch per implementation milestone:

```text
milestone/<number>-<short-name>
```

Use `docs/<short-name>` or `fix/<short-name>` for work outside a milestone. Work directly on `main` only when the owner explicitly requests it.

Commits must be atomic, limited to one coherent change, and use Conventional Commit-style messages:

```text
feat(catalog): add SQLite product repository
fix(orders): reject updates to paid orders
test(payments): cover rollback after payment insert
docs: record backup validation strategy
```

Do not mix milestones in one branch or commit. Before every commit, inspect `git diff`, run `git diff --check`, and run the checks relevant to that change. The milestone must end with a clean worktree.

## 6. Phase D — Implementation

Implement small vertical slices that finish with observable behavior. For each slice:

1. Add or update the domain rule and repository contract.
2. Implement the application use case and transaction boundary.
3. Implement infrastructure without leaking SQLite upward.
4. Add presentation state and widgets without business rules or SQL.
5. Add tests at the lowest useful level.
6. Run focused tests immediately.
7. Update the milestone evidence record.

Follow the architecture and business invariants in `AGENTS.md` and `docs/ARCHITECTURE.md`. Do not introduce a package, abstraction, or feature for hypothetical future use.

## 7. Phase E — Testing strategy

Every changed behavior needs a test at the cheapest level that proves it, plus broader coverage where integration risk warrants it.

### Domain and application

- Test calculations, validation, state transitions, and typed errors with plain Dart tests.
- Use in-memory fakes from `test/` to isolate use cases.
- Cover success, invalid input, forbidden state, and retry behavior.

### SQLite and migrations

- Test repositories against a temporary database with foreign keys enabled.
- Test multi-write operations for commit and injected-failure rollback.
- Test unique constraints and repeated attempts.
- Test each migration from a populated previous-version database.
- Test fresh install, repeated startup, failed migration rollback, data preservation, and `user_version`.

### Widgets and integration

- Test loading, empty, success, recoverable error, in-progress, and destructive confirmation states where applicable.
- Test relevant semantic labels, validation messages, and disabled actions.
- Use `integration_test` for critical Android flows and plugin boundaries.

### Coverage policy

There is no arbitrary percentage target for the MVP. Coverage is behavior-based: every acceptance criterion and business branch changed by the milestone must be mapped to an automated test or to an explicitly justified manual check.

## 8. Phase F — Required validation

Once the Flutter project exists, run from the repository root:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

When integration tests exist, also run:

```bash
flutter test integration_test
```

Run the application on every target required by the milestone:

```bash
flutter run
```

For documentation-only work before Flutter bootstrap, at minimum run `git diff --check`, validate changed SQL directly with SQLite when applicable, and inspect internal links and terminology.

Record the exact command, result, and any relevant environment details in the milestone evidence file. A skipped command requires a reason and prevents completion if it is a milestone gate.

## 9. Phase G — Review

Perform a self-review before requesting owner review:

- compare the diff with the approved scope and acceptance mapping;
- confirm no unrelated files, generated noise, secrets, or real data are present;
- confirm widgets contain no SQL or business rules;
- confirm domain and application import neither Flutter UI nor SQLite;
- confirm multi-table writes share one transaction;
- confirm money, timestamps, UUIDs, snapshots, and immutable sales follow repository rules;
- confirm errors and UI states are handled;
- confirm dependencies are necessary and documented;
- confirm affected documentation is current;
- confirm tests would fail if the implemented rule regressed.

If a remote and pull-request workflow are configured, use one pull request per milestone. Otherwise, present the local diff, validation results, manual demonstration, and commit list for owner review.

Review findings must be resolved or recorded as an explicit blocker. Deferring required milestone behavior to a later milestone requires owner approval and a documentation update.

## 10. Phase H — Manual demonstration

Demonstrate the milestone output named in `docs/IMPLEMENTATION_PLAN.md`. The evidence record must contain:

- environment or device used;
- initial data/setup;
- numbered actions;
- expected and actual result;
- screenshots or logs when they materially prove the behavior;
- cleanup or restoration performed.

Use an emulator for routine Android validation. The physical target tablet is mandatory when the milestone or final acceptance criteria require it, especially during hardening and release-candidate validation.

## 11. Completion gate

A milestone is `COMPLETE` only when all applicable statements are true:

- [ ] The approved milestone scope is implemented and no later scope was added.
- [ ] Every mapped acceptance criterion passes.
- [ ] Relevant unit, repository, widget, and integration tests pass.
- [ ] Formatting, analysis, tests, and the debug APK build pass.
- [ ] Migration tests pass against representative existing data when applicable.
- [ ] The milestone output was demonstrated on the required target.
- [ ] Accessibility and failure states affected by the milestone were reviewed.
- [ ] Documentation and the evidence record are current.
- [ ] Self-review found no unresolved required issue or unrelated diff.
- [ ] Commits are coherent and the worktree is clean.
- [ ] Final commits are pushed to the configured remote and the local branch matches its upstream.
- [ ] The owner explicitly accepts the milestone.

Passing tests alone does not complete a milestone. Likewise, owner acceptance does not waive failed required checks unless the requirement itself is explicitly changed in the source documentation.

## 12. Closure and next milestone

After approval:

1. Record the completion date, final commit IDs, and owner acceptance in the evidence file.
2. Ensure the final evidence update is committed.
3. Merge the milestone branch through the configured review method, or retain the reviewed commits on `main` when direct work was explicitly authorized.
4. Push the branch containing the final milestone commits to its configured remote. Set its upstream on the first push. If the reviewed commits were merged or retained on `main`, push `main` as well.
5. Fetch the remote and confirm that the worktree is clean and the final local branch is neither ahead of nor behind its upstream.
6. Record the remote branch in the evidence file and report the pushed commit to the owner.
7. Do not begin the next milestone until this closure is complete.

Typical commands are:

```bash
git push --set-upstream origin <branch>
git fetch origin --prune
git status --short --branch
```

If no remote is configured, authentication fails, or the push is rejected, keep the milestone `IN_PROGRESS` or `BLOCKED` and report the exact condition. Do not claim closure from local commits alone.

If work is blocked, record the blocker and the last passing checks. Do not create a completion commit or advance the implementation plan as though the milestone passed.
