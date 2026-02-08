#!/bin/bash

# Claude Code Tracker - Main Functions
# Version: 1.0.0
# Platform: Cross-platform (macOS, Linux, Windows)

# ============================================================================
# Dependency Check
# ============================================================================

check_jq() {
    if ! command -v jq &> /dev/null; then
        echo "Error: 'jq' is not installed."
        echo "Please install 'jq' to use the Claude Code Tracker."
        echo "  - macOS: brew install jq"
        echo "  - Linux: sudo apt-get install jq (Debian/Ubuntu) or sudo yum install jq (Fedora/RHEL)"
        echo "  - Windows (WSL/Git Bash): Follow Linux instructions"
        echo "  - Windows (PowerShell): Not directly supported, but WSL/Git Bash with jq is recommended."
        exit 1
    fi
}

check_jq

# ============================================================================
# Platform Detection
# ============================================================================

detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -qi microsoft /proc/version 2>/dev/null; then
            echo "wsl"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

PLATFORM=$(detect_platform)

# ============================================================================
# Configuration
# ============================================================================

INSTALL_DIR="${INSTALL_DIR:-$HOME/.claude_code_tracker}"
TRACKER_CONFIG_DIR="$INSTALL_DIR/config"
WORK_DIR="$INSTALL_DIR/data/work"
CLAUDE_CODE_JIRA_CONFIG="$TRACKER_CONFIG_DIR/claude_code_jira_config" # Used for JIRA_BASE_URL only
CLAUDE_CODE_JIRA_REGEX_CONFIG="$TRACKER_CONFIG_DIR/claude_code_jira_regex_config"

# ============================================================================
# Configuration Functions
# ============================================================================

get_config_value() {
    local config_file=$1
    local key=$2
    local default_value=$3
    if [ -f "$config_file" ]; then
        grep "^$key=" "$config_file" | cut -d'=' -f2- || echo "$default_value"
    else
        echo "$default_value"
    fi
}

set_config_value() {
    local config_file=$1
    local key=$2
    local value=$3
    local temp_file="${config_file}.tmp.$$"

    if [ -f "$config_file" ]; then
        # Use a portable sed command for in-place replacement or add new line
        if grep -q "^$key=" "$config_file"; then
            sed -e "s|^$key=.*|$key=$value|" "$config_file" > "$temp_file" && mv "$temp_file" "$config_file"
        else
            echo "$key=$value" >> "$config_file"
        fi
    else
        echo "$key=$value" > "$config_file"
    fi
}

get_jira_base_url() {
    get_config_value "$CLAUDE_CODE_JIRA_CONFIG" "JIRA_BASE_URL" "https://jira.yourcompany.com/browse"
}

set_jira_base_url() {
    set_config_value "$CLAUDE_CODE_JIRA_CONFIG" "JIRA_BASE_URL" "$1"
    echo "✓ JIRA base URL set to: $1"
}

get_jira_ticket_regex() {
    # Default Jira ticket regex (e.g., ABC-123, FOO-12)
    get_config_value "$CLAUDE_CODE_JIRA_REGEX_CONFIG" "JIRA_TICKET_REGEX" '[A-Z]+-[0-9]+'
}

set_jira_ticket_regex() {
    set_config_value "$CLAUDE_CODE_JIRA_REGEX_CONFIG" "JIRA_TICKET_REGEX" "$1"
    echo "✓ JIRA ticket regex set to: $1"
}

# ============================================================================
# Ticket Detection Functions
# ============================================================================

get_current_ticket() {
    local branch=${1:-$(git rev-parse --abbrev-ref HEAD 2>/dev/null)}
    
    if [ -z "$branch" ]; then
        return
    fi
    
    local jira_regex=$(get_jira_ticket_regex)
    # Strip leading/trailing double quotes from the regex
    jira_regex="${jira_regex%\"}"
    jira_regex="${jira_regex#\"}"
    echo "$branch" | grep -oE "$jira_regex" | head -1
}

