# Troubleshooting Guide

## Common Issues

### Installation Issues

#### "Command not found: work_start"

**Problem:** After installation, commands like `work_start` are not recognized.

**Solution:**
```bash
# Reload your shell configuration
source ~/.bashrc       # for bash
source ~/.zshrc        # for zsh  
source ~/.bash_profile # for Git Bash on Windows (or where you sourced functions.sh)

# Or restart your terminal
```

**Verification:**
```bash
type work_start
# Should output: work_start is a function
```

#### "Permission denied" during installation

**Problem:** `install.sh` script is not executable.

**Solution:**
```bash
chmod +x install.sh
./install.sh
```

#### Git hooks not working or missing ticket references in commits

**Problem:** Commit messages don't get ticket references automatically, or the hook isn't installed.

**Solution:**

1.  **Ensure global git template is configured (done by installer):**
    ```bash
    git config --global init.templateDir
    # Should output: ~/.git-templates
    ```
    If not set, re-run `install.sh` or set it manually:
    ```bash
    git config --global init.templateDir ~/.git-templates
    ```

2.  **For *new* repositories created after installation**, the hook should be automatically applied.

3.  **For *existing* repositories**, you need to initialize the hooks:
    ```bash
    cd your-existing-repo
    tracker init
    ```
    Alternatively, you can manually copy the hooks (this will overwrite any custom hooks):
    ```bash
    cd your-existing-repo
    rm -rf .git/hooks
    cp -r ~/.git-templates/hooks .git/
    ```

4.  **Verify the hook exists and is executable in your repository:**
    ```bash
    ls -la .git/hooks/prepare-commit-msg
    # Should exist and have execute permissions (e.g., -rwxr-xr-x)
    ```

### "bash: [: : integer expression expected"

**Problem:** You encounter an error like `bash: [: : integer expression expected` when using tracker commands or in the status line.

**Cause:** This typically happens when a shell arithmetic comparison (e.g., using `[ ... -gt 0 ]` or `[ ... -ge 0 ]`) is performed with a variable that is empty or contains a non-numeric value. This was a bug in earlier versions of the tracker.

**Solution:** This issue has been resolved in recent versions of the Claude Code Tracker by using more robust arithmetic evaluation (`(( ))`) that safely handles empty or non-numeric values. Ensure you have the latest version of the tracker installed by re-running `install.sh`. If the issue persists after updating, please report it.

### Status Line Issues

#### Claude Code status line not showing tracker info

**Problem:** Claude Code's status line is not displaying the tracker information (ticket, time, tokens).

**Possible causes and solutions:**

1.  **Tracker not active in current Git repository/branch:**
    *   Ensure you are inside a Git repository (`git status`).
    *   Ensure your current branch name contains a detected Jira ticket number. You can verify this manually:
        ```bash
        work_status
        # If it says "No Jira Ticket" or "💤 (no activity)", it's not active.
        ```
    *   If no ticket is found, check your branch name against the configured regex.

2.  **Claude Code `settings.json` not configured correctly:**
    *   The `install.sh` script automatically configures `settings.json`. Verify the `statusLine.command` entry:
        ```bash
        # macOS/Linux
        cat ~/.claude/settings.json
        
        # Windows
        type C:\Users\YourUsername\.claude\settings.json
        ```
        It should point to `~/.claude/scripts/claude_code_wrapper.sh`.
    *   Manually test the wrapper script:
        ```bash
        ~/.claude/scripts/claude_code_wrapper.sh
        ```
        This should output the status line information. If not, there's an issue with the script or its dependencies (`functions.sh`, `jq`).

3.  **Claude Code needs a restart:** After installation or configuration changes, restart Claude Code.

#### Claude Code status line shows "No Jira Ticket" but a valid ticket is in the branch name

**Problem:** The status line displays "No Jira Ticket", but your current branch name *seems* to contain a valid Jira ticket (e.g., `feature/EDE-123`).

**Solution:**
The ticket detection relies on a configurable regular expression. The most common cause for this is a mismatch between your branch name's format and the configured regex.

1.  **Check your current branch name:**
    ```bash
    git branch --show-current
    ```

