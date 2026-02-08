# Troubleshooting Guide

## Common Issues

### Installation Issues

#### "Command not found: work_start"

**Problem:** After installation, commands are not recognized.

**Solution:**
```bash
# Reload your shell configuration
source ~/.bashrc       # for bash
source ~/.zshrc        # for zsh  
source ~/.bash_profile # for Git Bash on Windows

# Or restart your terminal
```

**Verification:**
```bash
type work_start
# Should output: work_start is a function
```

#### "Permission denied" during installation

**Problem:** Install script is not executable.

**Solution:**
```bash
chmod +x install.sh
./install.sh
```

#### Git hooks not installed

**Problem:** Commit messages don't get ticket references.

**Solution:**
Check global git template is configured:
```bash
git config --global init.templateDir
# Should output: ~/.git-templates

# If not set:
git config --global init.templateDir ~/.git-templates
```

For existing repos, apply hooks manually:
```bash
cd your-repo
rm -rf .git/hooks
cp -r ~/.git-templates/hooks .git/
```

### Status Line Issues

#### Status line not showing

**Problem:** Prompt doesn't display work tracking.

**Possible causes and solutions:**

1. **Not in a git repository**
   ```bash
   git status
   # If error, you're not in a git repo
   ```

2. **No ticket in branch name**
   ```bash
   git branch --show-current
   # Check if it contains XXX-123 pattern
   ```

3. **Status line disabled**
   ```bash
   work_toggle_status
   ```

4. **PS1 was modified elsewhere**
   ```bash
   work_restore_ps1
   work_reconfigure_status
   ```

#### Status line shows "No ticket in branch name"

**Problem:** Valid branch name but ticket not detected.

**Solution:**
Ticket must match pattern: 3 uppercase letters + hyphen + numbers

Valid: `EDE-123`, `ABC-456`
Invalid: `ede-123`, `ED-123`, `EDIT-123`

Rename your branch:
```bash
git branch -m feature/EDE-123-description
```

#### Duplicated status line after re-installation

**Problem:** Status shows twice in prompt.

**Solution:**
```bash
# Restore original PS1
work_restore_ps1

# Remove duplicate entry from shell config
nano ~/.bashrc  # or ~/.zshrc

# Look for multiple lines with:
# source ~/.claude_code_tracker/functions.sh
# Keep only one

# Reload shell
source ~/.bashrc
```

### Session Tracking Issues

#### Session doesn't auto-start

**Problem:** Entering a directory doesn't start tracking.

**Solution:**

1. **Check if auto-detect is running:**
   ```bash
   echo $PROMPT_COMMAND | grep auto_work_detect
   # Should show auto_work_detect in the output
   ```

2. **Manually start:**
   ```bash
   work_start
   ```

3. **Reload shell config:**
   ```bash
   source ~/.bashrc
   ```

#### Session shows "no activity"

**Problem:** Status shows `💤 EDE-123 (no activity)`

**Cause:** No session file exists for this ticket yet.

**Solution:**
```bash
work_start
```

This creates the session file.

#### Token count not updating

**Problem:** Tokens show as 0 even after using Claude Code.

**Cause:** Token tracking is manual by default.

**Solution:**
Manually add tokens:
```bash
work_add_tokens 5000
```

Or integrate with Claude Code API (requires custom integration).

### Git Hook Issues

#### Commit messages missing ticket reference

**Problem:** Commits don't get `WIP: XXX-123` appended.

**Solution:**

1. **Check if hook is installed in the repo:**
   ```bash
   ls -la .git/hooks/prepare-commit-msg
   # Should exist and be executable
   ```

2. **Apply hook to repo:**
   ```bash
   rm -rf .git/hooks
   cp -r ~/.git-templates/hooks .git/
   ```

3. **Verify hook is executable:**
   ```bash
   chmod +x .git/hooks/prepare-commit-msg
   ```

#### Hook adds ticket even with existing reference

**Problem:** Commit gets duplicate ticket references.

**Solution:**
The hook checks for existing references. If you see duplicates:

```bash
# Edit the commit message manually
git commit --amend

# Or check your hook file
cat .git/hooks/prepare-commit-msg
# Ensure it's the correct version from the installer
```

#### Warning about no ticket shows in every commit

**Problem:** Git hook shows warning even with valid ticket.

**Cause:** Hook uses different regex than tracker.

**Solution:**
Ensure branch name has exactly 3 uppercase letters:
```bash
# Check current branch
git branch --show-current

# Valid patterns:
# feature/ABC-123-desc  ✅
# feature/ab-123-desc   ❌ (lowercase)
# feature/ABCD-123-desc ❌ (4 letters)
```

### Platform-Specific Issues

#### Windows / Git Bash

**Problem:** Slow performance

**Cause:** MSYS2 overhead is normal.

**Solution:**
- This is expected behavior
- Consider WSL for better performance
- Or accept the slight delay

**Problem:** Links not clickable

**Solution:**
Use Windows Terminal:
```bash
# Install Windows Terminal from Microsoft Store
# Set Git Bash as default profile
```

Or use command:
```bash
jira_open
```

**Problem:** Date formatting errors

**Cause:** Git Bash `date` command differences.

