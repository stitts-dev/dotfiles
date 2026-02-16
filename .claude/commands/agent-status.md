---
allowed-tools: Bash(ls:*), Bash(wc:*), Bash(find:*), Bash(cat:*), Bash(grep:*), Bash(du:*)
argument-hint: ""
description: Show status of active agents, plugins, MCP servers, and disk usage
---

Display comprehensive Claude Code configuration status.

echo "═══════════════════════════════════════════════════════════"
echo "           CLAUDE CODE CONFIGURATION STATUS"
echo "═══════════════════════════════════════════════════════════"
echo ""

echo "📋 ACTIVE AGENTS:"
echo "─────────────────────────────────────────────────────────"
AGENT_COUNT=$(ls -1 ~/.claude/agents/*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$AGENT_COUNT" -gt 0 ]; then
  echo "Total: $AGENT_COUNT agents"
  echo ""
  ls -1 ~/.claude/agents/*.md 2>/dev/null | while read -r agent; do
    agent_name=$(basename "$agent" .md)
    description=$(grep "^description:" "$agent" | head -1 | cut -d':' -f2- | sed 's/^ *//')
    echo "  ✓ $agent_name"
    echo "    $description"
    echo ""
  done
else
  echo "  ⚠️  No agents configured"
  echo ""
fi

echo "🔧 CUSTOM COMMANDS:"
echo "─────────────────────────────────────────────────────────"
COMMAND_COUNT=$(find ~/.claude/commands -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$COMMAND_COUNT" -gt 0 ]; then
  echo "Total: $COMMAND_COUNT commands"
  echo ""
  find ~/.claude/commands -name "*.md" 2>/dev/null | while read -r cmd; do
    cmd_name=$(basename "$cmd" .md)
    cmd_desc=$(grep "^description:" "$cmd" | head -1 | cut -d':' -f2- | sed 's/^ *//')
    echo "  • $cmd_name"
    [ -n "$cmd_desc" ] && echo "    $cmd_desc"
  done
  echo ""
else
  echo "  No custom commands"
  echo ""
fi

echo "🔌 INSTALLED PLUGINS:"
echo "─────────────────────────────────────────────────────────"
if [ -f ~/.claude/settings.json ]; then
  PLUGINS=$(grep -A 10 "enabledPlugins" ~/.claude/settings.json | grep "true" | sed 's/[",:]//g' | awk '{print $1}')
  if [ -n "$PLUGINS" ]; then
    echo "$PLUGINS" | while read -r plugin; do
      [ -n "$plugin" ] && echo "  ✓ $plugin"
    done
    echo ""
  else
    echo "  No plugins enabled"
    echo ""
  fi
else
  echo "  No settings.json found"
  echo ""
fi

echo "🌐 MCP SERVERS:"
echo "─────────────────────────────────────────────────────────"
if [ -f ~/.claude/settings.json ]; then
  MCP_SERVERS=$(grep -A 30 "mcpServers" ~/.claude/settings.json | grep "\"command\"" | sed 's/.*"command": "//; s/".*//')
  if [ -n "$MCP_SERVERS" ]; then
    SERVER_NAMES=$(grep -A 30 "mcpServers" ~/.claude/settings.json | grep -B 1 "\"command\"" | grep "^[[:space:]]*\"" | sed 's/.*"\(.*\)".*/\1/')
    echo "$SERVER_NAMES" | while read -r server; do
      [ -n "$server" ] && echo "  ✓ $server"
    done
    echo ""
  else
    echo "  ⚠️  No MCP servers configured"
    echo ""
  fi
else
  echo "  No settings.json found"
  echo ""
fi

echo "💾 DISK USAGE:"
echo "─────────────────────────────────────────────────────────"
TOTAL_SIZE=$(du -sh ~/.claude 2>/dev/null | awk '{print $1}')
echo "Total: $TOTAL_SIZE"
echo ""
echo "Breakdown:"
for dir in agents archive commands debug deprecated file-history plugins todos; do
  if [ -d ~/.claude/$dir ]; then
    SIZE=$(du -sh ~/.claude/$dir 2>/dev/null | awk '{print $1}')
    printf "  %-15s %s\n" "$dir:" "$SIZE"
  fi
done
echo ""

echo "═══════════════════════════════════════════════════════════"
