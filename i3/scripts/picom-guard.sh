#!/usr/bin/env bash
# Start picom only when it is not already running.
# Keeps i3 reloads from spawning duplicate compositors.
set -euo pipefail

if pgrep -u "$UID" -x picom >/dev/null; then
	exit 0
fi

exec picom --config "${XDG_CONFIG_HOME:-$HOME/.config}/picom/picom.conf" -b
