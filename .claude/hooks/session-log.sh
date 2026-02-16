#!/bin/bash
# Session logging hook for Claude Code
# Logs session metadata for analytics and learning workflow tracking

INPUT=$(cat)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_FILE="${HOME}/.claude/session-log.txt"

# Extract session information from input
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // "unknown"' 2>/dev/null)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
HOOK_TYPE=$(echo "$INPUT" | jq -r '.hook_type // "unknown"' 2>/dev/null)

# Create log directory if needed
mkdir -p "$(dirname "$LOG_FILE")"

# Log the session end
echo "$TIMESTAMP|$HOOK_TYPE|$SESSION_ID|$TRANSCRIPT_PATH" >> "$LOG_FILE"

# Output success for hook system
echo '{"status": "logged"}'
