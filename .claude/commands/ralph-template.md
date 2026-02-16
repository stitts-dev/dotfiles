---
description: Generate a context-aware ralph-loop prompt based on current project
allowed-tools: ["Read", "Glob", "Grep", "LSP", "mcp__taskmaster-ai__get_tasks", "mcp__taskmaster-ai__next_task"]
---

# Ralph-Loop Prompt Generator

Analyze the current project and generate a ready-to-use ralph-loop command.

## Steps

1. **Read project context:**
   - Read CLAUDE.md for project overview, tech stack, requirements
   - Check for taskmaster tasks (if .taskmaster/ or workstreams/*/.taskmaster/ exists, call get_tasks)
   - Scan project structure for key directories/patterns (package.json, Makefile, etc.)

2. **Identify actionable work:**
   - Pending/in-progress taskmaster tasks (use next_task)
   - Test commands (pnpm test, npm test, pytest, make test, npx playwright test, etc.)
   - Build commands (pnpm build, npm run build, make build, etc.)
   - Lint/type check commands (pnpm lint, tsc, eslint, etc.)

3. **Generate contextual prompt:**

Based on your analysis, output:

## Generated Ralph-Loop Prompt

Based on analysis of your project:
- [Summary of what you found: taskmaster workstream, test commands, key files]
- [Next task or priority work identified]
- [Verification command(s) discovered]

**Copy and run:**

```
/ralph-loop "[SPECIFIC_TASK_FROM_PROJECT - be detailed and actionable]

Steps:
1. [PROJECT_SPECIFIC_SETUP - e.g., Start dev server, install deps]
2. [PROJECT_SPECIFIC_FIRST_ACTION]
3. [PROJECT_SPECIFIC_SECOND_ACTION]
...
N. [ACTUAL_VERIFICATION_COMMAND - e.g., npx playwright test, pnpm test, make test]
N+1. If issues found, analyze error and fix
N+2. Repeat steps N-(N+1) until passing
N+3. [FINAL_VERIFICATION - e.g., Run 3x to confirm no flaky tests]

Completion criteria:
- [PROJECT_SPECIFIC_CRITERION_1]
- [PROJECT_SPECIFIC_CRITERION_2]
- [PROJECT_SPECIFIC_CRITERION_3]

When complete, output: <promise>[PROMISE]</promise>" --max-iterations [N] --completion-promise "[PROMISE]"
```

## Guidelines for generated prompt

- **Task**: Pull from taskmaster next_task or most relevant pending work
- **Steps**: Use ACTUAL project commands discovered (not placeholders)
- **Verification**: Use REAL test/build commands found in project
- **Iterations**: Simple=15, Medium=30, Complex=50
- **Promise**: Short phrase matching task (TESTS PASSING, BUILD COMPLETE, FEATURE DONE, etc.)

## Important

- DO NOT output a generic template with placeholders
- MUST read and analyze the actual project before generating
- The output should be a COMPLETE, ready-to-copy-paste command
- Include brief explanation of WHY you chose these specific steps
