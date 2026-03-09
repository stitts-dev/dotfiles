# ===== Jira Workflow Functions (jira-cli Integration) =====

# Enhanced validation for Jira environment
validate_jira_environment() {
    local function_name="$1"

    # Check if jira CLI is installed
    if ! command -v jira &> /dev/null; then
        echo "{\"status\":\"error\",\"message\":\"jira-cli not installed\",\"action\":\"brew install jira-cli\",\"context\":{\"function\":\"$function_name\"}}"
        return 1
    fi

    # Check if config exists
    if [[ ! -f ~/.config/.jira/.config.yml ]]; then
        echo "{\"status\":\"error\",\"message\":\"Jira config not found\",\"action\":\"Run: jira init\",\"context\":{\"function\":\"$function_name\"}}"
        return 1
    fi

    # Test connectivity (jira-cli will pull token from keychain automatically)
    if ! jira me &> /dev/null; then
        echo "{\"status\":\"error\",\"message\":\"Cannot connect to Jira\",\"action\":\"Verify API token in keychain (service: jira-cli, account: jstittsworth@iralogix.com)\",\"context\":{\"function\":\"$function_name\"}}"
        return 1
    fi

    return 0
}

# Core function to fetch Jira ticket context
get_jira_ticket_context() {
    local ticket="$1"
    local test_mode="${2:-false}"

    if [[ "$test_mode" == true ]]; then
        # Return mock data for testing
        cat <<EOF
# Jira Ticket: TEST-123

**Summary**: Test ticket for development
**Status**: In Progress
**Assignee**: Test User
**Priority**: High
**Type**: Bug
**Labels**: backend, testing

## Description
This is a test ticket used for development and testing purposes.

## Comments
- Test User (1 day ago): This is a test comment

## Linked Issues
None

## Recent Activity
- Status changed to In Progress (1 day ago)
EOF
        return 0
    fi

    # Fetch ticket details using jira-cli with raw JSON output
    local ticket_data=$(jira issue view "$ticket" --raw 2>&1)
    local jira_exit_code=$?

    if [[ $jira_exit_code -ne 0 ]] || [[ -z "$ticket_data" ]]; then
        echo "{\"status\":\"error\",\"message\":\"Failed to fetch ticket $ticket\",\"action\":\"Verify ticket exists and JIRA_API_TOKEN is valid\",\"context\":{\"ticket\":\"$ticket\",\"error\":\"$(echo $ticket_data | head -1)\"}}"
        return 1
    fi

    # Parse JSON and format as markdown
    local summary=$(echo "$ticket_data" | jq -r '.fields.summary // "No summary"')
    local ticket_status=$(echo "$ticket_data" | jq -r '.fields.status.name // "Unknown"')
    local assignee=$(echo "$ticket_data" | jq -r '.fields.assignee.displayName // "Unassigned"')
    local priority=$(echo "$ticket_data" | jq -r '.fields.priority.name // "None"')
    local issuetype=$(echo "$ticket_data" | jq -r '.fields.issuetype.name // "Unknown"')
    local reporter=$(echo "$ticket_data" | jq -r '.fields.reporter.displayName // "Unknown"')
    local created=$(echo "$ticket_data" | jq -r '.fields.created // "Unknown"')
    local updated=$(echo "$ticket_data" | jq -r '.fields.updated // "Unknown"')
    local description=$(echo "$ticket_data" | jq -r '.fields.description // "No description"')
    local labels=$(echo "$ticket_data" | jq -r '.fields.labels[]? // empty' | tr '\n' ', ' | sed 's/,$//')

    # Get comments
    local comments=$(echo "$ticket_data" | jq -r '.fields.comment.comments[]? | "- \(.author.displayName) (\(.created | split("T")[0])): \(.body)"' 2>/dev/null || echo "No comments")

    # Get linked issues
    local linked=$(echo "$ticket_data" | jq -r '.fields.issuelinks[]? | "\(.type.name): \(.outwardIssue.key // .inwardIssue.key) - \(.outwardIssue.fields.summary // .inwardIssue.fields.summary)"' 2>/dev/null || echo "No linked issues")

    # Get subtasks
    local subtasks=$(echo "$ticket_data" | jq -r '.fields.subtasks[]? | "- [\(.key)] \(.fields.summary) (\(.fields.status.name))"' 2>/dev/null || echo "")

    # Get epic info if it exists
    local epic_name=$(echo "$ticket_data" | jq -r '.fields.customfield_10014 // empty' 2>/dev/null)
    local epic_link=$(echo "$ticket_data" | jq -r '.fields.customfield_10016 // empty' 2>/dev/null)

    # Build markdown output
    cat <<EOF
# Jira Ticket: $ticket

**Summary**: $summary
**Status**: $ticket_status
**Type**: $issuetype
**Priority**: $priority
**Assignee**: $assignee
**Reporter**: $reporter
**Created**: $(echo "$created" | cut -d'T' -f1)
**Updated**: $(echo "$updated" | cut -d'T' -f1)
$([ -n "$labels" ] && echo "**Labels**: $labels")
$([ -n "$epic_name" ] && echo "**Epic**: $epic_name")
$([ -n "$epic_link" ] && echo "**Epic Link**: $epic_link")

## Description

$description

## Comments

$comments

## Linked Issues

$linked

$([ -n "$subtasks" ] && echo "## Subtasks\n\n$subtasks")

---
*Jira URL*: $(grep -E '^server:' ~/.config/.jira/.config.yml | awk '{print $2}')/browse/$ticket
EOF
}

