# ===== Minimal Plugin Configuration for Testing =====

# Set theme (consistent across terminals)
ZSH_THEME="clean"

# Only essential plugins
plugins=(git)

# Source Oh My Zsh
if [[ -f $ZSH/oh-my-zsh.sh ]]; then
  source $ZSH/oh-my-zsh.sh
fi

# COMMENT OUT PROBLEMATIC PLUGINS FOR TESTING
# Load zsh-autosuggestions if available
# if [[ -f "$(brew --prefix 2>/dev/null)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
#   source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
# fi

# Load zsh-syntax-highlighting if available  
# if [[ -f "$(brew --prefix 2>/dev/null)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
#   source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
# fi
