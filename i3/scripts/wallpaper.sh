#!/usr/bin/env bash
# Wallpaper switcher (feh/xwallpaper) with a rofi picker and thumbnails.
#
#   wallpaper             pick a wallpaper with previews
#   wallpaper --random    pick a random wallpaper
#   wallpaper --restore   restore the last wallpaper (used at login)
#   wallpaper --set FILE  set a specific wallpaper
#   wallpaper --dir DIR   pick from a different directory
set -euo pipefail

WALL_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wall}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_FILE="$CACHE_DIR/wallpaper"
THUMB_DIR="$CACHE_DIR/wallpaper-thumbs"
ROFI_THEME="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/wallpaper.rasi"

HAVE_PIL=0
if command -v python3 >/dev/null 2>&1 && python3 -c 'import PIL' 2>/dev/null; then
	HAVE_PIL=1
fi

usage() {
	cat <<EOF
Usage: wallpaper [option]
  (no option)   pick a wallpaper with previews
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

thumb_for() {
	local img="$1"
	local key thumb tmp

	key=$(printf 'v3:%s' "$img" | md5sum | cut -d' ' -f1)
	thumb="$THUMB_DIR/$key.png"

	if [[ -f "$thumb" && "$thumb" -nt "$img" ]]; then
		printf '%s\n' "$thumb"
		return 0
	fi

	mkdir -p "$THUMB_DIR"
	tmp="$thumb.tmp.$$"
	if ((HAVE_PIL)); then
		python3 - "$img" "$tmp" <<'PY' 2>/dev/null || true
import sys
from PIL import Image, ImageOps, ImageFilter, ImageEnhance

src, dst = sys.argv[1], sys.argv[2]
try:
    im = Image.open(src)
    im = ImageOps.exif_transpose(im).convert("RGB")

    # Square tile: blurred wallpaper as the background, sharp 16:9 preview
    # centered on top.
    size = 240
    bg = ImageOps.fit(im, (size, size), method=Image.Resampling.LANCZOS)
    bg = bg.filter(ImageFilter.GaussianBlur(12))
    bg = ImageEnhance.Brightness(bg).enhance(0.55)

    fg_h = size * 9 // 16
    fg = ImageOps.fit(im, (size, fg_h), method=Image.Resampling.LANCZOS)
    bg.paste(fg, (0, (size - fg_h) // 2))
    bg.save(dst, "PNG")
except Exception:
    sys.exit(1)
PY
	fi

	if [[ ! -s "$tmp" ]] && command -v gdk-pixbuf-thumbnailer >/dev/null 2>&1; then
		gdk-pixbuf-thumbnailer -s 320 "$img" "$tmp" >/dev/null 2>&1 || true
	fi

	if [[ -s "$tmp" ]]; then
		mv -f "$tmp" "$thumb"
		printf '%s\n' "$thumb"
	else
		rm -f "$tmp"
		return 1
	fi
}

prepare_thumbs() {
	local img key thumb jobs self
	local -a missing=()

	while IFS= read -r img; do
		[[ -n "$img" ]] || continue
		key=$(printf 'v3:%s' "$img" | md5sum | cut -d' ' -f1)
		thumb="$THUMB_DIR/$key.png"
		if [[ ! -f "$thumb" || ! "$thumb" -nt "$img" ]]; then
			missing+=("$img")
		fi
	done < <(list_walls)

	((${#missing[@]})) || return 0

	mkdir -p "$THUMB_DIR"
	jobs=$(nproc 2>/dev/null || echo 4)
	self=$(readlink -f "$0")

	# Generate thumbnails in parallel; each child handles exactly one image.
	printf '%s\0' "${missing[@]}" |
		xargs -0 -r -P "$jobs" -I{} "$self" --thumb "{}" >/dev/null 2>&1 || true
}

pick_rofi() {
	local img name thumb choice path
	local -a args=(-dmenu -i -p "wallpaper" -show-icons)

	[[ -f "$ROFI_THEME" ]] && args+=(-theme "$ROFI_THEME")

	# Build every thumbnail first, so rofi opens with the full grid instead of
	# streaming entries (and showing "Loading...") while images are processed.
	prepare_thumbs

	choice=$(
		while IFS= read -r img; do
			[[ -n "$img" ]] || continue
			name=$(basename "$img")
			if thumb=$(thumb_for "$img" 2>/dev/null); then
				printf '%s\0icon\x1f%s\n' "$name" "$thumb"
			else
				printf '%s\n' "$name"
			fi
		done < <(list_walls) | rofi "${args[@]}"
	) || return 1

	[[ -n "$choice" ]] || return 1

	path=$(find "$WALL_DIR" -maxdepth 2 -type f -name "$choice" -print -quit 2>/dev/null)
	[[ -n "$path" ]] || return 1
	printf '%s\n' "$path"
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
	--thumb)
		if [[ $# -lt 2 ]]; then
			usage >&2
			exit 1
		fi
		thumb_for "$2"
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
