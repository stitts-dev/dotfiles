# ===== Modular .zshrc Configuration =====
# Performance-optimized zsh configuration with modular structure

# === Load Configuration Modules ===
# Source all configuration modules from .config/zsh/

# Environment variables and exports
[[ -f ~/.config/zsh/env.zsh ]] && source ~/.config/zsh/env.zsh

# Plugin configuration and loading
[[ -f ~/.config/zsh/plugins.zsh ]] && source ~/.config/zsh/plugins.zsh

# General aliases
[[ -f ~/.config/zsh/aliases.zsh ]] && source ~/.config/zsh/aliases.zsh

# Git and GitHub CLI aliases
[[ -f ~/.config/zsh/git-aliases.zsh ]] && source ~/.config/zsh/git-aliases.zsh

# Custom functions
[[ -f ~/.config/zsh/functions.zsh ]] && source ~/.config/zsh/functions.zsh

# Jira workflow functions (go-jira integration)
[[ -f ~/.config/zsh/go-jira-functions.zsh ]] && source ~/.config/zsh/go-jira-functions.zsh

# Performance optimizations and tool integration
[[ -f ~/.config/zsh/performance.zsh ]] && source ~/.config/zsh/performance.zsh

# Task-master CLI aliases
[[ -f ~/.config/zsh/taskmaster-aliases.zsh ]] && source ~/.config/zsh/taskmaster-aliases.zsh

# Lattice collector functions (daily activity + weekly drafts)
[[ -f ~/.config/zsh/lattice-functions.zsh ]] && source ~/.config/zsh/lattice-functions.zsh

# Alias TUI (interactive alias browser)
[[ -f ~/.config/zsh/alias-tui.zsh ]] && source ~/.config/zsh/alias-tui.zsh


# ===== API Key Management (macOS Keychain) =====
# Load API keys from macOS Keychain (secure, encrypted storage)
load_api_keys() {
  export OPENAI_API_KEY=$(security find-generic-password -a ${USER} -s openai_api_key -w 2>/dev/null)
}
load_api_keys

# === WORKTREE MANAGEMENT ALIASES ===
# Unified Portal worktree management (work machine only)
if [[ -d "/Users/jstittsworth/Documents/repos/ilx-core/unified-portal" ]]; then
  export UNIFIED_PORTAL_ROOT="/Users/jstittsworth/Documents/repos/ilx-core/unified-portal"
  wt()  { source "$UNIFIED_PORTAL_ROOT/scripts/worktree/wt-switch.sh" "$@"; }
  wtc() { "$UNIFIED_PORTAL_ROOT/scripts/worktree/wt-switch.sh" "$1" --cursor; }
  wtt() { "$UNIFIED_PORTAL_ROOT/scripts/worktree/wt-switch.sh" "$1" --tmux; }
  wtl() { "$UNIFIED_PORTAL_ROOT/scripts/worktree/wt-list.sh" "$@"; }
  wtn() { "$UNIFIED_PORTAL_ROOT/scripts/worktree/wt-create.sh" "$@"; }
  wtr() { "$UNIFIED_PORTAL_ROOT/scripts/worktree/wt-remove.sh" "$@"; }
  wts() { "$UNIFIED_PORTAL_ROOT/scripts/worktree/wt-env-sync.sh" "$@"; }
fi
# === END WORKTREE ALIASES ===


# Enable Claude Code LSP tool
export ENABLE_LSP_TOOL=true
export ENABLE_EXPERIMENTAL_MCP_CLI=true
[ -f /opt/homebrew/etc/profile.d/autojump.sh ] && . /opt/homebrew/etc/profile.d/autojump.sh

# Added by claunch installer
export PATH="$HOME/bin:$PATH"
# $HOME/.local/bin is set in env.zsh
