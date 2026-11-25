# i3dots

A small, minimal **i3 + polybar + picom** desktop setup for X11 (not Wayland),
with 10 polybar themes, an automatic wallpaper switcher, and a one-command
installer that also handles dependencies.

It is meant to be readable and hackable: no compositor tricks, no icon fonts,
no pywal — just a clean bar, 10px gaps, and a few shell scripts.

---

## Contents

- [What you get](#what-you-get)
- [Requirements](#requirements)
- [Install](#install)
- [Supported distros](#supported-distros)
- [First run](#first-run)
- [Keybindings](#keybindings)
- [Polybar](#polybar)
- [Themes](#themes)
- [Wallpapers](#wallpapers)
- [Repository layout](#repository-layout)
- [Customizing](#customizing)
- [Troubleshooting](#troubleshooting)
- [Uninstall](#uninstall)

---

## What you get

- **i3** — tiling window manager, `Alt` as the modifier, 10px inner gaps.
- **polybar** — one slim 26px bar with workspaces, clock, network, volume,
  battery and a system tray.
- **picom** — window compositor (shadows/fading/transparency) with a sensible
  config already included.
- **10 polybar themes** — `gray`, `white`, `black`, `nord`, `gruvbox`,
  `dracula`, `catppuccin`, `solarized`, `rose-pine`, `everforest`.
- **Wallpaper switcher** — rofi picker, random mode, remembers the last image
  and restores it at login.
- **Installer** — detects your distro, installs packages with `sudo` / `doas` /
  `run0`, backs up old configs, and symlinks everything into place.

The configs work on any distro with X11; only the package installation is
distro-specific.

---

## Requirements

You need a working **X11 session** (Xorg). This setup does **not** work on
Wayland, because i3, polybar and picom are all X11 programs.

Packages used by the configs:

| Purpose | Packages |
| --- | --- |
| Window manager | `i3` |
| Bar | `polybar` |
| Compositor | `picom` |
| Launcher | `rofi` |
| Terminal | `kitty` |
| Wallpaper | `feh` or `xwallpaper` |
| Screenshots | `xfce4-screenshooter` |
| Session helpers | `dex`, `xss-lock`, `i3lock` |
| Network tray | `nm-applet` (NetworkManager) |
| Keyboard layout | `setxkbmap` |
| Volume | `pactl` (PulseAudio or PipeWire's pulse layer) |
| Font | DejaVu Sans Mono |

`install.sh` installs all of the above for your distro. If it can't detect your
package manager, see [Supported distros](#supported-distros).

---

## Install

```sh
git clone <this-repo> ~/i3dots     # or copy the folder to ~/i3dots
cd ~/i3dots
./install.sh
```

The installer will:

1. Detect your package manager and install missing dependencies.
2. Move existing configs to `~/.dotfiles-backup-<date>/`.
3. Symlink the configs:

   | From | To |
   | --- | --- |
   | `i3/` | `~/.config/i3` |
   | `polybar/` | `~/.config/polybar` |
   | `picom/` | `~/.config/picom` |
   | `i3/scripts/wallpaper.sh` | `~/.local/bin/wallpaper` |
   | `wallpapers/*` | `~/Pictures/wall/` (copied, not symlinked) |

4. Makes the shell scripts executable.
5. Creates the default theme (`gray`) on first run.

Because the configs are **symlinked**, editing `~/.config/i3/config` edits
`~/i3dots/i3/config` and vice versa. That makes the repo your live config.

### Installer options

```sh
./install.sh              # install packages + link configs
./install.sh --no-deps    # link configs only
./install.sh --deps-only  # install packages only
./install.sh --help
```

### Privilege escalation

Root commands are run with the first tool that works, in this order:

1. `sudo`
2. `doas`
3. `run0`

If you are already root, none is used. If none of them work, run the installer
as root or install one of them. This is why the installer also works on Gentoo
systems that only have `doas`.

---

## Supported distros

`install.sh` auto-detects these package managers:

| Distro family | Package manager | Status |
| --- | --- | --- |
| Arch, EndeavourOS, CachyOS, Manjaro… | `pacman` | Supported |
| Debian, Ubuntu, Mint, Pop!_OS, Kali… | `apt-get` | Supported |
| Fedora, Nobara, RHEL-like with `dnf` | `dnf` | Supported |
| Gentoo, Funtoo | `emerge` | Supported, see note below |

**Gentoo note:** polybar and picom need the correct USE flags (X, i3,
pulseaudio, etc.). The installer only runs `emerge --noreplace`; setting USE
flags is up to you in `/etc/portage/package.use`.

**Other distros** (openSUSE, Void, Alpine, NixOS, Slackware…): the installer
stops and prints the list of packages to install manually. After installing
them, run `./install.sh --no-deps` to link the configs.

---

## First run

After `./install.sh`:

```sh
i3-msg reload        # or press Alt+Shift+C inside i3
```

If i3 isn't running yet, log out and choose i3 as your session in your display
manager (or start it from a TTY with `startx` after configuring `~/.xinitrc`).

The wallpaper is restored on login. If `~/Pictures/wall` is empty, set one:

```sh
wallpaper --random
```

Add `exec i3` to `~/.xinitrc` if you start X manually.

---

## Keybindings

The modifier is **Alt**. (`Mod1`; change `set $mod` if you prefer Super/Win.)

### Applications

| Keys | Action |
| --- | --- |
| `Alt+Enter` | Terminal (`kitty`) |
| `Alt+D` | App launcher (`rofi -show drun`) |
| `Alt+Q` | Close focused window |
| `Print` | Screenshot menu |
| `Shift+Print` | Screenshot a region |

### Focus and moving windows

| Keys | Action |
| --- | --- |
| `Alt+J` / `Alt+K` / `Alt+L` / `Alt+;` | Focus left / down / up / right |
| `Alt+←` / `Alt+↓` / `Alt+↑` / `Alt+→` | Same, with arrow keys |
| `Alt+Shift+J/K/L/;` | Move window left / down / up / right |
| `Alt+Shift+←/↓/↑/→` | Same, with arrow keys |
| `Alt+A` | Focus parent container |
| `Alt+Space` | Toggle focus between tiling and floating |

### Layout

| Keys | Action |
| --- | --- |
| `Alt+H` | Split horizontally |
| `Alt+V` | Split vertically |
| `Alt+F` | Toggle fullscreen |
| `Alt+S` | Stacking layout |
| `Alt+W` | Tabbed layout |
| `Alt+E` | Toggle split layout |
| `Alt+Shift+S` | Toggle floating |
| `Alt+R` | Enter resize mode |

### Resize mode

Enter with `Alt+R`. Use `J` / `K` / `L` / `;` or the arrow keys to resize.
Press `Enter`, `Escape`, or `Alt+R` to leave.

### Workspaces

| Keys | Action |
| --- | --- |
| `Alt+1` … `Alt+9`, `Alt+0` | Switch to workspace 1…10 |
| `Alt+Shift+1` … `Alt+Shift+0` | Move window to workspace 1…10 |

### Session and extras

| Keys | Action |
| --- | --- |
| `Alt+Shift+C` | Reload i3 config |
| `Alt+Shift+R` | Restart i3 (keeps layout) |
| `Alt+Shift+E` | Exit i3 (with confirmation) |
| `Alt+Shift+W` | Random wallpaper |
| `Alt+Shift+T` | Polybar theme picker |
| `Alt+Shift+M` / `Alt+Shift+N` | Volume up / down |
| `XF86AudioRaiseVolume` / `LowerVolume` | Volume keys |
| `XF86AudioMute` / `XF86AudioMicMute` | Mute speaker / microphone |

Mouse: hold `Alt` and drag a window to move it.

---

## Polybar

The bar is intentionally minimal and icon-free:

- **Left:** i3 workspaces (focused has an accent underline)
- **Center:** time; **click it** to toggle the date
- **Right:** network, volume, battery, system tray
  - Network: prints the Wi-Fi SSID, interface name, or `offline`
  - Volume: **scroll** to change volume, **left-click** to mute
  - Battery: shows `82%`, or `82% +` while charging; hidden if there is no battery

The network and battery modules use small scripts, so the same config works on
laptops and desktops without editing.

Files:

```
polybar/
├── config.ini          # bar + module definitions
├── launch.sh           # starts one bar per monitor
├── theme.ini           # current theme (included by config.ini)
├── scripts/
│   ├── battery.sh      # auto-detects the battery
│   ├── network.sh      # auto-detects the active interface
│   └── theme.sh        # theme switcher
└── themes/             # 10 themes
```

Reload after manual edits:

```sh
~/.config/polybar/launch.sh
```

### Tray

`tray-position = right` is enabled, so NetworkManager's `nm-applet` has
somewhere to live. If you don't use a tray, set `tray-position = none` in
`polybar/config.ini`.

---

## Themes

Available themes:

| Name | Look |
| --- | --- |
| `gray` | Neutral dark (default) |
| `white` | Light background |
| `black` | Pure black |
| `nord` | Cool blue/gray |
| `gruvbox` | Warm retro |
| `dracula` | Purple/pink dark |
| `catppuccin` | Soft pastel dark |
| `solarized` | Solarized dark |
| `rose-pine` | Muted purple dark |
| `everforest` | Green/forest dark |

Switch themes:

```sh
~/.config/polybar/scripts/theme.sh nord
```

Or press `Alt+Shift+T` for a rofi menu.

Each theme is a tiny file in `polybar/themes/`:

```ini
[color]
background = #1c1c1c
foreground = #d0d0d0
background-alt = #2a2a2a
primary = #b8b8b8
muted = #7a7a7a
urgent = #e06c75
```

Switching copies the chosen theme to `polybar/theme.ini`, which
`polybar/config.ini` includes. To make your own theme, copy one of these files,
change the colors, and run `theme.sh <your-theme>`.

---

## Wallpapers

Wallpapers live in **`~/Pictures/wall`**. The installer copies everything from
`~/i3dots/wallpapers/` there, skipping files that already exist.

Usage:

```sh
wallpaper             # pick with rofi
wallpaper --random    # random image (also Alt+Shift+W)
wallpaper --set FILE  # use a specific image
wallpaper --restore   # restore the last one (used at login)
wallpaper --dir DIR   # pick from another directory
```

The last wallpaper is saved in `~/.cache/wallpaper`. At login, i3 runs
`wallpaper --restore`, which falls back to a random image if the cached file is
gone.

Supported formats: jpg, jpeg, png, webp, bmp. It uses `feh` if available and
falls back to `xwallpaper`. Override the directory with:

```sh
WALLPAPER_DIR=~/somewhere wallpaper --random
```

To sync new wallpapers into the repo so a fresh install has them:

```sh
cp ~/Pictures/wall/* ~/i3dots/wallpapers/
```

---

## Repository layout

```
i3dots/
├── install.sh                  # installer
├── README.md
├── i3/
│   ├── config                  # i3 window manager config
│   └── scripts/
│       └── wallpaper.sh        # wallpaper switcher
├── picom/
│   └── picom.conf              # compositor config
├── polybar/
│   ├── config.ini
│   ├── launch.sh
│   ├── theme.ini               # active theme
│   ├── scripts/
│   │   ├── battery.sh
│   │   ├── network.sh
│   │   └── theme.sh
│   └── themes/                 # 10 color themes
└── wallpapers/                 # wallpapers copied to ~/Pictures/wall
```

---

## Customizing

Some common edits:

- **Change the modifier** — in `i3/config`, replace `set $mod Mod1` with
  `set $mod Mod4` to use the Windows/Super key.
- **Gaps** — `gaps inner 10` and `gaps outer 5` in `i3/config`.
- **Bar height/font** — `height` and `font-0` in `polybar/config.ini`.
- **Bar contents** — `modules-left`, `modules-center`, `modules-right` in
  `polybar/config.ini`.
- **Keyboard layout** — the line
  `setxkbmap -layout us,ru -option 'grp:win_space_toggle'` in `i3/config`.
- **Autostart programs** — the `exec` lines at the top of `i3/config`.
- **Add a theme** — copy a file from `polybar/themes/`, edit the colors.
- **Add wallpapers** — drop images in `~/Pictures/wall` (and optionally
  `~/i3dots/wallpapers/` to keep them in the repo).

After editing i3: `Alt+Shift+C`. After editing polybar:
`~/.config/polybar/launch.sh`.

---

## Troubleshooting

**Polybar doesn't start.**
Run it in the foreground to see the error:

```sh
polybar main -c ~/.config/polybar/config.ini
```

A common cause is a missing theme file; run
`~/.config/polybar/scripts/theme.sh gray`.

**No tray icons / NetworkManager icon.**
`nm-applet` must be running (`exec --no-startup-id nm-applet`). Make sure
NetworkManager is enabled and `tray-position` isn't `none`.

**The theme picker is empty.**
`polybar/themes/*.ini` is missing, or rofi isn't installed.

**Wallpaper doesn't change.**
Make sure `feh` or `xwallpaper` is installed, and that `~/Pictures/wall`
contains images.

**No battery shown.**
There is no battery in `/sys/class/power_supply` (desktop or VM), or the
battery name is unusual. The module hides itself when it can't find one.

**No network shown.**
The script needs the `ip` command (iproute2). Wi-Fi names also need `nmcli`.

**Volume keys do nothing.**
`pactl` must be installed and an audio server (PulseAudio/PipeWire) running.

**Screenshots fail.**
Install `xfce4-screenshooter`.

**Icons/symbols look wrong.**
There are intentionally no icon fonts; only DejaVu Sans Mono is used. Install
`ttf-dejavu`/`fonts-dejavu` if text looks broken.

**I'm on Wayland.**
This setup is X11-only. Use an Xorg session, or look for Wayland equivalents
(sway, waybar, etc.).

---

## Uninstall

```sh
rm ~/.config/i3 ~/.config/polybar ~/.config/picom ~/.local/bin/wallpaper
```

Then restore your old configs from the newest `~/.dotfiles-backup-*` directory:

```sh
ls -d ~/.dotfiles-backup-*        # find the backup
mv ~/.dotfiles-backup-<date>/i3 ~/.config/i3
mv ~/.dotfiles-backup-<date>/polybar ~/.config/polybar
mv ~/.dotfiles-backup-<date>/picom ~/.config/picom
```

Wallpapers in `~/Pictures/wall` and the `~/i3dots` folder are not removed.

---

## Notes

- Everything is X11; there is no Wayland support.
- The configs assume a US/RU keyboard layout toggle on `Super+Space`; edit the
  `setxkbmap` line if that's not you.
- Tested on Gentoo with i3 4.25, polybar, picom and rofi.
- No icon fonts, no pywal, no external theme engine — just shell, polybar and
  plain text.