# Main function: Load Jira ticket context into Claude Code
cc-jira() {
    local test_mode=false
    local ticket=""

    # Parse arguments
    if [[ "$1" == "-t" ]]; then
        test_mode=true
        shift
    fi

    ticket="$1"

    # Validate ticket argument
    if [[ -z "$ticket" ]]; then
        echo "{\"status\":\"error\",\"message\":\"Ticket ID required\",\"action\":\"cc-jira TICKET-ID\",\"context\":{\"function\":\"cc-jira\"}}"
        return 1
    fi

    # Validate ticket format (PROJECT-NUMBER)
    if ! [[ "$ticket" =~ ^[A-Z]+-[0-9]+$ ]]; then
        echo "{\"status\":\"warning\",\"message\":\"Unusual ticket format\",\"action\":\"Expected format: PROJ-123\",\"context\":{\"ticket\":\"$ticket\"}}"
    fi

    # Validate environment
    local validation_result
    validation_result=$(validate_jira_environment "cc-jira")
    if [[ $? -ne 0 ]]; then
        echo "$validation_result"
        return 1
    fi

    echo "🔍 Fetching Jira ticket: $ticket"

    # Fetch ticket context
    local context
    context=$(get_jira_ticket_context "$ticket" "$test_mode")

    if [[ $? -ne 0 ]]; then
        echo "$context"
        return 1
    fi

    # Build prompt with context + planning instructions
    local prompt="# Jira Ticket Context

$context

---

## Instructions

Assume I have NOT read this ticket. Provide a comprehensive initial analysis:

1. **Ticket Summary**: Summarize what this ticket is asking for in 2-3 sentences. Extract the core problem/feature and acceptance criteria.

2. **Codebase Research**: Explore the codebase to identify:
   - Affected files and components
   - Existing patterns we should follow
   - Related implementations to reference

3. **Implementation Plan**: Present potential solutions with:
   - Recommended approach (with rationale)
   - Alternative approaches (if applicable)
   - Key technical decisions and trade-offs
   - Estimated scope/complexity

4. **Open Questions**: List any ambiguities or decisions that need input, embedded in the plan (don't block on them).

Do NOT ask clarifying questions first - present your analysis and let me react to it."

    if [[ "$test_mode" == true ]]; then
        echo "=== PROMPT PREVIEW (Test Mode) ==="
        echo "$prompt"
        echo ""
        echo "[TEST MODE] Would run: claude -p \"<prompt>\""
        return 0
    fi

    echo "✅ Context fetched successfully"
    echo "   Ticket: $ticket"
    echo ""
    echo "🚀 Opening Claude Code with context..."
    echo ""

    # Open Claude Code interactively with prompt
    claude "$prompt"
}

# Daily standup report generator
jira-standup() {
    local test_mode=false
    local format="${1:-display}"

    # Parse arguments
    if [[ "$1" == "-t" ]]; then
        test_mode=true
        shift
        format="${1:-display}"
    fi

    # Validate environment
    local validation_result
    validation_result=$(validate_jira_environment "jira-standup")
    if [[ $? -ne 0 ]]; then
        echo "$validation_result"
        return 1
    fi

    echo "=== Daily Standup Generator ==="
    echo ""

    if [[ "$test_mode" == true ]]; then
        cat <<EOF
## What I accomplished yesterday
- [TEST-123] Fixed authentication bug
- [TEST-124] Updated documentation

## What I'm working on today
- [TEST-125] Implement new feature
- [TEST-126] Code review

## Blockers/Help needed
- None at this time

[TEST MODE] Format: $format
EOF
        return 0
    fi

    # Fetch yesterday's activity
    local yesterday=$(jira issue list --jql "assignee=currentUser() AND updated >= -24h" --order-by updated --plain --no-headers --columns "KEY,SUMMARY,STATUS" 2>&1)
    if [[ $? -ne 0 ]]; then
        echo "❌ Error fetching yesterday's activity"
        echo "   Error: $(echo $yesterday | head -1)"
        return 1
    fi

    # Fetch current in-progress work (active statuses in your workflow)
    local in_progress=$(jira issue list --jql "assignee=currentUser() AND status IN ('In Development', 'Code Review', 'Deploy Review', 'Ready for QA', 'QA Testing')" --order-by priority --plain --no-headers --columns "KEY,SUMMARY,PRIORITY" 2>&1)

    # Fetch blockers (use 'Blocked' status or tickets with 'blocked' label)
    local blockers=$(jira issue list --jql "assignee=currentUser() AND (status='Blocked' OR labels='blocked')" --order-by priority --plain --no-headers --columns "KEY,SUMMARY,PRIORITY" 2>&1)

    # Handle "no results" for blockers gracefully
    if echo "$blockers" | grep -q "No result found"; then
        blockers="None at this time"
    fi

    # Format output
    local standup_content=$(cat <<EOF
## What I accomplished yesterday

$yesterday

## What I'm working on today

$in_progress

## Blockers/Help needed

$blockers

---
*Generated: $(date)*
EOF
)

    # Handle output format
    case "$format" in
        display)
            echo "$standup_content"
            ;;
        copy)
            echo "$standup_content" | pbcopy
            echo "📋 Standup copied to clipboard!"
            ;;
        file)
            local filename="standup_$(date +%Y%m%d).md"
            echo "$standup_content" > "$filename"
            echo "💾 Saved to $filename"
            ;;
        *)
            echo "$standup_content"
            ;;
    esac
}

