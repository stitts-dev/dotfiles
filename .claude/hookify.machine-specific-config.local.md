---
name: warn-machine-specific-config
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.(zsh|zshrc|bashrc|bash|sh|env|conf|toml|yaml|yml|gitconfig)$
  - field: new_text
    operator: regex_match
    pattern: /opt/homebrew/|\.local/share/|/usr/local/Cellar/|Jaden|jstittsworth\+irx@iralogix\.com|585768164488
---

**Machine-specific value detected in shared dotfile!**

This content may not work on other machines:
- `/opt/homebrew/` — macOS ARM only (Intel uses `/usr/local/`)
- User-specific email/name — varies per machine
- AWS account IDs — may differ per environment

**Consider:**
- Use conditional checks: `if [ -f "/opt/homebrew/..." ]; then ... fi`
- Move machine-specific values to `~/.local/env` (not tracked by stow)
- Use environment variables set per-machine instead of hardcoded values
