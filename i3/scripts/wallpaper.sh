#!/usr/bin/env bash
# Simple wallpaper switcher (feh/xwallpaper) with a rofi picker.
#
#   wallpaper             pick a wallpaper with rofi
#   wallpaper --random    pick a random wallpaper
#   wallpaper --restore   restore the last wallpaper (used at login)
#   wallpaper --set FILE  set a specific wallpaper
#   wallpaper --dir DIR   pick from a different directory
set -euo pipefail

WALL_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wall}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_FILE="$CACHE_DIR/wallpaper"

usage() {
	cat <<EOF
Usage: wallpaper [option]
  (no option)   pick a wallpaper with rofi
  --random      pick a random wallpaper
  --restore     restore the last wallpaper
  --set FILE    set a specific wallpaper
  --dir DIR     use a different wallpaper directory
EOF
}

list_walls() {
	find "$WALL_DIR" -maxdepth 2 -type f \
		\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
		-o -iname '*.webp' -o -iname '*.bmp' \) 2>/dev/null | sort
}

set_wall() {
	local img="$1"
	if [[ ! -f "$img" ]]; then
		printf 'wallpaper: not found: %s\n' "$img" >&2
		return 1
	fi

	if command -v feh >/dev/null 2>&1; then
		if ! feh --no-fehbg --bg-fill "$img"; then
			if command -v xwallpaper >/dev/null 2>&1; then
				xwallpaper --zoom "$img"
			else
				return 1
			fi
		fi
	elif command -v xwallpaper >/dev/null 2>&1; then
		xwallpaper --zoom "$img"
	else
		printf 'wallpaper: install feh or xwallpaper\n' >&2
		return 1
	fi

	mkdir -p "$CACHE_DIR"
	printf '%s\n' "$img" > "$CACHE_FILE"
}

pick_random() {
	list_walls | shuf -n 1
}

pick_rofi() {
	list_walls | rofi -dmenu -i -p "wallpaper"
}

case "${1:-}" in
	-h|--help)
		usage
		;;
	--random)
		img="$(pick_random || true)"
		if [[ -z "$img" ]]; then
			printf 'wallpaper: no images found in %s\n' "$WALL_DIR" >&2
			exit 1
		fi
		set_wall "$img"
		;;
	--restore)
		if [[ -s "$CACHE_FILE" && -f "$(cat "$CACHE_FILE")" ]]; then
			set_wall "$(cat "$CACHE_FILE")"
		else
			img="$(pick_random || true)"
			[[ -n "$img" ]] && set_wall "$img"
		fi
		;;
	--set)
		if [[ $# -lt 2 ]]; then
			usage >&2
			exit 1
		fi
		set_wall "$2"
		;;
	--dir)
		if [[ $# -lt 2 ]]; then
			usage >&2
			exit 1
		fi
		WALL_DIR="$2"
		img="$(pick_rofi || true)"
		[[ -n "$img" ]] && set_wall "$img"
		;;
	"")
		img="$(pick_rofi || true)"
		[[ -n "$img" ]] && set_wall "$img"
		;;
	*)
		usage >&2
		exit 1
		;;
esac
