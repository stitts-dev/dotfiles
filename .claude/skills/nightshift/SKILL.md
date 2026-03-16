---
name: nightshift
description: Autonomous code improvement loop. Finds one issue, fixes it, verifies, commits. Invoke via /loop 10m /nightshift for overnight runs, or standalone for single-pass.
---

# Nightshift — Autonomous Code Improvement

One scan-fix-verify-commit cycle per invocation. Designed for `/loop 10m /nightshift` overnight runs.

## Team Roster

| Role | subagent_type | Model | Purpose |
|------|---------------|-------|---------|
| Scanner | `feature-dev:code-reviewer` | sonnet | Find ONE issue |
| Fixer | `backend-engineer` or `frontend-engineer` | sonnet | Minimal fix |
| Verifier | `build-validator` | sonnet | Compile + test |

## Hard Rules

- ONE issue per iteration, max 3 files changed
- Never touch: `.env`, auth, webhooks, migrations, billing, API schemas
- Never: `git add -A`, `git commit --amend`, `git push`
- No new dependencies, no test file modifications, no generated files
- Use Make targets and built-in tools (Read/Grep/Glob/Edit)

## Workflow

### Step 0 — Branch Setup
Create `nightshift/$(date +%Y-%m-%d)` branch if not already on one.

### Step 1 — Read Tracking File
Read/create `.planning/nightshift/issues-log.md`. Parse iteration count and skip list.

### Step 2 — Dispatch Scanner
Discover project structure dynamically. Rotate scan area through app/package directories based on iteration number (3 iterations per directory, cycling).

Scanner returns: `ISSUE_ID`, `CATEGORY`, `FILE`, `TITLE`, `EVIDENCE`, `FIX_APPROACH`, `RISK`, `AFFECTED_TESTS`, `FILES_TO_CHANGE`.

Categories: `bug`, `dead-code`, `verbose-output`, `error-handling`, `design-smell`, `type-safety`, `naming`, `stale-todo`, `prompt-quality`.

### Step 3 — Safety Gate
Skip if: high risk, auth/billing/webhooks/migrations, >3 files, API shape change, new dependency.

### Step 4 — Dispatch Fixer
Select agent by technology. Minimal fix only, no scope expansion.

### Step 5 — Dispatch Verifier
Run project-specific build/test commands. On failure: revert, log as skipped, end iteration.

### Step 6 — Commit
Stage specific files only. Follow project's commit format.

### Step 7 — Update Tracking
Increment counters, append entry to issues log.

## Invocation

```
/nightshift          # Single pass
/loop 10m /nightshift  # Overnight
```
