# Usage Guide

## Basic Workflow

### 1. Start Working on a Ticket

Create a branch with a ticket number matching your configured regex (e.g., `[A-Z]+-[0-9]+`):

```bash
git checkout -b feature/EDE-123-new-authentication
# ▶️  Started new work on EDE-123
```

Supported patterns (example for default `[A-Z]+-[0-9]+`):
- `feature/EDE-123-description`
- `bugfix/ABC-456-fix`
- `chore/2027/XYZ-789-cleanup`
- `feature/w2021/DEV-111-foo`

The tracker automatically:
- Detects the ticket number
- Starts a new session
- Shows tracking in your Claude Code status line

### 2. Work on Your Code

Your Claude Code status line shows real-time tracking:

```
EDE-123 ⏱️  15m 🪙 2.5k
```

- `EDE-123` - Ticket number
- `⏱️  15m` - Time elapsed (shows hours when > 60 min)
- `🪙 2.5k` - Tokens used (formatted: 150→0.1k, 1500→1.5k, 15000→15k)

### 3. Commit Your Work

Commits automatically get ticket references:

```bash
git commit -m "Add user authentication"

# Automatically becomes:
# Add user authentication
#
# WIP: EDE-123
```

You can change `WIP:` to `Close:` if the commit closes the ticket:

```bash
git commit -m "Add user authentication

Close: EDE-123"
```

### 4. Open a Pull Request

When you create a PR with GitHub CLI, the session automatically ends:

```bash
gh pr create
# 🎉 PR created! Ending work session...
# ✅ Session ended for EDE-123
```

## Commands Reference

### Session Management

#### `work_start`
Manually start a work session for the current ticket.

```bash
work_start
# ▶️  Started new work on EDE-123
```

Auto-starts when you enter a directory with a ticket branch.

#### `work_end`
End the current work session and show summary.

```bash
work_end
# ✅ Session ended for EDE-123
#    This session: 2h 34m, 5000 tokens
# 
# 📊 Work Summary for EDE-123
#    Sessions: 2
#    Total time: 5h 47m
#    Total tokens: 15000
```

Auto-ends when you run `gh pr create`.

#### `work_add_tokens <count>`
Manually add token usage to current session.

```bash
work_add_tokens 1000
```

Useful if you're manually tracking Claude Code API usage.

### Viewing Information

#### `work_summary`
Show detailed summary for current ticket.

```bash
work_summary
# 📊 Work Summary for EDE-123
#    Created: 2026-02-07 14:30
#    Sessions: 3
#    Total time: 5h 47m
#    Total tokens: 15000
#    File: ~/.claude_code_work/EDE-123.json
#    Link: https://jira.yourcompany.com/browse/EDE-123
```

#### `work_list`
List all tracked tickets.

```bash
work_list
# 📋 Work History:
#   EDE-123: 3 sessions, 5h 47m, 15000 tokens
#   EDE-456: 1 session, 1h 20m, 3000 tokens
#   ABC-789: 2 sessions, 3h 15m, 8000 tokens
```

#### `work_view [TICKET]`
View raw JSON data for a ticket.

```bash
work_view EDE-123
# Shows raw JSON file content

work_view  # Uses current ticket
```

### Configuration

#### `set_jira_base_url <URL>`
Set your Jira instance's base URL.

```bash
set_jira_base_url https://your-jira.com/browse
# ✓ JIRA base URL set to: https://your-jira.com/browse
```

This updates the `~/.claude_code_tracker/config/claude_code_jira_config` file.

#### `set_jira_ticket_regex <REGEX>`
Set the regular expression used to detect Jira ticket numbers.

```bash
set_jira_ticket_regex '[A-Z]+-[0-9]+'
# ✓ JIRA ticket regex set to: [A-Z]+-[0-9]+
```

This updates the `~/.claude_code_tracker/config/claude_code_jira_regex_config` file.

### Jira Integration

#### `jira_open [TICKET]`
Open ticket in browser.

```bash
jira_open EDE-123
# ✓ Opened EDE-123 in browser

jira_open  # Opens current ticket
```

Configure your Jira URL using the `set_jira_base_url` command.

## Status Line States

### Active Session
```
EDE-123 ⏱️  2h 34m 🪙 15k
```
Working on ticket with active time tracking.

### No Activity
```
💤 EDE-123 (no activity)
```
Ticket found in branch but no session file exists yet.

