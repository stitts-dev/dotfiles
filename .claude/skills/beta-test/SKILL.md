---
name: beta-test
description: Playwright-based beta testing for Voxren desktop chat/coaching features. Use when user says "beta test", "test chat", "run beta tests", "validate chat", "test the app", "QA the UI", or wants to verify chat features work end-to-end. Also use PROACTIVELY after completing chat/coaching feature work — tasks are not done until beta-tested. Covers idle state, input behavior, streaming, panels, tier gates, error handling, and edge cases.
---

# Beta Test — Voxren Chat Feature Validation

You are a genuine beta tester. Your job is to find real bugs, not confirm things work. Be skeptical, try weird inputs, and break things. Document everything as user stories with screenshot evidence.

## Philosophy

Features are NOT done until beta-tested. This skill enforces that gate. When invoked after feature work, run the relevant subset of tests. When invoked standalone, run the full suite.

## Prerequisites Check

Before testing, verify the environment:

1. Confirm `make dev` is running (backend :8000 + synthesis :8001) — ask user if unsure
2. Confirm desktop dev server is on :1420 — ask user if unsure
3. If user says servers are running, trust them and proceed

## Setup

```
0. browser_close → gracefully close any existing Playwright session
   → If browser_navigate then fails with "Opening in existing browser session":
     → Run: pkill -f "Google Chrome.*mcp-chrome" 2>/dev/null
     → Wait 1 second
     → Retry browser_navigate
1. browser_navigate → http://localhost:1420
2. browser_resize → 1440 x 900 (input bar is fixed-bottom, invisible at small viewports)
3. browser_take_screenshot → "beta-00-initial-state.png"
4. browser_snapshot → capture accessibility tree, verify app loaded
```

After setup, create tasks for each test scenario using TaskCreate.

## Test Suite

Run tests in this order. For each test:
- Set task status to `in_progress` before starting
- Take screenshots as evidence (naming: `beta-{NN}-{description}.png`)
- Log PASS/FAIL/BUG with details
- Fix obvious bugs immediately (single-file, clear root cause)
- For ambiguous behavior, PAUSE and ask the user what they expect
- Set task status to `completed` when done

### Phase 1: Core Chat Flow

#### T-01: Idle State
**As a user** who just opened the app, I see a clear empty state and all controls are in appropriate defaults.

- [ ] Empty state message is visible and centered
- [ ] Input bar has placeholder text
- [ ] Send button is disabled (no text entered)
- [ ] Panel buttons (Builds, Matchups, Stats, Review) are visible
- [ ] No console errors on load (check `browser_console_messages`)

#### T-02: Input Bar Behavior
**As a user**, I can type messages, send them, and the input behaves predictably.

- [ ] Type text → send button enables (gradient appears)
- [ ] Clear text → send button disables
- [ ] Whitespace-only → send button stays disabled
- [ ] Enter key sends message
- [ ] Send button click sends message
- [ ] Input clears after sending
- [ ] Input disables during streaming ("Analyzing..." placeholder)
- [ ] Input re-enables after stream completes

```js
// Whitespace test
browser_type(ref, "   ") → verify send still disabled
// Send test
browser_type(ref, "test message", submit=true) → verify message appears in feed
```

#### T-03: Coaching Chat Round-Trip
**As a user**, I send a question and receive a streamed coaching response.

- [ ] Send "What should I build against Zed?"
- [ ] User message appears right-aligned with user icon
- [ ] Vox response streams in with avatar + "VOX" label
- [ ] Response contains relevant coaching content (not generic)
- [ ] Markdown renders correctly (bold, bullets, blockquotes)
- [ ] Input re-enables after response completes

Wait for streaming completion using:
```js
browser_evaluate: () => new Promise(resolve => {
  const check = () => {
    const input = document.querySelector('input[id="coach-input"]');
    if (!input?.disabled) resolve('done');
    else setTimeout(check, 1000);
  };
  setTimeout(check, 3000);
})
```

#### T-04: Follow-Up Messages
**As a user**, I can send follow-up questions that maintain conversation context.

- [ ] After T-03 completes, send a follow-up question
- [ ] Previous messages remain visible in feed
- [ ] Response references prior conversation context
- [ ] Multiple follow-ups work without errors

#### T-05: Clear Chat
**As a user**, I can clear all messages and reset to the initial state.

- [ ] Click clear chat button (trash icon)
- [ ] All messages removed from feed
- [ ] Empty state message reappears
- [ ] Input placeholder resets to default
- [ ] Console shows `[CoachStream] Reset`

### Phase 2: Demo & Champ Select

#### T-06: Demo Scenario
**As a user** (dev), I trigger a demo and see the champ select HUD.

```js
browser_evaluate: () => { window.demo(1); }
```

- [ ] HUD header appears with champion portraits
- [ ] Lane selector shows detected lane (e.g., "MID")
- [ ] Enemy champions have red glow ring
- [ ] CC badges visible on champions with hard CC
- [ ] Input shows "Analyzing..." during draft phase
- [ ] After demo ends, input re-enables (draftPhase → 'complete')
- [ ] No stuck "Analyzing..." state

