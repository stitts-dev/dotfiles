# ===== Lattice =====
# Lattice weekly update collector - daily activity tracking and weekly draft generation
# Auto-collected Mon-Fri at 6 PM via LaunchAgent, with manual backfill support

_LATTICE_DIR="$HOME/.config/lattice-collector"
_LATTICE_OUTPUT="$HOME/.local/share/lattice"

# ----- Daily Collection -----

# Collect today's activity (git, Jira, GitHub PRs, blockers)
lattice-collect() {
    zsh -l "$_LATTICE_DIR/lattice-daily-collect.sh" "$@"
}

# Collect for a specific past date
# Usage: lattice-collect-date YYYY-MM-DD [--force]
lattice-collect-date() {
    if [[ -z "$1" ]]; then
        echo "Usage: lattice-collect-date YYYY-MM-DD [--force]"
        return 1
    fi
    zsh -l "$_LATTICE_DIR/lattice-daily-collect.sh" "$@"
}

# ----- Backfill -----

# Backfill daily files for past dates
# Usage: lattice-backfill yesterday | last-week | this-week | YYYY-MM-DD [YYYY-MM-DD] [--force] [--weekly]
lattice-backfill() {
    if [[ $# -eq 0 ]]; then
        zsh -l "$_LATTICE_DIR/lattice-backfill.sh" --help
        return 0
    fi
    zsh -l "$_LATTICE_DIR/lattice-backfill.sh" "$@"
}

# ----- Weekly Draft -----

# Generate weekly Lattice draft from daily files via Claude Haiku
# Usage: lattice-draft [YYYY-MM-DD] [--force]
lattice-draft() {
    zsh -l "$_LATTICE_DIR/lattice-weekly-draft.sh" "$@"
}

# ----- Browse & Review -----

# Open the latest weekly draft in $EDITOR
lattice-review() {
    local latest=$(ls -t "$_LATTICE_OUTPUT/weekly/"*-draft.md 2>/dev/null | head -1)
    if [[ -z "$latest" ]]; then
        echo "No weekly drafts found."
        return 1
    fi
    echo "Opening: $latest"
    ${EDITOR:-code} "$latest"
}

# List all collected daily and weekly files
lattice-files() {
    echo "Daily files:"
    ls -1 "$_LATTICE_OUTPUT/daily/"*.md 2>/dev/null | while read f; do
        echo "  $(basename "$f")"
    done
    echo ""
    echo "Weekly drafts:"
    ls -1 "$_LATTICE_OUTPUT/weekly/"*.md 2>/dev/null | while read f; do
        echo "  $(basename "$f")"
    done
}

# View a specific daily file
# Usage: lattice-daily [YYYY-MM-DD]
lattice-daily() {
    local date="${1:-$(date +%Y-%m-%d)}"
    local file="$_LATTICE_OUTPUT/daily/$date.md"
    if [[ -f "$file" ]]; then
        cat "$file"
    else
        echo "No daily file for $date"
        echo "Available: $(ls "$_LATTICE_OUTPUT/daily/" 2>/dev/null | tr '\n' ' ')"
    fi
}

# View collector log
lattice-log() {
    local lines="${1:-30}"
    tail -n "$lines" "$_LATTICE_OUTPUT/.collector.log" 2>/dev/null || echo "No log file found."
}

# ----- Auto-Execution Status -----

# Show status of all auto-executed LaunchAgents and scheduled tasks
lattice-status() {
    local c_green=$'\e[32m'
    local c_red=$'\e[31m'
    local c_yellow=$'\e[33m'
    local c_cyan=$'\e[36m'
    local c_dim=$'\e[2m'
    local c_bold=$'\e[1m'
    local c_reset=$'\e[0m'

    echo "${c_bold}Lattice Collector Status${c_reset}"
    echo "========================"
    echo ""

    # --- LaunchAgent Status ---
    echo "${c_bold}LaunchAgents:${c_reset}"

    local plist_dir="$HOME/Library/LaunchAgents"
    local found_agents=false

    for plist in "$plist_dir"/com.jstittsworth.*.plist(N); do
        found_agents=true
        local label=$(basename "$plist" .plist)
        local state

        # Check if loaded
        if launchctl list 2>/dev/null | grep -q "$label"; then
            local exit_code=$(launchctl list 2>/dev/null | grep "$label" | awk '{print $2}')
            if [[ "$exit_code" == "0" || "$exit_code" == "-" ]]; then
                state="${c_green}active${c_reset}"
            else
                state="${c_red}error (exit $exit_code)${c_reset}"
            fi
        else
            state="${c_yellow}unloaded${c_reset}"
        fi

        # Parse schedule from plist
        local schedule=""
        if grep -q "StartCalendarInterval" "$plist" 2>/dev/null; then
            local hour=$(grep -A1 "<key>Hour</key>" "$plist" | grep integer | head -1 | sed 's/.*<integer>\(.*\)<\/integer>.*/\1/')
            local weekdays=$(grep -A1 "<key>Weekday</key>" "$plist" | grep integer | sed 's/.*<integer>\(.*\)<\/integer>.*/\1/' | tr '\n' ',' | sed 's/,$//')
            if [[ -n "$hour" ]]; then
                local day_names=""
                case "$weekdays" in
                    1,2,3,4,5) day_names="Mon-Fri" ;;
                    *) day_names="Days: $weekdays" ;;
                esac
                schedule="${c_dim}Schedule: $day_names at $(printf '%02d:00' "$hour")${c_reset}"
            fi
        fi

        # Parse script path
        local script=$(grep -A3 "<key>ProgramArguments</key>" "$plist" 2>/dev/null | grep "\.sh" | sed 's/.*<string>\(.*\)<\/string>.*/\1/' | sed "s|$HOME|~|")

        echo "  $state  ${c_cyan}$label${c_reset}"
        [[ -n "$schedule" ]] && echo "         $schedule"
        [[ -n "$script" ]] && echo "         ${c_dim}Script: $script${c_reset}"
    done

    if [[ "$found_agents" == "false" ]]; then
        echo "  ${c_dim}No LaunchAgents found.${c_reset}"
    fi

    echo ""

    # --- Last Run Info ---
    echo "${c_bold}Last Runs:${c_reset}"

    # Daily collector
    local latest_daily=$(ls -t "$_LATTICE_OUTPUT/daily/"*.md 2>/dev/null | head -1)
    if [[ -n "$latest_daily" ]]; then
        local daily_name=$(basename "$latest_daily" .md)
        local daily_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$latest_daily" 2>/dev/null)
        echo "  ${c_green}Daily${c_reset}   $daily_name  ${c_dim}($daily_time)${c_reset}"
    else
        echo "  ${c_yellow}Daily${c_reset}   No files collected yet"
    fi

    # Weekly draft
    local latest_weekly=$(ls -t "$_LATTICE_OUTPUT/weekly/"*-draft.md 2>/dev/null | head -1)
    if [[ -n "$latest_weekly" ]]; then
        local weekly_name=$(basename "$latest_weekly" .md)
        local weekly_time=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$latest_weekly" 2>/dev/null)
        echo "  ${c_green}Weekly${c_reset}  $weekly_name  ${c_dim}($weekly_time)${c_reset}"
    else
        echo "  ${c_yellow}Weekly${c_reset}  No drafts generated yet"
    fi

    echo ""

    # --- This Week's Coverage ---
    echo "${c_bold}This Week's Coverage:${c_reset}"
    local dow=$(date +%u)
    local monday=$(date -v-$((dow - 1))d +%Y-%m-%d)

    for i in 0 1 2 3 4; do
        local day=$(date -j -f "%Y-%m-%d" -v+${i}d "$monday" +%Y-%m-%d 2>/dev/null)
        local day_name=$(date -j -f "%Y-%m-%d" "$day" +%a 2>/dev/null)
        local file="$_LATTICE_OUTPUT/daily/$day.md"

        if [[ -f "$file" ]]; then
            local commits=$(grep -c '^\- \[' "$file" 2>/dev/null || echo "0")
            echo "  ${c_green}+${c_reset} $day_name $day  ${c_dim}($commits items)${c_reset}"
        elif [[ "$day" > "$(date +%Y-%m-%d)" ]]; then
            echo "  ${c_dim}-${c_reset} $day_name $day  ${c_dim}(upcoming)${c_reset}"
        else
            echo "  ${c_red}x${c_reset} $day_name $day  ${c_dim}(missing)${c_reset}"
        fi
    done

    echo ""

    # --- Recent Log Entries ---
    echo "${c_bold}Recent Log:${c_reset}"
    if [[ -f "$_LATTICE_OUTPUT/.collector.log" ]]; then
        tail -5 "$_LATTICE_OUTPUT/.collector.log" | while read line; do
            echo "  ${c_dim}$line${c_reset}"
        done
    else
        echo "  ${c_dim}No log entries.${c_reset}"
    fi
}

# ----- Aliases -----

# Short aliases for quick access
alias lc="lattice-collect"
alias lb="lattice-backfill"
alias ld="lattice-draft"
alias lr="lattice-review"
alias ls-lattice="lattice-files"
alias lstatus="lattice-status"
