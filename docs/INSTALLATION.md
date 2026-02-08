# Installation Guide

## Prerequisites

- Git
- Bash or Zsh shell
- Optional: GitHub CLI (gh) for PR integration

## Platform-Specific Requirements

### macOS
- No additional requirements
- Works out of the box

### Linux
- No additional requirements
- Works on most distributions

### Windows
- **Git Bash** (included with Git for Windows) - Recommended
- Download: https://git-scm.com/download/win
- Or use **WSL** (Windows Subsystem for Linux)
- **Windows Terminal** recommended for best experience

## Installation Steps

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/claude-code-tracker.git
cd claude-code-tracker
```

### 2. Run the Installer

```bash
./install.sh
```

The installer will:
- Detect your platform and shell
- Copy files to `~/.claude_code_tracker/`
- Create work directory at `~/.claude_code_work/`
- Set up global git hooks
- Add source line to your shell config
- Ask you to choose status line display mode

### 3. Choose Status Line Mode

You'll be asked how to display the work tracker:

**Option 1: New line above prompt (recommended)**
```
EDE-123 ⏱️  2h 34m 🪙 15k
user@host:~/project $
```

**Option 2: Same line as prompt**
```
EDE-123 ⏱️  2h 34m 🪙 15k user@host:~/project $
```

**Option 3: Manual configuration**
- Don't modify PS1 automatically
- You'll need to add `$(work_status)` to your PS1 manually

### 4. Restart Your Terminal

```bash
# Or reload your shell config
source ~/.bashrc       # for bash
source ~/.zshrc        # for zsh
source ~/.bash_profile # for Git Bash on Windows
```

### 5. Configure Your Ticket Prefix (Optional)

The default prefix is "EDE". To change it:

```bash
set_ticket_prefix ABC
```

Or edit `~/.claude_code_config` directly:
```bash
echo "ABC" > ~/.claude_code_config
```

## Apply Git Hooks to Existing Repositories

The installer sets up global git hooks for new repositories. For existing repos:

### Single Repository

```bash
cd your-existing-repo
rm -rf .git/hooks
cp -r ~/.git-templates/hooks .git/
```

### All Repositories in a Directory

```bash
find ~/projects -name .git -type d -exec bash -c 'rm -rf {}/hooks && cp -r ~/.git-templates/hooks {}/' \;
```

### Specific Repositories

Create a script to apply to multiple specific repos:

```bash
#!/bin/bash
repos=(
    ~/projects/repo1
    ~/projects/repo2
    ~/work/project-a
)

for repo in "${repos[@]}"; do
    if [ -d "$repo/.git" ]; then
        echo "Applying hooks to: $repo"
        rm -rf "$repo/.git/hooks"
        cp -r ~/.git-templates/hooks "$repo/.git/"
    fi
done
```

## Verification

After installation, verify everything works:

```bash
# Create a test branch with ticket
cd /tmp
mkdir test-repo && cd test-repo
git init
git checkout -b feature/EDE-123-test

# You should see:
# ▶️  Started new work on EDE-123

# Check status line
# Your prompt should show: EDE-123 ⏱️  0m 🪙 0

# Check commands
work_summary
work_list
```

## Troubleshooting Installation

### "Command not found: work_start"

You need to reload your shell config:
```bash
source ~/.bashrc  # or appropriate config file
```

### Git hooks not working in existing repos

Apply hooks manually (see "Apply Git Hooks" section above)

### Status line not showing

1. Check if tracking is active:
   ```bash
   work_status
   ```

2. Check if you're in a git repo with a ticket branch

3. Try toggling:
   ```bash
   work_toggle_status
   ```

4. Reconfigure status line mode:
   ```bash
   work_reconfigure_status
   ```

### Windows-specific issues

**Git Bash not found:**
- Install Git for Windows: https://git-scm.com/download/win

**Slow performance:**
- This is normal for Git Bash
- Consider using WSL for better performance

**Links not clickable:**
- Use Windows Terminal instead of cmd.exe
- Or use `jira_open` command

## Uninstallation

To remove Claude Code Tracker:

```bash
cd claude-code-tracker
./uninstall.sh
```

The uninstaller will ask whether to:
- Delete work history
- Delete configuration
- Remove global git hooks

## Next Steps

See [USAGE.md](USAGE.md) for how to use Claude Code Tracker.
