---
name: skill-registry
description: Inventory and discovery system for all available Claude Code skills
version: 1.0.0
author: system
tags: [discovery, registry, organization]
---

# Skill Registry

## Purpose

Maintain an inventory of all available skills and enable pre-task discovery of relevant knowledge. This ensures that existing skills are utilized before starting work.

## Skill Locations

Skills can exist in multiple locations (checked in order):

1. **User-level skills**: `~/.claude/skills/*/SKILL.md`
2. **Project-level skills**: `.claude/skills/*/SKILL.md`
3. **Plugin skills**: Installed via `claude plugins`

## Discovery Commands

### List All Skills

```bash
# User-level skills
ls -d ~/.claude/skills/*/SKILL.md 2>/dev/null

# Current project skills
ls -d .claude/skills/*/SKILL.md 2>/dev/null

# Plugin skills (check plugin directories)
ls ~/.claude/plugins/*/skills/*/SKILL.md 2>/dev/null
```

### Search Skills by Tag

```bash
grep -l "tags:.*\[.*database.*\]" ~/.claude/skills/*/SKILL.md .claude/skills/*/SKILL.md 2>/dev/null
```

### Search Skills by Content

```bash
grep -rl "graphql" ~/.claude/skills/ .claude/skills/ 2>/dev/null
```

## Pre-Task Workflow

Before starting a task, use `/query-skills [task]` to:

1. **Identify relevant skills** based on task keywords
2. **Load skill content** into context
3. **Review known failures** for similar tasks
4. **Apply established patterns** from the start

## Skill Categories

### Development Skills

- Backend architecture patterns
- Frontend component patterns
- Database schema analysis
- API design patterns

### Workflow Skills

- Git/GitHub operations
- Jira integration
- Code review processes
- PR management

### Learning Skills

- Retrospective processes
- Failure tracking
- Pattern documentation
- Skill creation

### Project-Specific Skills

- Technology-specific patterns
- Codebase conventions
- Team practices

## Skill Metadata

Each skill should include YAML frontmatter:

```yaml
---
name: skill-name
description: Brief description
version: 1.0.0
author: system|username
tags: [tag1, tag2, tag3]
---
```

## Registry Index

### Global Skills (~/.claude/skills/)

| Skill                              | Description                         | Tags                                 |
| ---------------------------------- | ----------------------------------- | ------------------------------------ |
| retrospective                      | Session learning extraction         | learning, improvement                |
| skill-registry                     | Skill discovery system              | discovery, organization              |
| failure-tracker                    | Systematic failure documentation    | failures, learning                   |
| playwright-manual-testing-workflow | Playwright MCP manual testing guide | testing, playwright, mcp, automation |

### Project Skills (.claude/skills/)

Varies by project. Run discovery commands to enumerate.

## Maintenance

### Adding New Skills

1. Create directory: `mkdir ~/.claude/skills/[skill-name]`
2. Create SKILL.md with YAML frontmatter
3. Include standard sections:
    - Purpose
    - When to Use
    - Process/Instructions
    - Examples
    - Failure Log

### Updating Skills

1. Use `/retrospective` to identify updates
2. Edit the relevant SKILL.md
3. Update version in frontmatter
4. Add changelog entry

### Deprecating Skills

1. Add `deprecated: true` to frontmatter
2. Add deprecation notice at top of skill
3. Reference replacement skill if applicable

## Integration

Works with:

- `/query-skills` command - primary interface
- `retrospective` skill - identifies skills to update
- `failure-tracker` skill - routes failures to correct skill

## Changelog

### v1.0.0 (2024-12-31)

- Initial version
- Discovery commands
- Pre-task workflow
- Registry index

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
