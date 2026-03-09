# ===== Environment Variables & Exports =====

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"

# PNPM configuration
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Go configuration
export GO_BIN="$HOME/go/bin"
case ":$PATH:" in
  *":$GO_BIN:"*) ;;
  *) export PATH="$GO_BIN:$PATH" ;;
esac

# Load local environment if available
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# ASDF version manager
if [ -f "/opt/homebrew/opt/asdf/libexec/asdf.sh" ]; then
  # Set ASDF_DIR to the parent directory so asdf can find its bin directory
  export ASDF_DIR="/opt/homebrew/opt/asdf"
  . /opt/homebrew/opt/asdf/libexec/asdf.sh
fi

# AWS Connect dev environment
export AWS_PROFILE=585768164488_IRX-Admin
export AWS_REGION=us-west-2
export AWS_DEFAULT_REGION=us-west-2
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=50000

# Jira API Token (stored in macOS keychain - service: jira-cli, account: jstittsworth@iralogix.com)
# jira-cli will automatically retrieve from keychain