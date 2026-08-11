# Current System State

Live system snapshot (OS, package versions, hardware configuration). Updated automatically via `scripts/snapshot.sh`.

## Operating System & Kernel
- **OS**: CachyOS Linux (Arch-based rolling release)
- **Kernel**: `7.1.3-2-cachyos`
- **Shell**: `/bin/fish` (Fish Shell)
- **Wayland Window Manager**: Hyprland 0.55.4 (built from branch v0.55.4)
- **Wayland Shell / Panel**: Noctalia 5.0.0_beta.3-2 (Wayland native bar & panel)

## System Specs & Display
- **CPU**: AMD Ryzen 9 4900HS with Radeon Graphics
- **GPU**:
  - NVIDIA Corporation TU106M [GeForce RTX 2060 Max-Q] (rev a1)
  - AMD Renoir [Radeon Vega Series / Radeon Vega Mobile Series] (rev c5)
- **RAM**: 22Gi
- **Display Output**:
  - `eDP-1` (Internal Monitor, 2560x1440@60Hz, scale 1.33)
- **Disk Usage**:
  - `/` and `/home`: nvme0n1p7 (~9.4 GB used, 222 GB free)

## Key Installed Packages & Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| hyprland | 0.56.0-2.1 | Window Manager |
| noctalia | 5.0.0_beta.3-2 | Status bar & menus (launcher, clipboard, etc.) |
| kitty | 0.48.0-1.1 | Default Terminal emulator |
| alacritty | 0.17.0-1.2 | Alternative Terminal emulator |
| zen-browser | 1.21.8b-1 | Primary web browser |
| firefox | 152.0.6-1 | Alternative web browser |
| grim | 1.5.0-2.1 | Wayland screenshot tool |
| slurp | 1.5.0-2.1 | Region selection tool |
| satty | 0.21.1-1.1 | Screenshot editor/viewer & Default Image Viewer |
| swayimg | 5.4-2.1 | Lightweight Wayland image viewer & Quick Look engine |
| jq | 1.8.2-1.1 | JSON processor |
| wl-clipboard | 1:2.3.0-1.1 | Clipboard controller |
| brightnessctl | 0.5.1-3 | Backlight controls |
| btop | 1.4.7-1.1 | Resource monitor |
| dolphin | 26.04.3-1.1 | File manager |
| neovim | 0.12.4 | Modal text editor (LazyVim base) |
| lazygit | 0.63.1 | Git TUI client |
| supergfxctl | 5.2.7-2 | GPU mode switcher for ASUS ROG |
| asusctl | 6.3.10-1 | ASUS ROG hardware & fan daemon |
| rog-control-center | 6.3.10-1 | GUI dashboard for asusctl & supergfxctl |
| localsend | 1.17.0-4 | Cross-platform local network file sharing |

## Active Helper Scripts (`~/.local/bin/`)
- `mac-key-helper`: Active window classifier for macOS shortcuts.
- `hypr-window-pop`: Window pop-out and workspace pinning (`SUPER+O`).
- `hypr-toggle-altwin`: On-the-fly Super/Alt position toggle (`SUPER+ALT+K`).
- `anime-lid-charging`: Automated lid-closed AC battery percentage & charging matrix daemon.

## Active Errors & Warnings
- **Hyprland Errors**: None

