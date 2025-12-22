# ===== Tool Integration & Performance Optimizations =====

# FZF & Enhanced Search Integration (Optional)
if command -v fzf &> /dev/null && command -v bat &> /dev/null; then
  # FZF configuration for better integration
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
  
  # Enhanced file preview with fzf
  if command -v rg &> /dev/null; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
  fi
fi

# Delta configuration for better diffs (if available)
if command -v delta &> /dev/null; then
  git config --global core.pager delta 2>/dev/null
  git config --global delta.navigate true 2>/dev/null
  git config --global delta.line-numbers true 2>/dev/null
fi

# ===== GitHub CLI Aliases Setup =====
# Only set up GitHub CLI aliases if gh is available
if command -v gh &> /dev/null; then
    # Check if aliases already exist to avoid errors
    if ! gh alias list 2>/dev/null | grep -q "^co:"; then
        gh alias set co --shell 'id="$(gh pr list -L100 | fzf | cut -f1)"; [ -n "$id" ] && gh pr checkout "$id"' 2>/dev/null || true
    fi
    
    if ! gh alias list 2>/dev/null | grep -q "^dpr:"; then
        gh alias set dpr 'pr create --draft --assignee @me' 2>/dev/null || true
    fi
    
    if ! gh alias list 2>/dev/null | grep -q "^lr:"; then
        gh alias set lr 'pr list --search "is:open review-requested:@me"' 2>/dev/null || true
    fi
fi