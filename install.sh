#!/usr/bin/env bash
# Install the i3 dots from ~/i3dots.
#
#   ./install.sh              install packages + link configs
#   ./install.sh --no-deps    only link configs
#   ./install.sh --deps-only  only install packages
set -euo pipefail

DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN_DIR="$HOME/.local/bin"
WALL_DIR="$HOME/Pictures/wall"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

WITH_DEPS=1
DEPS_ONLY=0

usage() {
	cat <<EOF
Usage: ./install.sh [option]
  (no option)    install packages and link configs
  --no-deps      only link configs
  --deps-only    only install packages
  -h, --help     show this help
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--no-deps) WITH_DEPS=0 ;;
		--deps-only) DEPS_ONLY=1 ;;
		-h|--help) usage; exit 0 ;;
		*) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
	esac
	shift
done

PRIV=()

# Pick a working privilege escalation tool: sudo -> doas -> run0.
select_priv() {
	if [[ $EUID -eq 0 ]]; then
		PRIV=()
		return 0
	fi

	local esc
	for esc in sudo doas run0; do
		command -v "$esc" >/dev/null 2>&1 || continue

		if "$esc" true; then
			PRIV=("$esc")
			echo "==> Using $esc for root commands"
			return 0
		fi

		echo "!! $esc is not usable, trying the next tool..." >&2
	done

	echo "!! No working privilege escalation tool found (tried sudo, doas, run0)." >&2
	echo "   Run the installer as root, or install one of the above." >&2
	return 1
}

as_root() {
	if ((${#PRIV[@]} > 0)); then
		"${PRIV[@]}" "$@"
	else
		"$@"
	fi
}

install_deps() {
	echo "==> Installing dependencies"
	select_priv

	if command -v pacman >/dev/null 2>&1; then
		as_root pacman -S --needed --noconfirm \
			i3-wm polybar picom rofi kitty feh xfce4-screenshooter \
			dex xss-lock i3lock dunst python-pillow \
			network-manager-applet networkmanager \
			iproute2 xorg-setxkbmap ttf-dejavu

	elif command -v apt-get >/dev/null 2>&1; then
		as_root apt-get update
		as_root apt-get install -y \
			i3-wm polybar picom rofi kitty feh xfce4-screenshooter \
			dex xss-lock i3lock dunst python3-pil \
			network-manager-gnome network-manager \
			iproute2 x11-xkb-utils x11-xserver-utils fonts-dejavu-core

	elif command -v dnf >/dev/null 2>&1; then
		as_root dnf install -y \
			i3 polybar picom rofi kitty feh xfce4-screenshooter \
			dex xss-lock i3lock dunst python3-pillow \
			network-manager-applet NetworkManager \
			iproute xorg-x11-xkb-utils xorg-x11-server-utils \
			dejavu-sans-mono-fonts

	elif command -v emerge >/dev/null 2>&1; then
		# Gentoo: USE flags for polybar/picom are your responsibility.
		as_root emerge --ask=n --noreplace \
			x11-wm/i3 x11-misc/polybar x11-misc/picom x11-misc/rofi \
			x11-terms/kitty media-gfx/feh xfce-extra/xfce4-screenshooter \
			x11-misc/dex x11-misc/xss-lock x11-misc/i3lock \
			x11-misc/dunst dev-python/pillow \
			gnome-extra/nm-applet net-misc/networkmanager \
			sys-apps/iproute2 x11-apps/setxkbmap x11-apps/xrandr \
			media-fonts/dejavu

	else
		echo "!! No supported package manager found." >&2
		echo "   Install these manually: i3 polybar picom rofi kitty feh" >&2
		echo "   xfce4-screenshooter dex xss-lock i3lock dunst nm-applet" >&2
		echo "   networkmanager iproute2 setxkbmap xrandr dejavu fonts" >&2
		echo "   python3-pillow (optional, for wallpaper previews)" >&2
		return 1
	fi
}

link() {
	local src="$1" dest="$2"
	mkdir -p "$(dirname "$dest")"

	if [[ -L "$dest" ]]; then
		rm -f "$dest"
	elif [[ -e "$dest" ]]; then
		mkdir -p "$BACKUP_DIR"
		mv "$dest" "$BACKUP_DIR/"
		echo "    backed up $dest"
	fi

	ln -s "$src" "$dest"
	echo "    $dest -> $src"
}

install_wallpapers() {
	local src="$DOTS/wallpapers"
	local f dest copied=0

	mkdir -p "$WALL_DIR"
	[[ -d "$src" ]] || return 0

	for f in "$src"/*; do
		[[ -f "$f" ]] || continue
		dest="$WALL_DIR/$(basename "$f")"
		[[ -e "$dest" ]] && continue
		cp -p "$f" "$dest"
		copied=$((copied + 1))
	done

	if ((copied > 0)); then
		echo "    copied $copied wallpaper(s) to $WALL_DIR"
	fi
}

link_configs() {
	echo "==> Linking configs"
	link "$DOTS/i3" "$CONFIG_DIR/i3"
	link "$DOTS/polybar" "$CONFIG_DIR/polybar"
	link "$DOTS/picom" "$CONFIG_DIR/picom"
	link "$DOTS/rofi" "$CONFIG_DIR/rofi"
	link "$DOTS/dunst" "$CONFIG_DIR/dunst"
	link "$DOTS/i3/scripts/wallpaper.sh" "$BIN_DIR/wallpaper"

	echo "==> Setting permissions"
	chmod +x "$DOTS/install.sh" \
		"$DOTS/i3/scripts/"*.sh \
		"$DOTS/polybar/launch.sh" \
		"$DOTS/polybar/scripts/"*.sh

	echo "==> Installing wallpapers"
	install_wallpapers
	[[ -f "$DOTS/polybar/theme.ini" ]] || cp "$DOTS/polybar/themes/gray.ini" "$DOTS/polybar/theme.ini"

	if [[ -n "$BACKUP_DIR" && -d "$BACKUP_DIR" ]]; then
		echo "==> Old configs saved in $BACKUP_DIR"
	fi
}

check_missing() {
	local missing=()
	local cmd
	for cmd in i3 polybar picom rofi kitty feh xfce4-screenshooter dex \
		xss-lock i3lock nm-applet setxkbmap pactl nmcli ip; do
		command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
	done

	if ((${#missing[@]} > 0)); then
		echo "!! Missing commands: ${missing[*]}" >&2
		echo "   Run ./install.sh without --no-deps, or install them manually." >&2
	fi
}

if ((WITH_DEPS)); then
	install_deps
fi

if ((DEPS_ONLY)); then
	exit 0
fi

link_configs
check_missing

cat <<EOF

Done.

Next steps:
  i3-msg reload        # or press Alt+Shift+C
  polybar              # restart the bar (installer already linked it)

Themes:      ~/i3dots/polybar/themes  (10 themes)
Switch:      Alt+Shift+T, or: polybar/scripts/theme.sh <name>
Wallpapers:  ~/Pictures/wall (copied from ~/i3dots/wallpapers)
Pick one:    Alt+Shift+W (random), or run: wallpaper
EOF
