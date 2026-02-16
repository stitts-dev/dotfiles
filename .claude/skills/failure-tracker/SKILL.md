---
name: failure-tracker
description: Systematic tracking and documentation of failures for learning
version: 1.0.0
author: system
tags: [failures, learning, prevention]
---

# Failure Tracker Skill

## Purpose

Systematically capture failures encountered during Claude Code sessions to prevent recurrence. LLMs are non-deterministic - documenting failures ensures the same mistakes aren't repeated.

## When to Log Failures

Log a failure when:

- An approach didn't work after significant effort
- You encountered an unexpected error or edge case
- A pattern you expected to work failed
- A tool or agent didn't behave as expected
- Code review identified a missed pattern
- Tests failed due to incorrect assumptions

## Failure Categories

### Code Failures

- Syntax or type errors
- Logic errors
- Integration failures
- Performance issues

### Pattern Failures

- Wrong pattern applied
- Pattern doesn't fit context
- Missing edge case handling

### Tool/Agent Failures

- Wrong tool selected
- Agent produced incorrect output
- Unexpected tool behavior

### Environment Failures

- Configuration issues
- Dependency problems
- Platform-specific issues

### Process Failures

- Skipped validation steps
- Incorrect sequence of operations
- Missing prerequisites

## Standard Log Format

```markdown
### [Date] - [Brief Title]

**Category**: [Code|Pattern|Tool|Environment|Process]
**Context**: What was being attempted
**Failure**: What went wrong
**Cause**: Root cause if identified
**Solution**: How it was resolved
**Prevention**: How to avoid in future
**Skill**: [skill to update, if applicable]
```

## Routing Failures

Determine where to log each failure:

### Global Failures → `~/.claude/skills/failure-tracker/SKILL.md`

- Generic failures applicable across projects
- Tool/agent behavior issues
- Claude Code configuration issues

### Skill-Specific Failures → `[skill]/SKILL.md` Failure Log

- Failures related to a specific domain
- Pattern-specific edge cases
- Technology-specific issues

### Project Failures → `.claude/skills/[skill]/SKILL.md`

- Codebase-specific issues
- Project configuration problems
- Team convention violations

## Failure Analysis Process

1. **Identify**: What exactly failed?
2. **Understand**: Why did it fail?
3. **Categorize**: What type of failure?
4. **Route**: Which skill should contain this?
5. **Document**: Write the failure log entry
6. **Prevent**: Add prevention guidance

## Example Entries

### Global Failure Example

```markdown
### 2024-12-31 - RTK Query Hook Generation Timeout

**Category**: Tool
**Context**: Running `pnpm api:generate` in unified-portal/ui
**Failure**: Generation hung indefinitely with no output
**Cause**: Schema file was malformed JSON (trailing comma)
**Solution**: Fixed schema.graphql formatting, regenerated
**Prevention**: Always validate schema JSON before generation
**Skill**: None (global issue)
```

### Skill-Specific Failure Example

```markdown
### 2024-12-31 - ActionService Missing Tenant Context

**Category**: Pattern
**Context**: Creating new GraphQL mutation using ActionService pattern
**Failure**: Mutation returned empty results for valid queries
**Cause**: Forgot to pass tenantId in service call
**Solution**: Added tenantId parameter from GraphQL context
**Prevention**: ActionService checklist item: verify tenant context
**Skill**: backend-architecture-pattern-discovery
```

## Integration

This skill integrates with:

- `/retrospective` command - identifies failures to log
- `retrospective` skill - routes failures here
- `skill-registry` skill - finds skills to update

## Prevention Checklist

Before committing work, verify:

- [ ] No known failure patterns violated
- [ ] Edge cases from failure log considered
- [ ] Similar past failures reviewed
- [ ] Prevention guidance applied

## Global Failure Log

This section contains failures not specific to any skill:

<!-- Template for failure entries -->
<!--
### [Date] - [Brief Title]
**Category**: [Code|Pattern|Tool|Environment|Process]
**Context**: What was being attempted
**Failure**: What went wrong
**Cause**: Root cause if identified
**Solution**: How it was resolved
**Prevention**: How to avoid in future
-->

## Changelog

### v1.0.0 (2024-12-31)

- Initial version
- Failure categories defined
- Routing logic established
- Standard log format created
