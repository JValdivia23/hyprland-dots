# Current System State

Live system snapshot (OS, package versions, hardware configuration). Refreshable via `scripts/snapshot.sh`.

## Operating System & Compositor
- **OS**: CachyOS Linux (Arch-based rolling release)
- **Kernel**: `7.2.3-1-cachyos` (active) / `6.18.48-1-cachyos-lts` (LTS fallback)
- **Shell**: `/bin/fish` (Fish 4.9.2)
- **Compositor**: Hyprland 0.56.2-2.1 (Lua-based modular configuration)
- **Wayland Shell / Panel**: Noctalia 5.0.1-1.1 (Wayland native bar & panel)

## System & Display
- **Hardware**: Apple MacBook Pro 15,1 (`MacBookPro15,1`)
- **CPU**: Intel Core i9-9880H (8 Cores, 16 Threads @ 2.30 GHz, boost to 4.80 GHz)
- **GPU**: AMD Radeon Pro 560X (Baffin / Polaris 11, `amdgpu` driver)
- **RAM**: 16 GiB (15.5 GiB usable) + 15.5 GiB zram swap
- **Display Output**: `eDP-1` (Apple Retina 2880x1800 @ 60Hz, scale 1.33)
- **Disk Usage**:
  - `/` and `/home`: `/dev/nvme0n1p4` (229 GB Btrfs, ~25 GB used)
  - `/boot`: `/dev/nvme0n1p3` (4.0 GB vfat, 796 MB used)

## Key Installed Packages & Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| `hyprland` | 0.56.2-2.1 | Window Manager / Wayland Compositor |
| `noctalia` | 5.0.1-1.1 | Status bar, launcher, session & quick settings |
| `kitty` | 0.48.2-1.1 | Default Terminal emulator |
| `alacritty` | 0.17.0-1.2 | Alternative Terminal emulator |
| `zen-browser-bin` | 1.22b-1 | Primary web browser |
| `firefox` | 155.0.1-1 | Alternative web browser |
| `brave-origin-bin` | 1:1.94.121-1 | WebApps engine & browser |
| `mesa` | 3:26.2.1-1 | 3D graphics library & OpenGL drivers |
| `vulkan-radeon` | 3:26.2.1-1 | Vulkan driver for AMD Radeon Pro 560X (RADV) |
| `opencl-mesa` | 3:26.2.1-1 | OpenCL Gallium compute drivers |
| `grim` | 1.5.0-2.1 | Wayland screenshot tool |
| `slurp` | 1.5.0-2.1 | Region selection tool |
| `satty` | 0.22.0-1.1 | Screenshot editor/viewer & default image viewer |
| `swayimg` | 5.6-1.1 | Lightweight Wayland image viewer & Quick Look engine |
| `waypaper` | 2.8-1 | Wallpaper selector & rotation GUI |
| `btop` | 1.4.7-1.1 | Terminal resource monitor |
| `dolphin` | 26.08.0-5.1 | Graphical file manager |
| `neovim` | 0.12.4-1.1 | Modal text editor (LazyVim base) |
| `lazygit` | 0.65.0-1.1 | Git TUI client |
| `localsend` | 1.17.0-4 | Cross-platform local network file sharing |
| `easyeffects` | 8.2.8-1.1 | Audio DSP processor & speaker equalizer daemon |
| `lsp-plugins-lv2` | 1.2.33-2.1 | LV2 studio audio plugins (multiband compressor, limiter, EQ) |
| `calf` | 0.90.9-2.1 | LV2 audio effects suite (bass enhancer) |
| `wl-clipboard` | 2.3.0-1.1 | Wayland clipboard manager |
| `brightnessctl` | 0.5.1-3 | Backlight control utility |
| `libva-utils` | 2.24.0-1.1 | VA-API diagnostic tools (`vainfo`) |
| `vulkan-tools` | 1.4.357.0-1.1 | Vulkan diagnostic utilities (`vulkaninfo`) |
| `jq` | 1.8.2-1.1 | Command-line JSON processor |

## Active Hardware & Power Daemons
- `t2fanrd.service`: Custom exponential thermal curve daemon for Intel Core i9-9880H (`/etc/t2fand.conf`, active).
- `tiny-dfr.service`: Touch Bar dynamic function row daemon with `EnablePixelShift = true` (OLED protection, active).
- `t2-touchbar-setup.service`: Cycles USB configuration `0 -> 2` and initializes `appletbdrm` DRM display node on system boot (active).
- `suspend-fix-t2.service`: Automatic PCIe sleep & wakeup handler for T2 security chip (`t2-sleep-helper`, active).
- `amdgpu-power-switch.sh`: Dynamic GPU PowerPlay profile, PCIe ASPM (`powersupersave`), and Intel Turbo Boost (`no_turbo`) power switcher for Battery vs AC.
- **Audio Routing**: Native PipeWire + WirePlumber routing directly to `Apple Audio Device Speakers` (`alsa_output.pci-0000_02_00.3.Speakers`).

## Active Helper Scripts (`~/.local/bin/`)
- `mac-key-helper`: Active window classifier for macOS shortcuts.
- `hypr-window-pop`: Window pop-out and workspace pinning (`SUPER+O` / `SUPER+SHIFT+O`).
- `hypr-toggle-altwin`: Dynamic Super/Alt layout swap toggle (`SUPER+ALT+K`).
- `hypr-quicklook`: macOS-style Quick Look image/file overlay preview (`ALT+Return`).
- `hypr-kbd-brightness`: Keyboard backlight step adjuster with Noctalia native OSD (`Fn + Up / Down`).
- `hypr-screen-brightness`: Display brightness adjuster with Noctalia native OSD (`BrightnessUp / Down`).
- `hypr-lid-handler`: Clamshell & ultra-low power lid close/open event handler (`switch:on/off:Lid Switch`).
- `fastfetch-custom`: Compact, two-column system info banner for Fish shell startup.

## Active Errors & Warnings
- **Hyprland Errors**: None (Clean)


