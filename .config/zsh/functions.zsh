# ===== Developer Workflow Functions (Claude Enhanced) =====

# Enhanced validation and error handling for all functions
validate_git_environment() {
    local function_name="$1"
    local context="{}"

    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "{\"status\":\"error\",\"message\":\"Not in a git repository\",\"action\":\"cd /Users/jstittsworth/Documents/repos/PROJECT_NAME\",\"context\":{\"pwd\":\"$(pwd)\",\"function\":\"$function_name\"}}"
        return 1
    fi

    # Check if we're in the repos directory
    if [[ "$(pwd)" != *"/repos/"* ]]; then
        echo "{\"status\":\"warning\",\"message\":\"Not in repos directory\",\"action\":\"cd /Users/jstittsworth/Documents/repos\",\"context\":{\"pwd\":\"$(pwd)\",\"function\":\"$function_name\"}}"
    fi

    # Get git context
    local current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
    local repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "unknown")
    local repo_name=$(basename "$repo_root" 2>/dev/null || echo "unknown")

    # Check remote connectivity
    if ! git remote >/dev/null 2>&1; then
        echo "{\"status\":\"warning\",\"message\":\"No git remotes configured\",\"action\":\"git remote add origin URL\",\"context\":{\"pwd\":\"$(pwd)\",\"branch\":\"$current_branch\",\"repo\":\"$repo_name\"}}"
    fi

    return 0
}

# Enhanced feature function with PR scope understanding
feature() {
    local test_mode=false
    if [[ "$1" == "-t" ]]; then
        test_mode=true
        shift
    fi

    # Validate environment
    local validation_result
    validation_result=$(validate_git_environment "feature")
    if [[ $? -ne 0 ]]; then
        echo "$validation_result"
        return 1
    fi

    local description="$1"
    local pr_title="$2"

    # Validate required parameters
    if [[ -z "$description" ]]; then
        echo "{\"status\":\"error\",\"message\":\"Description required\",\"action\":\"feature 'description' 'optional_pr_title'\",\"context\":{\"pwd\":\"$(pwd)\"}}"
        return 1
    fi

    # Get current state for context
    local current_branch=$(git branch --show-current)
    local staged_changes=$(git diff --cached --name-only)
    local unstaged_changes=$(git diff --name-only)

    # Check for uncommitted changes
    if [[ -n "$staged_changes" || -n "$unstaged_changes" ]]; then
        echo "{\"status\":\"warning\",\"message\":\"Uncommitted changes detected\",\"action\":\"git stash or git commit changes first\",\"context\":{\"staged\":\"$staged_changes\",\"unstaged\":\"$unstaged_changes\"}}"
        if [[ "$test_mode" != true ]]; then
            read -p "Continue anyway? (y/n): " continue_choice
            [[ "$continue_choice" != "y" ]] && return 1
        fi
    fi

    # Use Claude Code to analyze scope and suggest approach
    local analysis
    if [[ "$test_mode" == true ]]; then
        analysis='{"branch": "test-feature-branch", "commit_plan": ["Add test files", "Update documentation"], "file_groups": [["test.js", "spec.js"], ["README.md"]]}'
    else
        analysis=$(git status --porcelain | claude -p "
    Analyze these changes for a feature: '$description'
    Current branch: $current_branch

    Suggest:
    1. Branch name (kebab-case)
    2. How to break this into logical commits
    3. Files that should be grouped together

    Format as JSON: {\"branch\": \"name\", \"commit_plan\": [\"step1\", \"step2\"], \"file_groups\": [[\"file1\", \"file2\"], [\"file3\"]]}
    ")
    fi

    # Parse suggestions
    local suggested_branch=$(echo "$analysis" | jq -r '.branch')
    local commit_plan=$(echo "$analysis" | jq -r '.commit_plan[]')

    echo "🤖 Claude suggests:"
    echo "Branch: $suggested_branch"
    echo "Commit plan:"
    echo "$commit_plan" | nl

    read -p "Create branch '$suggested_branch'? (y/n/custom): " choice
    case $choice in
        y)
            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would create branch: $suggested_branch"
            else
                git checkout -b "$suggested_branch"
            fi
            ;;
        n) return ;;
        *) read -p "Branch name: " custom_branch
           if [[ "$test_mode" == true ]]; then
               echo "[TEST MODE] Would create branch: $custom_branch"
           else
               git checkout -b "$custom_branch"
           fi
           ;;
    esac

    # Store commit plan for qcp function
    echo "$analysis" > .claude_commit_plan.json
    echo "💾 Saved commit plan for qcp function"
}

# Enhanced qcp with granular commit suggestions
qcp() {
    local test_mode=false
    if [[ "$1" == "-t" ]]; then
        test_mode=true
        shift
    fi

    # Validate environment
    local validation_result
    validation_result=$(validate_git_environment "qcp")
    if [[ $? -ne 0 ]]; then
        echo "$validation_result"
        return 1
    fi

    local custom_message="$1"

    # Check if we have a commit plan from feature()
    local has_plan=false
    if [[ -f .claude_commit_plan.json ]]; then
        has_plan=true
        echo "📋 Found commit plan from feature()"
    fi

    # Get current diff and validate
    local diff_output=$(git diff --cached)
    local unstaged_diff=$(git diff)

    if [[ -z "$diff_output" && -z "$unstaged_diff" ]]; then
        echo "{\"status\":\"error\",\"message\":\"No changes to commit\",\"action\":\"Make changes first or git add files\",\"context\":{\"pwd\":\"$(pwd)\",\"branch\":\"$(git branch --show-current)\"}}"
        return 1
    fi

    if [[ -z "$diff_output" ]]; then
        echo "⚠️ No staged changes. Staging all changes..."
        if [[ "$test_mode" == true ]]; then
            echo "[TEST MODE] Would stage all changes"
            diff_output="$unstaged_diff"
        else
            git add .
            diff_output=$(git diff --cached)
        fi
    fi

    # Validate we're not committing too many files (potential accident)
    local file_count=$(echo "$diff_output" | grep -E "^\+\+\+ " | wc -l)
    if [[ $file_count -gt 50 ]]; then
        echo "{\"status\":\"warning\",\"message\":\"Large commit detected ($file_count files)\",\"action\":\"Consider splitting with interactive_commit_split\",\"context\":{\"files\":$file_count}}"
        if [[ "$test_mode" != true ]]; then
            read -p "Continue with large commit? (y/n): " large_commit_choice
            [[ "$large_commit_choice" != "y" ]] && return 1
        fi
    fi

    if [[ "$custom_message" ]]; then
        # User provided message, just commit
        if [[ "$test_mode" == true ]]; then
            echo "[TEST MODE] Would commit with message: $custom_message"
            echo "[TEST MODE] Would push to remote"
        else
            git commit -m "$custom_message"
            git push
        fi
        return
    fi

    # Use Claude Code for intelligent commit message and scope analysis
    local commit_suggestions
    if [[ "$test_mode" == true ]]; then
        commit_suggestions="1. feat: add test functionality\n2. fix: resolve test issue\n3. refactor: improve test structure"
    elif [[ "$has_plan" == true ]]; then
        commit_suggestions=$(git diff --cached | claude -p "
        Using this commit plan: $(cat .claude_commit_plan.json)

        Analyze the staged changes and suggest:
        1. Which step of the plan this represents
        2. 3 conventional commit messages
        3. If this commit covers too much scope

        Staged changes:
        $diff_output
        ")
    else
        commit_suggestions=$(git diff --cached | claude -p "
        Analyze these staged changes and provide:
        1. 3 conventional commit messages
        2. Whether this should be split into multiple commits
        3. Suggested file groupings if split needed

        Use conventional commits format (feat:, fix:, refactor:, etc.)
        ")
    fi

    echo "🤖 Claude analysis:"
    echo "$commit_suggestions"
    echo

    # Extract commit messages for selection
    local messages=$(echo "$commit_suggestions" | grep -E '^[0-9]+\.' | head -3)
    echo "Select commit message:"
    echo "$messages"
    echo "4) Write custom"
    echo "5) Split into multiple commits"
    echo "6) Cancel"

    read -p "Choice (1-6): " choice
    case $choice in
        [1-3])
            local selected_msg=$(echo "$messages" | sed -n "${choice}p" | sed 's/^[0-9]*\. *//')
            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would commit with: $selected_msg"
                echo "[TEST MODE] Would push to remote"
            else
                git commit -m "$selected_msg"
                git push
            fi
            ;;
        4)
            read -p "Custom message: " custom_msg
            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would commit with: $custom_msg"
                echo "[TEST MODE] Would push to remote"
            else
                git commit -m "$custom_msg"
                git push
            fi
            ;;
        5)
            echo "🔄 Splitting commits..."
            interactive_commit_split
            ;;
        6)
            echo "❌ Cancelled"
            ;;
    esac
}

