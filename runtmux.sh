#!/bin/bash

# Tmux Session Manager
# A console interface for managing tmux sessions

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Run tmux with the running server's own binary. After a package upgrade the
# server keeps running the old (deleted) binary, and a newer client can't
# attach to it ("open terminal failed: not a terminal").
tmux() {
    local pid
    pid=$(command tmux display-message -p '#{pid}' 2>/dev/null) || true
    if [ -n "$pid" ] && [ -x "/proc/$pid/exe" ]; then
        "/proc/$pid/exe" "$@"
    else
        command tmux "$@"
    fi
}

# Clear screen and show header
show_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════╗"
    echo "║         TMUX SESSION MANAGER             ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Interactive session selector
# Returns selected session name in $SELECTED_SESSION
# Returns 1 if cancelled
select_session() {
    local prompt="$1"
    local sessions=()
    local session_info=()
    local current=0
    local key=""

    # Read sessions into array
    while IFS= read -r line; do
        sessions+=("$(echo "$line" | cut -d: -f1)")
        session_info+=("$line")
    done < <(tmux list-sessions 2>/dev/null)

    local count=${#sessions[@]}
    if [ "$count" -eq 0 ]; then
        return 1
    fi

    # Hide cursor
    tput civis

    # Trap to restore cursor on exit
    trap 'tput cnorm' RETURN

    while true; do
        # Clear and redraw
        clear
        echo -e "${CYAN}${BOLD}"
        echo "╔══════════════════════════════════════════╗"
        echo "║         TMUX SESSION MANAGER             ║"
        echo "╚══════════════════════════════════════════╝"
        echo -e "${NC}"
        echo ""
        echo -e "${GREEN}${BOLD}$prompt${NC}"
        echo -e "${YELLOW}Use ↑/↓ arrows to navigate, Enter to select, q to cancel${NC}"
        echo "────────────────────────────────────────────"

        # Display sessions with highlighting
        for i in "${!sessions[@]}"; do
            if [ "$i" -eq "$current" ]; then
                echo -e "  ${BOLD}${CYAN}▶ ${session_info[$i]}${NC}"
            else
                echo -e "    ${session_info[$i]}"
            fi
        done

        echo "────────────────────────────────────────────"

        # Read key input
        IFS= read -rsn1 key

        # Handle escape sequences for arrow keys
        if [[ "$key" == $'\x1b' ]]; then
            read -rsn2 -t 0.1 key
            case "$key" in
                '[A') # Up arrow
                    ((current > 0)) && ((current--))
                    ;;
                '[B') # Down arrow
                    ((current < count - 1)) && ((current++))
                    ;;
            esac
        elif [[ "$key" == "" ]]; then
            # Enter key
            SELECTED_SESSION="${sessions[$current]}"
            tput cnorm
            return 0
        elif [[ "$key" == "q" || "$key" == "Q" ]]; then
            tput cnorm
            return 1
        elif [[ "$key" == "k" ]]; then
            # Vim-style up
            ((current > 0)) && ((current--))
        elif [[ "$key" == "j" ]]; then
            # Vim-style down
            ((current < count - 1)) && ((current++))
        fi
    done
}

# List all sessions with numbers
list_sessions() {
    if tmux list-sessions 2>/dev/null; then
        return 0
    else
        echo -e "${YELLOW}No active sessions${NC}"
        return 1
    fi
}

# Show sessions in a formatted way
show_sessions() {
    echo -e "${GREEN}${BOLD}Active Sessions:${NC}"
    echo "────────────────────────────────────────────"
    if ! list_sessions; then
        echo ""
    fi
    echo "────────────────────────────────────────────"
    echo ""
}

# Create new session
new_session() {
    echo -e "${CYAN}Enter session name (or press Enter for default):${NC} "
    read -r session_name

    if [ -z "$session_name" ]; then
        tmux new-session
    else
        if tmux has-session -t "$session_name" 2>/dev/null; then
            echo -e "${RED}Session '$session_name' already exists!${NC}"
            sleep 2
        else
            tmux new-session -s "$session_name"
        fi
    fi
}

