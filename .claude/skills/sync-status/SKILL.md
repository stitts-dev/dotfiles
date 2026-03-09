---
name: sync-status
description: Dashboard showing dotfiles sync state across machines — git status, stow integrity, plugin drift, settings template drift
version: 1.0.0
tags: [dotfiles, sync, maintenance]
---

# Sync Status Dashboard

Show a comprehensive sync status report for the dotfiles setup. This is a read-only diagnostic — use `/sync-fix` to resolve issues.

## Process

Run ALL of the following checks in parallel using the Bash tool, then compile results into a single dashboard.

### Check 1: Git Status

```bash
cd ~/.dotfiles && git fetch -q origin main 2>/dev/null; echo "=== BRANCH ===" && git branch --show-current && echo "=== BEHIND ===" && git rev-list HEAD..origin/main --count 2>/dev/null && echo "=== AHEAD ===" && git rev-list origin/main..HEAD --count 2>/dev/null && echo "=== DIRTY ===" && git status --porcelain 2>/dev/null | head -10
```

### Check 2: Stow Symlink Integrity

```bash
echo "=== CRITICAL SYMLINKS ===" && for f in ~/.zshrc ~/.gitconfig ~/.claude/CLAUDE.md ~/.config/zsh/aliases.zsh ~/.config/zsh/functions.zsh ~/.config/zsh/env.zsh; do if [ -L "$f" ]; then echo "OK: $f -> $(readlink "$f")"; elif [ -f "$f" ]; then echo "NOT LINKED: $f (regular file)"; else echo "MISSING: $f"; fi; done && echo "=== BROKEN LINKS ===" && find ~ -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null && find ~/.config -maxdepth 2 -type l ! -exec test -e {} \; -print 2>/dev/null && find ~/.claude -maxdepth 2 -type l ! -exec test -e {} \; -print 2>/dev/null
```

### Check 3: Plugin Drift

```bash
PLUGINS_FILE=~/.claude/plugins.txt && INSTALLED_JSON=~/.claude/plugins/installed_plugins.json && echo "=== EXPECTED ===" && grep -v '^\s*#' "$PLUGINS_FILE" | grep -v '^\s*$' | sort -u && echo "=== INSTALLED ===" && jq -r '.plugins | to_entries[] | select(.value[] | .scope == "user") | .key' "$INSTALLED_JSON" 2>/dev/null | sort -u && echo "=== MISSING ===" && comm -23 <(grep -v '^\s*#' "$PLUGINS_FILE" | grep -v '^\s*$' | sort -u) <(jq -r '.plugins | to_entries[] | select(.value[] | .scope == "user") | .key' "$INSTALLED_JSON" 2>/dev/null | sort -u) && echo "=== EXTRA ===" && comm -13 <(grep -v '^\s*#' "$PLUGINS_FILE" | grep -v '^\s*$' | sort -u) <(jq -r '.plugins | to_entries[] | select(.value[] | .scope == "user") | .key' "$INSTALLED_JSON" 2>/dev/null | sort -u)
```

### Check 4: Settings Template vs Active Settings

```bash
TEMPLATE=~/.dotfiles/.claude/settings.json.template && SETTINGS=~/.claude/settings.json && echo "=== TEMPLATE HOOKS ===" && jq -r '.hooks | keys[]' "$TEMPLATE" 2>/dev/null | sort && echo "=== ACTIVE HOOKS ===" && jq -r '.hooks | keys[]' "$SETTINGS" 2>/dev/null | sort && echo "=== TEMPLATE DENY RULES ===" && jq -r '.permissions.deny[]?' "$TEMPLATE" 2>/dev/null | sort && echo "=== ACTIVE DENY RULES ===" && jq -r '.permissions.deny[]?' "$SETTINGS" 2>/dev/null | sort && echo "=== ENV VARS ===" && jq -r '.env // {} | to_entries[] | "\(.key)=\(.value)"' "$TEMPLATE" 2>/dev/null
```

### Check 5: Agent & Skill Counts

```bash
echo "=== AGENTS ===" && ls ~/.claude/agents/*.md 2>/dev/null | wc -l | tr -d ' ' && echo "=== SKILLS ===" && ls -d ~/.claude/skills/*/SKILL.md 2>/dev/null | wc -l | tr -d ' ' && echo "=== HOOKS ===" && ls ~/.claude/hooks/*.sh 2>/dev/null | wc -l | tr -d ' ' && echo "=== HOOKIFY RULES ===" && ls ~/.claude/hookify.*.local.md 2>/dev/null | wc -l | tr -d ' '
```

## Output Format

Present results as a formatted dashboard:

```markdown
## Dotfiles Sync Status

### Git
| Check | Status |
|-------|--------|
| Branch | `main` |
| Behind remote | 0 commits |
| Ahead of remote | 0 commits |
| Uncommitted changes | 2 files |

### Stow Symlinks
| File | Status |
|------|--------|
| ~/.zshrc | OK -> ~/.dotfiles/.zshrc |
| ~/.gitconfig | OK -> ~/.dotfiles/.gitconfig |
| ... | ... |

Broken links: 0

### Plugins (expected vs installed)
| Status | Count |
|--------|-------|
| Synced | 12 |
| Missing | 2 (list them) |
| Extra | 0 |

### Settings Template
| Check | Status |
|-------|--------|
| Hook events | All present / Missing: SessionStart |
| Deny rules | All present / Missing: 2 rules |
| Env vars | All set |

### Inventory
| Type | Count |
|------|-------|
| Agents | 13 |
| Skills | 8 |
| Hooks | 7 |
| Hookify rules | 4 |

### Issues Found
- (list any problems with suggested fix commands)

### Quick Fix
Run `/sync-fix` to resolve all issues automatically.
```

Mark items with issues clearly. If everything is clean, say so concisely.
