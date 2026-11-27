#!/usr/bin/env bash
# Start dunst if it is installed and not already running.
# Stops another notification daemon that may hold the D-Bus name.
set -euo pipefail

command -v dunst >/dev/null 2>&1 || exit 0

if pgrep -u "$UID" -x dunst >/dev/null; then
	exit 0
fi

# D-Bus activates a different daemon on demand; stop it so dunst can own
# org.freedesktop.Notifications.
pkill -u "$UID" -x notification-daemon 2>/dev/null || true
pkill -u "$UID" -x xfce4-notifyd 2>/dev/null || true
pkill -u "$UID" -x notify-osd 2>/dev/null || true

# Wait until the old daemon has released the D-Bus name. Querying the name
# itself would re-activate the old service, so list names instead.
bus_has_notifications() {
	if command -v busctl >/dev/null 2>&1; then
		busctl --user list 2>/dev/null |
			awk '{ print $1 }' | grep -qx 'org.freedesktop.Notifications'
	else
		dbus-send --session --print-reply --dest=org.freedesktop.DBus \
			/org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null |
			grep -q '"org.freedesktop.Notifications"'
	fi
}

for ((i = 0; i < 30; i++)); do
	bus_has_notifications || break
	sleep 0.1
done

exec dunst -config "${XDG_CONFIG_HOME:-$HOME/.config}/dunst/dunstrc"
