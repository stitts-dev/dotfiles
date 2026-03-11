# Added by Toolbox App
[[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]] && \
  export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# Java (only if java_home exists)
[[ -x /usr/libexec/java_home ]] && /usr/libexec/java_home -v 11 &>/dev/null && \
  export JAVA_HOME=$(/usr/libexec/java_home -v 11)
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"


eval "$(/opt/homebrew/bin/brew shellenv)"