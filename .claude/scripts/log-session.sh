#!/bin/bash
# Backup session logging script
# Can be run manually if hook doesn't trigger

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_FILE="${HOME}/.claude/session-log.txt"
SESSION_INFO="${1:-manual}"

# Create log directory if needed
mkdir -p "$(dirname "$LOG_FILE")"

# Log entry
echo "$TIMESTAMP|manual|$SESSION_INFO" >> "$LOG_FILE"

echo "Session logged: $TIMESTAMP"