# Interactive commit splitting using Claude Code
interactive_commit_split() {
    local test_mode=false
    if [[ "$1" == "-t" ]]; then
        test_mode=true
        shift
    fi
    # Reset staging area
    if [[ "$test_mode" == true ]]; then
        echo "[TEST MODE] Would reset staging area"
    else
        git reset
    fi

    # Get file grouping suggestions
    local files_analysis
    if [[ "$test_mode" == true ]]; then
        files_analysis='[{"purpose": "Add new features", "files": ["feature.js", "test.js"]}, {"purpose": "Update documentation", "files": ["README.md"]}]'
    else
        files_analysis=$(git diff --name-only | claude -p "
    Group these modified files into logical commits.
    Provide response as JSON array of groups:
    [{\"purpose\": \"description\", \"files\": [\"file1\", \"file2\"]}, ...]

    Modified files:
    $(git diff --name-only)
    ")
    fi

    echo "🤖 Suggested file groups:"
    echo "$files_analysis" | jq -r '.[] | "\(.purpose): \(.files | join(", "))"' | nl

    # Let user stage and commit each group
    local group_count=$(echo "$files_analysis" | jq length)
    for i in $(seq 0 $((group_count - 1))); do
        local group=$(echo "$files_analysis" | jq -r ".[$i]")
        local purpose=$(echo "$group" | jq -r '.purpose')
        local files=$(echo "$group" | jq -r '.files[]')

        echo
        echo "📁 Group $((i + 1)): $purpose"
        echo "Files: $(echo "$files" | tr '\n' ' ')"
        read -p "Stage and commit this group? (y/n/skip): " stage_choice

        if [[ "$stage_choice" == "y" ]]; then
            # Stage files
            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would stage files: $(echo "$files" | tr '\n' ' ')"
                local group_message="feat: $purpose"
            else
                echo "$files" | xargs git add
                # Get commit message for this group
                local group_diff=$(git diff --cached)
                local group_message=$(echo "$group_diff" | claude -p "
            Create a conventional commit message for this change group: $purpose
            Only return the commit message, nothing else.
            ")
            fi

            echo "Suggested message: $group_message"
            read -p "Use this message? (y/n): " msg_choice

            if [[ "$msg_choice" == "y" ]]; then
                if [[ "$test_mode" == true ]]; then
                    echo "[TEST MODE] Would commit with: $group_message"
                else
                    git commit -m "$group_message"
                fi
            else
                read -p "Enter custom message: " custom_message
                if [[ "$test_mode" == true ]]; then
                    echo "[TEST MODE] Would commit with: $custom_message"
                else
                    git commit -m "$custom_message"
                fi
            fi
        fi
    done

    # Push all commits
    if [[ "$test_mode" == true ]]; then
        echo "[TEST MODE] Would push all commits to remote"
    else
        git push
    fi
}

# Enhanced repo_dashboard with AI insights
repo_dashboard() {
    local test_mode=false
    if [[ "$1" == "-t" ]]; then
        test_mode=true
        shift
    fi

    # Validate environment
    local validation_result
    validation_result=$(validate_git_environment "repo_dashboard")
    if [[ $? -ne 0 ]]; then
        echo "$validation_result"
        return 1
    fi

    echo "=== Repository Dashboard ==="

    # Gather repo metrics with error handling
    local stats=""
    local repo_name=$(basename "$(git rev-parse --show-toplevel)" 2>/dev/null || echo "unknown")

    # Build stats with fallbacks for missing data
    stats=$(cat <<EOF
Repository: $repo_name
Total commits: $(git rev-list --all --count 2>/dev/null || echo "0")
Contributors: $(git shortlog -sn --all 2>/dev/null | wc -l || echo "0")
Branches: $(git branch -a 2>/dev/null | wc -l || echo "0")
Recent activity (7 days): $(git log --since="7 days ago" --oneline 2>/dev/null | wc -l || echo "0")
Files tracked: $(git ls-files 2>/dev/null | wc -l || echo "0")
Current branch: $(git branch --show-current 2>/dev/null || echo "detached")
Uncommitted changes: $(git status --porcelain 2>/dev/null | wc -l || echo "0")
Remote URL: $(git remote get-url origin 2>/dev/null || echo "none")
Last fetch: $(stat -f "%Sm" .git/FETCH_HEAD 2>/dev/null || echo "never")
EOF
)

    echo "$stats"
    echo

    # Get AI analysis of repository health
    local repo_analysis
    if [[ "$test_mode" == true ]]; then
        repo_analysis="Repository Health: Good\nDevelopment velocity: Active\nSuggestions: Continue current practices"
    else
        repo_analysis=$(cat <<EOF | claude -p "Analyze this repository and provide insights:"
Repository Statistics:
$stats

Recent commits (last 10):
$(git log --oneline -10)

Active branches:
$(git branch -a | head -10)

File types distribution:
$(git ls-files | grep -E '\.[^.]+$' | sed 's/.*\.//' | sort | uniq -c | sort -nr | head -10)

Provide:
1. Repository health assessment
2. Potential concerns or suggestions
3. Development velocity insights
EOF
)
    fi

    echo "🤖 AI Analysis:"
    echo "$repo_analysis"

    # Optional: Save analysis to file
    read -p "Save analysis to REPO_HEALTH.md? (y/n): " save_choice
    if [[ "$save_choice" == "y" ]]; then
        if [[ "$test_mode" == true ]]; then
            echo "[TEST MODE] Would save analysis to REPO_HEALTH.md"
        else
            cat > REPO_HEALTH.md <<EOF
# Repository Health Analysis
Generated: $(date)

## Statistics
$stats

## AI Analysis
$repo_analysis
EOF
            echo "💾 Saved to REPO_HEALTH.md"
        fi
    fi
}

# Enhanced daily_standup with PR analysis
daily_standup() {
    local test_mode=false
    if [[ "$1" == "-t" ]]; then
        test_mode=true
        shift
    fi
    echo "=== Daily Standup Generator ==="

    # Gather activity data
    local yesterday_commits=$(git log --since="1 day ago" --author="$(git config user.name)" --oneline)
    local current_work=$(git status --porcelain)
    local current_branch=$(git branch --show-current)

    # Get PR information if available
    local pr_info=""
    if command -v gh &> /dev/null; then
        pr_info=$(gh pr list --author @me --state open 2>/dev/null | head -5)
    fi

    # Generate standup using Claude Code
    local standup_content
    if [[ "$test_mode" == true ]]; then
        standup_content="## What I accomplished yesterday\n- Worked on test features\n- Fixed test bugs\n\n## What I'm working on today\n- Continue test development\n- Review test PRs\n\n## Blockers/Help needed\n- None at this time"
    else
        standup_content=$(cat <<EOF | claude -p "Generate a professional standup update:"
Developer: $(git config user.name)
Current branch: $current_branch

Yesterday's commits:
$yesterday_commits

Current work in progress:
$current_work

Open PRs:
$pr_info

Format as:
## What I accomplished yesterday
## What I'm working on today
## Blockers/Help needed

Be concise but informative.
EOF
)
    fi

    echo "$standup_content"
    echo

    # Interactive options
    echo "Options:"
    echo "1) Copy to clipboard"
    echo "2) Edit before copying"
    echo "3) Save to file"
    echo "4) Post to Slack (if configured)"

    read -p "Choice (1-4): " choice
    case $choice in
        1)
            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would copy to clipboard"
            else
                echo "$standup_content" | pbcopy
                echo "📋 Copied to clipboard!"
            fi
            ;;
        2)
            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would open editor and copy to clipboard"
            else
                echo "$standup_content" > /tmp/standup.md
                ${EDITOR:-vim} /tmp/standup.md
                cat /tmp/standup.md | pbcopy
                echo "📋 Edited version copied to clipboard!"
            fi
            ;;
        3)
            local filename="standup_$(date +%Y%m%d).md"
            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would save to $filename"
            else
                echo "$standup_content" > "$filename"
                echo "💾 Saved to $filename"
            fi
            ;;
        4)
            # Slack integration (requires slack CLI or webhook)
            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would post to Slack"
            elif command -v slack &> /dev/null; then
                echo "$standup_content" | slack chat send --channel "#standup"
                echo "📤 Posted to Slack!"
            else
                echo "❌ Slack CLI not configured"
            fi
            ;;
    esac
}