# Helper function: Fetch git commits from last 24 hours across all repos via GitHub CLI
fetch_git_commits_24h() {
    local test_mode="${1:-false}"
    local since_time="${2:-24 hours ago}"  # Configurable time window

    # Test mode: return mock data
    if [[ "$test_mode" == true ]]; then
        cat <<EOF
[EX-1045] (unified-portal-ui) 9bde0d2 Fix distribution bug with Docusign payment frequency
[EX-1045] (unified-portal-ui) 84c8b33 Add tests for distribution fix
[EX-999] (unified-portal-xl) abc1234 Update profile cache logic
[NO-TICKET] (docs) def5678 Fix typo in README
EOF
        return 0
    fi

    # Get git author name from config
    local author=$(git config user.name 2>/dev/null)
    if [[ -z "$author" ]]; then
        echo "(Unable to get git author name)"
        return 1
    fi

    # Find all git repositories under ~/Documents/repos recursively
    local repos_base=~/Documents/repos
    if [[ ! -d "$repos_base" ]]; then
        echo "(Repos directory not found: $repos_base)"
        return 1
    fi

    local all_commits=""
    local jira_pattern='[A-Z]+-[0-9]+'

    # Find all .git directories (repos) recursively
    while IFS= read -r git_dir; do
        if [[ -n "$git_dir" ]]; then
            # Get the repo directory (parent of .git)
            local repo_dir="${git_dir%/.git}"

            # Extract repo name from path (relative to repos_base)
            local repo_name=$(echo "$repo_dir" | sed "s|^$repos_base/||" | sed 's|/|-|g')

            # Get commits from this repo
            local commits=$(git -C "$repo_dir" log --since="$since_time" --author="$author" --pretty=format:"%h|%s" 2>/dev/null)

            if [[ -n "$commits" ]]; then
                # Parse each commit
                while IFS='|' read -r sha message; do
                    if [[ -n "$sha" ]] && [[ -n "$message" ]]; then
                        # Extract ticket ID from message
                        local ticket=$(echo "$message" | grep -oE "$jira_pattern" | head -1)

                        if [[ -n "$ticket" ]]; then
                            all_commits+="[$ticket] ($repo_name) $sha $message"$'\n'
                        else
                            all_commits+="[NO-TICKET] ($repo_name) $sha $message"$'\n'
                        fi
                    fi
                done <<< "$commits"
            fi
        fi
    done < <(find "$repos_base" -name ".git" -type d 2>/dev/null)

    if [[ -z "$all_commits" ]]; then
        echo "No commits found since $since_time"
    else
        echo "$all_commits"
    fi
}

