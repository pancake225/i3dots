#!/usr/bin/env bash
# Lock the screen using the current theme's background color.
# Usage: lock.sh [--nofork]
set -euo pipefail

nofork=0
if [[ "${1:-}" == "--nofork" || "${1:-}" == "-n" ]]; then
	nofork=1
fi

theme="${XDG_CONFIG_HOME:-$HOME/.config}/polybar/theme.ini"
bg="#1c1c1c"

if [[ -r "$theme" ]]; then
	value=$(awk -F' *= *' '$1 == "background" { print $2; exit }' "$theme")
	bg="${value:-$bg}"
fi
bg="${bg#\#}"

if ! command -v i3lock >/dev/null 2>&1; then
	command -v notify-send >/dev/null 2>&1 &&
		notify-send -a lock "Lock failed" "i3lock is not installed" 2>/dev/null || true
	exit 1
fi

args=(-c "$bg")
((nofork)) && args+=(-n)

exec i3lock "${args[@]}"
