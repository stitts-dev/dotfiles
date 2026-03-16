# Global Standards

## Coding Principles

- Avoid writing scripts to complete tasks - find proper solution

## Test Execution

- NEVER run tests directly in the main context -- delegate to a testing subagent to avoid context bloat
- Invoke proactively: after code changes, after fixing lint/type errors, before commits

## Commit Messages

- Format: `TICKET type: description` (max 70 chars, single line ONLY)
- Types: `feat`, `bugfix`, `fixup`, `chore`
- Extract JIRA ticket from branch name (e.g., `EX-1208`)
- NEVER include: "Generated with Claude Code", "Co-Authored-By", emoji, multi-line

Examples:
```
EX-1208 feat: add SIMPLE IRA two-year certification
EX-1092 bugfix: prevent duplicate account creation
```

## Agent Delegation

- Delegate tasks requiring >5 files or specialized knowledge to subagents
- In Plan Mode, ALWAYS delegate investigation to subagents before planning
- Skip delegation for trivial tasks (1-2 line changes) or when context is already loaded
- For multi-file or cross-app tasks, use `/team-director` — it handles agent selection, routing, and roster composition. Do not manually pick subagent_types.

## Browser Automation

- Prefer `agent-browser` CLI over WebFetch/MCP browser tools for JS-rendered pages
- WebFetch is acceptable only for simple static page reads
- Full reference: see browser-automation skill

## Jira Integration

- Primary: `cc-jira TICKET-ID` to load ticket context
- Aliases: `ccj`, `jstd`, `jsearch`, `jq-jira`
- Full reference: see jira-workflow skill

## Completion Gate

Before declaring work complete:
1. `/simplify` — review changed code for reuse, quality, efficiency (may modify code)
2. Build validation: `build-validator` / `build-runner` to verify compilation
3. `superpowers:verification-before-completion` — evidence before assertions
4. If `/simplify` changed code, re-run build validation

For small changes (1-3 files), a single `code-reviewer` suffices instead of full team.

## Learning Workflow

- Run `/retrospective` after significant sessions
- Log failures with failure-tracker skill

## Agentic Development Patterns

These patterns emerged from intensive multi-agent development and apply across projects:

### Makefile as Agent Interface
Projects should expose `make stop`, `make dev`, `make restart-dev`, `make wait-ready`, `make api-smoke` (or equivalent). Agents call Make targets, never raw `lsof`/`kill`/`cargo run`/`uvicorn`. This prevents port conflicts, missed cleanup, and shell-specific failures.

### File-Handoff Orchestration
Multi-agent work uses `.planning/{dir}/` files for inter-agent communication, not context passing. Prevents context overflow on 5+ agent runs. Each agent writes structured output to a known path; the next agent reads it.

### Hookify Discipline
Use hookify rules to block deprecated commands, warn on anti-patterns, and auto-lint on save. Projects should define their own rules for project-specific forbidden patterns.

### Sub-Agent Discipline
- Explicit file ownership per agent — no two agents edit the same file
- No scope expansion — agents ONLY modify files listed in their task
- Must compile/lint before reporting completion
- Use built-in tools (Read/Grep/Glob/Edit), not shell equivalents (cat/grep/find/sed)
- Verify agent file writes — agents may report success without writing code. Always grep for key identifiers after agent completes.

### Hypothesis-First Debugging
Before editing: (1) state which file/component you'll modify, (2) your hypothesis for root cause, (3) how you'll verify. Rank 3 possible causes by likelihood, cheapest check first. Do not start fixing until root cause is confirmed.

### Commit Before Side Effects
`db.commit()` (or equivalent) the primary record before calling side-effect functions that manage their own transactions. Prevents transaction isolation bugs in service-to-service flows where flushed-but-uncommitted rows are invisible to other services.
