# Claude Code Tracker Installation and Uninstallation Summary

This document provides a detailed overview of the steps performed by the `install.sh` and `uninstall.sh` scripts.

## Installation Process (`install.sh`)

The `install.sh` script sets up the Claude Code Tracker on your system. It performs the following actions:

1.  **Platform Detection:** Identifies your operating system (macOS, Linux, WSL, or Windows/Git Bash) to tailor subsequent steps.
2.  **Directory Setup:** Creates the necessary directory structure for the tracker:
    *   `~/.claude_code_tracker/`: The main installation directory where all core scripts reside.
    *   `~/.claude_code_tracker/config/`: A dedicated directory for configuration files.
    *   `~/.claude_code_tracker/data/work/`: A dedicated directory for work session data files.
3.  **File Copying:** Copies all scripts and files from the `src/` directory of the project into the `~/.claude_code_tracker/` installation directory. This includes `functions.sh`, `claude_code_wrapper.sh`, `statusline.sh`, and `git-hooks/prepare-commit-msg`.
4.  **Claude Code Script Integration:**
    *   Creates the `~/.claude/scripts/` directory (if it doesn't exist).
    *   Copies `claude_code_wrapper.sh` into `~/.claude/scripts/`, ensuring it is configured with the correct tracker installation path (`INSTALL_DIR`). This script acts as the main interface for Claude Code's status line.
5.  **Configuration Prompts:** If configuration files do not exist, the script interactively prompts you for:
    *   The desired separator for the Claude Code status line (e.g., `\\n` for newline, ` ` for space).
    *   Your Jira base URL (e.g., `https://jira.yourcompany.com/browse`).
    *   Your Jira ticket regex (e.g., `[A-Z]+-[0-9]+`), with an interactive builder.
    These values are saved in `~/.claude_code_tracker/config/claude_code_statusline_config`, `claude_code_jira_config`, and `claude_code_jira_regex_config` respectively. If these files already exist, your custom settings are preserved.
6.  **Claude Code `settings.json` Modification:** The script *automatically* updates your Claude Code `settings.json` file to set `statusLine.command` to `~/.claude/scripts/claude_code_wrapper.sh`. If an original `statusLine.command` existed, it is backed up and later restored by `claude_code_wrapper.sh`.
7.  **Git Hook Setup:** Configures global Git hooks by:
    *   Copying the `prepare-commit-msg` script from `git-hooks/` to `~/.git-templates/hooks/`.
    *   Making the hook executable.
    *   Configuring Git to use `~/.git-templates` as its global template directory, ensuring the `prepare-commit-msg` hook is applied to new repositories.
8.  **Shell Integration:** Adds a `source` command for `~/.claude_code_tracker/functions.sh` to your shell's configuration file (`.zshrc`, `.bashrc`, or `.bash_profile`). This ensures that the tracker's functions and auto-detection mechanisms are loaded automatically when you start a new terminal session.

## Uninstallation Process (`uninstall.sh`)

The `uninstall.sh` script systematically removes the Claude Code Tracker from your system. It performs the following actions:

1.  **Shell Configuration Removal:** Locates your shell's configuration file (e.g., `.zshrc`, `.bashrc`) and removes the `source` command and associated comments that were added by the installer.
2.  **Claude Code `settings.json` Cleanup:** Automatically cleans up your Claude Code `settings.json` file. If an original `statusLine.command` was backed up during installation, it will be restored. Otherwise, the `statusLine` entry will be removed. If `settings.json` becomes empty, it will be deleted.
3.  **Work History Management:** Prompts you to confirm whether you want to delete your work history data, which is stored in `~/.claude_code_tracker/data/work/`.
4.  **Installation Directory Removal:** Deletes the main `~/.claude_code_tracker/` installation directory and all its contents (including `config/` and `data/work/` if not already removed).
5.  **Claude Code Scripts Cleanup:** Removes the `claude_code_wrapper.sh` script from `~/.claude/scripts/`. If the `~/.claude/scripts/` directory becomes empty, it will prompt you to confirm its removal.
6.  **Configuration File Removal:** Prompts you individually to confirm whether you want to delete the specific configuration files: `claude_code_jira_config`, `claude_code_jira_regex_config`, and `claude_code_statusline_config` from `~/.claude_code_tracker/config/`.
7.  **Global Git Hooks Removal:** Prompts you to confirm whether you want to unset the global Git template directory configuration and remove the `prepare-commit-msg` hook from `~/.git-templates/hooks/`.
8.  **Restart Terminal Instruction:** Advises you to restart your terminal for all changes to take effect.
