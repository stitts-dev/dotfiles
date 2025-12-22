# ===== General Aliases =====

# File operations
alias ll="ls -l"
alias la="ls -la"

# Configuration shortcuts
alias zshconfig="nano ~/.zshrc"
alias ohmyzsh="nano ~/.oh-my-zsh"

# Directory navigation
alias cdup1="cd ~/Documents/repos/ilx-core/unified-portal/ui"
alias cdup2="cd ~/Documents/repos/ilx-core/unified-portal/xl"
alias cdspw="cd ~/Documents/repos/ilx-core/ira-staff-portal-web"
alias cdahp="cd ~/Documents/repos/ira-accountholder-portal-web"
alias cdahep="cd ~/Documents/repos/ira-accountholder-enrollment-portal-web"
alias cdrk="cd ~/Documents/repos/ilx-core/ira-recordkeeper"
alias cdrkad="cd ~/Documents/repos/ilx-core/ira-recordkeeper-admin"

# Package manager shortcuts
alias nr="npm run"
alias pnr="pnpm run"

# ===== Alias Utilities =====

# Show what an alias expands to
# Usage: alias-info glog  (shows expansion)
#        alias-info       (lists all aliases)
alias-info() {
  local cmd="${1:-}"
  if [[ -z "$cmd" ]]; then
    alias
  else
    alias "$cmd" 2>/dev/null || echo "Not an alias: $cmd"
  fi
}

# Widget to expand alias inline (Ctrl+Space to expand before running)
expand-alias-inline() {
  zle _expand_alias
  zle expand-word
}
zle -N expand-alias-inline
bindkey '^ ' expand-alias-inline