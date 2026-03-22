#!/usr/bin/env bash
# tmux layout for React Native / Expo development
# Usage: bash dev-rn.sh [project-dir]
#
# Layout:
# ┌────────────────────┬──────────────┐
# │                    │  expo start  │
# │      nvim          ├──────────────┤
# │                    │    shell     │
# └────────────────────┴──────────────┘

DIR="${1:-.}"
SESSION="rn"

# If already running, just attach
tmux has-session -t "$SESSION" 2>/dev/null && exec tmux attach -t "$SESSION"

# Create session with nvim as the main pane
tmux new-session -d -s "$SESSION" -c "$DIR" -x "$(tput cols)" -y "$(tput lines)"
tmux rename-window -t "$SESSION" "dev"

# Right pane: Expo dev server (35% width)
tmux split-window -h -p 35 -t "$SESSION" -c "$DIR"
tmux send-keys -t "$SESSION" "npx expo start" Enter

# Bottom-right pane: spare shell for git, tests, etc.
tmux split-window -v -p 40 -t "$SESSION" -c "$DIR"

# Focus back on the editor pane
tmux select-pane -t "$SESSION:.0"
tmux send-keys -t "$SESSION" "nvim ." Enter

tmux attach -t "$SESSION"
