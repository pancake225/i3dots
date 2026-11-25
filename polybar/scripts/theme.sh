#!/usr/bin/env bash
# Switch polybar theme. Usage: theme.sh [NAME]
set -euo pipefail

dir="${XDG_CONFIG_HOME:-$HOME/.config}/polybar"
theme="${1:-}"

if [[ -z "$theme" ]]; then
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

cp "$dir/themes/$theme.ini" "$dir/theme.ini"
"$dir/launch.sh"
