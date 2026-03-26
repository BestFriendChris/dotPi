# Auto-run sync-settings on first login
if [ ! -f ~/.setup-complete ]; then
    sync-settings && touch ~/.setup-complete
fi

# Fix terminal paste issues
set -o emacs
bind 'set enable-bracketed-paste off'

# Environment
export PATH="$HOME/bin:$PATH"
export TERM=xterm-256color
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# Launch pi directly for interactive sessions (unless NOPI is set or we're in tmux)
# tmux is still available to use within pi if needed
if [[ $- == *i* ]] && [[ -z "${NOPI:-}" ]] && [[ -z "${TMUX:-}" ]]; then
    exec pi
fi
