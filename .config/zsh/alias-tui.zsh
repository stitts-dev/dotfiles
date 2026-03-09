# ===== Alias TUI =====
# Interactive TUI for browsing and executing shell aliases/functions
# Uses gum (https://github.com/charmbracelet/gum) for the interface
# Auto-discovers categories from comment patterns in .zsh files

# Cache location
_TUI_CACHE="/tmp/alias-tui-cache.json"
_TUI_ZSH_DIR="${HOME}/.config/zsh"

# ----- Icon Definitions (Emoji - universally supported) -----
typeset -A _TUI_ICONS
# Types
_TUI_ICONS[alias]="⌘"             # command/alias
_TUI_ICONS[function]="ƒ"          # function
# Categories (mapped by keyword matching)
_TUI_ICONS[git]="🔀"              # git merge/branch
_TUI_ICONS[github]="🐙"           # github octopus
_TUI_ICONS[jira]="🎫"             # ticket
_TUI_ICONS[java]="☕"             # coffee/java
_TUI_ICONS[agent]="🤖"            # robot
_TUI_ICONS[workflow]="⚡"         # workflow/automation
_TUI_ICONS[task]="📋"             # task list
_TUI_ICONS[healing]="🔧"          # wrench/fix
_TUI_ICONS[default]="📦"          # package/default
# Actions
_TUI_ICONS[execute]="▶"           # play
_TUI_ICONS[copy]="📋"             # clipboard
_TUI_ICONS[view]="👁"             # eye
_TUI_ICONS[back]="←"              # arrow left
_TUI_ICONS[cancel]="✕"            # x mark
_TUI_ICONS[search]="🔍"           # magnifying glass
_TUI_ICONS[customize]="🎨"        # customize icon
_TUI_ICONS[scheduled]="⏱"         # scheduled task

# ----- ANSI Code Utility -----

# Strip ANSI escape codes from string
_tui_strip_ansi() {
  echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

# ----- Custom Icon Overrides -----
_TUI_CUSTOM_ICONS="${HOME}/.config/zsh/tui-icons.conf"
typeset -A _TUI_CUSTOM

# Load custom icon overrides from config file
_tui_load_custom_icons() {
  _TUI_CUSTOM=()
  [[ -f "$_TUI_CUSTOM_ICONS" ]] || return
  while IFS='=' read -r key icon; do
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
    _TUI_CUSTOM[$key]="$icon"
  done < "$_TUI_CUSTOM_ICONS"
}

# Get icon with custom override support
_tui_get_icon() {
  local type="$1" name="$2"
  local key="${type}:${name}"
  # Check custom first
  [[ -n "${_TUI_CUSTOM[$key]}" ]] && { echo "${_TUI_CUSTOM[$key]}"; return; }
  # Fall back to defaults
  case "$type" in
    category) _tui_get_category_icon "$name" ;;
    alias)    echo "${_TUI_ICONS[alias]}" ;;
    function) echo "${_TUI_ICONS[function]}" ;;
  esac
}

# Set custom icon interactively
_tui_set_icon() {
  local type="$1" name="$2"
  local current=$(_tui_get_icon "$type" "$name")

  # Prompt for new icon
  local new_icon=$(gum input --placeholder "Enter emoji/icon" --value "$current" --width=20)
  [[ -z "$new_icon" ]] && return

  # Ensure config dir exists
  mkdir -p "$(dirname "$_TUI_CUSTOM_ICONS")"

  # Save to config (remove existing entry first)
  local key="${type}:${name}"
  if [[ -f "$_TUI_CUSTOM_ICONS" ]]; then
    local tmp=$(grep -v "^${key}=" "$_TUI_CUSTOM_ICONS" 2>/dev/null || true)
    echo "$tmp" > "$_TUI_CUSTOM_ICONS"
  fi
  echo "${key}=${new_icon}" >> "$_TUI_CUSTOM_ICONS"

  # Reload
  _tui_load_custom_icons
  echo "Icon updated: $name → $new_icon"
}

# Load custom icons on source
_tui_load_custom_icons

