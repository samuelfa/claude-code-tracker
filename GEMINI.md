# Gemini Code Assistant Context

This file provides context for the Gemini Code Assistant to understand the "Claude Code Tracker" project.

## Project Overview

**Claude Code Tracker** is a set of shell and PowerShell scripts designed to provide automatic work tracking for developers using an application called "Claude Code". It integrates with Claude Code's status line to display real-time information about development sessions, including time spent and AI token usage.

The project's core functionality includes:

*   **Automatic Time Tracking:** Detects when a developer starts and stops working on a task based on directory changes and shell activity.
*   **Jira Integration:** Automatically detects Jira ticket numbers from Git branch names (e.g., `feature/ABC-123-new-feature`).
*   **Token Usage Monitoring:** Tracks Claude Code API token usage on a per-ticket basis.
*   **Git Automation:** A `prepare-commit-msg` Git hook automatically adds the Jira ticket reference to commit messages.
*   **Cross-Platform Support:** Works on macOS, Linux, and Windows (via Git Bash or WSL). The Claude Code integration on Windows uses a Bash wrapper script.

## Architecture

The project consists of the following key components:

*   **`src/functions.sh`**: The core logic of the tracker, written in Bash. It handles session management, ticket detection, time/token calculations, and provides functions for displaying status and summaries. This script is sourced into the user's shell environment (`.bashrc`, `.zshrc`).
*   **`src/statusline.sh`**: A simple Bash script for macOS and Linux that sources `functions.sh` and calls the `work_status` function. The output of this script is displayed in Claude Code's status line.
*   **`src/claude_code_wrapper.sh`**: This script is used by Claude Code as its status line command. It sources `functions.sh`, retrieves the tracker's status, and combines it with any existing status line command configured by the user.
*   **`src/git-hooks/prepare-commit-msg`**: A Git hook that automatically appends the current Jira ticket to commit messages.
*   **`install.sh` and `uninstall.sh`**: Scripts for installing and uninstalling the tracker. The installer copies files to the appropriate locations, sets up Git hooks, and modifies the user's shell configuration and Claude Code's `settings.json`. The uninstaller reverses these actions.
*   **`~/.claude_code_tracker/data/work/`**: The directory where work session data is stored in JSON files, one for each ticket.
*   **`~/.claude_code_tracker/config/`**: This directory stores configuration files:
    *   `claude_code_jira_config`: Stores the Jira base URL.
    *   `claude_code_jira_regex_config`: Stores the regular expression used to detect Jira ticket numbers.
    *   `claude_code_statusline_config`: Stores information about the original Claude Code status line command and the separator used.

### Folder Change and Git Repository Detection

The tracker uses shell hooks to automatically detect when a user changes directories and if the new directory is part of a Git repository. It now also detects changes in the Git branch even when remaining in the same directory:

1.  **Shell Integration:** The core logic in `src/functions.sh` is sourced into the user's shell profile (`.bashrc` for Bash, `.zshrc` for Zsh).
2.  **`PROMPT_COMMAND` / `precmd`:** The `auto_work_detect` function is registered with the `PROMPT_COMMAND` (Bash) or `precmd` (Zsh) shell hooks. These hooks ensure `auto_work_detect` is executed just before the shell displays a new prompt.
3.  **Git Repository Check (On Every Prompt):** On every prompt, `auto_work_detect` first checks if the current directory is part of a Git repository using `git rev-parse --git-dir` and retrieves the current branch name.
4.  **Directory Change Detection:** The current working directory (`$PWD`) is compared against the `LAST_WORK_DIR` variable. If they differ, a directory change is detected, triggering a re-evaluation of the Git state.
5.  **Branch Change Detection (Without Directory Change):** The current Git branch is compared with the `LAST_KNOWN_BRANCH` variable (which stores the branch from the previous prompt). If the directory has not changed but the branch has, a branch change is detected.
6.  **Automated Actions:** If either a directory change (into/within a Git repo) or a branch change is detected:
    *   Any active work session associated with the *previous* branch's ticket (if `LAST_KNOWN_BRANCH` had a ticket) is automatically ended.
    *   The Jira ticket is extracted from the *current* Git branch name.
    *   A new work session is started or resumed for the newly detected ticket (if one is present in the branch name).
    *   The `LAST_WORK_DIR` and `LAST_KNOWN_BRANCH` variables are updated for the next prompt cycle.
    This ensures that work tracking is responsive to both directory changes and Git branch changes.

## Building and Running

This is a script-based project, so there is no compilation step. The project is "run" by being sourced into the user's shell and by being called from Claude Code.

**Installation:**
The project is installed by running the `install.sh` script:
```bash
./install.sh
```

**Execution:**
*   The core logic in `functions.sh` is automatically executed in the user's shell through the `PROMPT_COMMAND` (for Bash) or `precmd` (for Zsh) hooks. This allows the tracker to automatically detect when the user changes directories into a new project.
*   The status line is updated by Claude Code, which executes the `claude_code_wrapper.sh` script at regular intervals. This wrapper script then calls `work_status` from `functions.sh` to get the tracker's status.

**Commands:**
The `functions.sh` script also provides a number of user-facing commands that can be run from the terminal:
*   `work_start`: Manually starts a work session.
*   `work_end`: Ends the current session and shows a summary.
*   `work_summary`: Displays a summary for the current ticket.
*   `work_list`: Lists all tracked tickets.
*   `work_view [TICKET]`: Shows the raw data for a ticket.
*   `jira_open [TICKET]`: Opens a ticket in the browser.
*   `set_jira_ticket_regex [REGEX]`: Sets the regular expression used to detect Jira ticket numbers (e.g., `set_jira_ticket_regex '[A-Z]+-[0-9]+'`).
*   `work_status`: Tests the status line output for debugging purposes.

## Development Conventions

*   **Branching:** The project relies on a specific branch naming convention to automatically extract Jira ticket numbers. The convention is `.../<PREFIX>-<NUMBER>-...`, where `<PREFIX>` is a 3-letter code (e.g., `EDE`) and `<NUMBER>` is a number (e.g., `123`).
*   **Commit Messages:** The `prepare-commit-msg` hook encourages a convention of including `WIP: <TICKET>` or `Close: <TICKET>` in commit messages.
*   **Cross-Platform Compatibility:** The code is written to be compatible with macOS, Linux, and Windows. This is achieved by using POSIX-compliant shell scripts and providing a separate PowerShell script for the Windows status line. The `functions.sh` script includes platform detection and uses platform-specific commands where necessary (e.g., for date formatting).
*   **License:** The project is licensed under the GNU General Public License v3.0.
