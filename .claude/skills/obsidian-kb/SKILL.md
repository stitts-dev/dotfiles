---
name: obsidian-kb
description: Obsidian Engineering Knowledge Base — search, read, and write to the IraLogix vault before answering architecture/domain questions
---

# Obsidian Engineering Knowledge Base

The Obsidian vault at `~/Documents/obsidian-kb/` is the canonical second brain for IraLogix engineering knowledge. Use the `obsidian` MCP server tools to interact with it.

## When to Search the Vault

**Before answering questions about:**
- Architecture (services, data flows, infrastructure)
- Domain concepts (IRA terminology, business rules)
- Debugging / known issues
- Previous session context

**Search order:**
1. `10-mocs/` — Map of Content index notes (start here for navigation)
2. `20-architecture/` — Service notes, infrastructure docs
3. `30-domain/` — Domain concept definitions
4. `50-playbooks/` — Debugging playbooks and runbooks

## When to Write to the Vault

### Session Summaries (`80-sessions/`)
After significant work sessions, write a session note:
- Filename: `YYYY-MM-DD-<topic>.md`
- Frontmatter: `type: session`, `project`, `focus-area`, `date`, `tags`
- Include: key findings, decisions made, open questions, next steps

### Service Updates (`20-architecture/services/`)
When modifying service code, APIs, or architecture, update the corresponding service note.

### Domain Concepts (`30-domain/`)
When encountering new domain terminology or correcting understanding, create or update concept notes.

### Quick Captures (`00-inbox/`)
For anything that doesn't fit a category yet — triage later.

## Formatting Conventions

### Frontmatter
Every note MUST have YAML frontmatter with at minimum:
- `type:` — service, adr, playbook, domain-concept, session, moc, reference
- `tags:` — array of relevant tags

### Callouts for AI-Extractable Facts
Use Obsidian callouts for important facts:
```markdown
> [!warning] Known Issue
> Description of the issue

> [!info] Key Fact
> Important architectural or domain fact

> [!tip] Best Practice
> Recommended approach
```

### Wiki Links
Use `[[note-name]]` syntax for internal links. This enables Obsidian's graph view.

### Templates
Templates in `99-meta/templates/` — use the appropriate template when creating new notes:
- `tpl-service.md` — Service documentation
- `tpl-adr.md` — Architecture Decision Records
- `tpl-playbook.md` — Debugging/operational playbooks
- `tpl-domain-concept.md` — Domain terminology
- `tpl-session.md` — Session summaries
- `tpl-moc.md` — Map of Content notes

## Vault Structure

```
00-inbox/          — Quick captures, unsorted
10-mocs/           — Map of Content index notes
20-architecture/   — Service notes, infrastructure, data layer
  services/        — Per-service documentation
  data/            — Data layer docs
  infrastructure/  — Infrastructure (AWS, observability)
30-domain/         — IRA domain concepts
40-decisions/      — Architecture Decision Records (ADRs)
50-playbooks/      — Debugging and operational playbooks
  debugging/       — Diagnosis guides
  runbooks/        — Operational procedures
60-projects/       — Active project notes
70-references/     — External reference material
80-sessions/       — Session summaries
99-meta/           — Templates, vault config
  templates/       — Templater templates
```

## Do NOT

- Write notes to `.claude/memory/` — use the vault instead
- Create notes without frontmatter
- Duplicate content that already exists in the vault — link to it
- Skip searching the vault for architecture/domain questions
