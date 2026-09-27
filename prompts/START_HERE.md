# Convenience Prompts for Codex

These prompts are optional shortcuts, not sources of truth. `AGENTS.md`, its referenced documents, and `docs/DEVELOPMENT_WORKFLOW.md` remain authoritative. Replace `N` with the milestone number; use `0` for the first run.

## Plan a milestone

```text
Plan only Milestone N from docs/IMPLEMENTATION_PLAN.md. Read AGENTS.md and every source it requires, inspect the current repository, and follow the planning gate in docs/DEVELOPMENT_WORKFLOW.md. Map scope to acceptance criteria, tests, verification commands, manual demonstration, documentation, risks, and decisions requiring approval. Do not modify files or begin later milestones. Stop after the plan and wait for my approval.
```

## Implement an approved plan

```text
Implement only Milestone N according to the approved plan, AGENTS.md, and docs/DEVELOPMENT_WORKFLOW.md. Create docs/milestones/MILESTONE_N.md from the template, keep its evidence current, run every applicable check, and report blockers precisely. Do not declare completion or begin another milestone before owner review and acceptance.
```

## Review and close a milestone

```text
Review Milestone N against its approved scope, acceptance mapping, diff, tests, manual demonstration, and every completion gate in docs/DEVELOPMENT_WORKFLOW.md. Report findings before changing code. If all required checks pass and I accept the result, update the evidence record and complete the documented closure process.
```
