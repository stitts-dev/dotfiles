#!/bin/bash
# setup-claude.sh — Bootstrap Claude Code configuration from dotfiles
# Additive merge: adds to existing config without removing anything.
# Safe to re-run on any machine.
#
# Usage:
#   bash setup-claude.sh           # Merge dotfiles into existing config
#   bash setup-claude.sh --dry-run # Show what would change without applying

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
TEMPLATE_FILE="$DOTFILES_DIR/.claude/settings.json.template"
PLUGINS_FILE="$CLAUDE_DIR/plugins.txt"
REPOS_DIR="${REPOS_DIR:-$HOME/repos}"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[info]${NC}  $*"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC}  $*"; }
fail()  { echo -e "${RED}[fail]${NC}  $*"; }
step()  { echo -e "\n${GREEN}━━━ $* ━━━${NC}"; }

# ─── Preflight checks ────────────────────────────────────────────────
step "Preflight checks"

if ! command -v stow &>/dev/null; then
  fail "GNU Stow not found. Install with: brew install stow"
  exit 1
fi
ok "stow found"

if ! command -v jq &>/dev/null; then
  fail "jq not found. Install with: brew install jq"
  exit 1
fi
ok "jq found"

if ! command -v claude &>/dev/null; then
  warn "claude CLI not found — skipping plugin and MCP steps"
  SKIP_CLAUDE=true
else
  ok "claude CLI found"
  SKIP_CLAUDE=false
fi

if [[ ! -d "$DOTFILES_DIR" ]]; then
  fail "Dotfiles directory not found at $DOTFILES_DIR"
  exit 1
fi
ok "dotfiles at $DOTFILES_DIR"

# ─── Step 1: Stow symlinks ───────────────────────────────────────────
step "Step 1: Creating/updating symlinks via stow"

if $DRY_RUN; then
  info "Would run: stow --restow --target ~ --dir $DOTFILES_DIR ."
  stow --restow --target "$HOME" --dir "$DOTFILES_DIR" --simulate . 2>&1 | head -20 || true
else
  cd "$DOTFILES_DIR"
  if stow --restow --target "$HOME" . 2>&1; then
    ok "stow --restow completed"
  else
    warn "stow had conflicts — check output above"
  fi
fi

