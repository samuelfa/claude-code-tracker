#!/bin/bash

# Claude Code Status Line Script
# This script outputs the current work tracking status for display in Claude Code's status line

# Source the main functions (adjust path if needed)
TRACKER_DIR="${HOME}/.claude_code_tracker"
if [ -f "$TRACKER_DIR/functions.sh" ]; then
    # Source only the necessary functions, not the PS1 setup
    source "$TRACKER_DIR/functions.sh"
fi

# Get the work status
status=$(work_status)

# Output the status (Claude Code will display this)
if [ -n "$status" ]; then
    echo "$status"
else
    # Optional: show something when not tracking
    # echo "No active tracking"
    # Or output nothing for clean status line
    echo ""
fi