# AI-enhanced daily standup with executive summary
jira-ai-standup() {
    local test_mode=false
    local format="${1:-display}"

    # Parse arguments
    if [[ "$1" == "-t" ]]; then
        test_mode=true
        shift
        format="${1:-display}"
    fi

    # Validate environment
    local validation_result
    validation_result=$(validate_jira_environment "jira-ai-standup")
    if [[ $? -ne 0 ]]; then
        echo "$validation_result"
        return 1
    fi

    # Check Claude CLI availability
    if ! command -v claude &> /dev/null; then
        echo "{\"status\":\"error\",\"message\":\"Claude CLI not installed\",\"action\":\"Install Claude Code CLI\",\"context\":{\"function\":\"jira-ai-standup\"}}"
        return 1
    fi

    echo "=== AI-Enhanced Standup Generator ==="
    echo ""

    if [[ "$test_mode" == true ]]; then
        cat <<EOF
EXECUTIVE SUMMARY:
Focused on critical distribution fixes and profile improvements. Completed 3 high-priority bugs affecting cash distributions and beneficiary setup. Currently working on 5 features spanning authentication, profile settings, and document handling. Git activity shows 4 commits across 3 repos with strong correlation to Jira tickets.

YESTERDAY'S WORK (Grouped by Theme):
- **Distributions (EX-1045)**: Fixed Docusign payment frequency bug with 2 commits (implementation + tests)
- **Profile (EX-999)**: Completed profile caching root cause analysis, 1 commit updating cache logic
- **Documents**: Fixed activation document URL error
- **Other Work**: Documentation improvements (README typo fix)

CURRENT FOCUS (Grouped by Theme):
- **Distributions**: Integrating Docusign for transfer/rollover flows, fixing unfunded account selection
- **Profile**: Updating legal status/marital status/gender update functionality
- **Authentication**: Implementing password recovery and reset flows

BLOCKERS:
- None at this time

GIT ACTIVITY (Last 24 Hours):
Commits with Jira tickets:
  - EX-1045: 2 commits in unified-portal-ui (Fix + tests for distribution bug)
  - EX-999: 1 commit in unified-portal-xl (Profile cache update)

Other work:
  - 1 commit in docs (README typo fix)

[TEST MODE] Format: $format
EOF
        return 0
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 1: GIT COMMITS (PRIMARY EVIDENCE)
    # ═══════════════════════════════════════════════════════════════════════════
    echo "🔍 Fetching git commits (primary evidence)..."

    local git_commits=$(fetch_git_commits_24h "$test_mode" 2>&1)
    local git_fetch_status=$?
    local commit_ticket_ids=""
    local commit_tickets_context=""

    # Handle git fetch errors gracefully
    if [[ $git_fetch_status -ne 0 ]] || [[ "$git_commits" == *"not installed"* ]] || [[ "$git_commits" == *"not authenticated"* ]]; then
        echo "⚠️  $git_commits - continuing with Jira-only standup"
        git_commits="(Git commit context unavailable)"
    elif [[ "$git_commits" == "No commits found"* ]]; then
        echo "ℹ️  No git commits found in last 24 hours"
        git_commits="(No commits in last 24h)"
    else
        local commit_count=$(echo "$git_commits" | grep -c '^' | tr -d ' ')
        echo "✅ Found $commit_count commit(s) from last 24 hours"

        # Extract unique ticket IDs from commits
        commit_ticket_ids=$(echo "$git_commits" | grep -oE '\[[A-Z]+-[0-9]+\]' | tr -d '[]' | sort -u | tr '\n' ',' | sed 's/,$//')

        echo ""
        echo "┌─────────────────────────────────────────────────────────────────────────────┐"
        echo "│ GIT COMMITS (PRIMARY EVIDENCE)                                              │"
        echo "├─────────────────────────────────────────────────────────────────────────────┤"
        echo "$git_commits" | sed 's/^/│   /'
        echo "└─────────────────────────────────────────────────────────────────────────────┘"
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 2: JIRA CONTEXT FOR COMMITTED TICKETS
    # ═══════════════════════════════════════════════════════════════════════════
    echo ""
    echo "📊 Fetching Jira context..."

    if [[ -n "$commit_ticket_ids" ]]; then
        echo "   → Looking up tickets from commits: $commit_ticket_ids"
        commit_tickets_context=$(jira issue list --jql "key IN ($commit_ticket_ids)" --order-by priority --plain --no-headers --columns "KEY,SUMMARY,STATUS,PRIORITY" 2>&1)

        if echo "$commit_tickets_context" | grep -q "No result found"; then
            commit_tickets_context="(No Jira tickets found for commit IDs)"
        fi
    else
        commit_tickets_context="(No ticket IDs found in commits)"
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 3: USER'S STATUS CHANGES (narrower than "updated")
    # ═══════════════════════════════════════════════════════════════════════════
    local user_status_changes=$(jira issue list --jql "assignee=currentUser() AND status CHANGED BY currentUser() AFTER -24h" --order-by updated --plain --no-headers --columns "KEY,SUMMARY,STATUS" 2>&1)

    if echo "$user_status_changes" | grep -q "No result found"; then
        user_status_changes="(No status changes by you in last 24h)"
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # STEP 4: IN-PROGRESS WORK & BLOCKERS
    # ═══════════════════════════════════════════════════════════════════════════
    local in_progress=$(jira issue list --jql "assignee=currentUser() AND status IN ('In Development', 'Code Review', 'Deploy Review', 'Ready for QA', 'QA Testing')" --order-by priority --plain --no-headers --columns "KEY,SUMMARY,PRIORITY" 2>&1)

    if echo "$in_progress" | grep -q "No result found"; then
        in_progress="(No tickets currently in progress)"
    fi

    local blockers=$(jira issue list --jql "assignee=currentUser() AND (status='Blocked' OR labels='blocked')" --order-by priority --plain --no-headers --columns "KEY,SUMMARY,PRIORITY" 2>&1)

    if echo "$blockers" | grep -q "No result found"; then
        blockers="None"
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # DISPLAY COLLECTED DATA
    # ═══════════════════════════════════════════════════════════════════════════
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────────────────┐"
    echo "│ JIRA CONTEXT FOR COMMITTED TICKETS                                          │"
    echo "├─────────────────────────────────────────────────────────────────────────────┤"
    echo "$commit_tickets_context" | sed 's/^/│   /'
    echo "├─────────────────────────────────────────────────────────────────────────────┤"
    echo "│ YOUR STATUS CHANGES (last 24h):                                             │"
    echo "$user_status_changes" | sed 's/^/│   /'
    echo "├─────────────────────────────────────────────────────────────────────────────┤"
    echo "│ IN-PROGRESS WORK:                                                           │"
    echo "$in_progress" | sed 's/^/│   /'
    echo "├─────────────────────────────────────────────────────────────────────────────┤"
    echo "│ BLOCKERS:                                                                   │"
    echo "$blockers" | sed 's/^/│   /'
    echo "└─────────────────────────────────────────────────────────────────────────────┘"

    echo ""
    echo "🤖 Generating AI summary with Haiku..."
    echo ""

    # Build Claude prompt with git-first approach (using Haiku for speed/cost)
    local ai_summary=$(claude --model haiku -p "Generate a standup summary. Git commits are the PRIMARY evidence of actual work.

═══════════════════════════════════════════════════════════════════════════════
GIT COMMITS (PRIMARY EVIDENCE - Last 24 Hours):
$git_commits

JIRA CONTEXT FOR COMMITTED TICKETS:
$commit_tickets_context

YOUR JIRA STATUS CHANGES (tickets YOU transitioned in last 24h):
$user_status_changes

IN-PROGRESS WORK (current assignments):
$in_progress

BLOCKERS:
$blockers
═══════════════════════════════════════════════════════════════════════════════

CRITICAL PRIORITY:
1. GIT COMMITS are the PRIMARY evidence of actual work done
2. Only report tickets that appear in git commits OR that you personally transitioned
3. Do NOT include tickets that were merely 'updated' by others (QA, automation, managers)
4. If a ticket has commits, that PROVES you worked on it - lead with these
5. Status changes without commits = non-code work (planning, review, meetings)

CORRELATION RULES:
- [EX-1045] in commits → you coded on that ticket (mention commit count)
- [NO-TICKET] commits → tech debt, docs, minor fixes (list in 'Other Work')
- Ticket in status changes but NOT in commits → non-code activity (planning, review)
- Use JIRA CONTEXT to get ticket summaries for committed work

Generate output in this EXACT format:

EXECUTIVE SUMMARY:
[2-3 sentences. Lead with git commit stats (e.g., 'Committed X changes across Y repos'). Mention key tickets worked on. Write in first person.]

YESTERDAY'S WORK (Grouped by Theme):
- **Theme Name (TICKET-ID)**: Brief summary with commit evidence
[ONLY include tickets with git commits OR that you personally transitioned. Group by feature area.]

CURRENT FOCUS (Grouped by Theme):
- **Theme Name**: What you're actively working on
[From in-progress tickets, prioritize P0/P1]

BLOCKERS:
[List or 'None at this time']

OTHER WORK (if applicable):
[NO-TICKET commits - docs, tech debt, config changes]

IMPORTANT:
- Lead with commit-backed work (provable progress)
- Do NOT include tickets you didn't actually touch
- Keep executive summary concise for managers
- Return ONLY the formatted output, no commentary" 2>&1)

    local claude_exit_code=$?

    if [[ $claude_exit_code -ne 0 ]] || [[ -z "$ai_summary" ]]; then
        echo "❌ Failed to generate AI summary"
        echo "   Error: $(echo $ai_summary | head -1)"
        echo ""
        echo "Falling back to standard standup format..."
        jira-standup "$format"
        return 1
    fi

    # Clean up any markdown formatting from Claude response
    ai_summary=$(echo "$ai_summary" | sed 's/^```markdown//g' | sed 's/^```//g' | sed 's/```$//g')

    # Format final output with timestamp
    local standup_content=$(cat <<EOF
$ai_summary

---
*Generated: $(date)*
EOF
)

    # Handle output format
    case "$format" in
        display)
            echo "$standup_content"
            ;;
        copy)
            echo "$standup_content" | pbcopy
            echo "📋 AI-enhanced standup copied to clipboard!"
            ;;
        file)
            local filename="ai_standup_$(date +%Y%m%d).md"
            echo "$standup_content" > "$filename"
            echo "💾 Saved to $filename"
            ;;
        *)
            echo "$standup_content"
            ;;
    esac
}

