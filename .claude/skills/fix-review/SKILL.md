---
name: fix-review
description: "Triage and fix PR review comments with deep evaluation. Use when user says 'fix review', 'fix comments', 'address review', 'fix pr comments', or 'triage review'."
argument-hint: "[PR number]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, AskUserQuestion
model: opus
---

# Fix Review — PR Comment Triage & Fix Workflow

Fetch PR review comments, deeply evaluate each one (not blind acceptance), fix real issues with TDD, push from worktree.

## Phase 1: Gather Comments

### 1a. Detect PR

If `$ARGUMENTS[0]` is a number, use it as the PR number. Otherwise auto-detect:

```bash
gh pr view --json number,url,headRefName,baseRefName
```

Store: `PR_NUMBER`, `OWNER/REPO`, `HEAD_BRANCH`, `BASE_BRANCH`.

### 1b. Fetch Comments

Run both in parallel:

```bash
gh api repos/{owner}/{repo}/pulls/{PR_NUMBER}/comments --paginate
gh api repos/{owner}/{repo}/issues/{PR_NUMBER}/comments --paginate
```

### 1c. Parse & Group

Parse JSON into structured list per comment. Group by thread (via `in_reply_to_id`) then by file path. Filter out resolved threads and bot summary comments.

Write to `.planning/review/pr-{PR_NUMBER}-comments.md`.

## Phase 2: Deep Triage (Parallel Agents)

Group files into 1-3 batches. Dispatch one `general-purpose` agent per batch (sonnet, background).

Classification rubric:
- **REAL_BUG** — Genuine correctness issue → Fix with TDD
- **REAL_QUALITY** — Real improvement (perf, readability) → Fix directly
- **STYLE_NIT** — Preference/style, no functional impact → Skip unless trivial
- **FALSE_POSITIVE** — Reviewer lacks context → Skip with reasoning
- **NEEDS_DISCUSSION** — Valid concern, unclear fix → Flag for user

Agents write to `.planning/review/triage-{GROUP}.md`.

Do NOT blindly agree with reviewers. Verify claims against actual code. Be skeptical of automated reviewers.

## Phase 3: Present Findings

Merge triage files into summary table grouped by classification. Ask user:
- "Fix all real issues" — REAL_BUG + REAL_QUALITY
- "Fix bugs only" — REAL_BUG only
- "Cherry-pick" — user selects
- "Report only" — no fixes

## Phase 4: Fix in Worktree

Create worktree at `.claude/worktrees/fix-review-pr-{PR_NUMBER}`. Dispatch fix agents (opus, background) per technology group.

For REAL_BUG: TDD cycle (failing test → fix → green → suite passes).
For REAL_QUALITY: apply improvement, verify no regressions.

Agents write results to `.planning/review/fixes-{GROUP}.md`.

## Phase 5: Verify & Push

Run project-specific build/test commands from CLAUDE.md or Makefile. Commit following project conventions. Push. Present summary. Offer worktree cleanup.

## Rules

- Triage agents: `model: "sonnet"`. Fix agents: `model: "opus"`.
- ALL fix work in worktree, never main directory
- Do NOT skip TDD for REAL_BUG fixes
- Do NOT commit secrets or force-push
- File handoff: `comments.md → triage-*.md → fixes-*.md`