get_ticket_file() {
    local ticket=$1
    echo "$WORK_DIR/${ticket}.json"
}

# ============================================================================
# Token Formatting
# ============================================================================

format_tokens() {
    local tokens=$1
    
    if [ $tokens -ge 1000000 ]; then
        local millions=$((tokens / 100000))
        if [ $((millions % 10)) -eq 0 ]; then
            echo "$((millions / 10))m"
        else
            local result=$(awk "BEGIN {printf \"%.1f\", $millions / 10}")
            echo "${result}m"
        fi
    elif [ $tokens -ge 1000 ]; then
        local thousands=$((tokens / 100))
        if [ $((thousands % 10)) -eq 0 ]; then
            echo "$((thousands / 10))k"
        else
            local result=$(awk "BEGIN {printf \"%.1f\", $thousands / 10}")
            echo "${result}k"
        fi
    else
        echo "$tokens"
    fi
}

# ============================================================================
# Utility Functions
# ============================================================================

# Returns a Unix timestamp (seconds since epoch)
get_timestamp() {
    date +%s
}

# Formats a Unix timestamp into a readable date string
format_date() {
    local timestamp=$1
    case "$PLATFORM" in
        macos)
            date -r "$timestamp" "+%Y-%m-%d %H:%M:%S"
            ;;
        linux|wsl)
            date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S"
            ;;
        windows)
            # Git Bash / MSYS2 uses date -d, but may have issues with timezone or locale.
            # Fallback to a simpler format if necessary, or rely on WSL/Linux for full functionality.
            # For now, use the linux style date.
            date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S"
            ;;
        *)
            date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S" # Default to Linux style
            ;;
    esac
}


# ============================================================================
# Session Management Functions
# ============================================================================

work_start() {
    local ticket=$(get_current_ticket)

    if [ -z "$ticket" ]; then
        echo "⚠️  No ticket found in branch name"
        echo "   Expected format matches: $(get_jira_ticket_regex)"
        echo "   Branch examples: feature/ABC-123, chore/2027/DEV-456-desc"
        return 1
    fi

    local ticket_file=$(get_ticket_file "$ticket")
    local now=$(get_timestamp)

    # Ensure the directory for the ticket file exists
    mkdir -p "$(dirname "$ticket_file")"

    if [ -f "$ticket_file" ]; then
        # Check if there's an active session using jq
        local active=$(jq -r '.sessions[] | select(.active == true)' "$ticket_file" 2>/dev/null)
        if [ -n "$active" ]; then
            return 0
        fi
        # Count sessions using jq
        local sessions=$(jq '.sessions | length' "$ticket_file")
        echo "▶️  Resumed work on $ticket (session #$((sessions + 1)))"
    else
        # Create initial JSON structure using jq
        jq -n \
            --arg ticket_val "$ticket" \
            --argjson created_val "$now" \
            '{ticket: $ticket_val, created: $created_val, sessions: []}' > "$ticket_file"
        echo "▶️  Started new work on $ticket"
    fi

    # Append new session using jq
    jq \
        --argjson session_start_val "$now" \
        '.sessions += [{session_start: $session_start_val, session_end: null, tokens: 0, active: true}]' \
        "$ticket_file" > "${ticket_file}.tmp" && mv "${ticket_file}.tmp" "$ticket_file"
}
work_add_tokens() {
    local tokens_to_add=$1
    local ticket=$(get_current_ticket)

    if [ -z "$ticket" ]; then
        return
    fi

    local ticket_file=$(get_ticket_file "$ticket")

    if [ ! -f "$ticket_file" ]; then
        work_start
        # If work_start fails to create the file, we can't proceed
        if [ ! -f "$ticket_file" ]; then
            return 1
        fi
    fi

    # Find the index of the active session and its current tokens using jq
    local active_session_index
    active_session_index=$(jq '[.sessions[] | select(.active == true)] | length - 1' "$ticket_file" 2>/dev/null)

    if (( active_session_index >= 0 )); then
        local current_tokens
        current_tokens=$(jq -r ".sessions[$active_session_index].tokens" "$ticket_file")

        local new_tokens=$((current_tokens + tokens_to_add))

        # Update the tokens in the active session using jq
        jq ".sessions[$active_session_index].tokens = $new_tokens" \
            "$ticket_file" > "${ticket_file}.tmp" && mv "${ticket_file}.tmp" "$ticket_file"
    fi
}
work_end() {
    local target_ticket=${1:-$(get_current_ticket)}

    if [ -z "$target_ticket" ]; then
        echo "⚠️  No ticket found in current branch or provided as argument"
        return 1
    fi

    local ticket_file=$(get_ticket_file "$target_ticket")

    if [ ! -f "$ticket_file" ]; then
        echo "⚠️  No work history for $ticket"
        return 1
    fi

    local now=$(get_timestamp)

    # Find the index of the active session
    local active_session_index
    active_session_index=$(jq '[.sessions[] | select(.active == true)] | length - 1' "$ticket_file" 2>/dev/null)

    if [ "$active_session_index" -lt 0 ]; then
        echo "⚠️  No active session found"
        return 1
    fi

    local session_start
    session_start=$(jq -r ".sessions[$active_session_index].session_start" "$ticket_file")
    local tokens
    tokens=$(jq -r ".sessions[$active_session_index].tokens" "$ticket_file")
    local duration=$((now - session_start))

    # Update the active session using jq
    jq ".sessions[$active_session_index] = (.sessions[$active_session_index] | .session_end = $now | .duration = $duration | .active = false)" \
        "$ticket_file" > "${ticket_file}.tmp" && mv "${ticket_file}.tmp" "$ticket_file"

    local hours=$((duration / 3600))
    local minutes=$(((duration % 3600) / 60))

    echo "✅ Session ended for $target_ticket"
    echo "   This session: ${hours}h ${minutes}m, $tokens tokens"

    work_summary
}
# ============================================================================
# Display Functions
# ============================================================================