# Intelligent JQL query helper using Claude
jql() {
    local test_mode=false
    local natural_query=""
    local execute=false

    # Parse arguments
    if [[ "$1" == "-t" ]]; then
        test_mode=true
        shift
    fi

    if [[ "$1" == "-x" ]] || [[ "$1" == "--execute" ]]; then
        execute=true
        shift
    fi

    natural_query="$*"

    if [[ -z "$natural_query" ]]; then
        echo "{\"status\":\"error\",\"message\":\"Query required\",\"action\":\"jql 'natural language query'\",\"context\":{\"function\":\"jql\"}}"
        return 1
    fi

    # Validate environment
    local validation_result
    validation_result=$(validate_jira_environment "jql")
    if [[ $? -ne 0 ]]; then
        echo "$validation_result"
        return 1
    fi

    echo "🤖 Translating natural language to JQL..."
    echo "Query: \"$natural_query\""
    echo ""

    if [[ "$test_mode" == true ]]; then
        local test_jql="project = TEST AND assignee = currentUser() AND status = 'In Progress'"
        echo "Generated JQL: $test_jql"
        echo ""
        echo "[TEST MODE] Would execute: jira issue list --jql \"$test_jql\""
        return 0
    fi

    # Use Claude to translate natural language to JQL
    local jql_query=$(claude -p "Convert this natural language Jira query to JQL syntax. Return ONLY the JQL query, no explanation:

Natural query: $natural_query

Common JQL patterns:
- Use currentUser() for 'me' or 'my'
- Status values: 'Backlog', 'In Development', 'Code Review', 'Deploy Review', 'Ready for QA', 'QA Testing', 'UAT', 'Ready for Production', 'Done'
- For active work, use: status IN ('In Development', 'Code Review', 'Deploy Review', 'Ready for QA', 'QA Testing')
- Date filters: created >= -7d (last 7 days), updated >= startOfWeek()
- Priority: Highest, High, Medium, Low, Lowest
- Type: Bug, Task, Story, Epic
- Use ORDER BY for sorting

JQL Query:" 2>&1)
    local claude_exit_code=$?

    if [[ $claude_exit_code -ne 0 ]] || [[ -z "$jql_query" ]]; then
        echo "❌ Failed to translate query using Claude"
        echo "   Error: $(echo $jql_query | head -1)"
        return 1
    fi

    # Clean up the JQL query (remove any markdown formatting and ORDER BY clause)
    jql_query=$(echo "$jql_query" | sed 's/^```jql//g' | sed 's/^```//g' | sed 's/```$//g' | xargs)

    # Extract ORDER BY if present and convert to --order-by flag
    local order_by_clause=""
    local reverse_flag=""
    if echo "$jql_query" | grep -qi "ORDER BY"; then
        order_by_clause=$(echo "$jql_query" | sed -n 's/.*ORDER BY \([^ ]*\).*/\1/Ip')
        if echo "$jql_query" | grep -qi "DESC"; then
            reverse_flag="--reverse"
        fi
        jql_query=$(echo "$jql_query" | sed 's/ ORDER BY.*//I')
    fi

    echo "✅ Generated JQL:"
    echo "   $jql_query"
    if [[ -n "$order_by_clause" ]]; then
        echo "   Ordering by: $order_by_clause $([ -n \"$reverse_flag\" ] && echo \"(DESC)\" || echo \"(ASC)\")"
    fi
    echo ""

    if [[ "$execute" == true ]]; then
        echo "📊 Executing query..."
        echo ""
        if [[ -n "$order_by_clause" ]]; then
            jira issue list --jql "$jql_query" --order-by "$order_by_clause" $reverse_flag
        else
            jira issue list --jql "$jql_query"
        fi
    else
        if [[ -n "$order_by_clause" ]]; then
            echo "Run with -x or --execute to execute immediately, or use:"
            echo "   jira issue list --jql \"$jql_query\" --order-by \"$order_by_clause\" $reverse_flag"
        else
            echo "Run with -x or --execute to execute immediately, or use:"
            echo "   jira issue list --jql \"$jql_query\""
        fi
    fi
}

# Quick Jira search wrapper
jira-search() {
    local test_mode=false
    local filter="${1:-mine}"

    # Parse arguments
    if [[ "$1" == "-t" ]]; then
        test_mode=true
        shift
        filter="${1:-mine}"
    fi

    # Validate environment
    local validation_result
    validation_result=$(validate_jira_environment "jira-search")
    if [[ $? -ne 0 ]]; then
        echo "$validation_result"
        return 1
    fi

    local query=""
    local order_by="updated"
    local reverse_flag=""

    case "$filter" in
        mine)
            query="assignee=currentUser() AND resolution=unresolved"
            order_by="updated"
            reverse_flag="--reverse"
            ;;
        bugs)
            query="assignee=currentUser() AND type=Bug AND resolution=unresolved"
            order_by="priority"
            reverse_flag="--reverse"
            ;;
        in-progress|ip)
            query="assignee=currentUser() AND status IN ('In Development', 'Code Review', 'Deploy Review', 'Ready for QA', 'QA Testing')"
            order_by="priority"
            reverse_flag="--reverse"
            ;;
        blocked)
            query="assignee=currentUser() AND (status='Blocked' OR labels='blocked')"
            order_by="priority"
            reverse_flag="--reverse"
            ;;
        today)
            query="assignee=currentUser() AND updated >= startOfDay()"
            order_by="updated"
            reverse_flag="--reverse"
            ;;
        week)
            query="assignee=currentUser() AND updated >= startOfWeek()"
            order_by="updated"
            reverse_flag="--reverse"
            ;;
        *)
            # Treat as custom JQL
            query="$*"
            order_by="created"
            reverse_flag=""
            ;;
    esac

    if [[ "$test_mode" == true ]]; then
        echo "[TEST MODE] Query: $query"
        echo "[TEST MODE] Would execute: jira issue list --jql \"$query\" --order-by $order_by $reverse_flag"
        return 0
    fi

    echo "🔍 Searching: $filter"
    echo ""
    jira issue list --jql "$query" --order-by "$order_by" $reverse_flag
}