# Verify critical symlinks
AGENTS_COUNT=0
COMMANDS_COUNT=0
for f in "$CLAUDE_DIR"/agents/*.md; do
  [[ -L "$f" ]] && ((AGENTS_COUNT++)) || true
done
for f in "$CLAUDE_DIR"/commands/*.md; do
  [[ -L "$f" ]] && ((COMMANDS_COUNT++)) || true
done
info "Symlinked agents: $AGENTS_COUNT | commands: $COMMANDS_COUNT"

# ─── Step 2: Install plugins ─────────────────────────────────────────
step "Step 2: Registering marketplaces & installing plugins"

if $SKIP_CLAUDE; then
  warn "Skipping plugins (claude CLI not available)"
else
  # Register stitts-plugins marketplace (personal fork of claude-plugins-official)
  if $DRY_RUN; then
    info "Would register marketplace: stitts-plugins (stitts-dev/claude-plugins-official)"
  else
    claude marketplace add stitts-plugins --source github --repo stitts-dev/claude-plugins-official 2>/dev/null \
      && ok "Registered marketplace: stitts-plugins" \
      || info "Marketplace stitts-plugins already registered"
  fi
fi

if $SKIP_CLAUDE; then
  : # already warned above
elif [[ ! -f "$PLUGINS_FILE" ]]; then
  warn "No plugins.txt found at $PLUGINS_FILE — skipping"
else
  INSTALLED=0
  SKIPPED=0
  while IFS= read -r line; do
    # Skip comments and blank lines
    [[ -z "$line" || "$line" == \#* ]] && continue
    plugin="$line"

    if $DRY_RUN; then
      info "Would install: $plugin"
      ((INSTALLED++))
    else
      if claude plugins install "$plugin" --scope user 2>&1 | grep -qi "already installed\|success"; then
        ((INSTALLED++))
      else
        # Try anyway — claude plugins install is idempotent
        claude plugins install "$plugin" --scope user 2>/dev/null || true
        ((INSTALLED++))
      fi
    fi
  done < "$PLUGINS_FILE"
  ok "Plugins processed: $INSTALLED"
fi

# ─── Step 3: Add generic MCP servers ─────────────────────────────────
step "Step 3: Configuring MCP servers"

if $SKIP_CLAUDE; then
  warn "Skipping MCP servers (claude CLI not available)"
else
  # GitHub MCP server (uses gh auth)
  if $DRY_RUN; then
    info "Would add MCP server: github"
    info "Would add MCP server: filesystem (path: $REPOS_DIR)"
  else
    # Add github server — idempotent, overwrites if exists
    if claude mcp add github --scope user 2>/dev/null; then
      ok "MCP server added: github"
    else
      warn "MCP server 'github' may already exist or failed"
    fi

    # Add filesystem server with configurable path
    if claude mcp add filesystem --scope user -- "$REPOS_DIR" 2>/dev/null; then
      ok "MCP server added: filesystem ($REPOS_DIR)"
    else
      warn "MCP server 'filesystem' may already exist or failed"
    fi
  fi
fi

# ─── Step 4: Merge settings template ─────────────────────────────────
step "Step 4: Merging settings template"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  warn "No settings template found at $TEMPLATE_FILE — skipping"
else
  # Ensure settings.json exists
  if [[ ! -f "$SETTINGS_FILE" ]]; then
    info "No existing settings.json — creating from template"
    if $DRY_RUN; then
      info "Would create $SETTINGS_FILE from template"
    else
      cp "$TEMPLATE_FILE" "$SETTINGS_FILE"
      ok "Created settings.json from template"
    fi
  else
    # Backup existing settings
    BACKUP="$SETTINGS_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    if $DRY_RUN; then
      info "Would backup $SETTINGS_FILE to $BACKUP"
      info "Would merge template keys (preserving existing values and permissions.allow)"
    else
      cp "$SETTINGS_FILE" "$BACKUP"
      ok "Backed up settings to $BACKUP"

      # Deep merge: template provides defaults, existing values win.
      # permissions.allow is NEVER touched — only from existing.
      # permissions.deny merges (union of both arrays).
      # hooks arrays are concatenated (deduped by command string).
      MERGED=$(jq -s '
        # $existing = .[0], $template = .[1]
        .[0] as $existing | .[1] as $template |

        # Start with template as base
        $template

        # Overlay all existing top-level keys (existing wins)
        * $existing

        # Special handling for permissions: keep existing allow, merge deny
        | .permissions.allow = ($existing.permissions.allow // [])
        | .permissions.deny = (
            (($existing.permissions.deny // []) + ($template.permissions.deny // []))
            | unique
          )

        # Special handling for hooks: merge arrays, dedup by command
        | .hooks = (
            ($template.hooks // {}) as $th |
            ($existing.hooks // {}) as $eh |
            ($th | keys) + ($eh | keys) | unique | map(
              . as $event |
              {
                ($event): (
                  (($th[$event] // []) + ($eh[$event] // []))
                  | group_by(.hooks[0].command // .matcher // "")
                  | map(.[0])
                )
              }
            ) | add // {}
          )
      ' "$SETTINGS_FILE" "$TEMPLATE_FILE" 2>/dev/null)

      if [[ -n "$MERGED" ]] && echo "$MERGED" | jq empty 2>/dev/null; then
        echo "$MERGED" | jq '.' > "$SETTINGS_FILE"
        ok "Merged template into settings.json"
      else
        warn "jq merge failed — settings.json unchanged (backup at $BACKUP)"
        cp "$BACKUP" "$SETTINGS_FILE"
      fi
    fi
  fi
fi

# ─── Summary ─────────────────────────────────────────────────────────
step "Done"
if $DRY_RUN; then
  info "Dry run complete — no changes were made"
else
  ok "Claude Code configuration synced from dotfiles"
  echo ""
  info "Next steps:"
  info "  • Restart Claude Code to pick up hook changes"
  info "  • Run 'claude mcp list' to verify MCP servers"
  info "  • Run 'claude plugins list' to verify plugins"
fi
