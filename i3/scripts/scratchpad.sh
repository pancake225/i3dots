#!/usr/bin/env bash
# Toggle a floating scratchpad terminal.
set -euo pipefail

if i3-msg -t get_tree | grep -q '"class":"scratchpad"'; then
	i3-msg '[class="scratchpad"] scratchpad show' >/dev/null
	exit 0
fi

kitty --class scratchpad --title scratchpad &
for ((i = 0; i < 30; i++)); do
	i3-msg -t get_tree | grep -q '"class":"scratchpad"' && break
	sleep 0.1
done

i3-msg '[class="scratchpad"] move scratchpad' >/dev/null
i3-msg '[class="scratchpad"] scratchpad show' >/dev/null