# Quick Jira actions
jira-quick() {
    local test_mode=false
    local action="$1"

    # Parse arguments
    if [[ "$1" == "-t" ]]; then
        test_mode=true
        shift
        action="$1"
    fi

    shift

    # Validate environment
    local validation_result
    validation_result=$(validate_jira_environment "jira-quick")
    if [[ $? -ne 0 ]]; then
        echo "$validation_result"
        return 1
    fi

    case "$action" in
        view|v)
            local ticket="$1"
            if [[ -z "$ticket" ]]; then
                echo "{\"status\":\"error\",\"message\":\"Ticket required\",\"action\":\"jira-quick view TICKET-ID\"}"
                return 1
            fi

            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would execute: jira issue view $ticket"
                return 0
            fi

            jira issue view "$ticket"
            ;;

        comment|c)
            local ticket="$1"
            local comment="$2"

            if [[ -z "$ticket" ]]; then
                echo "{\"status\":\"error\",\"message\":\"Ticket required\",\"action\":\"jira-quick comment TICKET-ID 'comment text'\"}"
                return 1
            fi

            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would add comment to $ticket: $comment"
                return 0
            fi

            if [[ -n "$comment" ]]; then
                jira issue comment add "$ticket" "$comment"
            else
                # Interactive comment
                jira issue comment add "$ticket"
            fi
            ;;

        assign|a)
            local ticket="$1"
            local assignee="${2:-}"

            if [[ -z "$ticket" ]]; then
                echo "{\"status\":\"error\",\"message\":\"Ticket required\",\"action\":\"jira-quick assign TICKET-ID [user]\"}"
                return 1
            fi

            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would assign $ticket to ${assignee:-current user}"
                return 0
            fi

            if [[ -n "$assignee" ]]; then
                jira issue assign "$ticket" "$assignee"
            else
                # Assign to self
                jira issue assign "$ticket" "$(jira me)"
            fi
            ;;

        transition|t)
            local ticket="$1"
            local state="$2"

            if [[ -z "$ticket" ]] || [[ -z "$state" ]]; then
                echo "{\"status\":\"error\",\"message\":\"Ticket and state required\",\"action\":\"jira-quick transition TICKET-ID STATE\"}"
                return 1
            fi

            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would transition $ticket to $state"
                return 0
            fi

            jira issue move "$ticket" "$state"
            ;;

        browse|b)
            local ticket="$1"

            if [[ -z "$ticket" ]]; then
                echo "{\"status\":\"error\",\"message\":\"Ticket required\",\"action\":\"jira-quick browse TICKET-ID\"}"
                return 1
            fi

            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would open $ticket in browser"
                return 0
            fi

            jira open "$ticket"
            ;;

        *)
            echo "Usage: jira-quick [action] [args]"
            echo ""
            echo "Actions:"
            echo "  view|v TICKET          - View ticket details"
            echo "  comment|c TICKET TEXT  - Add comment"
            echo "  assign|a TICKET [USER] - Assign ticket (defaults to self)"
            echo "  transition|t TICKET STATE - Change status"
            echo "  browse|b TICKET        - Open in browser"
            return 1
            ;;
    esac
}

