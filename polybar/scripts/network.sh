#!/bin/sh
# Print the active network: Wi-Fi SSID, interface name, or "offline".

iface=""
if command -v ip >/dev/null 2>&1; then
	iface=$(ip route show default 2>/dev/null | awk '/^default/ {print $5; exit}')
fi

if [ -z "$iface" ]; then
	printf 'offline'
	exit 0
fi

if [ -d "/sys/class/net/$iface/wireless" ]; then
	if command -v nmcli >/dev/null 2>&1; then
		ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null \
			| awk -F: '$1 == "yes" {print $2; exit}')
		if [ -n "$ssid" ]; then
			printf '%s' "$ssid"
			exit 0
		fi
	fi
	printf 'wifi'
else
	printf '%s' "$iface"
fi
