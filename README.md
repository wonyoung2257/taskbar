# tbar - Menu Bar TODO Manager

tbar is a native macOS menu bar TODO manager with a matching CLI. It keeps a single JSON data store on disk so the menu bar app and terminal workflows stay in sync.

## Screenshot

_Screenshot coming soon._

## Features

- Native macOS menu bar app built with AppKit
- `tbar` CLI for full scriptable control
- Nested subtasks with per-todo subtask IDs
- High, medium, and low priorities
- File watching so the menu bar refreshes when the JSON store changes

## Installation

Install with Homebrew Cask:

```bash
brew install --cask tbar
```

Or build and install manually:

```bash
git clone <repo-url>
cd taskbar
make install
```

## CLI Usage

Add a todo:

```bash
tbar add "API design" --priority high
```

Add a subtask:

```bash
tbar add "Write tests" --parent 1
```

List todos:

```bash
tbar list
tbar list --all
tbar list --priority high
```

Mark items done or undone:

```bash
tbar done 1
tbar done 1.2
tbar undone 1
```

Delete a todo or subtask:

```bash
tbar delete 2
tbar delete 1.3
```

Change priority:

```bash
tbar priority 3 low
```

Search:

```bash
tbar search "docs"
```

## Building From Source

Build release binaries:

```bash
make build
```

Build a universal release:

```bash
make build-universal
```

Assemble the app bundle:

```bash
make app
make app-universal
```

Run tests:

```bash
make test
```

Create a release archive:

```bash
make release-zip VERSION=0.1.0
```

## License

MIT
