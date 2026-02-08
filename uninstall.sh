#!/bin/bash

INSTALL_DIR="$HOME/.claude_code_tracker"
TRACKER_CONFIG_DIR="$INSTALL_DIR/config"
CLAUDE_CODE_JIRA_CONFIG="$TRACKER_CONFIG_DIR/claude_code_jira_config" # Renamed for clarity
CLAUDE_CODE_STATUSLINE_CONFIG="$TRACKER_CONFIG_DIR/claude_code_statusline_config"
CLAUDE_CODE_JIRA_REGEX_CONFIG="$TRACKER_CONFIG_DIR/claude_code_jira_regex_config"
WORK_DIR="$INSTALL_DIR/data/work" # Moved after config definitions for consistency

echo "🗑️  Uninstalling Claude Code Tracker..."
echo ""


# Automate Claude Code settings.json cleanup
CLAUDE_CODE_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_CODE_SETTINGS" ]; then
    echo "ℹ️  Attempting to clean up Claude Code settings.json..."
    
    ORIGINAL_STATUSLINE_COMMAND=""
    # Source the statusline config to get the backed-up command
    if [ -f "$CLAUDE_CODE_STATUSLINE_CONFIG" ]; then
        source "$CLAUDE_CODE_STATUSLINE_CONFIG"
    fi

    # Conditionally restore original statusLine.command or delete it
    if [ -n "$ORIGINAL_STATUSLINE_COMMAND" ]; then
        echo "✓ Restoring original statusLine.command in $CLAUDE_CODE_SETTINGS..."
        jq --arg cmd "$ORIGINAL_STATUSLINE_COMMAND" '.statusLine = {type: "command", command: $cmd}' "$CLAUDE_CODE_SETTINGS" > "$CLAUDE_CODE_SETTINGS.tmp" && mv "$CLAUDE_CODE_SETTINGS.tmp" "$CLAUDE_CODE_SETTINGS"
    else
        echo "✓ No original statusLine.command to restore. Removing statusLine entry..."
        jq 'del(.statusLine)' "$CLAUDE_CODE_SETTINGS" > "$CLAUDE_CODE_SETTINGS.tmp" && mv "$CLAUDE_CODE_SETTINGS.tmp" "$CLAUDE_CODE_SETTINGS"
    fi
    
    # Check if settings.json is now effectively empty
    if [ "$(jq -c '.' "$CLAUDE_CODE_SETTINGS")" == "{}" ]; then
        echo "✓ Claude Code settings.json is now empty. Deleting it."
        rm "$CLAUDE_CODE_SETTINGS"
    else
        echo "✓ Updated $CLAUDE_CODE_SETTINGS"
    fi
else
    echo "ℹ️  Claude Code settings.json not found. No cleanup needed there."
fi

# Detect shell config
SHELL_CONFIG=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    fi
fi

# Remove from shell config
if [ -n "$SHELL_CONFIG" ] && [ -f "$SHELL_CONFIG" ]; then
    echo "ℹ️  Attempting to remove tracker configuration from $SHELL_CONFIG..."
    local temp_shell_config="${SHELL_CONFIG}.tmp"
    
    # Use grep -vE to remove the lines and rewrite the file
    grep -vE '# Claude Code Tracker|source.*claude_code_tracker/functions.sh' "$SHELL_CONFIG" > "$temp_shell_config"
    mv "$temp_shell_config" "$SHELL_CONFIG"
    
    echo "✓ Removed from $SHELL_CONFIG"
fi

# Ask about work history
echo ""
echo "Work history is stored in: $WORK_DIR"
read -p "Delete work history? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$WORK_DIR"
    echo "✓ Deleted work history"
else
    echo "ℹ️  Kept work history at $WORK_DIR"
fi

# Remove installation directory
rm -rf "$INSTALL_DIR"
echo "✓ Removed installation directory"

CLAUDE_SCRIPTS_DIR="$HOME/.claude/scripts"
if [ -d "$CLAUDE_SCRIPTS_DIR" ]; then
    echo "ℹ️  Attempting to clean up Claude Code scripts directory..."
    # Remove the specific wrapper script
    if [ -f "$CLAUDE_SCRIPTS_DIR/claude_code_wrapper.sh" ]; then
        rm "$CLAUDE_SCRIPTS_DIR/claude_code_wrapper.sh"
        echo "✓ Removed claude_code_wrapper.sh"
    fi
    # If the directory becomes empty, offer to remove it
    if [ -z "$(ls -A "$CLAUDE_SCRIPTS_DIR")" ]; then
        read -p "Claude Code scripts directory ($CLAUDE_SCRIPTS_DIR) is now empty. Remove it? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$CLAUDE_SCRIPTS_DIR"
            echo "✓ Removed Claude Code scripts directory"
        else
            echo "ℹ️  Kept empty Claude Code scripts directory at $CLAUDE_SCRIPTS_DIR"
        fi
    else
        echo "ℹ️  Claude Code scripts directory ($CLAUDE_SCRIPTS_DIR) is not empty, keeping it."
    fi
else
    echo "ℹ️  Claude Code scripts directory ($CLAUDE_SCRIPTS_DIR) not found. No cleanup needed there."
fi

# Remove config files
echo ""
echo "ℹ️  Attempting to clean up tracker configuration files..."
CONFIG_FILES_TO_REMOVE=("$CLAUDE_CODE_JIRA_CONFIG" "$CLAUDE_CODE_STATUSLINE_CONFIG" "$CLAUDE_CODE_JIRA_REGEX_CONFIG")
for config_file in "${CONFIG_FILES_TO_REMOVE[@]}"; do
    if [ -f "$config_file" ]; then
        read -p "Delete config file '$config_file'? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f "$config_file"
            echo "✓ Deleted config file '$config_file'"
        else
            echo "ℹ️  Kept config file at '$config_file'"
        fi
    fi
done

# Remove global git hooks
read -p "Remove global git hooks? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git config --global --unset init.templateDir
    rm -rf ~/.git-templates/hooks/prepare-commit-msg
    echo "✓ Removed global git hooks"
else
    echo "ℹ️  Kept global git hooks"
fi

echo ""
echo "✅ Uninstallation complete!"
echo "   Please restart your terminal"
