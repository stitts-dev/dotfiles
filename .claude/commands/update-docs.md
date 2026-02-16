---
description: Auto-generate documentation updates (README, CHANGELOG, API docs) after completing features
tags: [documentation, automation, changelog]
---

# Update Documentation

Generate documentation updates based on work completed in this session. Use after finishing features, bug fixes, or significant changes.

## Process

### Step 1: Summarize Session Changes

Analyze the conversation to identify:

- **Features added**: New functionality implemented
- **Bugs fixed**: Issues resolved
- **APIs changed**: New/modified endpoints, GraphQL types
- **Breaking changes**: Anything requiring migration
- **Dependencies**: New packages added

### Step 2: Identify Docs to Update

Check which documentation files exist and need updates:

| Doc Type     | Common Paths                             | Update Trigger              |
| ------------ | ---------------------------------------- | --------------------------- |
| README       | `README.md`, `*/README.md`               | New features, setup changes |
| CHANGELOG    | `CHANGELOG.md`                           | Any release-worthy change   |
| API Docs     | `docs/api/`, `openapi.yaml`              | Endpoint changes            |
| Architecture | `docs/architecture.md`, `.agent/System/` | Pattern changes             |

### Step 3: Read Existing Structure

Before generating updates:

1. Read the target documentation file
2. Understand its format and conventions
3. Identify where new content should go
4. Match existing style (headers, bullet format, etc.)

### Step 4: Generate Updates

For each doc that needs updating, provide:

```markdown
## [Doc Name] Update

**File**: `[path/to/doc.md]`
**Section**: [Where to add]

### Proposed Addition:

[Ready-to-paste markdown matching existing format]

### Alternative (if structure varies):

[Backup option if first doesn't fit]
```

## CHANGELOG Format

Use Keep a Changelog format (https://keepachangelog.com):

```markdown
## [Unreleased]

### Added

- New feature description with context

### Changed

- Modified behavior with before/after

### Fixed

- Bug fix with issue reference if applicable

### Removed

- Removed feature with migration note
```

## README Updates

Focus on:

- Feature list (if new capability)
- Usage examples (if API changed)
- Setup instructions (if deps changed)
- Quick start (if workflow changed)

## API Documentation

For endpoint changes, include:

- Request/response examples
- Parameter descriptions
- Authentication requirements
- Error responses

## Output Format

```markdown
# Documentation Updates - [Date]

## Summary

- [Brief description of what changed]

## CHANGELOG.md

**Location**: Under `## [Unreleased]` section

### Added

- [Feature description]

---

## README.md

**Location**: [Specific section]

[Ready-to-paste content]

---

## [Other Doc]

**Location**: [Section]

[Content]
```

## Best Practices

- **Non-destructive**: Propose additions, don't overwrite existing content
- **Context-aware**: Match existing formatting and conventions
- **Concise**: Document what changed and why, not implementation details
- **User-focused**: Write for someone who didn't work on this feature

## Integration

For complex documentation updates, delegate to `@documentation-updater` agent:

- Multi-file updates
- Migration guides
- API reference regeneration
- Architecture diagram updates
