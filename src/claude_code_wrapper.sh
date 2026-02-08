#!/bin/bash

# Define INSTALL_DIR relative to the script's location
INSTALL_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"

# Source the main functions.sh from the tracker
source "$INSTALL_DIR/functions.sh"

# Load status line configuration
TRACKER_CONFIG_DIR="$INSTALL_DIR/config"
CLAUDE_CODE_STATUSLINE_CONFIG="$TRACKER_CONFIG_DIR/claude_code_statusline_config"

ORIGINAL_STATUSLINE_COMMAND=""
STATUSLINE_SEPARATOR=" "

if [ -f "$CLAUDE_CODE_STATUSLINE_CONFIG" ]; then
    source "$CLAUDE_CODE_STATUSLINE_CONFIG"
fi

# Get tracker status output
TRACKER_OUTPUT=$(tracker status)

# Initialize combined output with tracker output
COMBINED_OUTPUT="$TRACKER_OUTPUT"

# If an original status line command was set, execute it and combine outputs
if [ -n "$ORIGINAL_STATUSLINE_COMMAND" ]; then
    # Use eval to execute the command, handling potential quotes/spaces within the command string
    ORIGINAL_OUTPUT=$(eval "$ORIGINAL_STATUSLINE_COMMAND")
    
    # Combine outputs with the specified separator
    # Handle newline separator specifically for display
    if [ "$STATUSLINE_SEPARATOR" == "
" ]; then
        COMBINED_OUTPUT="${COMBINED_OUTPUT}
${ORIGINAL_OUTPUT}"
    else
        COMBINED_OUTPUT="${COMBINED_OUTPUT}${STATUSLINE_SEPARATOR}${ORIGINAL_OUTPUT}"
    fi
fi

# Print the final combined output
echo -e "$COMBINED_OUTPUT"
