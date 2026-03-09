#!/bin/bash
# sync-check.sh — SessionStart hook: detect dotfiles drift, stow issues, project sync
# Outputs warnings for Claude to surface. Silent when everything is clean.

set -euo pipefail

DOTFILES_DIR="${HOME}/.dotfiles"
CLAUDE_DIR="${HOME}/.claude"
PLUGINS_FILE="${CLAUDE_DIR}/plugins.txt"
INSTALLED_JSON="${CLAUDE_DIR}/plugins/installed_plugins.json"
REPOS_DIR="${REPOS_DIR:-${HOME}/Documents/repos}"

warnings=()

# ─── 1. Dotfiles git status ──────────────────────────────────────────
if [[ -d "$DOTFILES_DIR/.git" ]]; then
  cd "$DOTFILES_DIR"

  # Check if behind remote
  git fetch -q origin main 2>/dev/null || true
  BEHIND=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo 0)
  AHEAD=$(git rev-list origin/main..HEAD --count 2>/dev/null || echo 0)

  if [[ "$BEHIND" -gt 0 ]]; then
    warnings+=("Dotfiles are $BEHIND commit(s) behind remote. Run: cd ~/.dotfiles && git pull")
  fi
  if [[ "$AHEAD" -gt 0 ]]; then
    warnings+=("Dotfiles have $AHEAD unpushed commit(s). Run: cd ~/.dotfiles && git push")
  fi

  # Check for uncommitted changes
  DIRTY=$(git status --porcelain 2>/dev/null | head -5)
  if [[ -n "$DIRTY" ]]; then
    COUNT=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    warnings+=("Dotfiles have $COUNT uncommitted change(s)")
  fi
fi

# ─── 2. Stow symlink integrity ───────────────────────────────────────
BROKEN_LINKS=()
while IFS= read -r link; do
  if [[ -L "$link" ]] && [[ ! -e "$link" ]]; then
    BROKEN_LINKS+=("$link")
  fi
done < <(find "$HOME" -maxdepth 1 -type l 2>/dev/null; find "$HOME/.config" -maxdepth 2 -type l 2>/dev/null; find "$CLAUDE_DIR" -maxdepth 2 -type l 2>/dev/null)

