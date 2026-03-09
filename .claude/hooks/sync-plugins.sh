#!/bin/bash
# sync-plugins.sh — Keep plugins.txt in sync with installed Claude Code plugins
#
# Usage:
#   bash sync-plugins.sh             # Bidirectional sync
#   bash sync-plugins.sh --export    # Installed → plugins.txt (used by Stop hook)
#   bash sync-plugins.sh --import    # plugins.txt → installed

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
PLUGINS_FILE="${CLAUDE_DIR}/plugins.txt"
INSTALLED_JSON="${CLAUDE_DIR}/plugins/installed_plugins.json"

MODE="${1:-both}"

added=0
installed=0

if ! command -v jq &>/dev/null; then
  echo '{"status":"error","message":"jq not found"}'
  exit 0
fi

# --- Export: installed (user-scope) → plugins.txt ---
if [[ "$MODE" == "--export" || "$MODE" == "both" ]]; then
  if [[ -f "$INSTALLED_JSON" && -f "$PLUGINS_FILE" ]]; then
    tracked=$(grep -v '^\s*#' "$PLUGINS_FILE" | grep -v '^\s*$' | sort -u)

    while IFS= read -r plugin; do
      if ! echo "$tracked" | grep -qxF "$plugin"; then
        echo "$plugin" >> "$PLUGINS_FILE"
        ((added++))
      fi
    done < <(jq -r '
      .plugins | to_entries[]
      | select(.value[] | .scope == "user")
      | .key
    ' "$INSTALLED_JSON" 2>/dev/null | sort -u)
  fi
fi

# --- Import: plugins.txt → installed ---
if [[ "$MODE" == "--import" || "$MODE" == "both" ]]; then
  if [[ -f "$PLUGINS_FILE" ]] && command -v claude &>/dev/null; then
    installed_names=""
    if [[ -f "$INSTALLED_JSON" ]]; then
      installed_names=$(jq -r '.plugins | keys[]' "$INSTALLED_JSON" 2>/dev/null | sort -u)
    fi

    while IFS= read -r line; do
      [[ -z "$line" || "$line" == \#* ]] && continue
      if ! echo "$installed_names" | grep -qxF "$line"; then
        claude plugins install "$line" --scope user 2>/dev/null && ((installed++)) || true
      fi
    done < "$PLUGINS_FILE"
  fi
fi

echo "{\"status\":\"synced\",\"added\":${added},\"installed\":${installed}}"
