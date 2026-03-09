---
name: update-vault-after-changes
enabled: true
event: stop
pattern: .*
action: warn
---

If this session modified service code, APIs, or architecture, update the corresponding vault notes in `20-architecture/services/` or `30-domain/`.
