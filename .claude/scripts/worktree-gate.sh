#!/usr/bin/env bash
# Blocks EnterWorktree if stale worktrees (>7 days old) exist.
# Used by: PreToolUse hook on EnterWorktree
set -euo pipefail

MAX_AGE_DAYS=${1:-7}

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

MAIN_DIR=$(git rev-parse --show-toplevel)
STALE=""

while IFS= read -r line; do
  [ -z "$line" ] && continue
  WT_PATH=$(echo "$line" | awk '{print $1}')
  [ "$WT_PATH" = "$MAIN_DIR" ] && continue

  LAST_COMMIT=$(git -C "$WT_PATH" log -1 --format=%ct 2>/dev/null || echo 0)
  NOW=$(date +%s)
  AGE_DAYS=$(( (NOW - LAST_COMMIT) / 86400 ))

  if [ "$AGE_DAYS" -gt "$MAX_AGE_DAYS" ]; then
    WT_NAME=$(basename "$WT_PATH")
    WT_BRANCH=$(git -C "$WT_PATH" branch --show-current 2>/dev/null || echo "detached")
    STALE="${STALE}  ${WT_NAME} [${WT_BRANCH}] — ${AGE_DAYS}d old -> git worktree remove ${WT_PATH}\n"
  fi
done < <(git worktree list)

if [ -n "$STALE" ]; then
  echo "BLOCKED: Stale worktrees (>${MAX_AGE_DAYS}d) must be cleaned up first:"
  echo ""
  printf "%b" "$STALE"
  echo ""
  echo "Clean up stale worktrees before creating new ones."
  exit 1
fi