### Phase 3: Panels

#### T-07: Panel Buttons
**As a user**, I can open/close overlay panels from the toolbar.

- [ ] Click Builds → Builds panel opens with build data
- [ ] Click Matchups → replaces Builds panel (only one open)
- [ ] Click Matchups again → panel closes (toggle off)
- [ ] Click Stats → Stats panel opens
- [ ] Close via X button works
- [ ] Chat feed resizes when panel is open
- [ ] Active panel button is highlighted in toolbar

### Phase 4: Edge Cases & Security

#### T-08: XSS / Special Characters
**As a user**, special characters in my messages don't break the UI.

```js
// Send XSS attempt
browser_type(ref, "<script>alert('xss')</script> **bold** `code`", submit=true)
```

- [ ] Script tag renders as literal text (not executed)
- [ ] No alert dialog appears
- [ ] Markdown syntax shows as plain text in user bubble
- [ ] Vox responds without crashing

#### T-09: Rapid Double-Send
**As a user**, clicking send twice quickly doesn't cause duplicate streams.

```js
// Type message first, then double-click programmatically
browser_evaluate: () => {
  const btn = document.querySelector('button[aria-label="Send message"]');
  btn?.click(); btn?.click();
}
```

- [ ] Only one user message appears in feed
- [ ] Only one streaming response starts
- [ ] No "duplicate key" React errors in console
- [ ] Check `browser_console_messages(level="error")` for key errors

#### T-10: Error Handling
**As a user**, when errors occur I see friendly messages, not raw stack traces.

- [ ] Error messages are user-friendly (no raw JS errors, no `Cannot read properties`)
- [ ] Error banner has appropriate styling (icon + colored background)
- [ ] No trailing colons in error messages (e.g., not "Chat request failed (500):")
- [ ] Input re-enables after error (can retry)

### Phase 5: Tier Gates

#### T-11: Tier Enforcement
**As a user**, tier-gated features show appropriate UI for my tier level.

- [ ] Check current tier in auth store (browser mode defaults to 'free')
- [ ] DebateFollowUpBar shows lock icon for free tier (requires champ select + debate)
- [ ] Main input bar has no client-side tier gate (free users can chat)
- [ ] Backend enforces budget/credits for free tier

## Bug Handling

When you find a bug:

1. **Screenshot it** with descriptive filename
2. **Classify severity**: High (crash/stuck state), Medium (wrong behavior), Low (cosmetic)
3. **If obvious fix** (single file, clear root cause) → fix it immediately, re-test
4. **If ambiguous** → pause and ask the user what they expect
5. **If complex** → document it and move on

### Known Bug Patterns to Watch For

These have bitten us before — actively check for them:

| Pattern | Symptom | Root Cause |
|---------|---------|------------|
| Missing `IS_TAURI` guard | Raw JS error in browser mode | `invoke()` called without Tauri check |
| `draftPhase` not `'complete'` | Input stuck in "Analyzing..." | Champ select exit path missing state transition |
| React state batching race | Duplicate streams on double-click | `isStreaming` state doesn't block synchronous calls |
| Stale refs after HMR | Click fails with "ref not found" | Hot reload changed DOM, need fresh `browser_snapshot()` |

## Cross-Cutting: Console Error Audit

After every test phase, run `browser_console_messages(level="error")` and check for:
- React duplicate key warnings (double-send race)
- Unhandled promise rejections (missing error boundaries)
- `invoke` or `TypeError` errors (browser-mode incompatibility)
- Network errors beyond expected 500s

Log any new errors not present at session start.

## Final Report

After all tests complete, produce a summary table AND save it to a file:

```markdown
## Beta Test Results — {date}

| Test | Description | Result | Notes |
|------|-------------|--------|-------|
| T-01 | Idle state | PASS/FAIL/BUG | ... |
| ...  | ...         | ...    | ... |

### Bugs Found
- BUG-1: [severity] description — {fixed/open}

### Recommendations
- ...

### Screenshots
- beta-00-initial-state.png
- beta-01-idle-state.png
- ...
```

Save the report to `.planning/audit/beta-test-{date}.md` for traceability.

## Relationship to Other Skills

- **`/coach-test`** — Pipeline QA (runs 10 randomized coach sessions at 1x speed). Tests the coaching *pipeline*, not the UI. Complementary.
- **`/validate-champ-select`** — Champ select HUD validation (demos 1-10 at 10x speed). Overlaps with T-06 but is more thorough for champ select specifically. Use that for champ-select-only work.
- **`/beta-test`** (this skill) — Chat/coaching *UI* quality gate. Covers the full chat experience: input, streaming, panels, errors, edge cases.

## Selective Testing

When invoked after specific feature work, run only the relevant subset:

- **Chat/messaging changes** → T-01 through T-05, T-08, T-09
- **Panel changes** → T-07
- **Champ select changes** → T-06
- **Auth/tier changes** → T-11
- **Error handling changes** → T-10
- **Full regression** → all tests (default when invoked standalone)