if [[ ${#BROKEN_LINKS[@]} -gt 0 ]]; then
  warnings+=("${#BROKEN_LINKS[@]} broken symlink(s) found: ${BROKEN_LINKS[*]:0:3}...")
fi

# Check critical symlinks exist
for target in ".zshrc" ".gitconfig" ".claude/CLAUDE.md"; do
  FULL="$HOME/$target"
  if [[ ! -L "$FULL" ]] && [[ -f "$DOTFILES_DIR/$target" ]]; then
    warnings+=("$target is not symlinked — run: cd ~/.dotfiles && stow --restow .")
  fi
done

# ─── 2b. Detect unstowed .claude files (new agents, skills, hooks) ───
for subdir in agents skills hooks; do
  DOTFILES_PATH="$DOTFILES_DIR/.claude/$subdir"
  ACTIVE_PATH="$CLAUDE_DIR/$subdir"
  if [[ -d "$DOTFILES_PATH" ]]; then
    while IFS= read -r src_file; do
      BASENAME=$(basename "$src_file")
      # For skills, check directory-level (each skill is a folder)
      if [[ "$subdir" == "skills" ]]; then
        SKILL_DIR=$(basename "$(dirname "$src_file")")
        DEST="$ACTIVE_PATH/$SKILL_DIR/$BASENAME"
      else
        DEST="$ACTIVE_PATH/$BASENAME"
      fi
      if [[ ! -e "$DEST" ]]; then
        warnings+=("New $subdir file not stowed: $BASENAME — run: cd ~/.dotfiles && stow --restow .")
        break  # One warning per subdir is enough
      fi
    done < <(find "$DOTFILES_PATH" -type f -name "*.md" -o -name "*.sh" 2>/dev/null)
  fi
done

# ─── 2c. Detect unstowed hookify rules ───────────────────────────────
for rule in "$DOTFILES_DIR/.claude"/hookify.*.local.md; do
  [[ ! -f "$rule" ]] && continue
  BASENAME=$(basename "$rule")
  if [[ ! -e "$CLAUDE_DIR/$BASENAME" ]]; then
    warnings+=("Hookify rule not stowed: $BASENAME — run: cd ~/.dotfiles && stow --restow .")
    break
  fi
done

# ─── 3. Plugin drift ─────────────────────────────────────────────────
if [[ -f "$PLUGINS_FILE" ]] && [[ -f "$INSTALLED_JSON" ]] && command -v jq &>/dev/null; then
  EXPECTED=$(grep -v '^\s*#' "$PLUGINS_FILE" | grep -v '^\s*$' | sort -u)
  INSTALLED=$(jq -r '.plugins | to_entries[] | select(.value[] | .scope == "user") | .key' "$INSTALLED_JSON" 2>/dev/null | sort -u)

  MISSING=$(comm -23 <(echo "$EXPECTED") <(echo "$INSTALLED") 2>/dev/null)
  EXTRA=$(comm -13 <(echo "$EXPECTED") <(echo "$INSTALLED") 2>/dev/null)

  if [[ -n "$MISSING" ]]; then
    COUNT=$(echo "$MISSING" | wc -l | tr -d ' ')
    warnings+=("$COUNT plugin(s) in plugins.txt not installed: $(echo "$MISSING" | head -3 | tr '\n' ', ')")
  fi
  if [[ -n "$EXTRA" ]]; then
    COUNT=$(echo "$EXTRA" | wc -l | tr -d ' ')
    warnings+=("$COUNT installed plugin(s) not in plugins.txt — run sync-plugins.sh --export")
  fi
fi

# ─── 4. Settings template drift ──────────────────────────────────────
TEMPLATE="$DOTFILES_DIR/.claude/settings.json.template"
SETTINGS="$CLAUDE_DIR/settings.json"
if [[ -f "$TEMPLATE" ]] && [[ -f "$SETTINGS" ]] && command -v jq &>/dev/null; then
  # Check if template has hooks not in settings
  TEMPLATE_HOOKS=$(jq -r '.hooks // {} | keys[]' "$TEMPLATE" 2>/dev/null | sort)
  SETTINGS_HOOKS=$(jq -r '.hooks // {} | keys[]' "$SETTINGS" 2>/dev/null | sort)
  MISSING_HOOKS=$(comm -23 <(echo "$TEMPLATE_HOOKS") <(echo "$SETTINGS_HOOKS") 2>/dev/null | tr -s '\n')

  if [[ -n "$MISSING_HOOKS" ]]; then
    warnings+=("Settings missing hook events from template: $MISSING_HOOKS — run setup-claude.sh")
  fi

  # Check if template deny rules are missing
  TEMPLATE_DENY=$(jq -r '.permissions.deny[]?' "$TEMPLATE" 2>/dev/null | sort)
  SETTINGS_DENY=$(jq -r '.permissions.deny[]?' "$SETTINGS" 2>/dev/null | sort)
  MISSING_DENY=$(comm -23 <(echo "$TEMPLATE_DENY") <(echo "$SETTINGS_DENY") 2>/dev/null | tr -s '\n')

  if [[ -n "$MISSING_DENY" ]]; then
    warnings+=("Settings missing deny rules from template — run setup-claude.sh")
  fi
fi

# ─── Output ───────────────────────────────────────────────────────────
if [[ ${#warnings[@]} -eq 0 ]]; then
  echo '{"status":"clean","message":"All synced"}'
else
  # Build JSON array of warnings
  JSON_WARNINGS="["
  for i in "${!warnings[@]}"; do
    [[ $i -gt 0 ]] && JSON_WARNINGS+=","
    # Escape quotes for JSON
    ESCAPED=$(echo "${warnings[$i]}" | sed 's/"/\\"/g')
    JSON_WARNINGS+="\"$ESCAPED\""
  done
  JSON_WARNINGS+="]"
  echo "{\"status\":\"drift\",\"warnings\":$JSON_WARNINGS}"
fi
