#!/usr/bin/env bash
# PreToolUse hook: Block Bash calls that should use built-in tools
# Catches piped/subshell usage that slips through permissions.deny matching
# (deny rules only match the first command word)

CMD="${CLAUDE_TOOL_INPUT}"

# Extract the command string from JSON input
COMMAND=$(echo "$CMD" | python3 -c "import sys,json; print(json.loads(sys.stdin.read()).get('command',''))" 2>/dev/null)

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Get just the first word/command
FIRST_CMD=$(echo "$COMMAND" | awk '{print $1}' | sed 's|.*/||')

# 1. First-word check (belt-and-suspenders with deny rules)
case "$FIRST_CMD" in
  grep|rg)
    echo "BLOCK: Use the built-in Grep tool instead of Bash($FIRST_CMD). Grep uses ripgrep under the hood with output_mode, glob filtering, and context options." >&2
    exit 2
    ;;
  find)
    echo "BLOCK: Use the built-in Glob tool instead of Bash(find). Glob supports patterns like '**/*.ts' and sorts by modification time." >&2
    exit 2
    ;;
  cat|head|tail)
    echo "BLOCK: Use the built-in Read tool instead of Bash($FIRST_CMD). Read supports line offset/limit and handles images, PDFs, and notebooks." >&2
    exit 2
    ;;
  sed|awk)
    echo "BLOCK: Use the built-in Edit tool instead of Bash($FIRST_CMD). Edit does exact string replacement with uniqueness checks." >&2
    exit 2
    ;;
esac

# 2. Pipe check — catch `| grep`, `| rg`, `| sed`, `| awk`, `| head`, `| tail` in pipes
if echo "$COMMAND" | grep -qE '\|\s*(grep|rg|find|cat|head|tail|sed|awk)\b'; then
  PIPED_CMD=$(echo "$COMMAND" | grep -oE '\|\s*(grep|rg|find|cat|head|tail|sed|awk)\b' | head -1 | sed 's/.*|[[:space:]]*//')
  echo "BLOCK: Piped '$PIPED_CMD' detected. Use the built-in tool instead: grep/rg → Grep, find → Glob, cat/head/tail → Read, sed/awk → Edit." >&2
  exit 2
fi

# 3. Subshell check — catch $(grep ...), $(cat ...), etc.
if echo "$COMMAND" | grep -qE '\$\(\s*(grep|rg|find|cat|head|tail|sed|awk)\b'; then
  SUB_CMD=$(echo "$COMMAND" | grep -oE '\$\(\s*(grep|rg|find|cat|head|tail|sed|awk)\b' | head -1 | sed 's/.*$([[:space:]]*//')
  echo "BLOCK: Subshell '$SUB_CMD' detected. Use the built-in tool instead: grep/rg → Grep, find → Glob, cat/head/tail → Read, sed/awk → Edit." >&2
  exit 2
fi

exit 0
