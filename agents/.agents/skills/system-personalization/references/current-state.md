# Current System State

Live system snapshot automatically generated on Fri Oct 09 05:31:42 PM MDT 2026.

## Operating System & Kernel
- **OS**: CachyOS
- **Kernel**: `7.2.9-1-cachyos` (active & verified; unpinned in `/etc/pacman.conf`)
- **Shell**: `/bin/fish` (fish, version 4.9.3)
- **Compositor**: Hyprland 0.56.2 (package: `0.56.2-4.1`)
- **Active Profiles**: macbook-t2

## System Specs & Display
- **Product**: MacBookPro15,1 (`cachyos-cu`)
- **CPU**: Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz
- **GPU**: Advanced Micro Devices, Inc. [AMD/ATI] Baffin [Radeon RX 460/560D / Pro 450/455/460/555/555X/560/560X] / Apple Inc. T2 Bridge Controller
- **RAM**: 15Gi RAM, 15Gi swap
- **Primary Display**: eDP-1 (2880x1800@60Hz, scale 1.3333334)

## Key Installed Packages & Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| hyprland | 0.56.2-4.1 | Core / Profile Utility |
| noctalia | 5.2.1-1.1 | Wayland Shell & Panels |
| kitty | 0.49.2-1.1 | Primary Terminal Emulator |
| alacritty | 0.17.0-1.2 | Secondary Terminal Emulator |
| fish | 4.9.3-1 | System Interactive Shell |
| btop | 1.4.7-1.1 | Process & System Monitor |
| satty | 0.22.0-1.1 | Screenshot Annotation Editor |
| swayimg | 5.6-2.1 | Image & Quick Look Viewer |
| dolphin | 26.08.2-1.1 | File Manager |
| zen-browser-bin | 1.23.1b-1 | Primary Web Browser |
| firefox | 157.0.1-1.1 | Secondary Web Browser |
| easyeffects | 8.2.9-1.1 | Audio Processing Backend |
| localsend | 1.17.0-4 | Local Network File Transfer |
| tiny-dfr | 0.3.2-2 | Apple T2 Touch Bar Daemon |
| apple-t2-audio-config | 0.3-2 | T2 Audio Driver Topology |

## Hardware Drivers & Subsystems
- **T2 Driver**: `t2bce_core` actively bound to PCI `02:00.1`
- **Virtual Input**: `t2bce_vhci` active (internal keyboard & trackpad)
- **Audio Routing**: `t2bce_audio` active -> PipeWire `Apple Audio Device Speakers`
- **Touch Bar**: `tiny-dfr.service` active + `appletbdrm`
- **Thermals / Fans**: `t2fanrd.service` active + `applesmc_t2`

## Compositor Health
- **Hyprland Errors**: None (Clean)
