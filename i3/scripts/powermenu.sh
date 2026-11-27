#!/usr/bin/env bash
# Rofi power menu: lock, suspend, logout, reboot, shutdown.
set -euo pipefail

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

notify() {
	command -v notify-send >/dev/null 2>&1 &&
		notify-send -a power "$@" 2>/dev/null || true
}

choice=$(printf '%s\n' Lock Suspend Logout Reboot Shutdown Cancel |
	rofi -dmenu -i -p "power" -no-custom) || exit 0

case "$choice" in
	Lock)
		exec "$scripts_dir/lock.sh"
		;;
	Suspend)
		"$scripts_dir/lock.sh" &
		sleep 1
		loginctl suspend 2>/dev/null ||
			systemctl suspend 2>/dev/null ||
			doas zzz ||
			notify "Suspend failed" "No supported suspend command"
		;;
	Logout)
		i3-msg exit
		;;
	Reboot)
		loginctl reboot 2>/dev/null ||
			systemctl reboot 2>/dev/null ||
			doas reboot ||
			notify "Reboot failed" "No supported reboot command"
		;;
	Shutdown)
		loginctl poweroff 2>/dev/null ||
			systemctl poweroff 2>/dev/null ||
			doas poweroff ||
			notify "Shutdown failed" "No supported poweroff command"
		;;
	*)
		exit 0
		;;
esac
