---
name: retrospective
description: Structured process for extracting learnings from Claude Code sessions
version: 1.0.0
author: system
tags: [learning, improvement, documentation]
---

# Retrospective Skill

## Purpose

Extract actionable learnings from Claude Code sessions and persist them in skills for future use. This enables continuous improvement by capturing what worked, what failed, and what patterns emerged.

## When to Use

- After completing a significant feature or task
- When you encountered unexpected challenges or failures
- After discovering a new working pattern
- At the end of a productive session
- When a code review identifies missed patterns

## Full Learning Workflow

### Pre-Task

- Run `/query-skills [task-description]` to discover relevant skills
- Review known failures before starting
- Apply established patterns where applicable

### During-Task

- Note significant decisions and their outcomes
- Capture working configurations immediately
- Document failures as they occur

### Post-Task

- Run `/retrospective` to trigger the process below
- Update skills with new patterns discovered
- Log failures with `failure-tracker` skill
- Use `@agentic-documenter` for complex learnings

### Key Commands

- `/query-skills [task]` - Discover relevant skills and known patterns
- `/retrospective` - Extract learnings and update skills
- `/review` - Comprehensive end-of-session review

### Skill Locations

- `~/.claude/skills/` - Global user skills
- `.claude/skills/` - Project-specific skills
- Plugins with skills - Installed via marketplace

## Process

### Step 1: Analyze Session

Review the session transcript and identify:

- **Tasks completed**: What work was accomplished?
- **Challenges faced**: What obstacles were encountered?
- **Solutions found**: How were problems resolved?
- **Tools/agents used**: Which were effective?

### Step 2: Categorize Learnings

Classify discoveries into categories:

#### Successes

- Patterns that worked well
- Effective tool/agent combinations
- Efficient workflows discovered

#### Failures

- Approaches that didn't work
- Common mistakes made
- Edge cases encountered

#### Patterns

- Reusable solutions
- Best practices identified
- Anti-patterns to avoid

#### Edge Cases

- Unusual scenarios
- Boundary conditions
- Environment-specific issues

### Step 3: Update Skills

For each learning, determine:

1. Which skill should contain this knowledge?
2. Should a new skill be created?
3. What section should be updated?
    - "Known Patterns" for successes
    - "Failure Log" for failures
    - "Examples" for edge cases

### Step 4: Document

Apply updates using this format:

**For Pattern Updates:**

```markdown
### [Pattern Name]

**Context**: When this applies
**Pattern**: What to do
**Example**: Code or command example
**Why**: Explanation of benefits
```

**For Failure Log Entries:**

```markdown
### [Date] - [Brief Title]

**Context**: What was being attempted
**Failure**: What went wrong
**Cause**: Root cause if identified
**Solution**: How it was resolved
**Prevention**: How to avoid in future
```

## Output Format

After running a retrospective, provide:

```markdown
## Session Retrospective

### Accomplishments

- [List of completed tasks]

### Key Learnings

1. [Learning 1 with context]
2. [Learning 2 with context]

### Skill Updates Proposed

| Skill        | Section   | Update              |
| ------------ | --------- | ------------------- |
| [skill-name] | [section] | [brief description] |

### Failures Documented

- [Failure 1]: Added to [skill-name]

### Follow-up Actions

- [ ] [Action item 1]
- [ ] [Action item 2]
```

## Integration

This skill works with:

- `/retrospective` command - triggers this process
- `/review` command - comprehensive version with @agentic-documenter
- `failure-tracker` skill - routes failures appropriately
- `skill-registry` skill - discovers skills to update

## Changelog

### v1.0.0 (2024-12-31)

- Initial version
- 4-step process (Analyze, Categorize, Update, Document)
- Integration with commands and other skills

## Failure Log

<!-- Template for failure entries -->
<!--
### [Date] - [Brief Title]
**Context**: What was being attempted
**Failure**: What went wrong
**Cause**: Root cause if identified
**Solution**: How it was resolved
**Prevention**: How to avoid in future
-->
