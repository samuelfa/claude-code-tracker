# Claude Code Setup Guide

## Quick Setup for Claude Code Status Line Integration

### Step 1: Install the Tracker

```bash
git clone https://github.com/yourusername/claude-code-tracker.git
cd claude-code-tracker
./install.sh
```

The installer will:
- Copy tracking scripts to `~/.claude_code_tracker/`
- Copy status line scripts to `~/.claude/scripts/`
- Set up git hooks
- Show you the exact command for your platform

### Step 2: Configure Claude Code

#### macOS / Linux

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/Users/your-username/.claude/scripts/statusline.sh"
  }
}
```

Replace `/Users/your-username` with your actual home directory path.

#### Windows

Add to `C:\Users\YourUsername\.claude\settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -NoProfile -ExecutionPolicy Bypass -File C:\\Users\\YourUsername\\.claude\\scripts\\statusline.ps1"
  }
}
```

Replace `YourUsername` with your Windows username.

### Step 3: Test the Setup

1. **Test the status line script:**

   **macOS/Linux:**
   ```bash
   ~/.claude/scripts/statusline.sh
   ```

   **Windows:**
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\YourUsername\.claude\scripts\statusline.ps1
   ```

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

The tracker detects tickets from branch names using this pattern:

**Valid:** 3 uppercase letters + hyphen + numbers

Examples:
- ✅ `feature/EDE-123-description`
- ✅ `bugfix/ABC-456-fix`
- ✅ `chore/2027/XYZ-789-cleanup`
- ✅ `feat/w2021/DEV-111-task`

Invalid:
- ❌ `feature/ede-123` (lowercase)
- ❌ `feature/ED-123` (only 2 letters)
- ❌ `feature/EDIT-123` (4 letters)
- ❌ `feature/123` (no prefix)

## Per-Project Configuration

You can also configure the status line per-project by creating a `.claude/settings.json` in your project root:

```bash
cd ~/my-project
mkdir -p .claude
cat > .claude/settings.json <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "/Users/your-username/.claude/scripts/statusline.sh"
  }
}
EOF
```

## Troubleshooting

### Status line not showing

1. **Check Claude Code settings location:**
   ```bash
   # macOS/Linux
   cat ~/.claude/settings.json
   
   # Windows
   type C:\Users\YourUsername\.claude\settings.json
   ```

2. **Test script manually:**
   ```bash
   # macOS/Linux
   ~/.claude/scripts/statusline.sh
   
   # Windows
   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\YourUsername\.claude\scripts\statusline.ps1
   ```

3. **Check if script is executable (macOS/Linux):**
   ```bash
   chmod +x ~/.claude/scripts/statusline.sh
   ```

4. **Restart Claude Code** after changing settings.json

### Script errors

**Error: "git: command not found"** (Windows PowerShell)
- Git is not in PATH
- Add Git to PATH or use full path in statusline.ps1:
  ```powershell
  $branch = & "C:\Program Files\Git\bin\git.exe" rev-parse --abbrev-ref HEAD 2>$null
  ```

**Error: "Permission denied"** (macOS/Linux)
- Make script executable:
  ```bash
  chmod +x ~/.claude/scripts/statusline.sh
  ```

**Error: "Cannot be loaded because running scripts is disabled"** (Windows)
- PowerShell execution policy issue
- The command includes `-ExecutionPolicy Bypass` which should handle this
- If still issues, run as administrator:
  ```powershell
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
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

Edit `~/.claude_code_tracker/src/functions.sh`:

```bash
# Find this line (around line 355):
local jira_url="https://jira.yourcompany.com/browse/$ticket"

# Change to your Jira instance:
local jira_url="https://yourcompany.atlassian.net/browse/$ticket"
```

Then update the status line scripts to use the new URL.

### Change Ticket Prefix

```bash
# Set default prefix
echo "ABC" > ~/.claude_code_config

# Or use command
set_ticket_prefix ABC
```

### Disable Terminal Output

If you only want Claude Code status line (no terminal messages):

Edit `~/.claude_code_tracker/src/functions.sh` and comment out echo statements in `auto_work_detect()`.

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
