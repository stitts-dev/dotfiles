# Export Plan

Export the current plan file to clipboard for sharing or archiving.

## Trigger

User says `/export-plan` or asks to export/copy/share the current plan.

## Behavior

1. Find the current plan file from the conversation context or locate the most recent plan in `~/.claude/plans/`
2. Generate a descriptive filename based on the plan content (e.g., `EX-331-auth0-user-creation-plan.md`)
3. Copy the file to clipboard using `osascript` so it can be pasted into Finder or other apps
4. Also copy the file to a well-named location in the current working directory if requested

## Implementation

```bash
# Get the plan file path (passed as $PLAN_FILE or find most recent)
PLAN_FILE="${1:-$(ls -t ~/.claude/plans/*.md 2>/dev/null | head -1)}"

if [ -z "$PLAN_FILE" ] || [ ! -f "$PLAN_FILE" ]; then
  echo "No plan file found"
  exit 1
fi

# Extract a meaningful name from the plan's first heading
PLAN_NAME=$(head -20 "$PLAN_FILE" | grep -E "^#" | head -1 | sed 's/^#* *//' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-' | cut -c1-50)

if [ -z "$PLAN_NAME" ]; then
  PLAN_NAME="exported-plan"
fi

EXPORT_NAME="${PLAN_NAME}-plan.md"

# Copy file to clipboard for pasting
osascript -e "set the clipboard to POSIX file \"$PLAN_FILE\""

echo "Plan copied to clipboard as: $EXPORT_NAME"
echo "Source: $PLAN_FILE"
```

## Options

- `/export-plan` - Copy current plan file to clipboard
- `/export-plan --save` - Also save a copy to current directory with descriptive name
- `/export-plan --path` - Just output the plan file path

## Example Output

```
Plan copied to clipboard: ex-331-auth0-user-creation-plan.md
Source: /Users/jstittsworth/.claude/plans/memoized-whistling-cookie.md

You can now paste this file into Finder, Slack, or any app that accepts files.
```
