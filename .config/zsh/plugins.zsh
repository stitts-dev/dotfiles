# ===== Oh My Zsh Configuration =====

# Set custom directory for Oh My Zsh
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"

# Set cache directory for Oh My Zsh
ZSH_CACHE_DIR="$HOME/.oh-my-zsh/cache"

# Set completion dump file
ZSH_COMPDUMP="$HOME/.oh-my-zsh/cache/.zcompdump-$HOST"

# Disable update prompt
DISABLE_UPDATE_PROMPT=true

# Disable auto update
DISABLE_AUTO_UPDATE=true

# Disable compfix
ZSH_DISABLE_COMPFIX=true

# Set theme (consistent across terminals)
# Note: We'll load p10k via direct source below instead of through Oh My Zsh theme system
ZSH_THEME="clean"

# Plugins to load
# globalias: auto-expands aliases when pressing Space (helps learn what aliases do)
plugins=(git globalias)

# Source Oh My Zsh
if [[ -f $ZSH/oh-my-zsh.sh ]]; then
  source $ZSH/oh-my-zsh.sh
fi

# ===== Completion Configuration =====

# Enable alias completion with TAB
# _expand_alias: expands aliases in completion
# _complete: standard completion
# _ignored: show ignored completions
zstyle ':completion:*' completer _expand_alias _complete _ignored

# ===== Plugin Enhancement =====

# Load zsh-autosuggestions if available
if [[ -f "$(brew --prefix 2>/dev/null)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Load zsh-syntax-highlighting if available
if [[ -f "$(brew --prefix 2>/dev/null)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
