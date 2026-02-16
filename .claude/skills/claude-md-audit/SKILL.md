---
name: claude-md-audit
description: Agent-powered CLAUDE.md audit and generation using parallel subagents for deep codebase analysis
version: 1.0.0
author: system
tags: [documentation, audit, agents, parallel, claude-md, quality]
---

# CLAUDE.md Audit Skill

## Purpose

Deep codebase analysis using **3 parallel Explore agents** to audit existing CLAUDE.md documentation and generate high-quality, ready-to-use content. Instead of just checking if sections exist, this skill actively analyzes the codebase to produce excellent documentation.

## When to Use

- Starting work on a new/unfamiliar codebase
- Onboarding to a project (generates instant context)
- Periodic documentation health checks
- Before major releases or handoffs
- After significant architectural changes
- When CLAUDE.md feels stale or incomplete

## Process

### Phase 1: Launch Parallel Agents

Launch **3 Explore agents simultaneously** in a single message with multiple Task tool calls:

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Agent 1: WHY │  │ Agent 2: WHAT│  │ Agent 3: HOW │
│              │  │              │  │              │
│ Purpose &    │  │ Architecture │  │ Workflows &  │
│ Business     │  │ & Commands   │  │ Patterns     │
│ Context      │  │              │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
```

#### Agent 1 Prompt (WHY Analyst)

```
Analyze this codebase to understand its PURPOSE and BUSINESS CONTEXT.

