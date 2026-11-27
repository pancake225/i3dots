#!/usr/bin/env bash
# Show a searchable cheatsheet of i3 keybindings.
set -euo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}/i3/config"
[[ -r "$config" ]] || {
	printf 'cheatsheet: cannot read %s\n' "$config" >&2
	exit 1
}

# Read bindsym lines. Skip resize mode internals to keep the list focused.
awk '
	/^[[:space:]]*mode[[:space:]]/ { in_mode = 1 }
	in_mode && /^[[:space:]]*}/ { in_mode = 0; next }
	in_mode { next }

	/^[[:space:]]*bindsym[[:space:]]/ {
		line = $0
		sub(/^[[:space:]]*bindsym[[:space:]]+/, "", line)
		sub(/^--release[[:space:]]+/, "", line)

		split(line, parts, /[[:space:]]+/)
		keys = parts[1]
		cmd = line
		sub(/^[^[:space:]]+[[:space:]]*/, "", cmd)

		# Shorten the most common long commands.
		gsub(/exec --no-startup-id /, "", cmd)
		gsub(/~\/\.config\/i3\/scripts\//, "", cmd)
		gsub(/~\/\.config\/polybar\/scripts\//, "", cmd)
		gsub(/~\/\.config\/polybar\//, "", cmd)
		gsub(/^exec /, "", cmd)

		if (keys == "" || cmd == "")
			next
		printf "%-22s %s\n", keys, cmd
	}
' "$config" |
	sed 's/\$mod/Alt/g; s/\bMod1\b/Alt/g; s/\bMod4\b/Super/g;
	     s/+grave/+`/g; s/+slash/+\//g; s/+semicolon/+;/g' |
	sort -k1,1 |
	rofi -dmenu -i -p "keys" -no-custom >/dev/null || true