2.  **Check the *configured* Jira ticket regex:**
    The tracker uses a regex defined in a configuration file. The default regex is `[A-Z]+-[0-9]+`, but it can be customized during installation or via the `set_jira_ticket_regex` command.
    ```bash
    # This will output the regex currently in use
    source ~/.claude_code_tracker/functions.sh && get_jira_ticket_regex
    ```
    Carefully compare your branch name against the outputted regex. Pay attention to:
    *   **Case sensitivity:** `[A-Z]` won't match `a-z`.
    *   **Number of characters:** `[A-Z]{3}` requires exactly three uppercase letters, while `[A-Z]+` requires one or more.
    *   **Separator character:** `-` vs `_`.
    *   **Quoting:** Ensure your regex doesn't include unintended quotes. The tracker automatically strips quotes, but it's good to be aware.

3.  **Update the regex if needed:** If your branch naming convention differs from the configured regex, you can update it. For example:
    ```bash
    # For patterns like ABC-123 (three uppercase letters, hyphen, then numbers)
    set_jira_ticket_regex '[A-Z]{3}-[0-9]+'

    # For patterns like FOO_12 (any uppercase letters, underscore, then numbers)
    set_jira_ticket_regex '[A-Z]+_[0-9]+'
    ```
    You can also edit `~/.claude_code_tracker/config/claude_code_jira_regex_config` directly.

4.  **Reload your shell or restart Claude Code:** Ensure the changes are picked up.

#### Claude Code status line is broken or shows "No such file or directory" for functions.sh

**Problem:** The Claude Code status line is completely empty, showing errors like `C:/Users/YourUsername/.claude/functions.sh: No such file or directory`, or generally not working, even after `install.sh` has been run.

**Cause:** The `claude_code_wrapper.sh` script, which powers the status line, was trying to source `functions.sh` from an incorrect location (e.g., `~/.claude/functions.sh` instead of `~/.claude_code_tracker/functions.sh`). This was due to an incorrect `INSTALL_DIR` calculation within the wrapper script itself. This issue has been fixed in recent versions of the tracker's `install.sh`.

**Solution:** This problem is resolved by re-running the `install.sh` script. The installer now correctly injects the absolute path to the tracker's `INSTALL_DIR` into the `claude_code_wrapper.sh` script, ensuring `functions.sh` is sourced from the right place.

1.  **Re-run `install.sh`:**
    ```bash
    ./install.sh
    ```
2.  **Restart Claude Code:** After re-running, restart Claude Code to pick up the updated wrapper script.




#### Duplicated status line entry in Claude Code

**Problem:** Claude Code's status line shows the tracker information multiple times.

**Solution:**
This usually indicates an issue with `settings.json` or a previous manual configuration.

1.  **Check `settings.json`:**
    ```bash
    # macOS/Linux
    cat ~/.claude/settings.json
    
    # Windows
    type C:\Users\YourUsername\.claude/settings.json
    ```
    Ensure there is only one `statusLine` entry, and that its `command` correctly points to `~/.claude/scripts/claude_code_wrapper.sh`. If you have duplicate `statusLine` entries, remove the incorrect ones. The installer is designed to update this cleanly, but manual edits can cause issues.

2.  **Contact Support:** If the issue persists, report it to the developers.

### Session Tracking Issues

#### Session doesn't auto-start when changing directories

**Problem:** Entering a new Git repository directory (with a ticket in the branch name) doesn't start or resume tracking.

**Solution:**

1.  **Check if auto-detection is configured in your shell:**
    ```bash
    echo $PROMPT_COMMAND | grep auto_work_detect
    # (for Bash) Should show 'auto_work_detect' in the output.
    # (for Zsh) Check ~/.zshrc for `precmd()` function calling `auto_work_detect`.
    ```
    If it's not configured, ensure `source ~/.claude_code_tracker/functions.sh` is in your shell's startup file (`.bashrc`, `.zshrc`, etc.) and reload your shell.

2.  **Manually start a session:**
    ```bash
    work_start
    ```

3.  **Reload shell config:**
    ```bash
    source ~/.bashrc # or appropriate config file
    ```

#### "✅ Session ended for" missing ticket name

**Problem:** When a work session ends, the message `✅ Session ended for` appears without the actual ticket name.

**Cause:** This was a bug in earlier versions of the tracker where the `work_end` function was using an incorrect variable to print the ticket name in the session end message.

**Solution:** This issue has been resolved in recent versions of the Claude Code Tracker. Ensure you have the latest version installed by re-running `install.sh`. If the issue persists after updating, please report it.

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

#### Windows (Git Bash / WSL)

**Problem:** Performance is slower than native Linux/macOS.

**Cause:** Overhead of Git Bash (MSYS2) or WSL emulation.

