---
description: Query the skill registry for relevant skills before starting a task
argument-hint: [task-description]
---

Before starting on: $ARGUMENTS

1. **List** all available skills from:
    - ~/.claude/skills/
    - .claude/skills/ (current project)
    - Installed plugins with skills
2. **Identify** which skills are relevant to this task
3. **Load** and summarize the relevant skills
4. **Check** for known failures related to this task
5. **Suggest** working patterns to apply
