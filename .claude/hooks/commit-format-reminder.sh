#!/bin/bash
# Commit Format Reminder - PreToolUse hook
# Displays format reminder before git commit commands

cat << 'EOF'
═══════════════════════════════════════════════════════════════
COMMIT FORMAT: TICKET type: description (≤70 chars, single line)
• NO footer, NO Co-Authored-By, NO emoji
• Types: feat | bugfix | fixup | chore
═══════════════════════════════════════════════════════════════
EOF