# Aliases for convenience
alias ccj='cc-jira'
alias jstd='jira-standup'
alias jaistd='jira-ai-standup'
alias jsearch='jira-search'
alias jq-jira='jira-quick'

# Help function
jira-help() {
    cat <<EOF
=== Jira Workflow Functions ===

Core Functions:
  cc-jira TICKET-ID        Load Jira ticket context into Claude Code
  jira-standup [format]    Generate daily standup (display|copy|file)
  jql "query"              Translate natural language to JQL
  jira-search [filter]     Quick search (mine|bugs|in-progress|blocked|today|week)
  jira-quick [action]      Quick actions (view|comment|assign|transition|browse)

Examples:
  cc-jira PROJ-123                    # Load ticket context for Claude
  jira-standup copy                   # Copy standup to clipboard
  jql "my open bugs from last week"   # Translate to JQL and show query
  jql -x "bugs in progress"           # Translate and execute
  jira-search bugs                    # Show my open bugs
  jira-quick view PROJ-123            # View ticket
  jira-quick comment PROJ-123 "Done"  # Add comment
  jira-quick assign PROJ-123          # Assign to self
  jira-quick transition PROJ-123 Done # Move to Done

Aliases:
  ccj      -> cc-jira
  jstd     -> jira-standup
  jsearch  -> jira-search
  jq-jira  -> jira-quick

Test Mode:
  All functions support -t flag for testing without API calls
  Example: cc-jira -t TEST-123

Configuration:
  Config file: ~/.jira.d/config.yml
  Templates: ~/.jira.d/templates/

For full go-jira help: jira --help
EOF
}
