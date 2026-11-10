# Workspace environment for the login shells ContainerSSH starts
# (/etc/profile resets PATH).
export PATH="$HOME/.local/bin:$HOME/go/bin:/usr/local/go/bin:$PATH"
export DISABLE_AUTOUPDATER=1

# An interactive login with a TTY lands in the shared tmux session "main", so
# whatever runs there survives a disconnect. WS_NO_TMUX=1 opts out.
if [ -t 0 ] && [ -t 1 ] && [ -z "${TMUX:-}" ] && [ -z "${WS_NO_TMUX:-}" ] && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s main
fi
