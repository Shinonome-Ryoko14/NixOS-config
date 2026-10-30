# Toggle a transparent "fullscreen" for the focused window.
#
# niri draws a solid black backdrop behind real fullscreen windows, which makes
# transparent terminals opaque. Windowed fullscreen hides the client UI while
# the window keeps its normal (semi-transparent) surface; maximizing it to the
# edges fills the screen. The Noctalia bar is hidden over IPC so it gets out of
# the way and comes back on the second press.

set -euo pipefail

wid="$(niri msg --json focused-window | jq -r '.id // empty')"
if [ -z "$wid" ]; then
    exit 0
fi

state_dir="${XDG_RUNTIME_DIR:-/tmp}/niri-fake-fullscreen"
mkdir -p "$state_dir"
state="$state_dir/$wid"

if [ -e "$state" ]; then
    rm -f "$state"
    niri msg action maximize-window-to-edges || true
    niri msg action toggle-windowed-fullscreen || true
    noctalia msg bar-show || true
else
    : >"$state"
    niri msg action toggle-windowed-fullscreen || true
    niri msg action maximize-window-to-edges || true
    noctalia msg bar-hide || true
fi
