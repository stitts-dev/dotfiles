---
name: playwright-manual-testing-workflow
description: Guide for executing manual testing plans using Playwright MCP plugin with systematic evidence capture
version: 1.0.0
author: system
tags: [testing, playwright, mcp, automation, pr-validation]
---

# Playwright Manual Testing Workflow

## Purpose

Execute manual testing plans systematically using the Playwright MCP plugin, capturing screenshot evidence and documenting results for PR validation. This skill enables comprehensive UI testing with organized evidence that can be attached to pull requests.

## When to Use

- User provides a manual testing plan with specific scenarios
- PR requires UI validation before merge
- Need to verify visual behavior across multiple user flows
- Testing edge cases in date pickers, forms, or interactive components
- Validating accessibility or UX patterns
- Creating visual documentation of feature behavior

## Prerequisites

1. **Playwright MCP Plugin** installed and configured
    - Tools available: `browser_navigate`, `browser_snapshot`, `browser_click`, `browser_type`, `browser_take_screenshot`
2. **Running Application** on localhost (typically port 80 or 3000)
3. **Test Plan** with defined scenarios, expected results, and test data requirements
4. **Valid Test Data** in the system (accounts, transactions, etc.)

## Core Workflow

### Step 1: Review Test Plan

Parse the test plan to identify:

- Number of test scenarios
- Expected outcomes for each
- Required test data (account types, transaction states)
- UI elements to interact with
- Screenshots needed as evidence

### Step 2: Navigate to Application

```
browser_navigate(url="http://localhost:80/path/to/feature")
```

Wait for page load, then take initial snapshot.

### Step 3: Capture Accessibility Tree

```
browser_snapshot()
```

This returns the accessibility tree with element references like:

- `ref=e3910` - clickable button
- `ref=e4521` - input field
- `ref=e5102` - dropdown menu

**Key Pattern**: Use these refs for reliable element targeting instead of CSS selectors.

### Step 4: Interact with Elements

Navigate the UI using accessibility refs:

```
browser_click(element="New Contribution", ref="e3910")
browser_type(element="Amount field", ref="e4521", text="500.00")
browser_click(element="Submit button", ref="e5102")
```

After each significant interaction, take a new snapshot to get updated refs.

### Step 5: Capture Screenshots

Use consistent naming convention:

```
browser_take_screenshot(filename="test1-contribution-helper-text.png")
browser_take_screenshot(filename="test1-contribution-calendar-past-disabled.png")
browser_take_screenshot(filename="test2-payment-dropdown-processing-times.png")
```

**Naming Pattern**: `testN-description.png`

- N = test scenario number
- description = what the screenshot shows (lowercase, hyphens)

### Step 6: Compile Test Results

Create a results table:

```markdown
| Scenario                       | Expected                           | Result  |
| ------------------------------ | ---------------------------------- | ------- |
| New Contribution - helper text | Shows same-day scheduling message  | ✅ PASS |
| New Contribution - calendar    | Past dates disabled                | ✅ PASS |
| Edit Distribution - date logic | Cannot change future date to today | ✅ PASS |
```

### Step 7: Update PR Documentation

1. **Edit PR description** with test results table:

    ```bash
    gh pr edit PR_NUMBER --body "$(cat updated_body.md)"
    ```

2. **Add PR comment** with screenshot guide:

    ```bash
    gh pr comment PR_NUMBER --body "## Test Screenshots

    ### Test 1: New Contribution
    - test1-contribution-helper-text.png - Helper text visible
    - test1-contribution-calendar-past-disabled.png - Past dates grayed

    ### Test 2: New Distribution
    ..."
    ```

## Best Practices

### Test Data Discovery

Before testing, verify valid test data exists:

- Navigate to list views first
- Check transaction/account status (avoid "Canceled", "Closed")
- Note IDs or names for test scenarios
- If no valid data, document and skip gracefully

### Accessibility Tree Navigation

- Take snapshots frequently - refs change after DOM updates
- Use descriptive element names in click commands for readability
- If ref not found, take new snapshot and find updated ref

### Screenshot Management

- Capture before AND after key interactions
- Include helper text, validation messages, disabled states
- Organize by test scenario number

### Edge Case Handling

- Document when test data is unavailable
- Note different UX patterns for same goal:
    - "Disable in calendar" vs "Allow click, then validate"
- Skip tests gracefully rather than forcing invalid scenarios

## Troubleshooting

### Invalid Test Data

**Problem**: Transaction shows "Canceled" status, cannot test edit flow.

**Solution**:

1. Navigate to list view
2. Find transaction with valid status (Pending, Scheduled)
3. Use that transaction for testing
4. Document skipped items in test notes

### Element Not Found

**Problem**: Click fails with "element not found"

**Solution**:

1. Take fresh `browser_snapshot()`
2. Find new ref for element
3. Verify element is visible/enabled
4. Retry with updated ref

### Page Not Loading

**Problem**: Navigate returns timeout or blank page

**Solution**:

1. Verify application is running (`curl localhost:80`)
2. Check correct port number
3. Ensure user is authenticated (may need to login first)

### Stale Accessibility Tree

**Problem**: Clicking ref from old snapshot fails

**Solution**:

- Always snapshot after navigation or major UI changes
- Refs are session-specific and change with DOM updates

## Examples

### Real Session: PR #503 (EX-1347) Same-Day Scheduling

**Test Plan**: 5 scenarios validating date picker behavior

**Scenarios Tested**:

1. **New Contribution** - Verified helper text and calendar disabled past dates
2. **New Distribution** - Tested ACH vs Check payment method hints
3. **New Distribution Recurring** - Validated dates 29-31 disabled for recurring
4. **Edit Distribution** - Confirmed future-dated cannot change to today
5. **Edit Contribution** - Verified different UX pattern (click-then-validate)

**Evidence Captured**: 11 screenshots organized by test number

**Edge Cases Handled**:

- Skipped canceled transaction, found valid one
- Documented different UX patterns between edit flows

**PR Updated**:

- Description with test results table
- Comment with organized screenshot guide

## Integration

Works with:

- **GitHub CLI** (`gh pr edit`, `gh pr comment`) for PR documentation
- **pr-review skill** for comprehensive PR validation workflows
- **retrospective skill** for capturing learnings from test sessions

## Success Criteria

A successful manual testing session includes:

- [ ] All scenarios from test plan executed
- [ ] Screenshots captured with consistent naming
- [ ] Test results table compiled (pass/fail for each)
- [ ] Edge cases documented
- [ ] PR updated with evidence
- [ ] Any failures logged with reproduction steps

## Changelog

### v1.0.0 (2024-12-31)

- Initial version
- 7-step workflow from test plan to PR documentation
- Accessibility tree navigation patterns
- Screenshot naming convention
- Troubleshooting guide
- Real example from PR #503

## Failure Log

<!-- Template for failure entries -->
<!--
### [Date] - [Brief Title]
**Context**: What was being tested
**Failure**: What went wrong
**Cause**: Root cause if identified
**Solution**: How it was resolved
**Prevention**: How to avoid in future
-->
