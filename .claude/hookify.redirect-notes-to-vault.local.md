---
name: redirect-notes-to-vault
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.claude/(projects|memory)/.*\.md$|MEMORY\.md$
action: warn
---

Writing to Claude's internal memory. Consider the Obsidian vault at `~/Documents/obsidian-kb/` instead — `00-inbox/` for quick captures, or the appropriate category folder.