Search for and analyze:
- README.md, ABOUT.md, docs/*.md (project descriptions)
- package.json/pom.xml/go.mod description fields
- License files (open-source vs proprietary context)
- Domain-specific terminology in code comments
- API documentation, OpenAPI/Swagger specs
- Any existing CLAUDE.md WHY section

Return a structured analysis with:

## Project Overview
[1-2 sentences: What this project does and what problem it solves]

## Business Domain
[Explain the domain: IRA management, e-commerce, developer tools, etc.]
[Key domain concepts and terminology]

## Target Users
- [User type 1]: [What they do with this system]
- [User type 2]: [What they do with this system]

## Component Purposes
| Component | Purpose |
|-----------|---------|
| [name]    | [what it does] |

## Key Findings
- [Discovery 1]
- [Discovery 2]
```

#### Agent 2 Prompt (WHAT Analyst)

```
Map the TECHNICAL ARCHITECTURE and AVAILABLE COMMANDS for this codebase.

Search for and analyze:
- Manifest files: package.json, pom.xml, go.mod, Cargo.toml, pyproject.toml
- Build configs: Dockerfile, docker-compose.yml, Makefile
- Scripts: scripts/*, bin/*, package.json scripts section
- Version configs: .tool-versions, .nvmrc, .python-version
- Workspace markers: pnpm-workspace.yaml, lerna.json, nx.json
- Config files: tsconfig.json, vite.config.ts, webpack.config.js
- External services: database configs, auth configs, API integrations

Return a structured analysis with:

## Tech Stack
| Technology | Version | Purpose |
|------------|---------|---------|
| [name]     | [x.y.z] | [role]  |

## Project Structure
```

[directory tree with descriptions]

```

## Available Commands
| Command | Description |
|---------|-------------|
| [cmd]   | [what it does] |

## Package Manager
[npm/pnpm/yarn/maven/go mod] - [any special notes]

## Environment Setup
- Prerequisites: [list]
- Setup steps: [numbered list]

## External Services
| Service | Purpose | Config Location |
|---------|---------|-----------------|
| [name]  | [role]  | [file path]     |

## Key Findings
- [Discovery 1]
- [Discovery 2]
```

#### Agent 3 Prompt (HOW Analyst)

```
Extract DEVELOPMENT WORKFLOWS and CODE PATTERNS from this codebase.

Search for and analyze:
- Linter configs: .eslintrc*, .prettierrc*, biome.json, .editorconfig
- Git hooks: .husky/*, .git/hooks/*, commitlint.config.js
- Test files: *.spec.ts, *.test.ts, *_test.go, *Test.java
- CI/CD: .github/workflows/*, .gitlab-ci.yml, Jenkinsfile
- Contributing guides: CONTRIBUTING.md, CODE_OF_CONDUCT.md
- Claude configs: .claude/ directory (agents, skills, hooks, settings)
- Code patterns: auth middleware, error handlers, logging utilities

Return a structured analysis with:

## Code Style
| Rule | Setting | Source |
|------|---------|--------|
| [rule] | [value] | [config file] |

[Key conventions: imports, naming, etc.]

## Testing Requirements
- Framework: [vitest/jest/go test/junit]
- Coverage requirement: [X%]
- Test patterns: [describe common patterns]
- Run command: [how to run tests]

## Git Workflow
- Branch naming: [pattern]
- Commit format: [conventional commits, etc.]
- PR requirements: [reviews, checks, etc.]

## CI/CD Pipeline
[Describe the pipeline stages and checks]

## Gotchas & Warnings
- [Gotcha 1]: [Why it matters, how to avoid]
- [Gotcha 2]: [Why it matters, how to avoid]

## Agent/Skill Usage (if .claude/ exists)
| Agent/Skill | When to Use |
|-------------|-------------|
| [name]      | [trigger]   |

## Key Findings
- [Discovery 1]
- [Discovery 2]
```

### Phase 2: Synthesize Results

After all 3 agents complete:

1. **Read existing CLAUDE.md** (if any)
2. **Compare agent findings** to documented content
3. **Calculate completeness scores** per pillar
4. **Generate gap analysis** (found vs documented)
5. **Produce ready-to-use content** from agent analyses

## Scoring Framework

### Pillar Weights

| Pillar   | Weight | Focus                                             |
| -------- | ------ | ------------------------------------------------- |
| **WHY**  | 25pts  | Purpose, business context, component descriptions |
| **WHAT** | 35pts  | Tech stack, structure, commands, environment      |
| **HOW**  | 40pts  | Code style, workflows, gotchas, testing           |

### Scoring Criteria

```
Pillar Score = (Documented Items / Agent-Discovered Items) × Pillar Weight

Total Score = WHY Score + WHAT Score + HOW Score

Grade Scale:
A (90-100): Comprehensive, matches codebase reality
B (80-89):  Good coverage, minor gaps
C (70-79):  Adequate, missing some important items
D (60-69):  Incomplete, significant gaps
F (<60):    Missing or severely outdated
```

### Item Scoring

**WHY items** (5 pts each):

- Project overview/mission
- Business domain explanation
- Component purpose descriptions
- Problem/solution context
- Target users/stakeholders

**WHAT items** (variable):

- Tech stack with versions (5)
- Project structure tree (5)
- Key directories explained (5)
- Common commands documented (5)
- Package manager specified (3)
- Build/test/lint commands (5)
- Environment setup (4)
- External services (3)

**HOW items** (variable):

- Code style guidelines (8)
- Import conventions (4)
- Error handling patterns (5)
- Testing requirements (5)
- Git workflow (5)
- Gotchas/warnings (5)
- Agent usage (4)
- Security considerations (4)

## Output Template

````markdown
## CLAUDE.md Audit Report

**Project**: {project-name}
**Detected Stack**: {primary technologies}
**Score**: {X}/100 ({grade})
**Generated**: {date}

### Score Summary

| Pillar    | Score     | Agent Found | Documented | Gap |
| --------- | --------- | ----------- | ---------- | --- |
| WHY       | X/25      | Y items     | Z items    | Y-Z |
| WHAT      | X/35      | Y items     | Z items    | Y-Z |
| HOW       | X/40      | Y items     | Z items    | Y-Z |
| **Total** | **X/100** |             |            |     |

### Critical Gaps (Must Address)

❌ **[Item]**: Agent discovered {finding} but CLAUDE.md doesn't document it.
→ Add: [specific content suggestion]

### High Priority Improvements

🟠 **[Item]**: [What's missing or outdated]
→ [Specific fix]

### Generated Content (Ready to Use)

Copy these sections directly into your CLAUDE.md:

---

#### WHY Section (Agent-Generated)

```markdown
## Project Overview

[Agent 1's project overview content]

## Business Domain

[Agent 1's business domain content]

## Target Users

[Agent 1's target users content]
```
````

---

#### WHAT Section (Agent-Generated)

```markdown
## Tech Stack

[Agent 2's tech stack table]

## Project Structure

[Agent 2's directory tree]

## Commands

[Agent 2's commands table]

## Environment Setup

[Agent 2's setup instructions]
```

---

#### HOW Section (Agent-Generated)

```markdown
## Code Style

[Agent 3's code style content]

## Testing

[Agent 3's testing content]

## Git Workflow

[Agent 3's git workflow content]

## Gotchas & Warnings

[Agent 3's gotchas content]
```

---

### Progressive Disclosure Recommendation

[If total content > 300 lines]

Consider splitting into:

```
CLAUDE.md (< 300 lines)
├── Overview (WHY highlights)
├── Quick Start (key WHAT)
├── Core Rules (key HOW)
└── See Also → agent_docs/

agent_docs/
├── architecture.md (full WHAT)
├── testing.md (testing details)
├── patterns.md (code patterns)
└── workflows.md (CI/CD, deployment)
```

````

## Quick Fix Templates

### Missing WHY Section

```markdown
## Project Overview

{project-name} is a {type: web app/CLI tool/API/library} that {solves X problem} for {target users}.

## Business Domain

This project operates in the {domain} space, handling:
- {Core concept 1}
- {Core concept 2}
- {Core concept 3}

Key terminology:
- **{Term}**: {Definition}
````

### Missing WHAT Section

````markdown
## Tech Stack

| Technology | Version | Purpose     |
| ---------- | ------- | ----------- |
| Node.js    | 22.x    | Runtime     |
| TypeScript | 5.x     | Type safety |
| {Add more} | x.x     | {Purpose}   |

## Quick Start

```bash
# Install dependencies
{package-manager} install

# Start development
{package-manager} run dev

# Run tests
{package-manager} test
```
````

## Project Structure

```
src/
├── {dir}/     # {purpose}
├── {dir}/     # {purpose}
└── {dir}/     # {purpose}
```

````

### Missing HOW Section

```markdown
## Code Style

- {Package manager}: {npm/pnpm/yarn}
- Formatting: {Prettier/ESLint rules}
- Imports: {ES modules/CommonJS, ordering}

## Testing

Run tests: `{command}`
Coverage requirement: {X}%

## Git Workflow

Branch naming: `{type}/{ticket}-{description}`
Commit format: `{TICKET} {type}: {description}`

## Gotchas

- **{Issue}**: {Why it happens} → {How to handle}
````

## Integration

This skill integrates with:

- **`/retrospective`**: Feed audit findings into continuous improvement
- **`skill-registry`**: Discover related skills for detected tech stack
- **`failure-tracker`**: Log documentation debt as failures to address

## Usage Notes

- **Read-only**: This skill never modifies files automatically
- **Copy-paste ready**: All generated content is formatted for direct use
- **Tech-aware**: Adapts checklist items based on detected project type
- **Parallel execution**: Always launch all 3 agents in a single message

## Changelog

### v1.0.0 (2025-01-15)

- Initial version
- 3-agent parallel architecture (WHY, WHAT, HOW)
- Scoring framework with 100-point scale
- Tech-aware detection for Node.js, Java, Go, Python, Rust
- Ready-to-use content generation
- Progressive disclosure recommendations

## Failure Log

<!-- Template for tracking issues with this skill -->
<!--
### [Date] - [Brief Title]
**Context**: What was being audited
**Failure**: What went wrong
**Cause**: Root cause
**Solution**: How it was resolved
**Prevention**: Updates to make
-->
