Created by Kangy w/ OpenCode AI Assistance
Version: 1.0.0-20260604

# caelestia-niri-shell — Dependencies

## Runtime

| Package | Source | Notes |
|---------|--------|-------|
| `niri` | official | Compositor |
| `quickshell` | AUR | QML shell runtime (provides `Quickshell.*` modules) |
| `python` | official | Script runner (≥3.12) |
| `fish` | official | Default shell |
| `kitty` | official | Default terminal |

## Qt / QML

| Package | Provides |
|---------|----------|
| `qt6-declarative` | QtQuick, QtQuick.Controls, QtQuick.Layouts, QtQuick.Shapes |
| `qt6-quickeffectmaker` | QtQuick.Effects |
| `qt6-multimedia-ffmpeg` | QtMultimedia video playback for wallpapers |
| `qt6-svg` | SVG icon rendering |
| `qt6-tools` | `qdbus` |

## C++ Plugin (`plugin/`)

Build-time:

`base-devel` `cmake` `clang` `ninja` `git` `qt6-base` `qt6-declarative` `qt6-shadertools` `libpipewire` `libqalculate` `aubio` `libcava-git` (AUR)

Linked at runtime:

| Library | Provides |
|---------|----------|
| Qt6::Core, Qml, Gui, Quick, Concurrent, Multimedia, Network, Sql, DBus | Qt6 modules |
| libpipewire-0.3 | Audio visualiser data |
| libqalculate | Calculator engine |
| aubio | Beat detection |
| libcava | Audio visualiser (AUR: `libcava-git`) |

## Official Repos (pacman)

### Core CLI tools
`bc` `coreutils` `curl` `wget` `jq` `ripgrep` `rsync` `xdg-user-dirs` `glib2` `gawk`

### Audio
`pipewire` `wireplumber` `pipewire-pulse` `pavucontrol-qt` `playerctl`

### Hardware / brightness
`brightnessctl` `ddcutil` `upower`

### Networking
`networkmanager` `networkmanager-qt` `nm-connection-editor` `wireguard-tools`

### Screenshot / recording
`grim` `slurp` `swappy` `wf-recorder` `tesseract` `tesseract-data-eng`

### Screen lock / idle
`hypridle` `hyprlock` `hyprpicker`

### Input simulation
`wtype` `ydotool`

### Desktop portals
`xdg-desktop-portal` `xdg-desktop-portal-kde` `xdg-desktop-portal-gtk`

### KDE integration
`bluedevil` `breeze` `breeze-plus` (AUR) `dolphin` `systemsettings`
`polkit-kde-agent` `plasma-nm` `gnome-keyring`

### Terminal / shell
`kitty` `fish` `starship` `eza` `fontconfig` `fuzzel`

### Misc
`cava` `libdbusmenu-gtk3` `imagemagick` `translate-shell` `libqalculate`
`cliphist` `gtk4` `libadwaita` `libsoup3` `libportal-gtk4` `gobject-introspection`

### Display manager
`sddm`

## AUR Packages

| Package | Purpose |
|---------|---------|
| `matugen` | Material You colour generation from images |
| `hyprshot` | Screenshot tool |
| `uv` | Python venv / package manager |
| `adw-gtk-theme-git` | GTK4/libadwaita theme |
| `darkly-bin` | KDE Qt widget style |
| `ttf-jetbrains-mono-nerd` | Terminal / UI monospace font |
| `ttf-material-symbols-variable-git` | Primary icon font (QML `material` family) |
| `ttf-readex-pro` | UI sans-serif font |
| `ttf-rubik-vf` | UI sans-serif font |
| `ttf-twemoji` | Emoji font |
| `otf-space-grotesk` | Display font |
| `bibata-cursor-theme-bin` | Cursor theme |
| `whitesur-icon-theme` | Icon theme |
| `papirus-icon-theme` | Application icons |
| `libcava-git` | C library for audio visualiser |
| `python-materialyoucolor` | Python colour library (or via venv) |
| `Colloid-kde` | Kvantum theme (clone from GitHub, not packaged) |

## Python Packages (via `uv` venv)

| Package | Used In |
|---------|---------|
| `pillow` | `generate_colors_material.py` |
| `materialyoucolor` | `generate_colors_material.py` |
| `opencv-python` `numpy` | `scheme_for_image.py` |
| `dbus-python` | `patched-kmyc.py` |
| `requests` | `wallhaven/*.py`, `uhdpaper/*.py` |

These are installed into `$XDG_STATE_HOME/quickshell/.venv` by `setup.sh`.

## Fonts

| Font | Package | QML Family |
|------|---------|------------|
| JetBrains Mono Nerd | `ttf-jetbrains-mono-nerd` | `mono` |
| Material Symbols Variable | `ttf-material-symbols-variable-git` | `material` |
| Readex Pro | `ttf-readex-pro` | `sans` |
| Rubik | `ttf-rubik-vf` | `sans` |
| Space Grotesk | `otf-space-grotesk` | `clock` |
| Twemoji | `ttf-twemoji` | emoji fallback |
| Noto Emoji | `noto-fonts-emoji` | emoji fallback |

## Runtime Groups

User must be in `video`, `i2c`, `input` groups for hardware access (backlight, DDC/CI monitors, input simulation).
