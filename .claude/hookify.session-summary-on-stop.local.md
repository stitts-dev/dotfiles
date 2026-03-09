---
name: session-summary-on-stop
enabled: true
event: stop
pattern: .*
action: warn
---

If this session produced learnings, write a session note to `80-sessions/` in the vault. Use `tpl-session.md` template. Skip for trivial sessions.