**Solution:**
Already handled in the code with fallbacks. If you still see errors:
```bash
# Verify date command works
date +%s
date -d "@$(date +%s)" "+%Y-%m-%d"
```

#### macOS

**Problem:** `sed: invalid command code` error

**Cause:** macOS `sed` syntax differences.

**Solution:**
Already handled in code. If issues persist:
```bash
# Install GNU sed
brew install gnu-sed

# Add to PATH in ~/.bashrc or ~/.zshrc
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
```

#### WSL

**Problem:** `jira_open` doesn't work

**Cause:** Need to call Windows browser from Linux.

**Solution:**
Install `wslview`:
```bash
sudo apt install wslu
```

Or use Windows path:
```bash
# Edit functions.sh to use:
/mnt/c/Program\ Files/Google/Chrome/Application/chrome.exe "$jira_url"
```

### Data and File Issues

#### Can't find session data

**Problem:** `work_list` shows no data but you've been tracking.

**Solution:**

1. **Check work directory:**
   ```bash
   ls -la ~/.claude_code_work/
   ```

2. **Check permissions:**
   ```bash
   ls -ld ~/.claude_code_work/
   # Should be writable
   ```

3. **Verify ticket file:**
   ```bash
   # For current ticket
   ticket=$(git branch --show-current | grep -oE '[A-Z]{3}-[0-9]+')
   cat ~/.claude_code_work/${ticket}.json
   ```

#### Corrupted session file

**Problem:** `work_summary` shows errors.

**Solution:**

1. **View the file:**
   ```bash
   cat ~/.claude_code_work/EDE-123.json
   ```

2. **Fix manually or delete:**
   ```bash
   # Backup first
   cp ~/.claude_code_work/EDE-123.json ~/.claude_code_work/EDE-123.json.bak
   
   # Delete corrupted file
   rm ~/.claude_code_work/EDE-123.json
   
   # Start fresh
   work_start
   ```

#### Lost work history after uninstall

**Problem:** Uninstalled and lost all tracking data.

**Solution:**
Work history is in `~/.claude_code_work/`. If you deleted it during uninstall, it's gone.

**Prevention:**
```bash
# Before uninstalling, backup work history
cp -r ~/.claude_code_work ~/claude_work_backup
```

### Integration Issues

#### GitHub CLI integration not working

**Problem:** `gh pr create` doesn't end session.

**Solution:**

1. **Check if gh is installed:**
   ```bash
   which gh
   gh --version
   ```

2. **Verify function override:**
   ```bash
   type gh
   # Should show it's a function, not just the binary
   ```

3. **Reload shell:**
   ```bash
   source ~/.bashrc
   ```

#### Jira URL is wrong

**Problem:** `jira_open` opens wrong URL.

**Solution:**
Edit the Jira URL in functions.sh:
```bash
nano ~/.claude_code_tracker/src/functions.sh

# Find this line:
local jira_url="https://jira.yourcompany.com/browse/$ticket"

# Change to your Jira instance:
local jira_url="https://yourcompany.atlassian.net/browse/$ticket"

# Reload:
source ~/.bashrc
```

## Getting More Help

### Debug Mode

Enable verbose output:
```bash
# Add to the top of functions.sh
set -x  # Enable debug mode

# Then run your command
work_start

# Disable debug mode
set +x
```

### Check Installation

Verify all components:
```bash
# Check files exist
ls -la ~/.claude_code_tracker/
ls -la ~/.claude_code_work/
ls -la ~/.git-templates/hooks/

# Check configuration
cat ~/.claude_code_config
cat ~/.claude_code_tracker/config/status_line_config.sh

# Check shell integration
grep claude_code_tracker ~/.bashrc  # or ~/.zshrc
echo $PROMPT_COMMAND | grep auto_work_detect
```

### Reinstall

If all else fails:
```bash
# Uninstall (keep work history)
cd claude-code-tracker
./uninstall.sh
# Choose "N" when asked to delete work history

# Reinstall
./install.sh
source ~/.bashrc
```

### Report an Issue

If you've tried everything and still have issues:

1. Include in your report:
   - Operating system and version
   - Shell (bash/zsh) and version
   - Output of `work_status`
   - Error messages
   - Steps to reproduce

2. Check existing issues on GitHub

3. Create a new issue with the "bug" label

## Performance Issues

### Slow prompt update

**Problem:** Status line updates slowly.

**Cause:** Running calculations on every prompt.

**Solution:**
This is expected behavior. Each update:
- Reads ticket file
- Calculates duration
- Formats tokens

For faster prompts:
```bash
# Disable status line
work_toggle_status

# Or use manual mode
work_reconfigure_status  # Choose option 3
```

### Large session files

**Problem:** Session file is very large.

**Cause:** Many sessions recorded.

**Solution:**
Session files grow with each session but should remain small (<100KB).

If larger:
```bash
# Check file size
ls -lh ~/.claude_code_work/EDE-123.json

# Archive old sessions
mv ~/.claude_code_work/EDE-123.json ~/.claude_code_work/EDE-123.json.archive
work_start  # Creates new file
```

## Still Having Issues?

1. Check the [GitHub Issues](https://github.com/yourusername/claude-code-tracker/issues)
2. Review the [Usage Guide](USAGE.md)
3. Read the [Installation Guide](INSTALLATION.md)
4. Open a new issue with details
