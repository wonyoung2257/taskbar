---
name: "tbar"
description: "Manage your TODO list with tbar - a macOS menu bar TODO app with CLI. Add, complete, track tasks, and view history."
argument-hint: "command args (e.g. add, done 1, list)"
---

# tbar — Agent Task Management

tbar is a native macOS menu bar TODO app with full CLI control. When you manage tasks through this skill, changes appear instantly in the user's menu bar.

## How It Works

- **Data**: `~/.tbar/todos.json` (JSON file, human-readable)
- **Menu bar**: Shows todos with checkboxes, auto-refreshes on file change
- **CLI**: `tbar` command for all CRUD operations

## Quick Reference

### Interpreting User Intent

| User says | Run |
|-----------|-----|
| "할일 보여줘" / "what's left?" / "show tasks" | `tbar list` |
| "할일 추가해줘" / "add a task" | `tbar add "title"` |
| "이거 끝났어" / "mark done" | `tbar done <id>` |
| "뭐 했었지?" / "what did I finish?" | `tbar history` |
| "우선순위 높여줘" / "make it high priority" | `tbar priority <id> high` |
| "검색해줘" / "find tasks about X" | `tbar search "keyword"` |

### All Commands

```bash
# Add
tbar add "title"                          # Add todo (default: medium priority)
tbar add "title" --priority high          # Priority: high, medium, low
tbar add "subtask title" --parent 1       # Add subtask to todo #1

# List
tbar list                                 # Show active todos (hides yesterday's completed)
tbar list --all                           # Show everything including old completed
tbar list --priority high                 # Filter by priority

# Complete / Reopen
tbar done 1                               # Complete todo #1
tbar done 1.2                             # Complete subtask #2 of todo #1
tbar undone 1                             # Reopen todo #1

# Delete
tbar delete 1                             # Delete todo #1
tbar delete 1.3                           # Delete subtask #3 of todo #1

# Priority
tbar priority 1 high                      # Change priority (high/medium/low)

# Search
tbar search "keyword"                     # Search in titles

# History
tbar history                              # Last 7 days of completed tasks
tbar history --days 30                    # Last 30 days
tbar history --date 2026-03-31            # Specific date

# Version
tbar --version
```

### Subtask Reference Syntax

Use `parentId.subtaskId` to target subtasks:
- `tbar done 1.2` → complete subtask #2 of todo #1
- `tbar delete 3.1` → delete subtask #1 of todo #3

### Priority Icons

Configurable via menu bar Settings. Default:
- 🔴 = high
- 🟡 = medium
- 🔵 = low

## Agent Workflow Guide

### When starting work
```bash
tbar list
```
Show the user their current tasks before diving into code. This sets context.

### When planning a task
Break it down into subtasks:
```bash
tbar add "Implement auth system" --priority high
tbar add "Design DB schema" --parent 1
tbar add "Write API endpoints" --parent 1
tbar add "Add tests" --parent 1
```

### During implementation
Mark subtasks done as you complete them:
```bash
tbar done 1.1    # Schema done
tbar done 1.2    # Endpoints done
```

### When finishing
```bash
tbar done 1      # Mark parent task complete
tbar list        # Show remaining tasks
```

### When reviewing progress
```bash
tbar history     # What was accomplished recently
```

## Data Model

`~/.tbar/todos.json`:
```json
{
  "version": 1,
  "todos": [
    {
      "id": 1,
      "title": "Task title",
      "priority": "high",
      "done": false,
      "completedAt": null,
      "createdAt": "2026-03-31T10:00:00Z",
      "nextSubtaskId": 3,
      "subtasks": [
        { "id": 1, "title": "Subtask", "done": true },
        { "id": 2, "title": "Subtask 2", "done": false }
      ]
    }
  ],
  "nextId": 2
}
```

## Daily Behavior

- Completed tasks are visible on the day they're completed
- The next day, they disappear from `tbar list` and the menu bar
- They remain in `tbar history` and `tbar list --all`
- Timezone follows the user's macOS system timezone

## Handling $ARGUMENTS

If `$ARGUMENTS` is provided, parse the first word as the command:

1. **Empty** → Run `tbar list` and show the result
2. **Starts with a known command** (add, list, done, undone, delete, priority, search, history) → Run `tbar $ARGUMENTS`
3. **Natural language** → Interpret intent and run the appropriate command. Ask for clarification if ambiguous.

## Installation

```bash
# Install tbar
brew tap wonyoung2257/tap
brew install --cask tbar

# Install this skill for Claude Code
cp skills/tbar/SKILL.md ~/.claude/commands/tbar.md
```
