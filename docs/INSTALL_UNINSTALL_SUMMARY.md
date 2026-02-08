# Claude Code Tracker Installation and Uninstallation Summary

This document provides a detailed overview of the steps performed by the `install.sh` and `uninstall.sh` scripts.

## Installation Process (`install.sh`)

The `install.sh` script sets up the Claude Code Tracker on your system. It performs the following actions:

1.  **Platform Detection:** Identifies your operating system (macOS, Linux, WSL, or Windows/Git Bash) to tailor subsequent steps.
2.  **Directory Setup:** Creates the necessary directory structure for the tracker:
    *   `~/.claude_code_tracker/`: The main installation directory where all core scripts reside.
    *   `~/.claude_code_tracker/config/`: A dedicated directory for configuration files.
    *   `~/.claude_code_tracker/data/work/`: A dedicated directory for work session data files.
3.  **File Copying:** Copies the core tracker scripts from the `src/` directory of the project into the `~/.claude_code_tracker/` installation directory. This includes `functions.sh`, `statusline.sh`, and `git-hooks/prepare-commit-msg`.
4.  **Claude Code Script Integration:**
    *   Creates the `~/.claude/scripts/` directory (if it doesn't exist).
    *   Copies `statusline.sh` (for macOS/Linux) into `~/.claude/scripts/`.
5.  **Configuration Prompt:** If the `~/.claude_code_tracker/config/claude_code_config` file does not exist, the script interactively prompts you for your desired Jira ticket prefix (e.g., `EDE`) and your Jira base URL (e.g., `https://jira.yourcompany.com/browse`). These values are then saved as key-value pairs in the `claude_code_config` file. If the file already exists, your custom settings are preserved.
6.  **Git Hook Setup:** Configures global Git hooks by:
    *   Copying the `prepare-commit-msg` script from `git-hooks/` to `~/.git-templates/hooks/`.
    *   Making the hook executable.
    *   Configuring Git to use `~/.git-templates` as its global template directory, ensuring the `prepare-commit-msg` hook is applied to new repositories.
7.  **Shell Integration:** Adds a `source` command for `~/.claude_code_tracker/functions.sh` to your shell's configuration file (`.zshrc`, `.bashrc`, or `.bash_profile`). This ensures that the tracker's functions and auto-detection mechanisms are loaded automatically when you start a new terminal session.
8.  **Instructions for Claude Code `settings.json`:** The script *prints* the exact JSON snippet you need to *manually* add or update within your Claude Code `settings.json` file. This is crucial for enabling the real-time status line integration and is the only step requiring manual intervention after running the installer.

## Uninstallation Process (`uninstall.sh`)

The `uninstall.sh` script systematically removes the Claude Code Tracker from your system. It performs the following actions:

1.  **Shell Configuration Removal:** Locates your shell's configuration file (e.g., `.zshrc`, `.bashrc`) and removes the `source` command and associated comments that were added by the installer.
2.  **Work History Management:** Prompts you to confirm whether you want to delete your work history data, which is stored in `~/.claude_code_tracker/data/work/`.
3.  **Installation Directory Removal:** Deletes the main `~/.claude_code_tracker/` installation directory and all its contents (including `config/` and `data/work/`).
4.  **Claude Code Scripts Directory Removal:** Prompts you to confirm whether you want to remove the `~/.claude/scripts/` directory.
5.  **Configuration File Removal:** Prompts you to confirm whether you want to delete the `~/.claude_code_tracker/config/claude_code_config` file.
6.  **Global Git Hooks Removal:** Prompts you to confirm whether you want to unset the global Git template directory configuration and remove the `prepare-commit-msg` hook from `~/.git-templates/hooks/`.
7.  **`settings.json` Cleanup Instructions:** Provides an important reminder that you must *manually* remove the Claude Code Tracker entry from your Claude Code `settings.json` file, as the script cannot modify this file programmatically.
8.  **Restart Terminal Instruction:** Advises you to restart your terminal for all changes to take effect.
