---
description: Agent-powered CLAUDE.md audit with parallel codebase analysis
tags: [documentation, audit, agents, quality]
---

# CLAUDE.md Audit

Deep analysis of your codebase using **3 parallel Explore agents** to audit existing documentation and generate high-quality, ready-to-use content.

## Instructions

### Phase 1: Launch Parallel Agents

Launch all 3 agents **in a single message** with multiple Task tool calls:

**Agent 1 (WHY Analyst)**:

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
- Project Overview (1-2 sentences: what it does, what problem it solves)
- Business Domain (explain the domain, key concepts, terminology)
- Target Users (who uses this, what they do with it)
- Component Purposes (table: component → purpose)
- Key Findings (discoveries relevant to WHY)
```

**Agent 2 (WHAT Analyst)**:

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
- Tech Stack (table: technology, version, purpose)
- Project Structure (directory tree with descriptions)
- Available Commands (table: command → description)
- Package Manager (which one, any special notes)
- Environment Setup (prerequisites, setup steps)
- External Services (table: service, purpose, config location)
- Key Findings (discoveries relevant to WHAT)
```

**Agent 3 (HOW Analyst)**:

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
- Code Style (table: rule, setting, source file)
- Testing Requirements (framework, coverage, patterns, run command)
- Git Workflow (branch naming, commit format, PR requirements)
- CI/CD Pipeline (stages, checks)
- Gotchas & Warnings (issues and how to avoid them)
- Agent/Skill Usage (if .claude/ exists: table of agents/skills)
- Key Findings (discoveries relevant to HOW)
```

### Phase 2: Synthesize Results

After all agents complete:

1. **Read existing CLAUDE.md** (if present in project root)

2. **Compare agent findings** to documented content:
    - WHY: Does existing doc match discovered business context?
    - WHAT: Are all tech stack items and commands documented?
    - HOW: Does it reflect actual patterns and workflows?

3. **Calculate scores**:
    - WHY: X/25 points
    - WHAT: X/35 points
    - HOW: X/40 points
    - Total: X/100 (Grade: A/B/C/D/F)

4. **Generate audit report** with:
    - Score summary table
    - Critical gaps (agent found, not documented)
    - Ready-to-use markdown for each section
    - Progressive disclosure recommendations (if >300 lines)

### Phase 3: Present Results

Output the complete audit report following the template in the skill file.

Key sections:

- **Score Summary**: Table showing pillar scores and gaps
- **Critical Gaps**: Items agents found that aren't documented
- **Generated Content**: Copy-paste ready markdown for WHY, WHAT, HOW
- **Recommendations**: Specific improvements and structure suggestions

## Usage

```
/claude-md-audit
```

## Expected Output

- Completeness score (0-100 with letter grade)
- Gap analysis (what's missing vs what agents discovered)
- Ready-to-use markdown for each section (copy directly into CLAUDE.md)
- Progressive disclosure recommendations for large projects

## Notes

- **Read-only**: This command never modifies files automatically
- **Parallel execution**: All 3 agents must be launched in a single message
- **Tech-aware**: Agents adapt their analysis based on detected project type
- **Copy-paste ready**: All generated content is formatted for direct use