# Agent-friendly command execution wrapper
execute_with_validation() {
    local command="$1"
    local test_mode="$2"
    local error_context="$3"

    if [[ "$test_mode" == true ]]; then
        echo "[TEST MODE] Would execute: $command"
        return 0
    fi

    # Execute command and capture output
    local output
    local exit_code
    output=$(eval "$command" 2>&1)
    exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        echo "{\"status\":\"error\",\"message\":\"Command failed: $command\",\"output\":\"$output\",\"context\":\"$error_context\"}"
        return $exit_code
    fi

    echo "$output"
    return 0
}

# Quick PR review using Claude Code
pr_review() {
    local test_mode=false
    if [[ "$1" == "-t" ]]; then
        test_mode=true
        shift
    fi

    # Validate environment
    local validation_result
    validation_result=$(validate_git_environment "pr_review")
    if [[ $? -ne 0 ]]; then
        echo "$validation_result"
        return 1
    fi

    local pr_number="$1"

    if [[ -z "$pr_number" ]]; then
        echo "{\"status\":\"error\",\"message\":\"PR number required\",\"action\":\"pr_review PR_NUMBER\",\"context\":{\"function\":\"pr_review\"}}"
        return 1
    fi

    # Validate PR number format
    if ! [[ "$pr_number" =~ ^[0-9]+$ ]]; then
        echo "{\"status\":\"error\",\"message\":\"Invalid PR number format\",\"action\":\"Use numeric PR number (e.g., pr_review 123)\",\"context\":{\"input\":\"$pr_number\"}}"
        return 1
    fi

    # Check if GitHub CLI is available
    if ! command -v gh &> /dev/null; then
        echo "{\"status\":\"error\",\"message\":\"GitHub CLI not installed\",\"action\":\"Install with: brew install gh\",\"context\":{\"function\":\"pr_review\"}}"
        return 1
    fi

    # Get PR details
    local pr_diff
    local pr_info
    if [[ "$test_mode" == true ]]; then
        pr_diff="+ Added test functionality\n- Removed old code"
        pr_info="PR #123: Test Feature\nAuthor: test-user\nStatus: Open"
    else
        pr_diff=$(gh pr diff "$pr_number")
        pr_info=$(gh pr view "$pr_number")
    fi

    # Use Claude Code for review
    local review_analysis
    if [[ "$test_mode" == true ]]; then
        review_analysis="## Code Review\n\n1. Security: No concerns\n2. Performance: Good\n3. Code Quality: Follows standards\n4. Testing: Add unit tests\n5. Recommendation: APPROVE"
    else
        review_analysis=$(cat <<EOF | claude -p "Perform a thorough code review:"
PR Information:
$pr_info

Changes:
$pr_diff

Provide:
1. Security considerations
2. Performance implications
3. Code quality feedback
4. Testing suggestions
5. Overall recommendation (APPROVE/REQUEST_CHANGES/COMMENT)

Use GitHub review format with specific line references where possible.
EOF
)
    fi

    echo "🔍 Code Review Analysis:"
    echo "$review_analysis"

    # Option to post review
    read -p "Post this review to GitHub? (y/n): " post_choice
    if [[ "$post_choice" == "y" ]]; then
        if [[ "$test_mode" == true ]]; then
            echo "[TEST MODE] Would post review to PR #$pr_number"
        else
            echo "$review_analysis" > /tmp/review.md
            ${EDITOR:-vim} /tmp/review.md
            gh pr review "$pr_number" --body "$(cat /tmp/review.md)"
            echo "✅ Review posted!"
        fi
    fi
}

