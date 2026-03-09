---
name: remind-stow-after-new-files
enabled: true
event: file
conditions:
  - field: file_path
    operator: regex_match
    pattern: \.dotfiles/\.(config|zshrc|bashrc|gitconfig|tool-versions)
  - field: old_text
    operator: equals
    pattern: ""
---

**New dotfile created — stow needed!**

A new file was added to `.dotfiles/`. It won't be active until symlinked.

**Run:** `cd ~/.dotfiles && stow --restow .`

Also check `.stow-local-ignore` — if this file should NOT be symlinked (docs, scripts, etc.), add it there.
