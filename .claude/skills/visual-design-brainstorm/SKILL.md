---
name: visual-design-brainstorm
description: Interactive UI/frontend design brainstorming with live browser mockups. Use when designing new UI features, components, layouts, or visual overhauls — especially when the user says "design", "brainstorm", "mockup", "what should X look like", "idle state", "empty state", "redesign", or any task where showing visual options in a browser would help the user decide. Also trigger when the user asks to "brainstorm UI", "design a component", or describes a feature that involves visual decisions. This skill is specifically for UI/visual work where seeing beats reading — use it proactively whenever visual questions will arise.
---

# Visual Design Brainstorm

Interactive design brainstorming for UI features with live browser mockups, structured decision-making, and spec output.

This skill combines three phases: **visual exploration** (browser mockups), **collaborative design** (structured questions + approach proposals), and **spec delivery** (validated design document). The browser mockup loop is the key differentiator — showing beats telling for visual decisions.

## When to Use This vs Text-Only Brainstorming

- **Use this skill** when the task involves visual decisions: layouts, component design, animations, empty states, dashboards, navigation, color/typography choices
- **Use text-only brainstorming** when the task is purely architectural, data modeling, or API design with no visual component

## Prerequisites

This skill uses the superpowers visual companion server for browser mockups. Check if it's available:

```
# Look for the brainstorming scripts
ls ~/.claude/plugins/cache/stitts-plugins/superpowers/*/skills/brainstorming/scripts/start-server.sh
```

If not found, the skill degrades gracefully — use inline ASCII/text descriptions instead of browser mockups. The workflow still applies.

## The Process

### Phase 1: Explore Context

Before asking any questions, understand what exists. This is research, not implementation.

1. **Read the current state** — Find the component(s) being redesigned. Read their source. Understand what renders today.
2. **Find the design system** — Look for theme files, design tokens, component presets, animation configs. Know what building blocks exist.
3. **Check for prior decisions** — Search docs, plans, memory, git history for any prior design work or decisions on this feature.

Use Explore subagents (up to 3 in parallel) for efficiency. Each agent gets a specific focus area.

### Phase 2: Visual Companion Setup

If the task will involve visual questions (layouts, component options, animation styles), offer the visual companion:

> "Some of what we're working on might be easier to show in a browser — I can put together live mockups as we go. Want to try it?"

**This offer is its own message.** Don't combine with clarifying questions.

If accepted, start the server:
```bash
# Find the superpowers brainstorming scripts directory
SCRIPTS_DIR=$(find ~/.claude/plugins/cache/stitts-plugins/superpowers -name "start-server.sh" -path "*/brainstorming/scripts/*" 2>/dev/null | head -1 | xargs dirname)
$SCRIPTS_DIR/start-server.sh --project-dir <project-root>
```

Save the `screen_dir` and `url` from the response. Tell the user to open the URL.

### Phase 3: Clarifying Questions

Ask questions **one at a time**. Prefer multiple choice. Focus on:

- **Scope** — Which screens/components are in play?
- **Interaction model** — How should users interact with this?
- **Content** — What data/text/media populates this?
- **Constraints** — Mobile? Accessibility? Performance? Existing design system?

For each question, decide: **browser or terminal?**

| Use browser | Use terminal |
|---|---|
| Layout comparisons | Scope/requirements questions |
| Component visual options | Conceptual A/B/C choices |
| Animation/transition demos | Tradeoff discussions |
| Color/typography choices | Technical architecture |
| Side-by-side mockups | Data model decisions |

A question *about* UI is not automatically visual. "What does this panel show?" is conceptual (terminal). "Which of these panel layouts works?" is visual (browser).

### Phase 4: Browser Mockups

When showing visual options:

#### Writing Mockup HTML

Write standalone HTML files (start with `<!DOCTYPE html>`) to `$SCREEN_DIR/`. Use semantic filenames: `layout-options.html`, `animation-demo.html`. Never reuse filenames.

**Critical rules:**
- Use unique CSS class prefixes (e.g., `vb-`) to avoid collisions with the frame template
- Use `!important` on background colors if the frame overrides them
- Keep mockups focused — 2-4 options max per screen
- Include real-ish content, not lorem ipsum
- Make options clickable with clear labels
- Include live CSS animations where relevant