# Attach to existing session
attach_session() {
    if ! tmux list-sessions &>/dev/null; then
        echo -e "${RED}No sessions available to attach!${NC}"
        sleep 2
        return
    fi

    if select_session "Select session to attach:"; then
        tmux attach-session -t "$SELECTED_SESSION"
    else
        echo -e "${CYAN}Cancelled${NC}"
        sleep 1
    fi
}

# Kill a session
kill_session() {
    if ! tmux list-sessions &>/dev/null; then
        echo -e "${RED}No sessions available to kill!${NC}"
        sleep 2
        return
    fi

    if select_session "Select session to kill:"; then
        echo ""
        echo -e "${YELLOW}Kill session '$SELECTED_SESSION'? (y/N):${NC} "
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            tmux kill-session -t "$SELECTED_SESSION"
            echo -e "${GREEN}Session '$SELECTED_SESSION' killed${NC}"
            sleep 1
        else
            echo -e "${CYAN}Cancelled${NC}"
            sleep 1
        fi
    else
        echo -e "${CYAN}Cancelled${NC}"
        sleep 1
    fi
}

# Kill all sessions
kill_all_sessions() {
    if ! tmux list-sessions &>/dev/null; then
        echo -e "${RED}No sessions to kill!${NC}"
        sleep 2
        return
    fi

    echo -e "${RED}${BOLD}WARNING: This will kill ALL tmux sessions!${NC}"
    echo -e "${YELLOW}Are you sure? (yes/N):${NC} "
    read -r confirm

    if [ "$confirm" = "yes" ]; then
        tmux kill-server
        echo -e "${GREEN}All sessions killed${NC}"
        sleep 1
    else
        echo -e "${CYAN}Cancelled${NC}"
        sleep 1
    fi
}

# Rename a session
rename_session() {
    if ! tmux list-sessions &>/dev/null; then
        echo -e "${RED}No sessions available to rename!${NC}"
        sleep 2
        return
    fi

    if select_session "Select session to rename:"; then
        echo ""
        echo -e "${CYAN}Enter new name for '$SELECTED_SESSION':${NC} "
        read -r new_name
        if [ -n "$new_name" ]; then
            tmux rename-session -t "$SELECTED_SESSION" "$new_name"
            echo -e "${GREEN}Session renamed to '$new_name'${NC}"
            sleep 1
        else
            echo -e "${CYAN}Cancelled${NC}"
            sleep 1
        fi
    else
        echo -e "${CYAN}Cancelled${NC}"
        sleep 1
    fi
}

# Detach all clients from a session
detach_clients() {
    if ! tmux list-sessions &>/dev/null; then
        echo -e "${RED}No sessions available!${NC}"
        sleep 2
        return
    fi

    if select_session "Select session to detach clients from:"; then
        tmux detach-client -s "$SELECTED_SESSION" -a
        echo -e "${GREEN}All clients detached from '$SELECTED_SESSION'${NC}"
        sleep 1
    else
        echo -e "${CYAN}Cancelled${NC}"
        sleep 1
    fi
}

# Main menu
main_menu() {
    while true; do
        show_header
        show_sessions

        echo -e "${BOLD}Options:${NC}"
        echo -e "  ${GREEN}n${NC} - New session"
        echo -e "  ${GREEN}a${NC} - Attach to session"
        echo -e "  ${GREEN}k${NC} - Kill session"
        echo -e "  ${GREEN}K${NC} - Kill ALL sessions"
        echo -e "  ${GREEN}r${NC} - Rename session"
        echo -e "  ${GREEN}d${NC} - Detach all clients from session"
        echo -e "  ${GREEN}l${NC} - Refresh list"
        echo -e "  ${GREEN}q${NC} - Quit"
        echo ""
        echo -e "${CYAN}Enter choice:${NC} "
        read -r -n1 choice
        echo ""

        case $choice in
            n|N)
                new_session
                ;;
            a|A)
                attach_session
                ;;
            k)
                kill_session
                ;;
            K)
                kill_all_sessions
                ;;
            r|R)
                rename_session
                ;;
            d|D)
                detach_clients
                ;;
            l|L)
                # Just refresh - loop will redraw
                ;;
            q|Q)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Check if tmux is installed
if ! command -v tmux &>/dev/null; then
    echo -e "${RED}Error: tmux is not installed${NC}"
    exit 1
fi

# Run main menu
main_menu
