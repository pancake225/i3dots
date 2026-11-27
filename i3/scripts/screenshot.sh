#!/usr/bin/env bash
# Take a screenshot, save it, and copy it to the clipboard.
# Usage: screenshot.sh [full|region|window]
set -euo pipefail

mode="${1:-full}"
dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
file="$dir/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

notify() {
	command -v notify-send >/dev/null 2>&1 &&
		notify-send -a screenshot "$@" 2>/dev/null || true
}

case "$mode" in
	full | region | window) ;;
	*)
		printf 'Usage: %s [full|region|window]\n' "$(basename "$0")" >&2
		exit 1
		;;
esac

mkdir -p "$dir"

if command -v xfce4-screenshooter >/dev/null 2>&1; then
	args=(-c -s "$file")
	case "$mode" in
		full) args+=(-f) ;;
		region) args+=(-r) ;;
		window) args+=(-w) ;;
	esac
	# Region selection can be cancelled; that is not an error.
	xfce4-screenshooter "${args[@]}" || exit 0
elif command -v maim >/dev/null 2>&1; then
	case "$mode" in
		full)
			maim "$file"
			;;
		region)
			maim -s "$file" || exit 0
			;;
		window)
			command -v xdotool >/dev/null 2>&1 || {
				notify "Screenshot failed" "xdotool is required for window screenshots"
				exit 1
			}
			maim -i "$(xdotool getactivewindow)" "$file"
			;;
	esac
	if command -v xclip >/dev/null 2>&1; then
		xclip -selection clipboard -t image/png -i "$file" 2>/dev/null || true
	else
		notify "Screenshot saved" "Install xclip to copy screenshots"
	fi
else
	notify "Screenshot failed" "Install xfce4-screenshooter or maim"
	exit 1
fi

[[ -f "$file" ]] || exit 0
notify "Screenshot saved" "$file"