# Get icon for a category based on keyword matching
_tui_get_category_icon() {
  local category="${1:l}"  # lowercase
  case "$category" in
    *git*|*github*)  echo "${_TUI_ICONS[git]}" ;;
    *jira*)          echo "${_TUI_ICONS[jira]}" ;;
    *java*|*spring*) echo "${_TUI_ICONS[java]}" ;;
    *agent*)         echo "${_TUI_ICONS[agent]}" ;;
    *workflow*)      echo "${_TUI_ICONS[workflow]}" ;;
    *task*)          echo "${_TUI_ICONS[task]}" ;;
    *heal*|*fix*)    echo "${_TUI_ICONS[healing]}" ;;
    *)               echo "${_TUI_ICONS[default]}" ;;
  esac
}

# ----- Cache Management -----

# Check if cache is valid (exists and newer than all source files)
_tui_cache_valid() {
  [[ ! -f "$_TUI_CACHE" ]] && return 1

  for f in "$_TUI_ZSH_DIR"/*.zsh; do
    [[ -f "$f" && "$f" -nt "$_TUI_CACHE" ]] && return 1
  done
  return 0
}

# Parse all .zsh files and build cache
_tui_build_cache() {
  local items=()
  local current_category="Uncategorized"
  local current_subcategory=""

  # Shell keywords and builtins to exclude from function detection
  local -a shell_keywords=(
    # Control flow
    "if" "then" "else" "elif" "fi" "case" "esac" "for" "while" "until"
    "do" "done" "in" "function" "select" "time" "coproc"
    # Shell builtins
    "shift" "echo" "return" "break" "continue" "exit" "export" "local"
    "read" "eval" "exec" "source" "alias" "unalias" "command" "builtin"
    "declare" "typeset" "readonly" "unset" "printf" "print" "trap" "set"
    # Heredoc markers and common words
    "EOF" "END" "EOM" "HEREDOC" "None" "null" "true" "false"
    "EXAMPLES" "USAGE" "HELP" "cat" "end"
  )

  for file in "$_TUI_ZSH_DIR"/*.zsh; do
    [[ ! -f "$file" ]] && continue

    # Skip the TUI file itself to avoid self-referential entries
    [[ "$(basename "$file")" == "alias-tui.zsh" ]] && continue

    local filename=$(basename "$file")
    local line_num=0
    local in_heredoc=false
    local heredoc_delimiter=""
    local last_comment=""
    local last_args_hint=""

    while IFS= read -r line || [[ -n "$line" ]]; do
      ((line_num++))

      # Track heredoc state - skip lines inside heredocs
      if [[ "$in_heredoc" == true ]]; then
        # Check if this line ends the heredoc
        if [[ "$line" =~ ^[[:space:]]*${heredoc_delimiter}[[:space:]]*$ ]]; then
          in_heredoc=false
          heredoc_delimiter=""
        fi
        continue
      fi

      # Detect heredoc start: cat << 'EOF' or cat <<EOF or <<-EOF etc
      if [[ "$line" =~ \<\<-?[[:space:]]*[\'\"]?([A-Za-z_][A-Za-z0-9_]*)[\'\"]? ]]; then
        in_heredoc=true
        heredoc_delimiter="${match[1]}"
        continue
      fi

      # Track non-header comments for descriptions and usage hints
      # Match: # Some comment text (not ===== or ----- headers)
      if [[ "$line" =~ ^[[:space:]]*\#[[:space:]]+([^=\-].*)$ ]]; then
        local potential_comment="${match[1]}"
        # Skip if it looks like a header marker
        if [[ ! "$potential_comment" =~ ^[=\-]{3,} ]]; then
          # Check for usage patterns: Usage:, Args:, or contains [-flag] or <arg> patterns
          if [[ "$potential_comment" =~ ^(Usage|Args|Arguments|Options):?[[:space:]]*(.*) ]]; then
            last_args_hint="${match[2]}"
          elif [[ "$potential_comment" =~ (\[-[a-zA-Z]|\<[a-zA-Z]) ]]; then
            # Contains argument patterns like [-t] or <name>
            last_args_hint="$potential_comment"
          else
            last_comment="$potential_comment"
          fi
        fi
        # Don't continue - let it fall through to check for category/subcategory headers
      fi

      # Match category headers: # ===== Category Name =====
      # Extract text between the = delimiters
      if [[ "$line" == \#*=====*=====* ]]; then
        # Remove leading # and spaces, then extract text between ===== markers
        current_category=$(echo "$line" | sed 's/^#[[:space:]]*=*[[:space:]]*//; s/[[:space:]]*=*[[:space:]]*$//')
        [[ -z "$current_category" ]] && current_category="Uncategorized"
        current_subcategory=""
        last_comment=""  # Reset after category change
        last_args_hint=""
        continue
      fi

      # Match subcategory headers: # ----- Subcategory Name -----
      if [[ "$line" == \#*-----*-----* ]]; then
        current_subcategory=$(echo "$line" | sed 's/^#[[:space:]]*-*[[:space:]]*//; s/[[:space:]]*-*[[:space:]]*$//')
        last_comment=""  # Reset after subcategory change
        last_args_hint=""
        continue
      fi

      # Match alias definitions: alias name="command" or alias name='command'
      # Handle single-quoted and double-quoted separately to avoid greedy matching issues
      local name="" command=""
      if [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+([a-zA-Z0-9_-]+)=\'([^\']*)\'[[:space:]]*$ ]]; then
        # Single-quoted alias (no escaping inside single quotes)
        name="${match[1]}"
        command="${match[2]}"
      elif [[ "$line" =~ ^[[:space:]]*alias[[:space:]]+([a-zA-Z0-9_-]+)=\"([^\"]*)\"[[:space:]]*$ ]]; then
        # Double-quoted alias (simple case - no internal quotes)
        name="${match[1]}"
        command="${match[2]}"
      fi

      if [[ -n "$name" && -n "$command" ]]; then
        # JSON-escape the command string using jq
        local escaped_command=$(printf '%s' "$command" | jq -Rsa .)

        # Use last_comment as description, or empty string
        local desc="${last_comment:-}"
        local escaped_desc=$(printf '%s' "$desc" | jq -Rsa .)

        items+=("{\"name\":\"$name\",\"type\":\"alias\",\"command\":$escaped_command,\"description\":$escaped_desc,\"category\":\"$current_category\",\"subcategory\":\"$current_subcategory\",\"file\":\"$filename\",\"line\":$line_num}")
        last_comment=""  # Reset after capturing
        continue
      fi

      # Match function definitions: function_name() { or function function_name()
      # Require either: (1) "function" keyword, OR (2) starts at column 1 (no indent)
      if [[ "$line" =~ ^function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_-]*)[[:space:]]*\(\) ]] || \
         [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*)\(\) ]]; then
        # Extract name from whichever pattern matched
        local name="${match[1]}"

        # Skip if this looks like an array/variable assignment
        # e.g., "plugins=(git zsh)" - these don't have () after name anyway
        [[ "$line" == *"="* ]] && [[ "$line" != *"=="* ]] && [[ "$line" != *"!="* ]] && continue

        # Skip internal functions (starting with _)
        [[ "$name" == _* ]] && continue

        # Skip shell keywords
        local is_keyword=false
        for kw in "${shell_keywords[@]}"; do
          [[ "$name" == "$kw" ]] && { is_keyword=true; break; }
        done
        $is_keyword && continue

        # Use last_comment as description, or empty string
        local desc="${last_comment:-}"
        local escaped_desc=$(printf '%s' "$desc" | jq -Rsa .)
        local args="${last_args_hint:-}"
        local escaped_args=$(printf '%s' "$args" | jq -Rsa .)

        items+=("{\"name\":\"$name\",\"type\":\"function\",\"command\":\"(function)\",\"description\":$escaped_desc,\"args_hint\":$escaped_args,\"category\":\"$current_category\",\"subcategory\":\"$current_subcategory\",\"file\":\"$filename\",\"line\":$line_num}")
        last_comment=""  # Reset after capturing
        last_args_hint=""
        continue
      fi

    done < "$file"
  done

  # Write JSON array to cache using jq for proper formatting
  printf '%s\n' "${items[@]}" | jq -s '.' > "$_TUI_CACHE"
}

# Load cache, rebuilding if necessary
_tui_load_cache() {
  if ! _tui_cache_valid; then
    _tui_build_cache
  fi
  cat "$_TUI_CACHE"
}

# ----- Display Helpers -----

# Ensure cache is valid, rebuild if needed
_tui_ensure_cache() {
  if ! _tui_cache_valid; then
    _tui_build_cache
  fi
}

# Get unique categories with counts and icons
_tui_get_categories() {
  _tui_ensure_cache
  local categories
  categories=$(jq -r '
    group_by(.category) |
    map({category: .[0].category, count: length}) |
    sort_by(.category) |
    .[] |
    "\(.category)\t\(.count)"
  ' "$_TUI_CACHE")

  # Add colored icons to each category (supports custom overrides)
  while IFS=$'\t' read -r cat count; do
    local icon=$(_tui_get_icon "category" "$cat")
    echo -e "\e[38;5;212m${icon}\e[0m  ${cat}  \e[2m${count}\e[0m"
  done <<< "$categories"
}

# Get items for a specific category with icons and descriptions
_tui_get_items_by_category() {
  local category="$1"
  _tui_ensure_cache
  _tui_load_custom_icons  # Reload to get latest custom icons
  local c_icon=$'\e[38;5;212m'
  local c_dim=$'\e[2m'
  local c_reset=$'\e[0m'

  # Process items in shell to support per-item custom icons
  jq -c --arg cat "$category" '.[] | select(.category == $cat)' "$_TUI_CACHE" | while read -r item; do
    local name=$(echo "$item" | jq -r '.name')
    local type=$(echo "$item" | jq -r '.type')
    local desc=$(echo "$item" | jq -r 'if .type == "alias" then .command[0:45] else (.description // "")[0:45] end')
    local icon=$(_tui_get_icon "$type" "$name")
    echo -e "${c_icon}${icon}${c_reset}  ${name}  ${c_dim}${desc}${c_reset}"
  done
}

# Get all items for search with icons
_tui_get_all_items() {
  _tui_ensure_cache
  _tui_load_custom_icons  # Reload to get latest custom icons
  local c_icon=$'\e[38;5;212m'
  local c_dim=$'\e[2m'
  local c_reset=$'\e[0m'

  # Process items in shell to support per-item custom icons
  jq -c '.[]' "$_TUI_CACHE" | while read -r item; do
    local name=$(echo "$item" | jq -r '.name')
    local type=$(echo "$item" | jq -r '.type')
    local desc=$(echo "$item" | jq -r 'if .type == "alias" then .command[0:35] else (.description // "")[0:35] end')
    local cat=$(echo "$item" | jq -r '.category[0:20]')
    local icon=$(_tui_get_icon "$type" "$name")
    echo -e "${c_icon}${icon}${c_reset}  ${name}  ${c_dim}${desc}  [${cat}]${c_reset}"
  done
}

# Get item details by name
_tui_get_item_details() {
  local name="$1"
  _tui_ensure_cache
  jq -r --arg name "$name" '.[] | select(.name == $name) | @json' "$_TUI_CACHE"
}

# ----- Scheduled Tasks Banner -----

# Display scheduled background tasks (LaunchAgents) as a banner
_tui_scheduled_banner() {
  local plist_dir="$HOME/Library/LaunchAgents"
  local plists=("$plist_dir"/com.jstittsworth.*.plist(N))
  [[ ${#plists[@]} -eq 0 ]] && return

  local c_green=$'\e[32m'
  local c_red=$'\e[31m'
  local c_yellow=$'\e[33m'
  local c_dim=$'\e[2m'
  local c_reset=$'\e[0m'
  local sched_icon="${_TUI_ICONS[scheduled]}"

  local lines=()
  lines+=("${sched_icon}  Scheduled Tasks")
  lines+=("")

  for plist in "${plists[@]}"; do
    local label=$(basename "$plist" .plist)
    local short_name="${label#com.jstittsworth.}"

    # Check launchctl status
    local dot
    if launchctl list 2>/dev/null | grep -q "$label"; then
      local exit_code=$(launchctl list 2>/dev/null | grep "$label" | awk '{print $2}')
      if [[ "$exit_code" == "0" || "$exit_code" == "-" ]]; then
        dot="${c_green}●${c_reset}"
      else
        dot="${c_red}●${c_reset}"
      fi
    else
      dot="${c_yellow}●${c_reset}"
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
        schedule="${day_names} $(printf '%02d:00' "$hour")"
      fi
    fi

    # Find last run (newest daily file for lattice, generic log check otherwise)
    local last_run=""
    case "$short_name" in
      lattice-daily)
        local latest=$(ls -t "$HOME/Documents/lattice-updates/daily/"*.md 2>/dev/null | head -1)
        if [[ -n "$latest" ]]; then
          local fname=$(basename "$latest" .md)
          if [[ "$fname" == "$(date +%Y-%m-%d)" ]]; then
            last_run="Last: ${fname} (today)"
          else
            last_run="Last: ${fname}"
          fi
        fi
        ;;
      *)
        last_run=""
        ;;
    esac

    lines+=("${dot} ${short_name}    ${c_dim}${schedule}${c_reset}")
    [[ -n "$last_run" ]] && lines+=("  ${c_dim}${last_run}${c_reset}")
  done

  local banner_text=""
  for line in "${lines[@]}"; do
    if [[ -z "$banner_text" ]]; then
      banner_text="$line"
    else
      banner_text="${banner_text}
${line}"
    fi
  done

  gum style --border rounded --padding "1 2" --border-foreground "240" "$banner_text"
  echo ""
}

# ----- Main TUI Functions -----

# Main TUI entry point
tui() {
  # Check for gum
  if ! command -v gum &>/dev/null; then
    echo "gum is required but not installed."
    echo "Install with: brew install gum"
    return 1
  fi

  # Check for jq
  if ! command -v jq &>/dev/null; then
    echo "jq is required but not installed."
    echo "Install with: brew install jq"
    return 1
  fi

  local categories items header selected_category selected_item

  local search_icon="${_TUI_ICONS[search]}"

  # Navigation loop - Escape goes back to category selection
  while true; do
    # Show scheduled tasks banner
    _tui_scheduled_banner

    # Category selection
    categories=$(_tui_get_categories)
    local search_opt="\e[38;5;212m${search_icon}\e[0m  Search All..."
    local edit_cat_opt="\e[38;5;212m${_TUI_ICONS[customize]}\e[0m  Edit Category Icons..."
    selected_category=$(echo -e "$search_opt\n$edit_cat_opt\n$categories" | \
      gum choose --no-strip-ansi --header "Select Category (Esc to exit)" --cursor "▸ " --cursor.foreground="212")

    # Escape at category level exits
    [[ -z "$selected_category" ]] && return 0

    if [[ "$selected_category" == *"Search All..."* ]]; then
      items=$(_tui_get_all_items)
      header="$search_icon  Search all (Esc to go back)"
    elif [[ "$selected_category" == *"Edit Category Icons..."* ]]; then
      # Show category list for icon editing
      local cat_to_edit=$(echo "$categories" | \
        gum choose --no-strip-ansi --header "Select category to change icon" --cursor "▸ " --cursor.foreground="212")
      [[ -z "$cat_to_edit" ]] && continue
      # Extract category name
      local stripped=$(_tui_strip_ansi "$cat_to_edit")
      local cat_name=$(echo "$stripped" | sed 's/^[^[:alpha:]]*//; s/[[:space:]]*[0-9]*$//')
      _tui_set_icon "category" "$cat_name"
      continue
    else
      # Extract category name (format: "icon  Category Name  count")
      # Remove leading icon and spaces, then trailing count
      local stripped=$(_tui_strip_ansi "$selected_category")
      local cat_name=$(echo "$stripped" | sed 's/^[^[:alpha:]]*//; s/[[:space:]]*[0-9]*$//')
      items=$(_tui_get_items_by_category "$cat_name")
      header="$cat_name (Esc to go back)"
    fi

    # Item selection with fuzzy filter
    selected_item=$(echo -e "$items" | \
      gum filter --no-strip-ansi --header "$header" --placeholder "Type to filter..." \
      --indicator "▸" --indicator.foreground="212" --height=20)

    # Escape at item level goes back to categories
    [[ -z "$selected_item" ]] && continue

    # Extract name from selection (format: "ANSI_CODES icon ANSI_CODES  name  ANSI_CODES description ANSI_CODES")
    # Strip ANSI codes first, then skip icon (first field) and extract name (second field)
    local stripped=$(_tui_strip_ansi "$selected_item")
    local item_name=$(echo "$stripped" | awk '{print $2}')

    # Get full item details
    local details=$(_tui_get_item_details "$item_name")
    [[ -z "$details" || "$details" == "null" ]] && {
      echo "Item not found: $item_name"
      continue
    }

    local item_type=$(echo "$details" | jq -r '.type')
    local item_command=$(echo "$details" | jq -r '.command')
    local item_description=$(echo "$details" | jq -r '.description // ""')
    local item_args_hint=$(echo "$details" | jq -r '.args_hint // ""')
    local item_file=$(echo "$details" | jq -r '.file')
    local item_line=$(echo "$details" | jq -r '.line')
    local item_category=$(echo "$details" | jq -r '.category')
    local item_subcategory=$(echo "$details" | jq -r '.subcategory')

    # Get icons
    local type_icon="${_TUI_ICONS[$item_type]}"
    local cat_icon=$(_tui_get_category_icon "$item_category")

    # Build detail text with enhanced formatting
    local detail_text="$type_icon  $item_name"

    # Add description if available
    if [[ -n "$item_description" ]]; then
      detail_text="$detail_text
$item_description"
    fi

    detail_text="$detail_text

$cat_icon  $item_category"
    [[ -n "$item_subcategory" && "$item_subcategory" != "null" ]] && \
      detail_text="$detail_text > $item_subcategory"

    detail_text="$detail_text
${_TUI_ICONS[$item_type]}  $item_type
  $item_file:$item_line"

    if [[ "$item_type" == "alias" ]]; then
      detail_text="$detail_text

Command:
$item_command"
    elif [[ -n "$item_args_hint" ]]; then
      detail_text="$detail_text

Args:
$item_args_hint"
    fi

    echo ""
    gum style --border rounded --padding "1 2" --border-foreground "212" "$detail_text"
    echo ""

    # Action selection with icons
    local action
    local exec_opt="${_TUI_ICONS[execute]}  Execute"
    local copy_opt="${_TUI_ICONS[copy]}  Copy command"
    local view_opt="${_TUI_ICONS[view]}  View source"
    local icon_opt="${_TUI_ICONS[customize]}  Change icon"
    local back_opt="${_TUI_ICONS[back]}  Back"
    local cancel_opt="${_TUI_ICONS[cancel]}  Cancel"

    if [[ "$item_type" == "alias" ]]; then
      action=$(gum choose --header "Action" "$exec_opt" "$copy_opt" "$icon_opt" "$back_opt" "$cancel_opt")
    else
      action=$(gum choose --header "Action" "$exec_opt" "$view_opt" "$icon_opt" "$back_opt" "$cancel_opt")
    fi

    case "$action" in
      *Execute*)
        local placeholder="${item_args_hint:-Arguments (optional)}"
        local args=$(gum input --placeholder "$placeholder" --width=50)
        echo "Executing: $item_name $args"
        echo ""
        eval "$item_name $args"
        return 0
        ;;
      *"Copy command"*)
        echo "$item_command" | pbcopy
        echo "Command copied to clipboard"
        return 0
        ;;
      *"View source"*)
        local full_path="$_TUI_ZSH_DIR/$item_file"
        if command -v bat &>/dev/null; then
          bat --style=numbers --highlight-line "$item_line" "$full_path"
        else
          sed -n "${item_line},$((item_line + 20))p" "$full_path" | nl -ba -v "$item_line"
        fi
        return 0
        ;;
      *"Change icon"*)
        _tui_set_icon "$item_type" "$item_name"
        continue
        ;;
      *Back*)
        continue
        ;;
      *)
        return 0
        ;;
    esac
  done
}

