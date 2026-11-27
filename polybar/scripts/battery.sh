#!/bin/sh
# Print battery percentage, or nothing if there is no battery.

for bat in /sys/class/power_supply/*; do
	[ -r "$bat/type" ] || continue
	[ "$(cat "$bat/type" 2>/dev/null)" = "Battery" ] || continue

	capacity=$(cat "$bat/capacity" 2>/dev/null) || exit 0
	status=$(cat "$bat/status" 2>/dev/null)

	case "$status" in
		Charging) printf '%s%% +' "$capacity" ;;
		Full)     printf '%s%%' "$capacity" ;;
		*)        printf '%s%%' "$capacity" ;;
	esac
	exit 0
done

# No battery found: print nothing
exit 0