**Mockup template:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Layout Options</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: #111; color: #e5e7eb; font-family: system-ui; padding: 24px; }
  .vb-title { font-size: 20px; font-weight: 600; margin-bottom: 4px; }
  .vb-sub { font-size: 14px; color: #9ca3af; margin-bottom: 24px; }
  .vb-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; max-width: 1100px; }
  .vb-card {
    border: 2px solid rgba(255,255,255,0.08);
    border-radius: 12px; overflow: hidden; cursor: pointer;
    transition: border-color 0.2s, box-shadow 0.2s;
  }
  .vb-card:hover { border-color: rgba(99,102,241,0.4); }
  .vb-card.vb-sel { border-color: rgba(99,102,241,0.7); box-shadow: 0 0 20px rgba(99,102,241,0.15); }
  .vb-preview { height: 400px; position: relative; overflow: hidden; background: #0a0a0f !important; }
  .vb-label { padding: 12px 16px; background: rgba(255,255,255,0.03); }
  .vb-label h3 { font-size: 14px; font-weight: 600; }
  .vb-label p { font-size: 12px; color: #9ca3af; margin-top: 2px; }
</style>
</head>
<body>
<div class="vb-title">Question Title</div>
<p class="vb-sub">Brief context for the decision</p>
<div class="vb-grid">
  <div class="vb-card" onclick="document.querySelectorAll('.vb-card').forEach(c=>c.classList.remove('vb-sel'));this.classList.add('vb-sel')">
    <div class="vb-preview">
      <!-- Your mockup content here -->
    </div>
    <div class="vb-label">
      <h3>Option A: Name</h3>
      <p>Brief description of this approach</p>
    </div>
  </div>
  <!-- More options... -->
</div>
</body>
</html>
```

#### The Mockup Loop

1. Write HTML to `$SCREEN_DIR/`
2. Tell user what's on screen + remind them of the URL
3. Ask them to respond in terminal (click to select, or describe preference)
4. Read `$SCREEN_DIR/.events` for click data on next turn
5. If feedback changes current screen → write new version (`layout-v2.html`)
6. Only advance when current step is validated

When returning to terminal-only questions, push a waiting screen:
```html
<div style="display:flex;align-items:center;justify-content:center;min-height:60vh">
  <p style="color:#9ca3af">Continuing in terminal...</p>
</div>
```

### Phase 5: Propose Approaches

After understanding the design through questions + mockups:

1. Propose 2-3 implementation approaches with tradeoffs
2. Lead with your recommendation and why
3. Be direct about which approach is better and why
4. Let the user pick or mix elements

### Phase 6: Present Design

Present the design section by section. After each section, confirm it looks right before moving on. Cover:

- Component hierarchy
- Data flow / state management
- File changes (new + modified)
- Reuse opportunities (existing components, utilities, patterns)
- Transition/animation behavior
- Accessibility considerations

### Phase 7: Write Spec

Write a design spec document to `docs/specs/YYYY-MM-DD-<topic>-design.md` (or the project's preferred spec location):

**Spec structure:**
```markdown
# Feature Name — Design Spec
**Date:** YYYY-MM-DD
**Status:** Draft

## Context
Why this change is being made.

## Design Decisions
Table of key decisions, choices, and rationale.

## Architecture
Component hierarchy, new/modified files, data flow, type definitions, key code snippets.

## Verification
How to test the changes end-to-end.
```

### Phase 8: Spec Review Loop

Dispatch a code-reviewer subagent to validate the spec against the actual codebase:

- Do referenced files/types/components actually exist?
- Are import paths correct?
- Are there missing edge cases?
- Does the proposal follow existing patterns?

Categorize issues as `[CRITICAL]`, `[IMPORTANT]`, `[MINOR]`. Fix criticals and importants, then re-review. Max 3 iterations — surface remaining issues to the user.

### Phase 9: User Approval

Present the final spec location and ask the user to review before proceeding to implementation planning.

## Key Principles

- **One question at a time** — Don't overwhelm
- **Show, don't tell** — Use the browser for visual questions
- **Multiple choice preferred** — Easier to answer than open-ended
- **Reuse over reinvent** — Find existing components/patterns first
- **Spec review catches fabrication** — Always validate references against the real codebase
- **YAGNI** — Remove unnecessary features from designs

## Common Pitfalls

- **Frame template CSS collisions**: Always use unique class prefixes in mockup HTML (`vb-`, `mk-`, etc.)
- **Fabricated component names**: The spec reviewer exists because it's easy to reference components that don't exist. Always validate.
- **Skipping the mockup loop**: If you have the visual companion, use it for layout/visual decisions. Text descriptions of UI are lossy.
- **Over-scoping the spec**: Keep v1 tight. Defer future enhancements explicitly rather than baking them in.

## Cleanup

When brainstorming is complete:
```bash
$SCRIPTS_DIR/stop-server.sh $SCREEN_DIR
```

Mockup files persist in `.superpowers/brainstorm/` for reference. Add `.superpowers/` to `.gitignore` if not already there.
