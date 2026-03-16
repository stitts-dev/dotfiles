#!/usr/bin/env bash
# Reports status of all git worktrees beyond main checkout.
# Used by: SessionStart hook, worktree management
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

MAIN_DIR=$(git rev-parse --show-toplevel)
EXTRAS=$(git worktree list | grep -v "^${MAIN_DIR} " | grep -v "(bare)$" || true)

if [ -z "$EXTRAS" ]; then
  if [ "${1:-}" = "--verbose" ]; then
    echo "No worktrees found."
  fi
  exit 0
fi

COUNT=$(echo "$EXTRAS" | wc -l | tr -d ' ')
echo ""
echo "=== WORKTREE STATUS: ${COUNT} worktree(s) ==="
echo ""

while IFS= read -r line; do
  [ -z "$line" ] && continue
  WT_PATH=$(echo "$line" | awk '{print $1}')
  WT_BRANCH=$(echo "$line" | sed 's/.*\[//' | sed 's/\].*//')
  WT_NAME=$(basename "$WT_PATH")

  LAST_COMMIT=$(git -C "$WT_PATH" log -1 --format=%ct 2>/dev/null || echo 0)
  NOW=$(date +%s)
  AGE_DAYS=$(( (NOW - LAST_COMMIT) / 86400 ))

  if git merge-base --is-ancestor "$WT_BRANCH" main 2>/dev/null; then
    MERGED="MERGED"
  else
    AHEAD=$(git rev-list --count main.."$WT_BRANCH" 2>/dev/null || echo "?")
    MERGED="NOT merged (${AHEAD} commits ahead)"
  fi

  echo "  ${WT_NAME} [${WT_BRANCH}] — ${AGE_DAYS}d old — ${MERGED}"
  echo "    -> git worktree remove ${WT_PATH}"
done <<< "$EXTRAS"

echo ""
echo "Cleanup: remove merged worktrees or prune stale ones."
echo ""
