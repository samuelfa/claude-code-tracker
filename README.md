# Claude Code Tracker

> Automatic work tracking integrated with Claude Code's status line

Track development time, monitor AI token usage, and manage Jira tickets seamlessly while using Claude Code. Zero-config time tracking that integrates directly with Claude Code's status line.

## Features

- **Claude Code integration** - Shows tracking info in Claude Code's status line
- **Automatic time tracking** - Detects when you start/stop work based on directory changes
- **Jira integration** - Auto-detects tickets from branch names (e.g., feature/ABC-123-description)
- **Token monitoring** - Track Claude Code API usage per ticket
- **Git automation** - Auto-adds ticket references to commits (WIP: ABC-123 or Close: ABC-123)
- **Session history** - Persistent per-ticket storage
- **Cross-platform** - Works on macOS, Linux, Windows (Git Bash/WSL)

## Quick Start

```bash
git clone https://github.com/samuelfa/claude-code-tracker.git
cd claude-code-tracker
./install.sh
```

## Updating

To update the Claude Code Tracker to the latest version:

1.  Navigate to your cloned `claude-code-tracker` directory.
2.  Run `git pull` to fetch the latest changes.
3.  Re-run the installer: `./install.sh`

The installer is designed to update existing files and configurations without overwriting your custom settings (e.g., your Jira prefix and URL will be preserved).

## Configure Claude Code

The `install.sh` script automatically configures your Claude Code `settings.json` to integrate the tracker. It will set the `statusLine.command` to use `~/.claude/scripts/claude_code_wrapper.sh`.

This wrapper script intelligently combines the Claude Code Tracker's status output with any existing `statusLine.command` you might have had, using a separator you define during installation.

**Note:** If you run Claude Code as a different user or in an environment where the installer's paths are not accessible, you may need to manually adjust the `statusLine.command` in your `settings.json` to the correct absolute path of `claude_code_wrapper.sh`.

## Status Line Display

Once configured, Claude Code's status line will show:

```
EDE-123 ⏱️  2h 34m 🪙 15k
```

- `EDE-123` - Current Jira ticket
- `⏱️  2h 34m` - Time working (hides hours if less than 1 hour)
- `🪙 15k` - Tokens used (formatted: 1500→1.5k, 15000→15k)

## Usage

### Basic Workflow

```bash
# Create a branch with ticket number
git checkout -b feature/EDE-123-new-feature
# ▶️  Started new work on EDE-123

# Claude Code status line shows:
# EDE-123 ⏱️  15m 🪙 2.5k

# Commit with auto-added ticket reference
git commit -m "Add authentication"
# Results in: "Add authentication\n\nWIP: EDE-123"

# Open a PR (auto-ends session)
gh pr create
# 🎉 PR created! Ending work session...
```

### Commands

- `work_start` - Manually start a work session
- `work_end` - End current session and show summary
- `work_summary` - View summary for current ticket
- `work_list` - List all tracked tickets
- `work_view [TICKET]` - View raw ticket data
- `jira_open [TICKET]` - Open ticket in browser
- `set_ticket_prefix ABC` - Set default ticket prefix
- `work_status` - Test status line output (for debugging)

## Claude Code Settings Location

**macOS/Linux:**
```
~/.claude/settings.json
```

**Windows:**
```
C:\Users\YourUsername\.claude\settings.json
```

Or configure per-project in your project's `.claude/settings.json`

## Status Line States

```bash
# Active session
EDE-123 ⏱️  2h 34m 🪙 15k

# Just started (no hours)
EDE-123 ⏱️  15m 🪙 0.5k

# No active session
💤 EDE-123 (session ended)

# No ticket in branch
No Jira Ticket

# Not in git repo
(nothing displayed)
```

## Configuration

The tracker's configuration files are stored in `~/.claude_code_tracker/config/`:

-   `claude_code_jira_config`: Stores `JIRA_BASE_URL`.
-   `claude_code_jira_regex_config`: Stores `JIRA_TICKET_REGEX`.
-   `claude_code_statusline_config`: Stores `ORIGINAL_STATUSLINE_COMMAND` and `STATUSLINE_SEPARATOR`.

You can edit these files directly or use the provided commands:

-   `set_jira_base_url https://your-jira.com/browse` - Set your Jira instance's base URL.
-   `set_jira_ticket_regex '[A-Z]+-[0-9]+'` - Set your custom Jira ticket regex. The installer provides an interactive way to generate this.

Supported branch patterns (example for default regex `[A-Z]+-[0-9]+`):
-   `feature/EDE-123-description`
-   `chore/2027/EDE-456-cleanup`
-   `feature/w2021/ABC-789-foo`

Pattern: One or more uppercase letters, followed by a hyphen, then one or more numbers (e.g., ABC-123, XYZ-789).

## Windows Support

### Supported Environments

- ✅ Git Bash (recommended)
- ✅ Windows Terminal
- ✅ WSL (Windows Subsystem for Linux)
- ✅ MSYS2 / Cygwin

### Windows Setup

1. Install Git for Windows: https://git-scm.com/download/win
2. Open Git Bash (recommended shell on Windows for this tracker).
3. Clone and install as shown in Quick Start.


### Troubleshooting Windows

**Issue: Status line not updating in Claude Code**
- Ensure Git Bash (or WSL) is properly installed and configured.
- Test `work_status` manually in your shell: `source ~/.claude_code_tracker/functions.sh && work_status`

**Issue: Git commands not found in PowerShell**
- This tracker is primarily designed for Git Bash or WSL on Windows. If using PowerShell, ensure `bash` is in your PATH and accessible.

## Apply Hooks to Existing Repos

For a single repository, the preferred method is to use the `tracker init` command from within that repository:
```bash
cd your-repo
tracker init
```

Alternatively, you can manually copy the hooks:

**Single repo (manual):**
```bash
cd your-repo
rm -rf .git/hooks
cp -r ~/.git-templates/hooks .git/
```

**All repos in a directory:**
```bash
find ~/projects -name .git -type d -exec bash -c 'rm -rf {}/hooks && cp -r ~/.git-templates/hooks {}/' \;
```

## File Locations

- Work sessions: `~/.claude_code_tracker/data/work/TICKET-123.json`
- Configuration: `~/.claude_code_tracker/config/` (contains `claude_code_jira_config`, `claude_code_jira_regex_config`, `claude_code_statusline_config`)
- Installation: `~/.claude_code_tracker/`
- Git hooks: `~/.git-templates/hooks/`

## Detailed Installation and Uninstallation Steps

For a detailed breakdown of what the `install.sh` and `uninstall.sh` scripts do, refer to:
[docs/INSTALL_UNINSTALL_SUMMARY.md](docs/INSTALL_UNINSTALL_SUMMARY.md)

## Requirements

- Git
- Bash or Zsh
- Optional: GitHub CLI (`gh`) for PR integration

## License

This project is licensed under the GNU General Public License v3.0.

**What this means:**
- ✅ Free to use for personal projects
- ✅ Free to use at work (internal use)
- ✅ Free to modify and share improvements
- ❌ Cannot sell as a closed-source product
- ❌ Cannot integrate into proprietary software without sharing source

See [LICENSE](LICENSE) for full details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and questions, please open an issue on GitHub.
