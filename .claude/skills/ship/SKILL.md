---
description: "Review changes, create focused commits, and push. Use when user says 'ship this', 'commit and push', 'review my changes', or 'ship it'."
argument-hint: "[branch-name]"
---

# Ship Workflow

Review all local changes, organize into focused commits, and push.

## Steps

1. **Survey**: `git status` + `git diff` (staged + unstaged)
2. **Match style**: `git log --oneline -10` for commit message conventions
3. **Group logically**: Separate commits per concern (backend/frontend/docs/etc.)
4. **Validate**: Run project-specific build/lint/test commands (check CLAUDE.md or Makefile)
5. **Commit**: Focused, atomic commits with conventional prefixes
6. **Push**: `git push -u origin HEAD`
7. **Report**: Summarize what shipped

## Commit Format

`type(scope): description` — single line, max 70 chars, no emoji.

Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`, `style`, `build`, `ci`, `revert`

JIRA ticket prefix if on branch name: `EX-1208 feat: ...`

Follow project's CLAUDE.md commit format when specified (takes precedence).

## Rules

- No .env/credentials/secrets in commits
- No amend or force-push unless explicitly asked
- Fix pre-commit hook failures with NEW commits
- If `$ARGUMENTS[0]` provided, create/checkout that branch first
- Split when 3+ unrelated concerns. Prefer atomic commits.