# Quick search mode - skip category selection
tui_search() {
  # Check for gum
  if ! command -v gum &>/dev/null; then
    echo "gum is required but not installed."
    echo "Install with: brew install gum"
    return 1
  fi

  local search_icon="${_TUI_ICONS[search]}"
  local items=$(_tui_get_all_items)
  local selected_item=$(echo -e "$items" | \
    gum filter --no-strip-ansi --header "$search_icon  Search all aliases and functions" \
    --placeholder "Type to filter..." --indicator "▸" --indicator.foreground="212" --height=20)

  [[ -z "$selected_item" ]] && return 0

  # Extract name from selection (format: "icon  name  description")
  # Strip ANSI codes first, then skip icon (first field) and extract name (second field)
  local stripped=$(_tui_strip_ansi "$selected_item")
  local item_name=$(echo "$stripped" | awk '{print $2}')

  # Get full item details
  local details=$(_tui_get_item_details "$item_name")
  [[ -z "$details" || "$details" == "null" ]] && {
    echo "Item not found: $item_name"
    return 1
  }

  local item_type=$(echo "$details" | jq -r '.type')
  local item_command=$(echo "$details" | jq -r '.command')
  local item_description=$(echo "$details" | jq -r '.description // ""')
  local item_args_hint=$(echo "$details" | jq -r '.args_hint // ""')
  local item_file=$(echo "$details" | jq -r '.file')
  local item_line=$(echo "$details" | jq -r '.line')
  local item_category=$(echo "$details" | jq -r '.category')

  # Get icons
  local type_icon="${_TUI_ICONS[$item_type]}"
  local cat_icon=$(_tui_get_category_icon "$item_category")

  # Build detail text with enhanced formatting
  local detail_text="$type_icon  $item_name"

  if [[ -n "$item_description" ]]; then
    detail_text="$detail_text
$item_description"
  fi

  detail_text="$detail_text

$cat_icon  $item_category
${_TUI_ICONS[$item_type]}  $item_type
  $item_file:$item_line"

  if [[ "$item_type" == "alias" ]]; then
    detail_text="$detail_text

Command:
$item_command"
  elif [[ -n "$item_args_hint" ]]; then
    detail_text="$detail_text

Args:
$item_args_hint"
  fi

  echo ""
  gum style --border rounded --padding "1 2" --border-foreground "212" "$detail_text"
  echo ""

  # Quick action with icons
  local action
  local exec_opt="${_TUI_ICONS[execute]}  Execute"
  local copy_opt="${_TUI_ICONS[copy]}  Copy command"
  local view_opt="${_TUI_ICONS[view]}  View source"
  local icon_opt="${_TUI_ICONS[customize]}  Change icon"
  local cancel_opt="${_TUI_ICONS[cancel]}  Cancel"

  if [[ "$item_type" == "alias" ]]; then
    action=$(gum choose --header "Action" "$exec_opt" "$copy_opt" "$icon_opt" "$cancel_opt")
  else
    action=$(gum choose --header "Action" "$exec_opt" "$view_opt" "$icon_opt" "$cancel_opt")
  fi

  case "$action" in
    *Execute*)
      local placeholder="${item_args_hint:-Arguments (optional)}"
      local args=$(gum input --placeholder "$placeholder" --width=50)
      echo "Executing: $item_name $args"
      echo ""
      eval "$item_name $args"
      ;;
    *"Copy command"*)
      echo "$item_command" | pbcopy
      echo "Command copied to clipboard"
      ;;
    *"View source"*)
      local full_path="$_TUI_ZSH_DIR/$item_file"
      if command -v bat &>/dev/null; then
        bat --style=numbers --highlight-line "$item_line" "$full_path"
      else
        sed -n "${item_line},$((item_line + 20))p" "$full_path" | nl -ba -v "$item_line"
      fi
      ;;
    *"Change icon"*)
      _tui_set_icon "$item_type" "$item_name"
      ;;
    *)
      echo "Cancelled"
      ;;
  esac
}

# Force rebuild cache
tui_rebuild() {
  echo "Rebuilding alias cache..."
  rm -f "$_TUI_CACHE"
  _tui_build_cache
  local count=$(jq length "$_TUI_CACHE")
  echo "Cache rebuilt with $count items"
}

# Show TUI help
tui_help() {
  cat << 'EOF'
Alias TUI - Interactive alias/function browser

COMMANDS:
  a, tui          Browse aliases by category
  as, tui_search  Search all aliases directly
  tui_rebuild     Force rebuild the cache
  tui_help        Show this help

NAVIGATION:
  - Use arrow keys or type to filter
  - Enter to select
  - Esc or Ctrl+C to cancel

FEATURES:
  - Auto-discovers aliases from ~/.config/zsh/*.zsh
  - Categories parsed from # ===== Category ===== comments
  - Cache auto-rebuilds when source files change

REQUIREMENTS:
  - gum (brew install gum)
  - jq (brew install jq)
EOF
}

# ----- Aliases -----
alias a="tui"
alias as="tui_search"
