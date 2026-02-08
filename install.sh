#!/bin/bash

set -e

INSTALL_DIR="$HOME/.claude_code_tracker" # Explicitly define INSTALL_DIR
TRACKER_CONFIG_DIR="$INSTALL_DIR/config"
WORK_DIR="$INSTALL_DIR/data/work"
CLAUDE_CODE_JIRA_CONFIG="$TRACKER_CONFIG_DIR/claude_code_jira_config" # Renamed for clarity
CLAUDE_CODE_STATUSLINE_CONFIG="$TRACKER_CONFIG_DIR/claude_code_statusline_config"

echo "🚀 Installing Claude Code Tracker..."
echo ""

# Detect platform
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    PLATFORM="windows"
    echo "📍 Detected platform: Windows (Git Bash)"
elif grep -qi microsoft /proc/version 2>/dev/null; then
    PLATFORM="wsl"
    echo "📍 Detected platform: WSL (Windows Subsystem for Linux)"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    echo "📍 Detected platform: macOS"
else
    PLATFORM="linux"
    echo "📍 Detected platform: Linux"
fi
echo ""

# Create necessary directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$TRACKER_CONFIG_DIR"
mkdir -p "$WORK_DIR"

# Copy source files
echo "📦 Copying files..."
cp -r src/* "$INSTALL_DIR/"

# Setup Claude Code integration
echo "🔧 Setting up Claude Code integration..."
CLAUDE_DIR="$HOME/.claude"
CLAUDE_SCRIPTS_DIR="$CLAUDE_DIR/scripts"

mkdir -p "$CLAUDE_SCRIPTS_DIR"

# Copy wrapper script
cp "$INSTALL_DIR/claude_code_wrapper.sh" "$CLAUDE_SCRIPTS_DIR/claude_code_wrapper.sh"
chmod +x "$CLAUDE_SCRIPTS_DIR/claude_code_wrapper.sh"
echo "✓ Copied Claude Code wrapper script to $CLAUDE_SCRIPTS_DIR"

# Configure Claude Code settings.json
CLAUDE_CODE_SETTINGS="$HOME/.claude/settings.json"
ORIGINAL_STATUSLINE_COMMAND=""
STATUSLINE_SEPARATOR="\\n" # Default separator

if [ -f "$CLAUDE_CODE_SETTINGS" ]; then
    echo ""
    echo "🔍 Found existing Claude Code settings: $CLAUDE_CODE_SETTINGS"
    
    # Extract existing statusLine.command if it exists
    EXISTING_COMMAND=$(jq -r '.statusLine.command // empty' "$CLAUDE_CODE_SETTINGS")
    if [ -n "$EXISTING_COMMAND" ]; then
        ORIGINAL_STATUSLINE_COMMAND="$EXISTING_COMMAND"
        echo "✓ Detected existing statusLine.command: $ORIGINAL_STATUSLINE_COMMAND"
    else
        echo "✗ No existing statusLine.command found in $CLAUDE_CODE_SETTINGS"
    fi
else
    echo ""
    echo "✗ Claude Code settings.json not found at $CLAUDE_CODE_SETTINGS. It will be created."
    # Initialize an empty JSON if file doesn't exist
    echo "{}" > "$CLAUDE_CODE_SETTINGS"
fi

# Prompt for separator only if config doesn't exist
if [ ! -f "$CLAUDE_CODE_STATUSLINE_CONFIG" ]; then
    echo ""
    echo "⚙️  Configuring Claude Code Status Line integration..."
    echo "   (You can change these values later by editing $CLAUDE_CODE_STATUSLINE_CONFIG)"

    read -p "Enter the desired separator between tracker info and your original status line (e.g., ' ' for space, '\\n' for newline) [newline]: " STATUSLINE_SEPARATOR_INPUT
    if [ -n "$STATUSLINE_SEPARATOR_INPUT" ]; then
        STATUSLINE_SEPARATOR="$STATUSLINE_SEPARATOR_INPUT"
    fi

    # Save original command and separator
    echo "ORIGINAL_STATUSLINE_COMMAND=\"$ORIGINAL_STATUSLINE_COMMAND\"" > "$CLAUDE_CODE_STATUSLINE_CONFIG"
    echo "STATUSLINE_SEPARATOR=\"$STATUSLINE_SEPARATOR\"" >> "$CLAUDE_CODE_STATUSLINE_CONFIG"
    echo "✓ Created status line config: $CLAUDE_CODE_STATUSLINE_CONFIG"
else
    echo "✓ Existing status line config found at $CLAUDE_CODE_STATUSLINE_CONFIG"
    # Load existing separator if config file already exists
    source "$CLAUDE_CODE_STATUSLINE_CONFIG"
fi

# Update settings.json with the new wrapper command
NEW_COMMAND="$CLAUDE_SCRIPTS_DIR/claude_code_wrapper.sh"
jq --arg cmd "$NEW_COMMAND" '.statusLine = {type: "command", command: $cmd}' "$CLAUDE_CODE_SETTINGS" > "$CLAUDE_CODE_SETTINGS.tmp" && mv "$CLAUDE_CODE_SETTINGS.tmp" "$CLAUDE_CODE_SETTINGS"
echo "✓ Updated $CLAUDE_CODE_SETTINGS to use '$NEW_COMMAND'"

echo "✓ Status line script configured for Claude Code"

CLAUDE_CODE_JIRA_REGEX_CONFIG="$TRACKER_CONFIG_DIR/claude_code_jira_regex_config"

# Configure Jira settings (Base URL)
if [ ! -f "$CLAUDE_CODE_JIRA_CONFIG" ]; then
    echo ""
    echo "⚙️  Configuring Jira Integration..."
    echo "   (You can change these values later by editing $CLAUDE_CODE_JIRA_CONFIG)"
    
    default_jira_base_url="https://jira.yourcompany.com/browse"
    read -p "Enter your Jira base URL (e.g., https://jira.mycompany.com/browse) [${default_jira_base_url}]: " JIRA_BASE_URL_INPUT
    JIRA_BASE_URL=${JIRA_BASE_URL_INPUT:-$default_jira_base_url}
    
    echo "JIRA_BASE_URL=$JIRA_BASE_URL" > "$CLAUDE_CODE_JIRA_CONFIG"
    echo "✓ Created config: $CLAUDE_CODE_JIRA_CONFIG"
else
    echo "✓ Existing Jira config found at $CLAUDE_CODE_JIRA_CONFIG"
fi

# Configure Jira Ticket Regex
if [ ! -f "$CLAUDE_CODE_JIRA_REGEX_CONFIG" ]; then
    echo ""
    echo "⚙️  Configuring Jira Ticket Regex..."
    echo "   (You can change this later by editing $CLAUDE_CODE_JIRA_REGEX_CONFIG)"

    JIRA_REGEX_CHARS="" # To build the character class, e.g., A-Z0-9
    JIRA_REGEX_PART1=""
    JIRA_REGEX_SEPARATOR=""
    JIRA_REGEX_NUMBER=""

    echo "  -- Jira ticket prefix character types --"
    read -p "Include uppercase letters (A-Z) in prefix? (Y/n): " INCLUDE_UPPERCASE
    [[ "$INCLUDE_UPPERCASE" =~ ^[Yy]$ || -z "$INCLUDE_UPPERCASE" ]] && JIRA_REGEX_CHARS+="A-Z"

    read -p "Include lowercase letters (a-z) in prefix? (y/N): " INCLUDE_LOWERCASE
    [[ "$INCLUDE_LOWERCASE" =~ ^[Yy]$ ]] && JIRA_REGEX_CHARS+="a-z"

    read -p "Include numbers (0-9) in prefix? (y/N): " INCLUDE_NUMBERS
    [[ "$INCLUDE_NUMBERS" =~ ^[Yy]$ ]] && JIRA_REGEX_CHARS+="0-9"

    read -p "Include other characters (e.g., _, ., etc.) in prefix? (y/N): " INCLUDE_OTHER_CHARS
    if [[ "$INCLUDE_OTHER_CHARS" =~ ^[Yy]$ ]]; then
        read -p "Please enter the specific other characters to include (e.g., '_.-'): " OTHER_CHARS
        JIRA_REGEX_CHARS+=$(printf '%s' "$OTHER_CHARS" | sed 's/[][\/.^$*+?(){}|-]/\\&/g')
    fi
    
    if [ -n "$JIRA_REGEX_CHARS" ]; then
        JIRA_REGEX_PART1="[${JIRA_REGEX_CHARS}]"
    else
        echo "⚠️ No character types selected for prefix. Defaulting to uppercase letters (A-Z)."
        JIRA_REGEX_PART1="[A-Z]"
    fi

    read -p "Jira ticket prefix character quantity (e.g., '1', '1-3', '3') [1+]: " CHAR_QUANTITY_INPUT
    CHAR_QUANTITY=${CHAR_QUANTITY_INPUT:-"1+"}
    case "$CHAR_QUANTITY" in
        "1") JIRA_REGEX_PART1="${JIRA_REGEX_PART1}{1}" ;;
        "1+") JIRA_REGEX_PART1="${JIRA_REGEX_PART1}+" ;;
        "0+") JIRA_REGEX_PART1="${JIRA_REGEX_PART1}*" ;;
        *) JIRA_REGEX_PART1="${JIRA_REGEX_PART1}{${CHAR_QUANTITY}}" ;;
    esac

    # Separator
    read -p "Jira ticket separator (e.g., '-', '_') [-]: " SEPARATOR_INPUT
    JIRA_REGEX_SEPARATOR=${SEPARATOR_INPUT:-"-"}
    # Escape special regex characters in separator
    JIRA_REGEX_SEPARATOR=$(printf '%s' "$JIRA_REGEX_SEPARATOR" | sed 's/[][\/.^$*+?(){}|]/\\&/g')

    # Part 2: Number quantity
    read -p "Jira ticket number quantity (e.g., '1', '1-3', '3') [1+]: " NUMBER_QUANTITY_INPUT
    NUMBER_QUANTITY=${NUMBER_QUANTITY_INPUT:-"1+"}
    case "$NUMBER_QUANTITY" in
        "1") JIRA_REGEX_NUMBER="[0-9]{1}" ;;
        "1+") JIRA_REGEX_NUMBER="[0-9]+" ;;
        "1-") JIRA_REGEX_NUMBER="[0-9]+" ;; # Interpret 1- as 1 or more
        "0+") JIRA_REGEX_NUMBER="[0-9]*" ;;
        *) JIRA_REGEX_NUMBER="[0-9]{${NUMBER_QUANTITY}}" ;;
    esac
    
    # Construct final regex
    FINAL_JIRA_REGEX="${JIRA_REGEX_PART1}${JIRA_REGEX_SEPARATOR}${JIRA_REGEX_NUMBER}"
    
    echo "JIRA_TICKET_REGEX=\"$FINAL_JIRA_REGEX\"" > "$CLAUDE_CODE_JIRA_REGEX_CONFIG"
    echo "✓ Created Jira ticket regex config: $CLAUDE_CODE_JIRA_REGEX_CONFIG"
    echo "  Configured regex: $FINAL_JIRA_REGEX"
else
    echo "✓ Existing Jira ticket regex config found at $CLAUDE_CODE_JIRA_REGEX_CONFIG"
fi

# Setup global git hooks
echo "🔧 Setting up git hooks..."
mkdir -p ~/.git-templates/hooks
cp src/git-hooks/prepare-commit-msg ~/.git-templates/hooks/
chmod +x ~/.git-templates/hooks/prepare-commit-msg
cp src/git-hooks/post-checkout ~/.git-templates/hooks/
chmod +x ~/.git-templates/hooks/post-checkout
git config --global init.templateDir ~/.git-templates
echo "✓ Git hooks configured globally"

# Detect shell
SHELL_CONFIG=""
SHELL_NAME=""
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
    SHELL_NAME="zsh"
elif [ -n "$BASH_VERSION" ]; then
    if [[ "$PLATFORM" == "windows" ]]; then
        # Git Bash on Windows uses .bash_profile
        if [ -f "$HOME/.bash_profile" ]; then
            SHELL_CONFIG="$HOME/.bash_profile"
        elif [ -f "$HOME/.bashrc" ]; then
            SHELL_CONFIG="$HOME/.bashrc"
        else
            # Create .bash_profile for Git Bash
            SHELL_CONFIG="$HOME/.bash_profile"
            touch "$SHELL_CONFIG"
        fi
    else
        if [ -f "$HOME/.bashrc" ]; then
            SHELL_CONFIG="$HOME/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            SHELL_CONFIG="$HOME/.bash_profile"
        fi
    fi
    SHELL_NAME="bash"
fi

if [ -z "$SHELL_CONFIG" ]; then
    echo "⚠️  Could not detect shell config file"
    echo "   Please manually add to your shell config:"
    echo "   source $INSTALL_DIR/functions.sh"
    exit 1
fi

# Add to shell config if not already present
if ! grep -q "claude_code_tracker" "$SHELL_CONFIG"; then
    echo "" >> "$SHELL_CONFIG"
    echo "# Claude Code Tracker" >> "$SHELL_CONFIG"
    echo "source $INSTALL_DIR/functions.sh" >> "$SHELL_CONFIG"
    echo "✓ Added to $SHELL_CONFIG"
else
    echo "✓ Already configured in $SHELL_CONFIG"
fi

echo ""
echo "✅ Installation complete!"
echo ""

# Platform-specific instructions
if [[ "$PLATFORM" == "windows" ]]; then
    echo "Windows-specific notes:"
    echo "  • Using Git Bash: Restart Git Bash or run: source $SHELL_CONFIG"
    echo ""
fi

echo "Next steps:"
echo "  1. Restart Claude Code or reload window"
echo "  2. Create a branch with ticket: git checkout -b feature/ABC-123-description"
echo "  3. Claude Code status line will show tracking info"
echo "  4. To initialize git hooks for the current repository, run: tracker init"
echo ""
echo "Apply hooks to existing repositories (advanced options):"
if [[ "$PLATFORM" == "windows" ]]; then
    echo "  cd your-repo"
    echo "  rm -rf .git/hooks"
    echo "  cp -r ~/.git-templates/hooks .git/"
else
    echo "  cd your-repo && rm -rf .git/hooks && cp -r ~/.git-templates/hooks .git/"
fi
echo ""
echo "Or apply to all repos in a directory:"
echo "  find ~/projects -name .git -type d -exec bash -c 'rm -rf {}/hooks && cp -r ~/.git-templates/hooks {}/' \\;"
echo ""
