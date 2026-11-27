#!/usr/bin/env bash
# Choose where notifications appear.
# Usage: notify-position.sh [POSITION]
set -euo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}/dunst/dunstrc"

positions=(
	top-left top-center top-right
	left-center center right-center
	bottom-left bottom-center bottom-right
)

[[ -r "$config" ]] || {
	printf 'notify-position: cannot read %s\n' "$config" >&2
	exit 1
}

current=$(awk -F' *= *' '$1 == "origin" { print $2; exit }' "$config")

if (($# > 0)); then
	position="$1"
else
	# Mark the current position and let rofi pick a new one.
	menu=$(for p in "${positions[@]}"; do
		if [[ "$p" == "$current" ]]; then
			printf '* %s\n' "$p"
		else
			printf '  %s\n' "$p"
		fi
	done)

	choice=$(printf '%s\n' "$menu" | rofi -dmenu -i -p "notifications" -no-custom) || exit 0
	position="${choice#\* }"
	position="${position#  }"
fi

valid=0
for p in "${positions[@]}"; do
	[[ "$position" == "$p" ]] && valid=1
done

if ((!valid)); then
	printf 'notify-position: unknown position "%s"\n' "$position" >&2
	printf 'available: %s\n' "${positions[*]}" >&2
	exit 1
fi

# Replace only the origin inside [global].
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

awk -v position="$position" '
	/^\[/ { section = $0 }
	section == "[global]" && /^[[:space:]]*origin[[:space:]]*=/ {
		sub(/=.*/, "= " position)
		print
		next
	}
	{ print }
' "$config" > "$tmp"

cat "$tmp" > "$config"

# Reload dunst; if it is not running, start it.
if command -v dunstctl >/dev/null 2>&1 && dunstctl reload 2>/dev/null; then
	:
elif command -v dunst >/dev/null 2>&1; then
	pkill -x dunst 2>/dev/null || true
	dunst -config "$config" >/dev/null 2>&1 &
	sleep 0.3
fi

command -v notify-send >/dev/null 2>&1 &&
	notify-send -a notifications "Notifications" "Position: $position" 2>/dev/null || true

printf 'notifications: %s\n' "$position"
