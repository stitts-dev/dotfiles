#!/bin/bash
PLAN_DIR=".claude/plans"
[ ! -d "$PLAN_DIR" ] && exit 0

LATEST=$(ls -t "$PLAN_DIR"/*.md 2>/dev/null | head -1)
[ -z "$LATEST" ] && exit 0

TITLE=$(grep -m1 '^# ' "$LATEST" | sed 's/^# //')
[ -z "$TITLE" ] && TITLE=$(basename "$LATEST" .md)

# Tab title — try multiple OSC sequences for cross-terminal compat
printf '\033]0;%s\007' "$TITLE"    # OSC 0 + BEL (iTerm2, Terminal.app)
printf '\033]2;%s\007' "$TITLE"    # OSC 2 + BEL (window title, may work in Warp)

# Tab color — deterministic from plan filename so same plan = same color across sessions
HASH=$(echo "$LATEST" | md5 -q 2>/dev/null || md5sum <<< "$LATEST" | cut -d' ' -f1)
R=$(( 16#${HASH:0:2} ))
G=$(( 16#${HASH:2:2} ))
B=$(( 16#${HASH:4:2} ))
# Clamp to muted range (40-180) so colors aren't blinding or invisible
clamp() { local v=$1; v=$(( v % 141 + 40 )); echo $v; }
R=$(clamp $R); G=$(clamp $G); B=$(clamp $B)

# iTerm2 proprietary tab color
printf '\033]6;1;bg;red;brightness;%d\a' "$R"
printf '\033]6;1;bg;green;brightness;%d\a' "$G"
printf '\033]6;1;bg;blue;brightness;%d\a' "$B"

# Warp: no runtime tab color API (open feature requests #3108, #2743, #6897).
# Title works via OSC 0 but requires WARP_DISABLE_AUTO_TITLE=true in .zshrc.
