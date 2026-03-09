---
name: vault-search-first
enabled: true
event: prompt
pattern: (how does|architecture|where is|debug|service map|domain|what is the|infrastructure|observability|provisioning|valuation|matrix|distribution)
action: warn
---

Search the Obsidian vault before answering. Use `mcp__obsidian__search-vault` to check `10-mocs/`, `20-architecture/`, `30-domain/`, `50-playbooks/`.
