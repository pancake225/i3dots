#!/usr/bin/env bash
# Launch polybar. Usage: launch.sh [--theme NAME]
set -euo pipefail

dir="${XDG_CONFIG_HOME:-$HOME/.config}/polybar"

if [[ "${1:-}" == "--theme" ]]; then
	shift
	exec "$dir/scripts/theme.sh" "$@"
fi

# First run: fall back to the default theme
[[ -f "$dir/theme.ini" ]] || cp "$dir/themes/gray.ini" "$dir/theme.ini"

killall -q polybar 2>/dev/null || true
while pgrep -u "$UID" -x polybar >/dev/null; do sleep 0.2; done

# One bar per connected monitor
monitors=$(polybar -m 2>/dev/null | cut -d: -f1)

if [[ -n "$monitors" ]]; then
	while read -r m; do
		MONITOR="$m" polybar -q main -c "$dir/config.ini" &
	done <<< "$monitors"
else
	polybar -q main -c "$dir/config.ini" &
fi
