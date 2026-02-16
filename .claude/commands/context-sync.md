---
allowed-tools: Bash(git:*), Bash(cd:*), Bash(ls:*), Bash(test:*), Bash(echo:*), Bash(wc:*)
argument-hint: "[project-dirs...]"
description: Gather context and changes across multiple project directories
---

Analyzing project state across specified directories.

PROJECTS="${ARGUMENTS:-./}"

echo "PROJECT CONTEXT SYNC"
echo "===================="
echo ""

for PROJECT_DIR in $PROJECTS; do
    !test -d "$PROJECT_DIR" && echo "Directory not found: $PROJECT_DIR" && continue
    
    echo "PROJECT: $PROJECT_DIR"
    echo "-----------------------------------"
    
    cd "$PROJECT_DIR" 2>/dev/null || continue
    
    # Branch and status
    echo ""
    echo "Branch:"
    !git branch --show-current 2>/dev/null || echo "Not a git repository"
    
    # Uncommitted changes
    echo ""
    echo "Uncommitted:"
    !git status --short 2>/dev/null | head -10 || echo "Clean"
    CHANGES=$(git status --short 2>/dev/null | wc -l)
    !test $CHANGES -gt 10 && echo "... and $((CHANGES - 10)) more"
    
    # Recent commits
    echo ""
    echo "Recent commits:"
    !git log --oneline -5 2>/dev/null || echo "No commits"
    
    # Statistics
    echo ""
    echo "Stats:"
    !git diff --stat --stat-width=60 2>/dev/null | tail -1 || echo "No changes"
    
    # Stashes
    STASHES=$(git stash list 2>/dev/null | wc -l)
    !test $STASHES -gt 0 && echo "Stashes: $STASHES"
    
    echo ""
    echo "-----------------------------------"
    echo ""
    
    cd - >/dev/null 2>&1
done

echo "COMPLETE"