---
name: stop-uncommitted-dotfiles
enabled: true
event: stop
pattern: .*
---

**Before wrapping up — check dotfiles sync!**

If you modified any dotfiles in this session:

1. **Commit changes:** `cd ~/.dotfiles && git add -p && git commit`
2. **Push to remote:** `git push` so the other machine can pull
3. **Re-stow if needed:** `stow --restow .` (only if new files were added)

Uncommitted dotfile changes won't sync to your other machine.