### Session Ended
```
💤 EDE-123 (session ended)
```
Session was ended with `work_end` or PR creation.

### No Ticket
```
⚠️  No ticket in branch name
```
Branch name doesn't contain a valid ticket number.

### Not in Git Repo
```
(nothing displayed)
```
Not in a git repository.

## File Storage

### Session Data
Work sessions are stored in: `~/.claude_code_tracker/data/work/`

Each ticket has its own JSON file:
```
~/.claude_code_tracker/data/work/
├── EDE-123.json
├── EDE-456.json
└── ABC-789.json
```

### File Format
```json
{
  "ticket": "EDE-123",
  "created": 1738886400,
  "sessions": []
}
{"session_start":1738886400,"session_end":1738895600,"duration":9200,"tokens":5000,"active":false}
{"session_start":1738900000,"session_end":null,"tokens":2500,"active":true}
```

- First line: Ticket metadata
- Following lines: Session records (one per line)

### Configuration
Configuration files are stored in `~/.claude_code_tracker/config/`:
- `claude_code_jira_config`: Stores the Jira base URL.
- `claude_code_jira_regex_config`: Stores the regular expression for Jira ticket detection.
- `claude_code_statusline_config`: Stores Claude Code status line preferences.

## Git Integration

### Commit Message Format

**Automatic addition:**
```bash
git commit -m "Add feature"

# Becomes:
# Add feature
#
# WIP: EDE-123
```

**Change to closing:**
Edit in your editor before saving:
```
Add feature

Close: EDE-123
```

**Reference without closing:**
```
Add feature

Refs: EDE-123
```

### Branch Name Requirements

Valid patterns will depend on your configured `JIRA_TICKET_REGEX`. By default, this is one or more uppercase letters + hyphen + one or more numbers:
- ✅ `feature/EDE-123-description`
- ✅ `bugfix/ABC-999-fix`
- ✅ `chore/2027/XYZ-456-task`
- ✅ `feat/EDE-1-start`

Invalid patterns (for the default regex):
- ❌ `feature/ede-123` (lowercase prefix)
- ❌ `feature/ED-123` (only 2 letters, if regex expects more)
- ❌ `feature/123` (no prefix)
You can customize the regex using the `set_jira_ticket_regex` command.

## Advanced Usage

### Multiple Work Sessions

You can work on a ticket across multiple days:

```bash
# Day 1
git checkout -b feature/EDE-123-auth
# Work for 2 hours
work_end

# Day 2
cd ~/project
# Automatically resumes session
# Work for 3 hours
work_end

# Total tracked: 5 hours across 2 sessions
```

### Switching Between Tickets

```bash
# Work on ticket 1
git checkout feature/EDE-123-auth
# Status: EDE-123 ⏱️  1h 15m 🪙 5k

# Switch to ticket 2
git checkout feature/EDE-456-refactor
# ▶️  Resumed work on EDE-456 (session #2)
# Status: EDE-456 ⏱️  0m 🪙 0

# Previous session auto-paused
```

Each ticket tracks independently.

### Manual Token Tracking

If you're using Claude Code and want to manually log token usage:

```bash
# After a Claude Code session
work_add_tokens 5000
```

### Exporting Data

Session data is stored as JSON and can be processed:

```bash
# View all sessions for a ticket
cat ~/.claude_code_work/EDE-123.json

# Extract total time using jq
cat ~/.claude_code_work/EDE-123.json | grep duration | grep -oE '[0-9]+' | awk '{sum+=$1} END {print sum/3600 " hours"}'
```

## Tips and Best Practices

### 1. Branch Naming Convention
Always include the ticket number in your branch name:
```bash
git checkout -b feature/EDE-123-short-description
```

### 2. Review Before PR
Check your work summary before creating a PR:
```bash
work_summary
gh pr create
```

### 3. Regular Work Summaries
Review your progress:
```bash
work_list  # See all tickets
work_summary  # Current ticket details
```

### 4. Jira URL Configuration
Update the Jira URL to match your company using the `set_jira_base_url` command:
```bash
set_jira_base_url https://your-company.atlassian.net/browse
```

### 5. Commit Message Editing
The git hook adds "WIP:" by default. Change it in your editor if needed:
- `WIP:` - Work in progress
- `Close:` - Closes the ticket
- `Refs:` - References the ticket

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.
