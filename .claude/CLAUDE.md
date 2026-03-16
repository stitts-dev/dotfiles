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
