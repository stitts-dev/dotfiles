---
name: warn-hardcoded-paths
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.(zsh|zshrc|bashrc|bash|sh|env|conf|toml|yaml|yml)$
  - field: new_text
    operator: regex_match
    pattern: /Users/jstittsworth/
---

**Hardcoded user path detected in dotfile!**

You're writing `/Users/jstittsworth/` — this breaks on other machines.

**Use instead:**
- `$HOME/` or `~/` in shell scripts
- `${HOME}` in config files
- `~` in tool configs that support tilde expansion

This dotfiles repo is shared across machines. Hardcoded paths prevent portability.
