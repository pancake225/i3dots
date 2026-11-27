#!/usr/bin/env bash
# Switch the desktop theme (polybar + rofi + dunst). Usage: theme.sh [NAME]
set -euo pipefail

dir="${XDG_CONFIG_HOME:-$HOME/.config}/polybar"
theme="${1:-}"
interactive=0

if [[ -z "$theme" ]]; then
	interactive=1
	theme=$(find "$dir/themes" -maxdepth 1 -name '*.ini' -printf '%f\n' \
		| sed 's/\.ini$//' | sort \
		| rofi -dmenu -i -p "theme") || true
fi

[[ -n "$theme" ]] || exit 0

if [[ ! -f "$dir/themes/$theme.ini" ]]; then
	printf 'theme: unknown theme "%s"\n' "$theme" >&2
	printf 'available:' >&2
	find "$dir/themes" -maxdepth 1 -name '*.ini' -printf ' %f' | sed 's/\.ini//g' >&2
	printf '\n' >&2
	exit 1
fi

# Resolve the real repo directory even though ~/.config/polybar is a symlink.
polybar_dir="$(cd "$dir" && pwd -P)"
root="$(dirname "$polybar_dir")"

theme_color() {
	awk -F' *= *' -v key="$1" '$1 == key { print $2; exit }' "$dir/themes/$theme.ini"
}

# Keep rofi in sync with the polybar palette.
write_rofi_colors() {
	local rofi_dir="$root/rofi"
	local bg fg alt accent muted urgent

	[[ -d "$rofi_dir" ]] || return 0

	bg=$(theme_color background)
	fg=$(theme_color foreground)
	alt=$(theme_color background-alt)
	accent=$(theme_color primary)
	muted=$(theme_color muted)
	urgent=$(theme_color urgent)

	cat > "$rofi_dir/colors.rasi" <<EOF
* {
    bg: ${bg:-#1c1c1c};
    fg: ${fg:-#d0d0d0};
    alt: ${alt:-#2a2a2a};
    accent: ${accent:-#b8b8b8};
    muted: ${muted:-#7a7a7a};
    urgent: ${urgent:-#e06c75};
}
EOF
}

# Keep dunst in sync with the polybar palette.
write_dunst_colors() {
	local dunst="$root/dunst/dunstrc"
	local bg fg accent

	[[ -f "$dunst" ]] || return 0

	bg=$(theme_color background)
	fg=$(theme_color foreground)
	accent=$(theme_color primary)

	awk -v bg="${bg:-#1c1c1c}" \
		-v fg="${fg:-#d0d0d0}" \
		-v accent="${accent:-#b8b8b8}" '
		/^# >>> i3dots theme colors/ {
			print
			print "    frame_color = \"" accent "\""
			skip = 1
			next
		}
		/^# <<< i3dots theme colors/ { skip = 0 }
		/^# >>> i3dots theme rule/ {
			print
			print "[theme]"
			print "    background = \"" bg "\""
			print "    foreground = \"" fg "\""
			print "    highlight = \"" accent "\""
			skip = 1
			next
		}
		/^# <<< i3dots theme rule/ { skip = 0 }
		!skip { print }
	' "$dunst" > "$dunst.tmp" && mv "$dunst.tmp" "$dunst"
}

# Offer the wallpaper that belongs to the selected theme.
ask_theme_wallpaper() {
	local map="$root/polybar/themes/wallpapers.conf"
	local file wall answer

	[[ -r "$map" ]] || return 0

	file=$(awk -F' *= *' -v t="$theme" '$1 == t { print $2; exit }' "$map")
	[[ -n "$file" ]] || return 0

	if [[ "$file" = /* ]]; then
		wall="$file"
	else
		wall="$HOME/Pictures/wall/$file"
		[[ -f "$wall" ]] || wall="$root/wallpapers/$file"
	fi

	[[ -f "$wall" ]] || return 0

	answer=$(printf 'Yes\nNo\n' |
		rofi -dmenu -i -p "use theme wallpaper?" \
			-mesg "Theme: $theme | $(basename "$wall")" -no-custom) || return 0

	[[ "$answer" == "Yes" ]] || return 0

	"$root/i3/scripts/wallpaper.sh" --set "$wall"
}

cp "$dir/themes/$theme.ini" "$dir/theme.ini"
write_rofi_colors
write_dunst_colors
"$dir/launch.sh"

if ((interactive)); then
	ask_theme_wallpaper
fi

if command -v dunstctl >/dev/null 2>&1; then
	dunstctl reload 2>/dev/null || true
fi

printf 'theme: %s\n' "$theme"
