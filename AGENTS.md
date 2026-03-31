# tbar — macOS Menu Bar TODO App + CLI

## Overview
A native macOS menu bar TODO app with full CLI control. Built with Swift (AppKit).
- CLI command: `tbar`
- Data: `~/.tbar/todos.json` (JSON file)
- Target: macOS 14.0+ (Sonoma)

## Architecture
- **TBarCore** (library): Shared data models + JSON CRUD + file locking
- **tbar** (executable): CLI using swift-argument-parser
- **TBarApp** (executable): Menu bar app using AppKit (NSStatusItem + NSMenu)

## Data Model
```json
{
  "version": 1,
  "todos": [
    {
      "id": 1,
      "title": "API design",
      "priority": "high",
      "done": false,
      "createdAt": "2026-03-29T10:00:00Z",
      "nextSubtaskId": 4,
      "subtasks": [
        { "id": 1, "title": "Define endpoints", "done": true },
        { "id": 2, "title": "Design schema", "done": true },
        { "id": 3, "title": "Write tests", "done": false }
      ]
    }
  ],
  "nextId": 2
}
```

Fields:
- `version`: Schema version (for future migration)
- `id`: Auto-incrementing integer
- `priority`: "high" | "medium" | "low" (default: "medium")
- `nextSubtaskId`: Per-todo subtask ID counter
- Auto-create `~/.tbar/` directory and empty JSON on first access

## Error Types
```swift
enum TodoStoreError: Error {
    case todoNotFound(id: Int)
    case subtaskNotFound(todoId: Int, subtaskId: Int)
    case corruptedData
    case fileLocked
}
```

## TodoStore Requirements
- **File locking**: Use `flock()` for read-modify-write operations
- **Atomic write**: Write to temp file, then `rename()` to target path
- **Auto-init**: Create `~/.tbar/` directory and empty `todos.json` if not exists

## CLI Commands
```bash
tbar add "title" [--priority high|medium|low]
tbar add "subtask title" --parent <todoId>
tbar list [--all] [--priority high|medium|low]
tbar done <id>          # e.g., tbar done 3 or tbar done 1.2 (subtask)
tbar undone <id>        # same syntax as done
tbar delete <id>        # e.g., tbar delete 2 or tbar delete 1.3
tbar priority <id> <high|medium|low>
tbar search "keyword"
tbar --version
```

### Subtask Reference: `parentId.subtaskId`
- `1.2` means todo #1's subtask #2
- No dot = top-level todo

### CLI Output Format
```
$ tbar list
  1. [!] API design (2/3)
     ├─ [x] Define endpoints
     ├─ [x] Design schema
     └─ [ ] Write tests
  2. [ ] Update docs
  3. [·] Code review
```
Priority icons: `[!]` = high, (none) = medium, `[·]` = low

## Menu Bar App
- NSStatusItem with SF Symbol "checklist" + incomplete count badge
- NSMenu dropdown showing todos sorted by priority (high → medium → low)
- Completed items at bottom
- NSMenuItem with checkbox state for toggling done/undone
- Subtasks shown as NSMenu submenu (hover to expand)
- FileWatcher using DispatchSource monitoring `.write`, `.rename`, `.delete` events
- On `.rename`/`.delete`: cancel old source, open new file descriptor, create new source
- Info.plist with LSUIElement=true (no Dock icon)
- Use `NSApp.setActivationPolicy(.accessory)` as backup

## Build
- SPM produces flat binaries only — Makefile assembles .app bundle
- Universal binary: `swift build -c release --arch arm64 --arch x86_64`
- Build output path with --arch: `.build/apple/Products/Release/`

## Coding Style
- Swift 5.9+
- Use Codable for JSON serialization
- Immutable patterns preferred (structs, let)
- Comprehensive error handling
- All public APIs documented
- Tests use XCTest
