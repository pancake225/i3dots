#!/usr/bin/env bash
# Quick toggles: gaps, polybar, picom.
# Usage: toggle.sh [gaps|polybar|picom]
set -euo pipefail

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/i3-dots"
state_file="$state_dir/gaps"
mkdir -p "$state_dir"

notify() {
	command -v notify-send >/dev/null 2>&1 &&
		notify-send -a toggle "$@" 2>/dev/null || true
}

toggle_gaps() {
	if [[ "$(cat "$state_file" 2>/dev/null || echo on)" == "on" ]]; then
		i3-msg 'gaps inner all set 0; gaps outer all set 0' >/dev/null
		echo off > "$state_file"
		notify "Gaps off"
	else
		i3-msg 'gaps inner all set 10; gaps outer all set 5' >/dev/null
		echo on > "$state_file"
		notify "Gaps on"
	fi
}

toggle_polybar() {
	if pgrep -u "$UID" -x polybar >/dev/null; then
		killall -q polybar 2>/dev/null || true
		notify "Polybar hidden"
	else
		"${XDG_CONFIG_HOME:-$HOME/.config}/polybar/launch.sh"
		notify "Polybar shown"
	fi
}

toggle_picom() {
	if pgrep -u "$UID" -x picom >/dev/null; then
		killall -q picom 2>/dev/null || true
		notify "Compositor off"
	else
		picom --config "${XDG_CONFIG_HOME:-$HOME/.config}/picom/picom.conf" -b
		notify "Compositor on"
	fi
}

case "${1:-}" in
	gaps) toggle_gaps ;;
	polybar) toggle_polybar ;;
	picom) toggle_picom ;;
	*)
		printf 'Usage: %s [gaps|polybar|picom]\n' "$(basename "$0")" >&2
		exit 1
		;;
esac
