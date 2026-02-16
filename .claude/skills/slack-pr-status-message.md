# Slack PR Status Message

## Purpose

Generate formatted PR status messages for Slack team updates.

## Trigger

- "PR status for team"
- "open PRs message"
- "slack update for PRs"

## Slack Link Format

**Use standard markdown** - Slack supports it:

```
[#123](https://github.com/iralogix-software-engineering/unified-portal-ui/pull/123) Title here
```

**Avoid mrkdwn pipe format** - gets URL-encoded:

```
# ❌ Don't use - pipe becomes %7C
<https://github.com/iralogix-software-engineering/unified-portal-ui/pull/123|#123>
```

## Template

```markdown
PRs ready for review (ordered by priority/complexity):

• [#485](https://github.com/iralogix-software-engineering/unified-portal-ui/pull/485) TICKET-123 - Description
• [#498](https://github.com/iralogix-software-engineering/unified-portal-ui/pull/498) TICKET-456 - Description
```

## Workflow

1. Use `@git-github-expert` to fetch PR status:

    ```
    gh pr list --author @me
    gh pr view <num> --json title,reviewDecision,statusCheckRollup,mergeable
    ```

2. Categorize PRs:
    - Ready for review (pending/no reviews)
    - Approved (ready to merge)
    - Changes requested (needs work)
    - Has conflicts (needs rebase)

3. Order by priority/complexity (most important first)

4. Format with markdown links `[text](url)`

## Notes

- Slack hides link previews for messages with >5 links (expected behavior)
- Keep descriptions terse (5-7 words max)
