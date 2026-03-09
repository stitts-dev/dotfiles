# Global Standards

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

### Agent Selection by Task Type

| Task | Agent(s) |
|------|----------|
| Codebase exploration | `Explore` subagent_type |
| Implementation planning | `Plan` subagent_type |
| Frontend (unified-portal) | `unified-ui-builder`, `react-mui-consultant` |
| Frontend (general React) | `frontend-developer` |
| Backend/API design | `backend-architect` |
| TypeScript type issues | `typescript-pro` or `typescript-expert` |
| Database investigation | `database-expert` (MCP), `database-schema-analyst` |
| Build validation | `build-validator` or `build-runner` |
| Test execution | `test-runner` |
| Security review | `security-specialist` |
| Performance analysis | `performance-analyzer` |
| Git/PR operations | `git-github-expert` |
| Debugging | `debugger` |
| Documentation | `documentation-updater` |
| Research/docs lookup | `research-specialist` |

## Code Review Agents

Multiple review agents are available — use them in parallel for comprehensive coverage:

| Agent | Focus | When to Use |
|-------|-------|-------------|
| `code-simplifier:code-simplifier` | Reuse, quality, efficiency | First pass — may change code |
| `code-reviewer` | Quality, security, maintainability | General-purpose review |
| `feature-dev:code-reviewer` | Bugs, logic errors, conventions | Feature implementation review |
| `coderabbit:code-reviewer` | AI-powered deep analysis | PR-level or large changesets |
| `superpowers:code-reviewer` | Plan adherence, requirements | After completing a plan step |

### Dispatch Pattern

For significant changes (>3 files or new features), dispatch reviews as a team:

1. `code-simplifier:code-simplifier` — runs first (may modify code)
2. If code-simplifier changed code, re-stage changes
3. In parallel: `feature-dev:code-reviewer` + `coderabbit:code-reviewer` + `security-specialist`
4. `superpowers:code-reviewer` — final check against plan/requirements

For small changes (1-3 files), a single `code-reviewer` suffices.

## Complex Features

- For features spanning 5+ files or multiple layers (UI, service, API, tests), use `TeamCreate` to parallelize work
- Break the feature into independent subtasks and dispatch concurrent subagents via `Agent` tool
- Assign each teammate a specific `subagent_type` matching their task (see Agent Selection table)
- After implementation, run the Code Review Agents dispatch pattern before declaring complete
- Coordinate results and resolve conflicts in the main orchestrator context

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
1. Code review agents: follow dispatch pattern in "Code Review Agents" section above
2. build-validator + build-runner: verify compilation (run in parallel with reviews after step 1)
3. verify-app: confirm feature works end-to-end (always last)

If code-simplifier makes changes, re-run build validation and review agents against the updated code. Do not claim completion until all checks pass. The superpowers `verification-before-completion` evidence discipline applies within each agent run -- no success claims without fresh verification output.

## Learning Workflow

- Run `/retrospective` after significant sessions
- Log failures with failure-tracker skill
