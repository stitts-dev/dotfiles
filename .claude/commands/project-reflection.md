---
description: Analyze session to identify CLAUDE.md improvements from misunderstandings and missing context
tags: [improvement, documentation, learning]
---

# Project Reflection

Analyze the current session to continuously improve CLAUDE.md. This differs from `/retrospective` (which focuses on skills) by specifically targeting CLAUDE.md improvements.

## Process

### Step 1: Analyze Session

Review the conversation and identify:

1. **Misunderstandings**: Where did Claude make incorrect assumptions?
2. **Missing Context**: What information would have helped?
3. **Over-Engineering**: Where did Claude add unnecessary complexity?
4. **Repeated Clarifications**: What did the user have to explain multiple times?

### Step 2: Categorize Findings

Group discoveries into:

- **Gotchas & Warnings**: Unexpected behaviors, edge cases, things to avoid
- **Project Context**: Business logic, domain knowledge, architectural decisions
- **Code Patterns**: Preferred approaches, anti-patterns to avoid
- **Tool/Workflow**: Commands, build steps, environment specifics

### Step 3: Generate CLAUDE.md Additions

For each finding, create specific, actionable text to add:

```markdown
## Finding: [Brief Title]

**Issue**: [What went wrong]
**Root Cause**: [Why it happened - missing context]
**CLAUDE.md Addition**:

> [Exact text to add to CLAUDE.md]

**Section**: [Where to add it - e.g., "Gotchas & Warnings", "Code Style"]
```

### Step 4: Present Results

Output a structured report:

```markdown
## Reflection Analysis - [Date]

### Misunderstandings Found

| Issue | What Claude Assumed | Correct Behavior | Proposed Addition |
| ----- | ------------------- | ---------------- | ----------------- |
| ...   | ...                 | ...              | ...               |

### Missing Context

- [Context 1]: [Where to add in CLAUDE.md]
- [Context 2]: [Where to add in CLAUDE.md]

### Over-Engineering Patterns

- [Pattern]: [Prevention rule to add]

### Ready-to-Apply Edits

[Copy-paste ready markdown for each addition]
```

## What to Look For

**Strong signals of missing CLAUDE.md context:**

- User said "actually, we do X not Y"
- Claude proposed a solution that violated project conventions
- Multiple back-and-forth to clarify requirements
- Claude asked about something documented elsewhere
- User provided information that should be persistent

**Over-engineering indicators:**

- Added error handling for impossible scenarios
- Created abstractions for one-time use
- Added configuration for things that won't change
- Refactored code that wasn't asked to be changed

## Output Requirements

- Be specific: "Add to Gotchas section" not "Consider documenting"
- Be actionable: Provide exact text to add, not summaries
- Be conservative: Only propose additions for clear gaps
- Respect existing structure: Match CLAUDE.md formatting

## Integration

After running this command:

1. Review proposed additions with user
2. Apply approved changes to CLAUDE.md
3. Consider if any findings should go to skills instead (use `/retrospective`)