work_status() {
    local ticket=$(get_current_ticket)

    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo ""
        return
    fi

    if [ -z "$ticket" ]; then
        echo "No Jira Ticket" # More concise message for status line
        return
    fi

    local ticket_file=$(get_ticket_file "$ticket")

    if [ ! -f "$ticket_file" ]; then
        echo "💤 $ticket (no activity)"
        return
    fi

    local active_session_count=$(jq '[.sessions[] | select(.active == true)] | length' "$ticket_file" 2>/dev/null)

    if [ "$active_session_count" -eq 0 ]; then
        echo "💤 $ticket (session ended)"
        return
    fi

    local session_start=$(jq -r '.sessions[] | select(.active == true) | .session_start' "$ticket_file" | tail -1)
    local current_tokens=$(jq -r '.sessions[] | select(.active == true) | .tokens' "$ticket_file" | tail -1)
    local now=$(get_timestamp)
    local duration=$((now - session_start))

    local hours=$((duration / 3600))
    local minutes=$(((duration % 3600) / 60))

    local time_display
    if [ $hours -eq 0 ]; then
        time_display="${minutes}m"
    else
        time_display="${hours}h ${minutes}m"
    fi

    local token_display=$(format_tokens $current_tokens)

    echo "$ticket ⏱️  $time_display 🪙 $token_display"
}
work_summary() {
    local ticket=$(get_current_ticket)

    if [ -z "$ticket" ]; then
        echo "⚠️  No ticket found in current branch"
        return 1
    fi

    local ticket_file=$(get_ticket_file "$ticket")

    if [ ! -f "$ticket_file" ]; then
        echo "⚠️  No work history for $ticket"
        return 1
    fi

    local created
    created=$(jq -r '.created' "$ticket_file")

    local session_count
    session_count=$(jq '.sessions | length' "$ticket_file")

    local total_duration=0
    local total_tokens=0

    # Calculate total duration and tokens considering active session
    local session_data
    session_data=$(jq -c '.sessions[]' "$file")

    while IFS= read -r session_json; do
        local session_start=$(echo "$session_json" | jq -r '.session_start')
        local tokens=$(echo "$session_json" | jq -r '.tokens')
        local is_active=$(echo "$session_json" | jq -r '.active')
        local duration=$(echo "$session_json" | jq -r '.duration // 0') # Use 0 if duration is null

        if [ "$is_active" = "true" ]; then
            local now=$(get_timestamp)
            duration=$((now - session_start))
        fi

        total_duration=$((total_duration + duration))
        total_tokens=$((total_tokens + tokens))
    done <<< "$session_data"

    local hours=$((total_duration / 3600))
    local minutes=$(((total_duration % 3600) / 60))
    local created_date=$(format_date "$created")

    echo ""
    echo "📊 Work Summary for $ticket"
    echo "   Created: $created_date"
    echo "   Sessions: $session_count"
    echo "   Total time: ${hours}h ${minutes}m"
    echo "   Total tokens: $total_tokens"
    echo "   File: $ticket_file"
    echo ""

    local jira_base_url=$(get_jira_base_url)
    local jira_url="${jira_base_url}/$ticket"

    if [[ "$TERM_PROGRAM" == "iTerm.app" ]] || [[ "$TERM_PROGRAM" == "WezTerm" ]] || [[ -n "$WT_SESSION" ]]; then
        echo -e "   Link: \e]8;;${jira_url}\e\\${ticket}\e]8;;\e\\"
        echo "   💡 Tip: Click the link above to open in browser"
    else
        echo "   Link: $jira_url"
        if [[ "$PLATFORM" == "windows" ]]; then
            echo "   💡 Tip: Use Windows Terminal for clickable links, or run: jira_open"
        else
            echo "   💡 Tip: For clickable links, use Windows Terminal, iTerm2, or WezTerm"
            echo "   Or run: jira_open"
        fi
    fi
}
work_list() {
    echo "📋 Work History:"
    echo ""

    local found=0
    for file in "$WORK_DIR"/*.json; do
        if [ -f "$file" ]; then
            found=1
            local ticket=$(basename "$file" .json)

            local sessions=$(jq '.sessions | length' "$file")

            local total_duration=0
            local total_tokens=0

            # Calculate total duration and tokens considering active session
            local session_data
            session_data=$(jq -c '.sessions[]' "$file")

            while IFS= read -r session_json; do
                local session_start=$(echo "$session_json" | jq -r '.session_start')
                local tokens=$(echo "$session_json" | jq -r '.tokens')
                local is_active=$(echo "$session_json" | jq -r '.active')
                local duration=$(echo "$session_json" | jq -r '.duration // 0') # Use 0 if duration is null

                if [ "$is_active" = "true" ]; then
                    local now=$(get_timestamp)
                    duration=$((now - session_start))
                fi

                total_duration=$((total_duration + duration))
                total_tokens=$((total_tokens + tokens))
            done <<< "$session_data"

            local hours=$((total_duration / 3600))
            local minutes=$(((total_duration % 3600) / 60))

            echo "  $ticket: ${sessions} sessions, ${hours}h ${minutes}m, $total_tokens tokens"
        fi
    done

    if [ $found -eq 0 ]; then
        echo "  No work history found"
    fi
}
work_view() {
    local ticket=${1:-$(get_current_ticket)}
    
    if [ -z "$ticket" ]; then
        echo "⚠️  No ticket specified or found"
        return 1
    fi
    
    local ticket_file=$(get_ticket_file "$ticket")
    
    if [ ! -f "$ticket_file" ]; then
        echo "⚠️  No work history for $ticket"
        return 1
    fi
    
    cat "$ticket_file"
}

# ============================================================================
# Browser Integration
# ============================================================================

jira_open() {
    local ticket=${1:-$(get_current_ticket)}
    
    if [ -z "$ticket" ]; then
        echo "⚠️  No ticket specified or found"
        return 1
    fi
    
    local jira_base_url=$(get_jira_base_url)
    local jira_url="${jira_base_url}/$ticket"
    
    case "$PLATFORM" in
        macos)
            open "$jira_url"
            ;;
        linux)
            xdg-open "$jira_url" 2>/dev/null
            ;;
        wsl)
            if command -v wslview &> /dev/null; then
                wslview "$jira_url"
            elif command -v explorer.exe &> /dev/null; then
                explorer.exe "$jira_url"
            else
                powershell.exe -Command "Start-Process '$jira_url'"
            fi
            ;;
        windows)
            if command -v start &> /dev/null; then
                start "$jira_url"
            elif command -v cygstart &> /dev/null; then
                cygstart "$jira_url"
            elif command -v cmd.exe &> /dev/null; then
                cmd.exe /c start "$jira_url"
            else
                echo "⚠️  Could not open browser. Please visit: $jira_url"
                return 1
            fi
            ;;
        *)
            echo "⚠️  Platform not supported for auto-open. Please visit: $jira_url"
            return 1
            ;;
    esac
    
    echo "✓ Opened $ticket in browser"
}



# ============================================================================
# Auto-Detection Functions
# ============================================================================

LAST_WORK_DIR=""
LAST_KNOWN_BRANCH=""

auto_work_detect() {
    local current_dir="$PWD"
    
    if [ "$current_dir" != "$LAST_WORK_DIR" ]; then
        local prev_dir_was_git=false
        if [ -n "$LAST_KNOWN_BRANCH" ]; then # If LAST_KNOWN_BRANCH was set, we were in a git repo
            prev_dir_was_git=true
        fi

        LAST_WORK_DIR="$current_dir" # Update LAST_WORK_DIR immediately

        local current_is_git=false
        local current_git_branch="" # Initialize here
        if git rev-parse --git-dir > /dev/null 2>&1; then
            current_is_git=true
            current_git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        fi

        # Scenario: Moving out of a Git repo, or into a different one where previous session needs ending
        if [ "$prev_dir_was_git" = true ] && [ "$current_is_git" = false ]; then
            # Moved out of a Git repo entirely
            local prev_ticket=$(get_current_ticket "$LAST_KNOWN_BRANCH")
            if [ -n "$prev_ticket" ]; then
                local prev_ticket_file=$(get_ticket_file "$prev_ticket")
                if [ -f "$prev_ticket_file" ]; then
                    local prev_active_session_count=$(jq '[.sessions[] | select(.active == true)] | length' "$prev_ticket_file" 2>/dev/null)
                    if (( prev_active_session_count > 0 )); then
                        echo "🔄 Moved out of Git repo. Ending active session for $prev_ticket..."
                        work_end "$prev_ticket"
                    fi
                fi
            fi
            LAST_KNOWN_BRANCH="" # Clear as no longer in a git repo
        elif [ "$prev_dir_was_git" = true ] && [ "$current_is_git" = true ]; then
            # Moved from one Git repo to another, or within a Git repo
            # Here, we need to make sure LAST_KNOWN_BRANCH is updated if we moved to a new git repo that the hook didn't handle.
            if [ "$current_git_branch" != "$LAST_KNOWN_BRANCH" ]; then
                # This happens if moving between two different git repos
                # or into a repo where branch was not handled by hook on last entry.
                local current_ticket=$(get_current_ticket "$current_git_branch")
                
                # End previous session if it exists and is different
                local prev_ticket=$(get_current_ticket "$LAST_KNOWN_BRANCH")
                if [ -n "$prev_ticket" ] && [ "$prev_ticket" != "$current_ticket" ]; then
                    local prev_ticket_file=$(get_ticket_file "$prev_ticket")
                    if [ -f "$prev_ticket_file" ]; then
                        local prev_active_session_count=$(jq '[.sessions[] | select(.active == true)] | length' "$prev_ticket_file" 2>/dev/null)
                        if (( prev_active_session_count > 0 )); then
                            echo "🔄 Directory changed to new repo/branch. Ending active session for $prev_ticket..."
                            work_end "$prev_ticket"
                        fi
                    fi
                fi

                # Start/resume session for current ticket
                if [ -n "$current_ticket" ]; then
                    echo "▶️  Directory changed. Ensuring work session for $current_ticket is active."
                    work_start
                fi
                LAST_KNOWN_BRANCH="$current_git_branch" # Update after processing
            fi
        elif [ "$prev_dir_was_git" = false ] && [ "$current_is_git" = true ]; then
            # Moved into a Git repo from a non-Git directory
            local current_ticket=$(get_current_ticket "$current_git_branch")

            if [ -n "$current_ticket" ]; then
                echo "▶️  Entered Git repo. Ensuring work session for $current_ticket is active."
                work_start
            fi
            LAST_KNOWN_BRANCH="$current_git_branch" # Update after processing
        fi

        # Display warning if in a Git repo but no ticket (after processing all scenarios)
        local display_warning_branch="$current_git_branch" # Use the branch from current scan
        if [ "$current_is_git" = true ] && [ -z "$(get_current_ticket "$display_warning_branch")" ]; then
            echo ""
            echo "⚠️  No ticket number in branch name!"
            echo "   Current branch: $display_warning_branch"
            echo "   Expected format matches: $(get_jira_ticket_regex)"
            echo "   Tip: Rename with: git branch -m feature/ABC-123-description"
            echo ""
        fi
    fi
    # No action if directory didn't change (branch changes are handled by hook)
}

# ============================================================================
# GitHub Integration
# ============================================================================

gh() {
    command gh "$@"
    local exit_code=$?
    
    if [ "$1" = "pr" ] && [ "$2" = "create" ] && [ $exit_code -eq 0 ]; then
        echo ""
        echo "🎉 PR created! Ending work session..."
        work_end
    fi
    
    return $exit_code
}

# ============================================================================
# Tracker Command Line Interface (CLI)
# ============================================================================

# Helper function for initializing repo hooks
_tracker_init_repo() { # Renamed from tracker_init_repo
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "⚠️  Not inside a Git repository."
        echo "   Please navigate to the root of your Git repository and try again."
        return 1
    fi

    local git_root=$(git rev-parse --show-toplevel)
    local hooks_dir="$git_root/.git/hooks"
    local global_template_hook="$HOME/.git-templates/hooks/prepare-commit-msg"
    local local_hook="$hooks_dir/prepare-commit-msg"

    mkdir -p "$hooks_dir"

    if [ -f "$global_template_hook" ]; then
        cp "$global_template_hook" "$local_hook"
        chmod +x "$local_hook"
        echo "✓ Git 'prepare-commit-msg' hook installed for current repository: $local_hook"
    else
        echo "⚠️  Global Git template hook not found at $global_template_hook."
        echo "   Please ensure the Claude Code Tracker is fully installed."
        return 1
    fi
}


tracker() {
    local subcommand=$1
    shift # Remove the subcommand from the arguments list

    case "$subcommand" in
        "init")
            _tracker_init_repo "$@"
            ;;
        # Add other subcommands here as needed
        *)
            echo "Usage: tracker <subcommand>"
            echo "Subcommands:"
            echo "  init      - Initialize Git hooks for the current repository"
            # Add descriptions for other subcommands here
            return 1
            ;;
    esac
}

# ============================================================================
# Shell Integration - Auto-detection only
# ============================================================================

# For bash
if [ -n "$BASH_VERSION" ]; then
    PROMPT_COMMAND="auto_work_detect${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi

# For zsh
if [ -n "$ZSH_VERSION" ]; then
    precmd() {
        auto_work_detect
    }
fi