# Quick code context for Claude - lightweight and token-efficient
# Usage: cc [path] [pr_number]
#   cc              - Current directory context
#   cc ui           - UI workspace context
#   cc xl           - XL workspace context
#   cc ~/project    - Arbitrary path context
#   cc 325          - PR #325 context (if in git repo)
cc() {
    local test_mode=false
    local target_path=""
    local pr_number=""
    local original_dir=$(pwd)

    # Parse arguments
    if [[ "$1" == "-t" ]]; then
        test_mode=true
        shift
    fi

    # Determine if first argument is a path or PR number
    if [[ -n "$1" ]]; then
        if [[ "$1" =~ ^[0-9]+$ ]]; then
            # Numeric argument = PR number
            pr_number="$1"
            target_path="$original_dir"
        else
            # Non-numeric = path
            target_path="$1"
            # Second argument could be PR number
            if [[ -n "$2" ]] && [[ "$2" =~ ^[0-9]+$ ]]; then
                pr_number="$2"
            fi
        fi
    else
        # No arguments = current directory
        target_path="$original_dir"
    fi

    # Resolve target path
    if [[ "$target_path" != /* ]]; then
        # Relative path - resolve from current directory
        if [[ -d "$original_dir/$target_path" ]]; then
            target_path="$original_dir/$target_path"
        elif [[ "$target_path" == "ui" ]] || [[ "$target_path" == "xl" ]]; then
            # Special case: ui/xl shortcuts in monorepo
            if [[ -d "$original_dir/$target_path" ]]; then
                target_path="$original_dir/$target_path"
            elif [[ -d "$original_dir/../$target_path" ]]; then
                target_path="$original_dir/../$target_path"
            else
                echo "❌ Error: Cannot find $target_path workspace"
                return 1
            fi
        else
            # Try to expand ~ or resolve path
            target_path="${target_path/#\~/$HOME}"
            if [[ ! -d "$target_path" ]]; then
                echo "❌ Error: Directory not found: $target_path"
                return 1
            fi
        fi
    fi

    # Navigate to target directory
    cd "$target_path" || {
        echo "❌ Error: Cannot access directory: $target_path"
        return 1
    }

    # Validate git environment
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "❌ Error: Not in a git repository: $target_path"
        cd "$original_dir"
        return 1
    fi

    # Get repository root and determine workspace type
    local repo_root=$(git rev-parse --show-toplevel)
    local repo_name=$(basename "$repo_root")
    local relative_path=$(realpath --relative-to="$repo_root" "$target_path" 2>/dev/null || echo ".")
    local workspace_type="monorepo-root"

    if [[ "$relative_path" == "ui" ]] || [[ "$relative_path" == ui/* ]]; then
        workspace_type="ui-workspace"
    elif [[ "$relative_path" == "xl" ]] || [[ "$relative_path" == xl/* ]]; then
        workspace_type="xl-workspace"
    elif [[ "$relative_path" == "." ]]; then
        workspace_type="root"
    else
        workspace_type="subdirectory"
    fi

    local context=""
    local context_file="$target_path/.claude-context.md"

    if [[ -n "$pr_number" ]]; then
        # ===== PR MODE =====
        if ! command -v gh &> /dev/null; then
            echo "❌ Error: GitHub CLI not installed"
            echo "   Install with: brew install gh"
            cd "$original_dir"
            return 1
        fi

        if [[ "$test_mode" == true ]]; then
            context="# PR Context: #$pr_number

**Repository:** $repo_name
**Workspace:** $workspace_type
**Path:** $relative_path

## PR Information
- **PR:** #123
- **Title:** Test Feature
- **Author:** test-user
- **Status:** Open
- **Files changed:** 2 (+15, -0)

## File Changes
\`\`\`
 test.js    | 10 ++++++++++
 README.md  |  5 +++++
 2 files changed, 15 insertions(+)
\`\`\`

## Diff
\`\`\`diff
+ Added test functionality
- Removed old code
\`\`\`"
        else
            local pr_info=$(gh pr view "$pr_number" --json number,title,author,state,additions,deletions,changedFiles --template '
## PR Information
- **PR:** #{{.number}}
- **Title:** {{.title}}
- **Author:** {{.author.login}}
- **Status:** {{.state}}
- **Files changed:** {{.changedFiles}} (+{{.additions}}, -{{.deletions}})
')
            local pr_stat=$(gh pr diff "$pr_number" --stat --color=never 2>/dev/null || echo "")
            local pr_diff=$(gh pr diff "$pr_number" --color=never)

            context="# PR Context: #$pr_number

**Repository:** $repo_name
**Workspace:** $workspace_type
**Path:** $relative_path

$pr_info

## File Changes
\`\`\`
$pr_stat
\`\`\`

## Diff
\`\`\`diff
$pr_diff
\`\`\`"
        fi

    else
        # ===== BRANCH MODE =====
        local current_branch=$(git branch --show-current)

        if [[ "$test_mode" == true ]]; then
            context="# Branch Context

**Repository:** $repo_name
**Workspace:** $workspace_type
**Path:** $relative_path
**Branch:** test-feature-branch
**Base:** origin/main
**Merge Base:** abc123def

## Summary
- **Commits:** 2
- **Files changed:** 3 (+25, -10)

## File Changes
\`\`\`
 src/test.js     | 15 +++++++++++++++
 src/utils.js    | 10 ++++++++--
 README.md       |  5 +++--
 3 files changed, 25 insertions(+), 10 deletions(-)
\`\`\`

## Commit History
\`\`\`
abc123d feat: add new test functionality
def456e fix: update utils logic
\`\`\`

## Full Diff
\`\`\`diff
+ Added new test function
+ Updated utility helper
~ Modified README
\`\`\`"
        else
            # Auto-detect base branch using merge-base
            local base_branch=""
            local merge_base=""

            # Try common base branches in order of preference
            for candidate in "origin/develop" "origin/main" "origin/master" "develop" "main" "master"; do
                if git rev-parse --verify "$candidate" &>/dev/null; then
                    base_branch="$candidate"
                    merge_base=$(git merge-base HEAD "$candidate" 2>/dev/null)
                    if [[ -n "$merge_base" ]]; then
                        break
                    fi
                fi
            done

            if [[ -z "$base_branch" ]]; then
                echo "❌ Error: Cannot detect base branch"
                echo "   Available branches:"
                git branch -a | head -10
                cd "$original_dir"
                return 1
            fi

            # Get commit stats
            local commits=$(git log "$base_branch"..HEAD --oneline --no-decorate 2>/dev/null || echo "")
            local commit_count=$(echo "$commits" | grep -c "^" || echo "0")

            # Get file stats
            local file_count=$(git diff "$base_branch"...HEAD --name-only 2>/dev/null | wc -l | xargs)
            local additions=$(git diff "$base_branch"...HEAD --numstat 2>/dev/null | awk '{add+=$1} END {print add+0}')
            local deletions=$(git diff "$base_branch"...HEAD --numstat 2>/dev/null | awk '{del+=$2} END {print del+0}')

            # Get diff stats and full diff
            local diff_stat=$(git diff "$base_branch"...HEAD --stat --color=never 2>/dev/null || echo "No changes")
            local diff_output=$(git diff "$base_branch"...HEAD --color=never 2>/dev/null || echo "No changes")

            context="# Branch Context

**Repository:** $repo_name
**Workspace:** $workspace_type
**Path:** $relative_path
**Branch:** $current_branch
**Base:** $base_branch
**Merge Base:** ${merge_base:0:12}

## Summary
- **Commits:** $commit_count
- **Files changed:** $file_count (+$additions, -$deletions)

## File Changes
\`\`\`
$diff_stat
\`\`\`

## Commit History
\`\`\`
$commits
\`\`\`

## Full Diff
\`\`\`diff
$diff_output
\`\`\`"
        fi
    fi

    # Write context to file and open Claude
    if [[ "$test_mode" == true ]]; then
        echo "=== CODE CONTEXT (Test Mode) ==="
        echo "$context"
        echo ""
        echo "[TEST MODE] Would write to: $context_file"
        echo "[TEST MODE] Would run: claude \"@$context_file\""
        cd "$original_dir"
    else
        # Save to file for reference
        echo "$context" > "$context_file"

        # Print status messages to stderr so they don't interfere with piping
        local branch_info="${current_branch:-PR #$pr_number}"
        echo "✅ Context gathered for: $branch_info" >&2
        echo "   Repository: $repo_name" >&2
        echo "   Workspace: $workspace_type" >&2
        echo "   Base: ${base_branch:-PR}" >&2
        if [[ -n "$file_count" ]]; then
            echo "   Files changed: $file_count (+$additions, -$deletions)" >&2
        fi
        echo "" >&2
        echo "📋 Context written to: .claude-context.md" >&2
        echo "" >&2
        echo "🚀 Opening Claude with context..." >&2
        echo "" >&2

        cd "$original_dir"

        # Open Claude with file reference
        claude "@$context_file"
    fi
}

# Setup custom Claude Code commands
setup_claude_commands() {
    local commands_dir=".claude/commands"
    mkdir -p "$commands_dir"

    # Create custom commit analysis command
    cat > "$commands_dir/analyze-commit.md" <<'EOF'
Analyze the current staged changes and provide:

1. **Commit Message Suggestions** (3 options using conventional commits)
2. **Scope Analysis** - Are changes focused or should they be split?
3. **Impact Assessment** - What areas of the codebase are affected?
4. **Testing Recommendations** - What should be tested?

Use the staged changes: `git diff --cached`

Arguments: $ARGUMENTS (optional context)
EOF

    # Create PR preparation command
    cat > "$commands_dir/prep-pr.md" <<'EOF'
Prepare this branch for a pull request:

1. **Analyze all commits** since branching from main
2. **Suggest PR title and description**
3. **Identify breaking changes** if any
4. **Recommend reviewers** based on file changes
5. **Generate test checklist**

Branch: `git branch --show-current`
Commits: `git log main..HEAD --oneline`
Files changed: `git diff main..HEAD --name-only`

Arguments: $ARGUMENTS (additional context)
EOF

    echo "✅ Claude Code commands created in $commands_dir"
    echo "Available as: /analyze-commit and /prep-pr"
}

# Initialize project with Claude Code
init_claude_project() {
    # Create CLAUDE.md with project context
    if [[ ! -f "CLAUDE.md" ]]; then
        cat > CLAUDE.md <<EOF
# $(basename $(pwd))

## Project Overview
$(git remote get-url origin 2>/dev/null || echo "Local repository")

## Architecture
- Language: $(git ls-files | grep -E '\.(py|js|ts|go|java|rb)$' | head -1 | sed 's/.*\.//')
- Framework: [To be documented]
- Database: [To be documented]

## Development Guidelines
- Use conventional commits
- Follow existing code style
- Write tests for new features
- Update documentation

## Common Commands
- `npm test` or `pytest` - Run tests
- `npm lint` or `flake8` - Lint code
- `git flow` - Use git flow for features

## File Structure
```
$(tree -L 2 2>/dev/null || find . -maxdepth 2 -type d | head -10)
```
EOF
        echo "📝 Created CLAUDE.md project context file"
    fi

    # Setup commands
    setup_claude_commands

    echo "🚀 Claude Code project initialized!"
    echo "Run 'claude' to start interactive session"
}

# ===== Agent-Friendly Command Wrappers =====

# Comprehensive agent-friendly repository operation
agent_repo_op() {
    local operation="$1"
    local test_mode=false

    # Check for test mode flag
    if [[ "$1" == "-t" ]]; then
        test_mode=true
        shift
        operation="$1"
        shift
    else
        shift
    fi

    # Validate environment first
    local validation_result
    validation_result=$(validate_git_environment "agent_repo_op")
    if [[ $? -ne 0 ]]; then
        echo "$validation_result"
        return 1
    fi

    case "$operation" in
        "status")
            # Get comprehensive repository status
            local repo_name=$(basename "$(git rev-parse --show-toplevel)")
            local current_branch=$(git branch --show-current)
            local uncommitted=$(git status --porcelain | wc -l)
            local commits_ahead=$(git rev-list --count HEAD..@{upstream} 2>/dev/null || echo "0")
            local commits_behind=$(git rev-list --count @{upstream}..HEAD 2>/dev/null || echo "0")

            echo "{\"status\":\"success\",\"data\":{\"repo\":\"$repo_name\",\"branch\":\"$current_branch\",\"uncommitted\":$uncommitted,\"ahead\":$commits_ahead,\"behind\":$commits_behind,\"pwd\":\"$(pwd)\"}}"
            ;;

        "branch-diff")
            local target_branch="${1:-origin/master}"
            local source_branch="${2:-HEAD}"

            # Check if branches exist
            if ! git rev-parse --verify "$target_branch" >/dev/null 2>&1; then
                echo "{\"status\":\"error\",\"message\":\"Target branch does not exist: $target_branch\",\"action\":\"git fetch origin or use correct branch name\",\"context\":{\"target\":\"$target_branch\"}}"
                return 1
            fi

            local files_changed=$(git diff --name-only "$target_branch...$source_branch" 2>/dev/null | wc -l)
            local commits_diff=$(git log --oneline "$target_branch..$source_branch" 2>/dev/null | wc -l)

            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would compare $target_branch with $source_branch"
                echo "Files changed: $files_changed, Commits: $commits_diff"
            else
                echo "{\"status\":\"success\",\"data\":{\"target\":\"$target_branch\",\"source\":\"$source_branch\",\"files_changed\":$files_changed,\"commits\":$commits_diff}}"
            fi
            ;;

        "safe-commit")
            local message="$1"
            if [[ -z "$message" ]]; then
                echo "{\"status\":\"error\",\"message\":\"Commit message required\",\"action\":\"agent_repo_op safe-commit 'message'\",\"context\":{\"operation\":\"safe-commit\"}}"
                return 1
            fi

            # Check for uncommitted changes
            local staged=$(git diff --cached --name-only | wc -l)
            local unstaged=$(git diff --name-only | wc -l)

            if [[ $staged -eq 0 && $unstaged -eq 0 ]]; then
                echo "{\"status\":\"error\",\"message\":\"No changes to commit\",\"action\":\"Make changes first\",\"context\":{\"staged\":$staged,\"unstaged\":$unstaged}}"
                return 1
            fi

            if [[ "$test_mode" == true ]]; then
                echo "[TEST MODE] Would commit with message: $message"
                echo "[TEST MODE] Staged: $staged, Unstaged: $unstaged"
            else
                # Stage all changes if nothing staged
                if [[ $staged -eq 0 ]]; then
                    git add .
                fi

                git commit -m "$message"
                local commit_result=$?

                if [[ $commit_result -eq 0 ]]; then
                    echo "{\"status\":\"success\",\"message\":\"Committed successfully\",\"data\":{\"message\":\"$message\",\"hash\":\"$(git rev-parse HEAD)\"}}"
                else
                    echo "{\"status\":\"error\",\"message\":\"Commit failed\",\"context\":{\"message\":\"$message\"}}"
                    return 1
                fi
            fi
            ;;

        "validate-repo")
            # Comprehensive repository validation for agents
            local issues=()
            local repo_root=$(git rev-parse --show-toplevel)
            local repo_name=$(basename "$repo_root")

            # Check repository structure
            if [[ ! -d "$repo_root/.git" ]]; then
                issues+=("No .git directory found")
            fi

            # Check remote configuration
            if ! git remote get-url origin >/dev/null 2>&1; then
                issues+=("No origin remote configured")
            fi

            # Check for large files or common issues
            local large_files=$(find "$repo_root" -type f -size +50M 2>/dev/null | wc -l)
            if [[ $large_files -gt 0 ]]; then
                issues+=("$large_files large files detected (>50MB)")
            fi

            # Check for node_modules in git
            if git ls-files | grep -q "node_modules/"; then
                issues+=("node_modules tracked in git")
            fi

            local validation_status="success"
            if [[ ${#issues[@]} -gt 0 ]]; then
                validation_status="warning"
            fi

            echo "{\"status\":\"$validation_status\",\"repo\":\"$repo_name\",\"issues\":[$(printf '"%s",' "${issues[@]}" | sed 's/,$//')]}"
            ;;

        *)
            echo "{\"status\":\"error\",\"message\":\"Unknown operation: $operation\",\"action\":\"Use: status, branch-diff, safe-commit, validate-repo\",\"context\":{\"available_ops\":[\"status\",\"branch-diff\",\"safe-commit\",\"validate-repo\"]}}"
            return 1
            ;;
    esac
}

# Quick agent command aliases
alias arepo='agent_repo_op'
alias arepo-test='agent_repo_op -t'

# Function to test all enhanced functions (for debugging)
test_all_functions() {
    echo "=== Testing All Enhanced Functions ==="

    local functions=("feature" "qcp" "repo_dashboard" "daily_standup" "pr_review")

    for func in "${functions[@]}"; do
        echo "Testing $func..."
        $func -t "test" 2>/dev/null || echo "  ⚠️ $func test failed"
        echo "  ✅ $func test completed"
    done

    echo "=== Testing agent_repo_op ==="
    agent_repo_op -t status
    agent_repo_op -t validate-repo

    echo "=== All Tests Complete ==="
}

# ===== Self-Healing Function System =====

# Meta-function to diagnose and fix function issues
# Usage: fix_function <func_name> [error description] or fix_function -f <name> -e <error>
fix_function() {
    local test_mode=false
    local function_name=""
    local error_message=""
    local usage_example=""
    local expected_behavior=""
    local actual_behavior=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--test)
                test_mode=true
                shift
                ;;
            -f|--function)
                function_name="$2"
                shift 2
                ;;
            -e|--error)
                error_message="$2"
                shift 2
                ;;
            -u|--usage)
                usage_example="$2"
                shift 2
                ;;
            -x|--expected)
                expected_behavior="$2"
                shift 2
                ;;
            -a|--actual)
                actual_behavior="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: fix_function [options]"
                echo "Options:"
                echo "  -t, --test           Test mode - don't apply fixes"
                echo "  -f, --function NAME  Function name to fix"
                echo "  -e, --error MSG      Error message encountered"
                echo "  -u, --usage CMD      Usage example that failed"
                echo "  -x, --expected DESC  Expected behavior"
                echo "  -a, --actual DESC    Actual behavior"
                echo ""
                echo "Example:"
                echo "  fix_function -f feature -e 'no such directory' -u 'feature \"test\"' -x 'should create branch' -a 'failed with path error'"
                return 0
                ;;
            *)
                # Allow first positional arg as function name (UX improvement)
                if [[ -z "$function_name" && "$1" != -* ]]; then
                    function_name="$1"
                    shift
                    # Capture remaining non-flag args as error message
                    if [[ $# -gt 0 && "$1" != -* ]]; then
                        error_message="$*"
                        break
                    fi
                else
                    echo "Unknown option: $1"
                    echo "Use -h for help"
                    return 1
                fi
                ;;
        esac
    done

    # Validate required parameters
    if [[ -z "$function_name" ]]; then
        echo "{\"status\":\"error\",\"message\":\"Function name required\",\"action\":\"fix_function -f FUNCTION_NAME [other options]\",\"context\":{\"function\":\"fix_function\"}}"
        return 1
    fi

    # Find the function's source file in dotfiles
    local func_file=$(grep -rl "^${function_name}()" ~/.dotfiles/.config/zsh/ 2>/dev/null | head -1)

    if [[ -z "$func_file" ]]; then
        echo "Could not find function '$function_name' in ~/.dotfiles/.config/zsh/"
        return 1
    fi

    # Get line number where function starts
    local func_line=$(grep -n "^${function_name}()" "$func_file" | cut -d: -f1 | head -1)

    # Build the task description for Claude
    local task="Fix the '$function_name' function in $func_file:$func_line

Issue: $error_message"

    [[ -n "$usage_example" ]] && task="$task
Usage that failed: $usage_example"

    [[ -n "$expected_behavior" ]] && task="$task
Expected: $expected_behavior"

    [[ -n "$actual_behavior" ]] && task="$task
Actual: $actual_behavior"

    if [[ "$test_mode" == true ]]; then
        echo "=== Test Mode - Would start Claude Code session ==="
        echo "Directory: ~/.dotfiles"
        echo "Task:"
        echo "$task"
        return 0
    fi

    # Start Claude Code in dotfiles directory with the task
    echo "Starting Claude Code session in ~/.dotfiles..."
    echo "Task: $task"
    echo ""

    # Use subshell to cd without affecting caller, then start Claude
    (cd ~/.dotfiles && claude "$task")
}

# Core diagnosis engine
diagnose_function_issue() {
    local func_name="$1"
    local error_msg="$2"
    local usage="$3"
    local expected="$4"
    local actual="$5"
    local test_mode="$6"

    local fixes=()
    local diagnosis=""
    local fix_status="none"

    # Pattern matching for common issues
    case "$error_msg" in
        *"no such file or directory"*|*"no such directory"*)
            diagnosis="Path navigation error detected"
            fixes+=("Add path validation before function execution")
            fixes+=("Use full absolute paths: /Users/jstittsworth/Documents/repos/PROJECT")
            fixes+=("Add pwd verification step")
            fix_status="applicable"
            ;;

        *"not a git repository"*|*"not in git repo"*)
            diagnosis="Git repository context error"
            fixes+=("Add git repository validation")
            fixes+=("Navigate to correct repository first")
            fixes+=("Use validate_git_environment() function")
            fix_status="applicable"
            ;;

        *"ambiguous argument"*|*"unknown revision"*)
            diagnosis="Git branch reference error"
            fixes+=("Update remote references with 'git fetch origin'")
            fixes+=("Use proper branch names: origin/master, origin/main")
            fixes+=("Validate branch existence before operations")
            fix_status="applicable"
            ;;

        *"command not found"*)
            diagnosis="Missing dependency error"
            if [[ "$error_msg" == *"gh"* ]]; then
                fixes+=("Install GitHub CLI: brew install gh")
                fixes+=("Authenticate with: gh auth login")
            elif [[ "$error_msg" == *"claude"* ]]; then
                fixes+=("Install Claude CLI or configure Claude integration")
            else
                fixes+=("Install missing command dependency")
            fi
            fix_status="applicable"
            ;;

        *"permission denied"*)
            diagnosis="Permission error"
            fixes+=("Check file/directory permissions")
            fixes+=("Use sudo if appropriate")
            fixes+=("Verify user has access to repository")
            fix_status="manual"
            ;;

        *)
            diagnosis="Analyzing function behavior patterns..."
            # Analyze function-specific issues
            case "$func_name" in
                "feature")
                    if [[ "$actual" == *"path error"* ]]; then
                        fixes+=("Add repository path validation to feature()")
                        fixes+=("Implement better error handling for git operations")
                        fix_status="applicable"
                    fi
                    ;;
                "qcp")
                    if [[ "$actual" == *"no changes"* ]]; then
                        fixes+=("Add better change detection in qcp()")
                        fixes+=("Implement staged vs unstaged change handling")
                        fix_status="applicable"
                    fi
                    ;;
                "pr_review")
                    if [[ "$actual" == *"failed"* ]]; then
                        fixes+=("Add GitHub CLI authentication check")
                        fixes+=("Implement PR existence validation")
                        fix_status="applicable"
                    fi
                    ;;
            esac
            ;;
    esac

    # Generate improvement suggestions
    local improvements=()
    improvements+=("Add comprehensive input validation")
    improvements+=("Implement structured error responses")
    improvements+=("Add test mode support for safe testing")
    improvements+=("Include recovery suggestions in error messages")

    # Create structured response
    local response=$(cat <<EOF
{
  "status": "success",
  "function": "$func_name",
  "diagnosis": "$diagnosis",
  "fixes": [$(printf '"%s",' "${fixes[@]}" | sed 's/,$//')],
  "improvements": [$(printf '"%s",' "${improvements[@]}" | sed 's/,$//')],
  "fix_status": "$fix_status",
  "confidence": "high",
  "test_mode": $test_mode
}
EOF
)

    echo "$response"
}

# Apply fixes to functions
apply_function_fixes() {
    local diagnosis_json="$1"

    echo "=== Applying Function Fixes ==="

    local func_name=$(echo "$diagnosis_json" | jq -r '.function')
    local fixes=$(echo "$diagnosis_json" | jq -r '.fixes[]')

    echo "Applying fixes for: $func_name"

    # Create a backup of the current functions file
    local backup_file=".dotfiles/.config/zsh/functions.zsh.backup.$(date +%Y%m%d_%H%M%S)"
    cp .dotfiles/.config/zsh/functions.zsh "$backup_file"
    echo "Backup created: $backup_file"

    # Apply specific fixes based on the function
    case "$func_name" in
        "feature"|"qcp"|"repo_dashboard"|"daily_standup"|"pr_review")
            echo "Applying enhanced validation to $func_name..."
            enhance_function_validation "$func_name"
            ;;
    esac

    echo "Fixes applied. Reload functions with: source .dotfiles/.config/zsh/functions.zsh"
}

# Enhance function validation (example implementation)
enhance_function_validation() {
    local func_name="$1"

    echo "Enhanced validation for $func_name would be applied here"
    echo "This could include:"
    echo "- Better path validation"
    echo "- Improved error messages"
    echo "- Additional safety checks"
    echo "- Recovery suggestions"
}

# Quick diagnosis helper
quick_fix() {
    local last_command="$1"
    local error_output="$2"

    echo "=== Quick Fix Analysis ==="
    echo "Last command: $last_command"
    echo "Error: $error_output"

    # Extract function name from command
    local func_name=$(echo "$last_command" | awk '{print $1}')

    # Run diagnosis
    fix_function -f "$func_name" -e "$error_output" -u "$last_command" -x "successful execution" -a "failed with error"
}

# Agent-friendly fix wrapper
agent_fix() {
    local function_name="$1"
    local error_context="$2"

    # Parse error context if it's JSON
    local error_msg=$(echo "$error_context" | jq -r '.message' 2>/dev/null || echo "$error_context")
    local suggested_action=$(echo "$error_context" | jq -r '.action' 2>/dev/null || echo "")

    echo "=== Agent Fix System ==="
    echo "Function: $function_name"
    echo "Error: $error_msg"
    echo "Suggested Action: $suggested_action"

    # Try to execute the suggested action if available
    if [[ -n "$suggested_action" && "$suggested_action" != "null" ]]; then
        echo "Attempting suggested recovery action..."
        eval "$suggested_action"
        local action_result=$?

        if [[ $action_result -eq 0 ]]; then
            echo "Recovery action successful. Retry original function."
            return 0
        else
            echo "Recovery action failed. Running full diagnosis..."
            fix_function -f "$function_name" -e "$error_msg" -a "recovery action failed"
        fi
    else
        echo "No suggested action available. Running full diagnosis..."
        fix_function -f "$function_name" -e "$error_msg"
    fi
}

# Aliases for convenience
alias ffix='fix_function'
alias qfix='quick_fix'
alias afix='agent_fix'

# ===== Java/Spring Boot Development =====

# Start IRA Recordkeeper with debug support using Maven (sustainable approach)
start-rk() {
    local debug_port="${1:-65108}"  # Default to 65108, allow override
    local profile="${2:-local}"      # Default to local profile

    # Navigate to src directory where parent pom.xml is located
    local rk_src_dir="/Users/jstittsworth/Documents/repos/ilx-core/ira-recordkeeper/src"

    if [[ ! -d "$rk_src_dir" ]]; then
        echo "❌ Error: ira-recordkeeper/src directory not found at $rk_src_dir"
        return 1
    fi

    cd "$rk_src_dir" || return 1

    # Clean up port 9000 if it's in use
    local port_pid=$(lsof -ti :9000)
    if [[ -n "$port_pid" ]]; then
        echo "⚠️  Port 9000 is in use by PID $port_pid. Killing process..."
        kill -9 $port_pid
        sleep 1
        echo "✅ Port 9000 cleared"
    fi

    echo "🚀 Starting IRA Recordkeeper Worker..."
    echo "   Profile: $profile"
    echo "   Debug Port: $debug_port"
    echo "   Directory: $(pwd)"
    echo ""

    # Define cleanup function for graceful shutdown
    cleanup() {
        echo ""
        echo "🛑 Shutting down IRA Recordkeeper Worker..."
        if [[ -n "$maven_pid" ]] && kill -0 "$maven_pid" 2>/dev/null; then
            # Send SIGTERM for graceful shutdown
            kill -TERM "$maven_pid" 2>/dev/null

            # Wait up to 10 seconds for graceful shutdown
            local count=0
            while kill -0 "$maven_pid" 2>/dev/null && [[ $count -lt 10 ]]; do
                sleep 1
                ((count++))
            done

            # Force kill if still running
            if kill -0 "$maven_pid" 2>/dev/null; then
                echo "⚠️  Forcing shutdown..."
                kill -9 "$maven_pid" 2>/dev/null
            fi
        fi
        echo "✅ Shutdown complete"
        trap - INT TERM
        exit 0
    }

    # Set up signal trap for Ctrl+C
    trap cleanup INT TERM

    # Use Maven Spring Boot plugin with debug enabled
    # fork=false prevents process forking, trap ensures proper signal handling
    mvn spring-boot:run \
        -pl ira-recordkeeper-worker \
        -Dspring-boot.run.fork=false \
        -Dspring-boot.run.profiles="$profile" \
        -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:$debug_port" \
        -Dspring-boot.run.arguments="--neo4j-conf=k4YUff%!6\$20kiRO --neo4j-prod=GH9gaRfXPBz\$fsQI" &

    maven_pid=$!
    echo "📦 Maven PID: $maven_pid"
    echo "   Press Ctrl+C to stop gracefully"
    echo ""

    # Wait for Maven process
    wait $maven_pid
}

# Alternative: Start with custom neo4j credentials
start-rk-custom() {
    local debug_port="${1:-65108}"
    local profile="${2:-local}"
    local neo4j_conf="${3:-k4YUff%!6\$20kiRO}"
    local neo4j_prod="${4:-GH9gaRfXPBz\$fsQI}"

    cd "/Users/jstittsworth/Documents/repos/ilx-core/ira-recordkeeper/src" || return 1

    # Clean up port 9000 if it's in use
    local port_pid=$(lsof -ti :9000)
    if [[ -n "$port_pid" ]]; then
        echo "⚠️  Port 9000 is in use by PID $port_pid. Killing process..."
        kill -9 $port_pid
        sleep 1
        echo "✅ Port 9000 cleared"
    fi

    echo "🚀 Starting IRA Recordkeeper Worker (Custom Config)..."
    echo "   Profile: $profile"
    echo "   Debug Port: $debug_port"
    echo ""

    # Define cleanup function for graceful shutdown
    cleanup() {
        echo ""
        echo "🛑 Shutting down IRA Recordkeeper Worker..."
        if [[ -n "$maven_pid" ]] && kill -0 "$maven_pid" 2>/dev/null; then
            # Send SIGTERM for graceful shutdown
            kill -TERM "$maven_pid" 2>/dev/null

            # Wait up to 10 seconds for graceful shutdown
            local count=0
            while kill -0 "$maven_pid" 2>/dev/null && [[ $count -lt 10 ]]; do
                sleep 1
                ((count++))
            done

            # Force kill if still running
            if kill -0 "$maven_pid" 2>/dev/null; then
                echo "⚠️  Forcing shutdown..."
                kill -9 "$maven_pid" 2>/dev/null
            fi
        fi
        echo "✅ Shutdown complete"
        trap - INT TERM
        exit 0
    }

    # Set up signal trap for Ctrl+C
    trap cleanup INT TERM

    # fork=false prevents process forking, trap ensures proper signal handling
    mvn spring-boot:run \
        -pl ira-recordkeeper-worker \
        -Dspring-boot.run.fork=false \
        -Dspring-boot.run.profiles="$profile" \
        -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:$debug_port" \
        -Dspring-boot.run.arguments="--neo4j-conf=$neo4j_conf --neo4j-prod=$neo4j_prod" &

    maven_pid=$!
    echo "📦 Maven PID: $maven_pid"
    echo "   Press Ctrl+C to stop gracefully"
    echo ""

    # Wait for Maven process
    wait $maven_pid
}

# ===== GitHub PR Summary for Claude =====

# Summarize open PRs in markdown format for Claude processing
# Uses -R flag to query specific repos - works from anywhere
# Usage: gprsum [-t]
gprsum() {
    local test_mode=false
    [[ "$1" == "-t" ]] && test_mode=true && shift

    if ! command -v gh &> /dev/null; then
        echo "Error: GitHub CLI (gh) not installed"
        return 1
    fi

    if [[ "$test_mode" == true ]]; then
        cat <<'EOF'
# My Open PRs Summary (TEST MODE)

## PR #123: Test PR Title
- **Repo:** iralogix/unified-portal
- **Branch:** feature/test -> develop
- **Status:** MERGEABLE | CI: PASSING | Review: APPROVED
- **Changes:** 5 files (+100, -50)
- **URL:** https://github.com/iralogix/unified-portal/pull/123

## PR #456: Another PR [MERGE CONFLICT]
- **Repo:** iralogix/unified-portal
- **Branch:** feature/conflict -> develop
- **Status:** **CONFLICTING** | CI: PASSING | Review: PENDING
- **Changes:** 3 files (+20, -10)
- **URL:** https://github.com/iralogix/unified-portal/pull/456
EOF
        return 0
    fi

    # Known repos to check (add more as needed)
    local repos=("iralogix-software-engineering/unified-portal-ui")

    echo "# My Open PRs Summary"
    echo ""

    for repo in "${repos[@]}"; do
        local prs=$(gh pr list -R "$repo" --author "@me" --state open --limit 30 \
            --json number,title,headRefName,baseRefName,mergeable,reviewDecision,statusCheckRollup,additions,deletions,changedFiles,url 2>/dev/null)

        if [[ -n "$prs" && "$prs" != "[]" ]]; then
            # Check for merge conflicts and warn
            local conflict_count=$(echo "$prs" | jq '[.[] | select(.mergeable == "CONFLICTING")] | length')
            if [[ "$conflict_count" -gt 0 ]]; then
                echo "## WARNING: $conflict_count PR(s) have merge conflicts!"
                echo ""
            fi

            echo "$prs" | jq -r --arg repo "$repo" '.[] |
                (if .mergeable == "CONFLICTING" then "## PR #\(.number): \(.title) [MERGE CONFLICT]\n" else "## PR #\(.number): \(.title)\n" end) +
                "- **Repo:** \($repo)\n" +
                "- **Branch:** \(.headRefName) -> \(.baseRefName)\n" +
                "- **Status:** \(
                    if .mergeable == "CONFLICTING" then "**CONFLICTING**"
                    elif .mergeable == "MERGEABLE" then "MERGEABLE"
                    else .mergeable // "UNKNOWN"
                    end
                ) | CI: \(
                    if .statusCheckRollup == null or (.statusCheckRollup | length) == 0 then "NONE"
                    elif (.statusCheckRollup | all(.conclusion == "SUCCESS")) then "PASSING"
                    elif (.statusCheckRollup | any(.conclusion == "FAILURE")) then "FAILING"
                    else "PENDING"
                    end
                ) | Review: \(.reviewDecision // "PENDING")\n" +
                "- **Changes:** \(.changedFiles) files (+\(.additions), -\(.deletions))\n" +
                "- **URL:** \(.url)\n"'
        fi
    done
}
