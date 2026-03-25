# Auto-run sync-settings on first login
if [ ! -f ~/.setup-complete ]; then
    sync-settings && touch ~/.setup-complete
fi

# Environment
export PATH="$HOME/bin:$PATH"
export TERM=xterm-256color
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Launch tmux with pi for interactive sessions
if [[ -z "$TMUX" && $- == *i* ]]; then
    n=0
    while tmux has-session -t "pi-$n" 2>/dev/null; do ((n++)); done
    exec tmux new-session -s "pi-$n" "pi"
fi
