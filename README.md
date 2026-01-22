# Tmux Session Manager

A terminal-based interface for managing tmux sessions with interactive navigation.

## Requirements

- tmux
- bash

## Usage

```bash
./runtmux.sh
```

## Features

### Main Menu

The main menu displays all active tmux sessions and provides the following options:

| Key | Action |
|-----|--------|
| `n` | Create a new session |
| `a` | Attach to an existing session |
| `k` | Kill a session |
| `K` | Kill ALL sessions |
| `r` | Rename a session |
| `d` | Detach all clients from a session |
| `l` | Refresh the session list |
| `q` | Quit |

### Interactive Session Selector

When attaching, killing, renaming, or detaching clients, an interactive selector appears:

**Navigation:**
- `↑` / `↓` - Move selection up/down
- `j` / `k` - Vim-style navigation
- `Enter` - Select highlighted session
- `q` - Cancel and return to menu

The currently selected session is highlighted with a `▶` indicator.

### Creating Sessions

Press `n` to create a new session. You can either:
- Enter a custom session name
- Press Enter for tmux's default naming

### Killing Sessions

- Press `k` to kill a single session (with confirmation)
- Press `K` to kill ALL sessions (requires typing "yes" to confirm)

## Example

```
╔══════════════════════════════════════════╗
║         TMUX SESSION MANAGER             ║
╚══════════════════════════════════════════╝

Active Sessions:
────────────────────────────────────────────
dev: 3 windows (created Thu Jan 22 10:30:00 2026)
server: 1 windows (created Thu Jan 22 09:15:00 2026)
────────────────────────────────────────────

Options:
  n - New session
  a - Attach to session
  k - Kill session
  K - Kill ALL sessions
  r - Rename session
  d - Detach all clients from session
  l - Refresh list
  q - Quit
```
