---
name: sync-fix
description: Fix dotfiles sync issues — pull changes, restow, install missing plugins, merge settings template. Runs in background.
version: 1.0.0
tags: [dotfiles, sync, maintenance, fix]
---

# Sync Fix

Resolve all dotfiles sync issues in a single pass. Dispatch a background agent to handle the fixes while the user continues working.

## Process

### Step 1: Run `/sync-status` first

Before fixing anything, invoke the `sync-status` skill to get the current state. If you already have recent sync-status output from this session, skip this step.

### Step 2: Dispatch background fix agent

Launch an Agent with `run_in_background: true` to perform the fixes. The agent should run the following steps sequentially, stopping on critical failures.

**Agent prompt template:**

```
You are fixing dotfiles sync issues. Run each step sequentially. Report results as JSON.

Step 1 — Pull latest dotfiles:
  cd ~/.dotfiles && git stash && git pull --rebase origin main && git stash pop 2>/dev/null || true

Step 2 — Restow symlinks:
  cd ~/.dotfiles && stow --restow --target ~ .

Step 3 — Install missing plugins:
  bash ~/.claude/hooks/sync-plugins.sh --import

Step 4 — Export new plugins to plugins.txt:
  bash ~/.claude/hooks/sync-plugins.sh --export

Step 5 — Merge settings template:
  bash ~/.dotfiles/setup-claude.sh

Step 6 — Verify fix:
  bash ~/.claude/hooks/sync-check.sh

After each step, report what changed. If step 1 has merge conflicts, STOP and report — do not force resolve.
```

### Step 3: Report results

When the background agent completes, summarize:

```markdown
## Sync Fix Results

| Step | Status | Details |
|------|--------|---------|
| Git pull | OK / CONFLICT | pulled 3 commits |
| Stow restow | OK / WARN | 2 new symlinks created |
| Plugin install | OK | installed 1 missing plugin |
| Plugin export | OK | added 0 new to plugins.txt |
| Settings merge | OK | added SessionStart hook |
| Verification | CLEAN / DRIFT | (remaining issues) |

### Remaining Issues
- (any issues that couldn't be auto-fixed)

### Manual Steps Needed
- (e.g., resolve merge conflicts, re-authenticate gh CLI)
```

## Safety

- **Git conflicts**: Do NOT force-resolve. Stash local changes, attempt rebase. If conflicts arise, stop and report.
- **Settings merge**: The setup-claude.sh script is additive — it won't remove existing config.
- **Plugin install**: Idempotent — safe to re-run.
- **Stow restow**: Will warn on conflicts but won't overwrite non-symlinked files.

## When to Use

- After `/sync-status` shows issues
- When switching machines (first session of the day)
- After pulling dotfiles changes manually
- When the SessionStart hook reports drift
