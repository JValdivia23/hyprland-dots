# Current State — 2026-11-08

## Operating System

```
OS: CachyOS Linux (Arch-based)
Kernel: 7.3.3-1-cachyos
Init: systemd
Session: Wayland (Hyprland)
Shell: /usr/bin/zsh
```

## Desktop Environment

```
WM: Hyprland 0.57.1 (Native Lua modular configuration via hyprland-dots profiles/desktop)
Display Manager: SDDM (standard login screen)
Bar/Launcher: Quickshell 0.3.2 (desktop / palette-only mode)
  Config: ~/.config/quickshell/
  Cache: /run/user/1000/quickshell/
Terminal: Alacritty 0.17.0, Ghostty 1.4.0-1.1
Notifications: Mako
Idle daemon: Hypridle
Lock screen: Hyprlock
```

## Key Packages

| Package | Version | Purpose |
|---------|---------|---------|
| hyprland | 0.57.1-1.1 | Window manager (Native Lua) |
| quickshell | 0.3.2-1.1 | Bar + palette launcher |
| alacritty | 0.17.0 | Terminal emulator |
| ghostty | 1.4.0-1.1 | Terminal emulator (with Kitty graphics support) |
| google-chrome | 155.0.8059.84-1 | Browser |
| zen-browser | 1.23.3b-1 | Browser (Zen Browser) |
| firefox | 158.0.1-1 | Browser (fallback) |
| zed | 1.24.4-1 | Code editor |
| paru | 2.1.0-3 | Package management |
| plymouth | 26.134.222-2.1 | Graphical boot splash screen |
| grim | 1.5.0-2.1 | Wayland screenshots |
| slurp | 1.5.0-2.1 | Region selection |
| tesseract | 5.5.3-1.1 | OCR engine |
| wl-clipboard | 1:2.3.0-1.1 | Wayland clipboard |
| jq | 1.8.2-1.1 | JSON processor |
| tesseract-data-eng | — | English OCR language |
| tesseract-data-spa | — | Spanish OCR language |
| pamixer | 1.6-4.2 | Audio control |
| brightnessctl | 0.5.1-3 | Brightness control |

## Installed via AUR / Manual

| Package | Source | Purpose |
|---------|--------|---------|
| upscayl-desktop-git | Chaotic-AUR | AI image upscaler desktop GUI |
| upscayl-ncnn | Chaotic-AUR | AI image upscaler CLI engine |
| whisper.cpp (whisper-cli) | Built from source | Voice dictation |
| ggml-base.bin | ~/.cache/whisper-models/ | Whisper model (148 MB) |
| hyprresume | AUR | Session persistence |
| google-chrome | AUR (paru -S --aur) | Browser |
| elephant-all-bin | AUR | Walker data providers |

## Omarchy Fork

```
Repo: https://github.com/lentra0/omarchy-cachyos.git
Path: ~/.local/share/omarchy/
Current: CachyOS fork, ~1 year behind upstream Hyprland
Last commit: 41f7de5 "Update aur.sh"
```

## Display

```
Primary Monitor: KTC A32Q8
Resolution: 3840x2160 @ 60Hz
Connection: DP-1 (DisplayPort)
Scale: 1.67 (fractional scaling)

Secondary Monitor (Left): KTC Q24T09
Resolution: 2560x1440 @ 120Hz
Connection: HDMI-A-1 (HDMI)
Scale: 1.33 (fractional scaling, ~1920x1080 logical)

Config: ~/.config/hypr/monitors.conf
```

## Input

```
Keyboard layout: us (primary), es (secondary via script)
Keyboard: Attack Shark X85 (USB, SONiX chip, 5 HID interfaces)
Mouse: Logitech G903 LIGHTSPEED (wireless)
Battery path: /sys/class/power_supply/hidpp_battery_0
XRemap: ~/.config/xremap/config.yml (CapsLock remapping)
```

## Audio & Voice

```
Dictation: whisper.cpp (~/.local/bin/whisper-cli)
Model: ggml-base.bin (~/.cache/whisper-models/, 148 MB)
Dictation script: ~/.local/bin/hypr-dictate
Toggle bind: SUPER+Ctrl+X
Push-to-talk: F9
TTS: MOSS-TTS-Nano (~/dev/tts/MOSS-TTS-Nano/)
Voice: Clairy (bilingual EN/ES)
```

## Quickshell Palette

```
Launch: SUPER+Space → OmniMenu palette
Quick tiles: SUPER+Shift+Space → 4x3 grid
App backup: SUPER+D → wofi --show drun
Refresh command: "Refresh Quickshell" .desktop entry or:
  pkill -9 qs; rm -rf /run/user/1000/quickshell; qs -n -d -c palette-only &
```

## System Services (user)

```
quickshell (palette-only): runs as user process
hypridle: idle management
hyprlock: screen lock
whisper dictation: on-demand (not a service)
OCR: on-demand (not a service)
```

## Environment Variables

Key env vars (from `~/.config/hypr/envs.conf`):
- `XCURSOR_THEME=breeze_cursors`
- `HYPRCURSOR_THEME=breeze_cursors`
- `QT_ACCESSIBILITY=1`
- `RADV_PERFTEST=gpl,nggc,sam`
- `mesa_glthread=true`

## Network

```
SSH to MacBook: ssh clairy@10.0.0.39 (key auth)
SSH to CUdesk: ssh CUdesk (ProxyJump login.rc.colorado.edu)
Chaotic-aur repo: enabled (/etc/pacman.conf)
```