**Solution:** This is expected behavior. For optimal performance, native Linux or macOS environments are preferred. WSL generally offers better performance than Git Bash.

**Problem:** Links in terminal not clickable.

**Solution:** Use Windows Terminal, which supports clickable links. Alternatively, use the `jira_open` command to manually open the link in your default browser.

#### macOS

**Problem:** `sed: invalid command code` errors.

**Cause:** macOS's BSD `sed` has different syntax than GNU `sed` (often used on Linux).

**Solution:** The tracker's scripts are designed with cross-platform `sed` compatibility in mind. If you encounter this, ensure your `PATH` prioritizes GNU `sed` if you have it installed (e.g., via `brew install gnu-sed`).

#### WSL (Windows Subsystem for Linux)

**Problem:** `jira_open` doesn't open the browser on the Windows host.

**Solution:**
Ensure you have `wslu` installed, which provides the `wslview` command for opening Windows applications from WSL:
```bash
sudo apt update && sudo apt install wslu
```
The `jira_open` function is designed to use `wslview` if available, or fall back to other methods to open the browser on the Windows host.

### Data and File Issues

#### Can't find session data

**Problem:** `work_list` shows no data but you've been tracking.

**Solution:**

1.  **Check work directory:**
    ```bash
    ls -la ~/.claude_code_tracker/data/work/
    ```

2.  **Check permissions:**
    ```bash
    ls -ld ~/.claude_code_tracker/data/work/
    # Should be writable
    ```

3.  **Verify ticket file:**
    ```bash
    # For current ticket
    ticket=$(git branch --show-current | grep -oE "$(source ~/.claude_code_tracker/functions.sh && get_jira_ticket_regex)")
    cat ~/.claude_code_tracker/data/work/${ticket}.json
    ```

#### Corrupted session file

**Problem:** `work_summary` shows errors.

**Solution:**

1.  **View the file:**
    ```bash
    ticket=$(git branch --show-current | grep -oE "$(source ~/.claude_code_tracker/functions.sh && get_jira_ticket_regex)")
    cat ~/.claude_code_tracker/data/work/${ticket}.json
    ```

2.  **Fix manually or delete:**
    ```bash
    # Backup first
    cp ~/.claude_code_tracker/data/work/${ticket}.json ~/.claude_code_tracker/data/work/${ticket}.json.bak
    
    # Delete corrupted file
    rm ~/.claude_code_tracker/data/work/${ticket}.json
    
    # Start fresh
    work_start
    ```

#### Lost work history after uninstall

**Problem:** Uninstalled and lost all tracking data.

**Solution:**
Work history is in `~/.claude_code_tracker/data/work/`. If you chose to delete it during uninstall, it's gone.

**Prevention:**
```bash
# Before uninstalling, backup work history
cp -r ~/.claude_code_tracker/data/work ~/claude_work_backup
```

### Integration Issues

#### GitHub CLI integration not working

**Problem:** `gh pr create` doesn't end session.

**Solution:**

1.  **Check if gh is installed:**
    ```bash
    which gh
    gh --version
    ```

2.  **Verify function override:**
    ```bash
    type gh
    # Should show it's a function, not just the binary
    ```

3.  **Reload shell:**
    ```bash
    source ~/.bashrc # or appropriate config file
    ```

#### Jira URL is wrong

**Problem:** `jira_open` opens the wrong URL.

**Solution:**
Use the `set_jira_base_url` command to update your Jira base URL:
```bash
set_jira_base_url https://your-jira.com/browse
```
Alternatively, you can edit the configuration file `~/.claude_code_tracker/config/claude_code_jira_config` directly.

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
ls -la ~/.claude_code_tracker/data/work/
ls -la ~/.git-templates/hooks/

# Check configuration
cat ~/.claude_code_tracker/config/claude_code_jira_config
cat ~/.claude_code_tracker/config/claude_code_jira_regex_config
cat ~/.claude_code_tracker/config/claude_code_statusline_config

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
source ~/.bashrc # or appropriate config file
```

### Report an Issue

If you've tried everything and still have issues:

1.  Include in your report:
    *   Operating system and version
    *   Shell (bash/zsh) and version
    *   Output of `work_status`
    *   Error messages
    *   Steps to reproduce

2.  Check existing issues on GitHub

3.  Create a new issue with the "bug" label

## Still Having Issues?

1.  Check the [GitHub Issues](https://github.com/samuelfa/claude-code-tracker/issues)
2.  Review the [Usage Guide](USAGE.md)
3.  Open a new issue with details
