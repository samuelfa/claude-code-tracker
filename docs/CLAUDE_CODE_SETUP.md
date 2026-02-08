# Claude Code Setup Guide

## Quick Setup for Claude Code Status Line Integration

### Step 1: Install the Tracker

```bash
git clone https://github.com/samuelfa/claude-code-tracker.git
cd claude-code-tracker
./install.sh
```

The installer will:
- Copy tracking scripts to `~/.claude_code_tracker/`
- Copy status line scripts to `~/.claude/scripts/`
- Set up git hooks
- Show you the exact command for your platform

### Step 2: Configure Claude Code (Automatic)

The `install.sh` script automatically configures your Claude Code `settings.json` to integrate the tracker. It sets the `statusLine.command` to use `~/.claude/scripts/claude_code_wrapper.sh`.

This wrapper script intelligently combines the Claude Code Tracker's status output with any existing `statusLine.command` you might have had, using a separator you define during installation.

**Note:** If you run Claude Code as a different user or in an environment where the installer's paths are not accessible, you may need to manually verify the `statusLine.command` in your `settings.json` points to the correct absolute path of `claude_code_wrapper.sh`.
You can find your `settings.json` at:
- macOS/Linux: `~/.claude/settings.json`
- Windows: `C:\Users\YourUsername\.claude\settings.json`

### Step 3: Test the Setup

1. **Test the status line script:**

   **macOS/Linux/Windows (Git Bash/WSL):**
   ```bash
   ~/.claude/scripts/claude_code_wrapper.sh
   ```
   This script is a Bash script and runs correctly in Git Bash/WSL on Windows.


2. **Create a test branch:**
   ```bash
   cd /tmp
   mkdir test-repo && cd test-repo
   git init
   git checkout -b feature/EDE-123-test
   ```

3. **Run the status line script again:**
   - Should output: `EDE-123 ⏱️  0m 🪙 0`

4. **Restart or reload Claude Code**
   - The status line should now show your tracking info

### Step 4: Start Working

```bash
# Navigate to your project
cd ~/my-project

# Create a branch with a ticket number
git checkout -b feature/EDE-123-new-feature

# Claude Code status line should show:
# EDE-123 ⏱️  0m 🪙 0

# As you work, time updates automatically
# EDE-123 ⏱️  15m 🪙 0
# EDE-123 ⏱️  1h 23m 🪙 5.2k
```

## Ticket Number Format

The tracker detects tickets from branch names using a configurable regular expression. By default, it looks for patterns like:

**Default Pattern:** One or more uppercase letters + hyphen + one or more numbers

Examples (for default pattern):
- ✅ `feature/EDE-123-description`
- ✅ `bugfix/ABC-456-fix`
- ✅ `chore/2027/XYZ-789-cleanup`
- ✅ `feat/w2021/DEV-111-task`

Invalid (for default pattern):
- ❌ `feature/ede-123` (lowercase prefix)
- ❌ `feature/ED-123` (only 2 letters, if regex expects more)
- ❌ `feature/123` (no prefix)

You can customize the regex using the `set_jira_ticket_regex` command during installation or anytime afterwards.

## Per-Project Configuration

You can also configure the status line per-project by creating a `.claude/settings.json` in your project root:

```bash
cd ~/my-project
mkdir -p .claude
cat > .claude/settings.json <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "/Users/your-username/.claude/scripts/claude_code_wrapper.sh"
  }
}
EOF
```

## Troubleshooting

### Status line not showing



1.  **Check Claude Code settings location:**

    ```bash

    # macOS/Linux

    cat ~/.claude/settings.json

    

    # Windows

    type C:\Users\YourUsername\.claude\settings.json

    ```



2.  **Test wrapper script manually:**

    ```bash

    # macOS/Linux/Windows (Git Bash/WSL)

    ~/.claude/scripts/claude_code_wrapper.sh

    ```



3.  **Check if script is executable (macOS/Linux):**

    ```bash

    chmod +x ~/.claude/scripts/claude_code_wrapper.sh

    ```



4.  **Restart Claude Code** after changing settings.json

### Script errors

**Error: "git: command not found"**
- Ensure Git is installed and in your system's PATH.

**Error: "Permission denied"** (macOS/Linux)
- Make script executable:
  ```bash
  chmod +x ~/.claude/scripts/claude_code_wrapper.sh
  ```

### Status shows wrong information

**Shows old ticket after switching branches:**
- The status line updates when Claude Code polls it
- May take a few seconds to update
- Force update by running any command in terminal

**Time doesn't update:**
- Status line is polled by Claude Code
- Check Claude Code's status line update interval
- Time should update every few seconds

## Advanced Configuration

### Custom Jira URL

Use the `set_jira_base_url` command to configure your Jira instance's base URL:
```bash
set_jira_base_url https://yourcompany.atlassian.net/browse
```
Alternatively, you can edit the file `~/.claude_code_tracker/config/claude_code_jira_config` directly.

### Custom Jira Ticket Regex

Use the `set_jira_ticket_regex` command to configure the regular expression for detecting Jira ticket numbers:
```bash
set_jira_ticket_regex '[A-Z]+-[0-9]+'
```
The installer provides an interactive prompt to help you build this regex during setup. You can also edit the file `~/.claude_code_tracker/config/claude_code_jira_regex_config` directly.

## Status Line Update Frequency

Claude Code polls the status line command periodically. The exact frequency depends on Claude Code's configuration.

If you need more frequent updates, you may need to configure Claude Code's status line refresh rate (check Claude Code documentation).

## Next Steps

- Read [USAGE.md](docs/USAGE.md) for all available commands
- See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for common issues
- Configure git hooks for automatic commit messages

## Summary

1. Install: `./install.sh`
2. Configure Claude Code's `settings.json` with status line command
3. Create branch with ticket: `git checkout -b feature/ABC-123-task`
4. Watch Claude Code status line update automatically
