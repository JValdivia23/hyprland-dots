# System Personalization Changelog

A dated log of all package changes, configurations, script modifications, and hardware setups for `cachyos-cu`.

## [2.11.0] - 2026-08-14
### Fixed
- **Workspace Window Move Keybinding Error (`SUPER + SHIFT + 1..3`)**:
  - Diagnosed `[ERR] Monitor not found` runtime error when moving windows across workspaces: [`~/.config/hypr/config/binds.lua`](file:///home/java1127/.config/hypr/config/binds.lua) contained conflicting duplicate bindings targeting `MONITOR1`, `MONITOR2`, and `MONITOR3` which were initialized to empty strings `""` in [`variables.lua`](file:///home/java1127/.config/hypr/config/variables.lua).
  - Removed duplicate monitor bindings from `binds.lua`, enabling the full workspace movement loop (`SUPER + SHIFT + [1-9, 0]`) to operate cleanly for all 10 workspaces.
  - Documented root cause and solution in [`references/gotchas/hyprland.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/hyprland.md#L97-L104).

## [2.10.0] - 2026-08-14
### Fixed
- **Waypaper GUI Progressive Rendering & Instant Launch (`ALT + Space`)**:
  - Diagnosed slow startup delay (7+ seconds) and apparent missing cache: stock `/usr/bin/waypaper` unconditionally displayed a `"Caching wallpapers..."` banner on every launch and blocked until 1,700+ GTK buttons were created.
  - Executed a multi-threaded Python pre-cacher script (`ThreadPoolExecutor` + PIL) generating all 1,644 PNG thumbnails into `~/.cache/waypaper/` in parallel.
  - Deployed optimized Waypaper build in `~/.local/share/waypaper` with dedicated virtualenv (`~/.local/share/waypaper/venv`):
    - **Two-Stage Progressive Rendering**: Renders first 20 wallpapers in `< 0.05s` and caps processing batches to 160 items for fast launch and smooth scrolling.
    - **Smart Caching Label**: Only displays `"Caching new wallpapers..."` if an image is actually missing from disk.
    - **Live Daemon Status Badge**: Displays `🟢 Active` / `🔴 Inactive` rotation status next to interval timer.
  - Updated `ALT + Space` in [`~/.config/hypr/config/binds.lua`](file:///home/java1127/.config/hypr/config/binds.lua#L121) to execute `~/.local/share/waypaper/venv/bin/waypaper` and created `~/.local/bin/waypaper` symlinks.

## [2.9.0] - 2026-08-14
### Fixed
- **Apple Touch Bar Full Hardware Mode & Function Keys Configuration**:
  - Configured [`/etc/modprobe.d/touchbar.conf`](file:///etc/modprobe.d/touchbar.conf) with `options hid_appletb_kbd mode=1 fntoggle=1 double_press_switch_time=500` to set `F1`–`F12` Function Keys as the active default row, with dynamic switching to Media controls on `Fn` hold or double-tap toggle.
  - Disabled and stopped obsolete `supergfxd.service` (ASUS ROG GPU daemon) to prevent spurious PCIe bus rescans and T2 VHCI endpoint resets.
  - Documented Touch Bar architecture and modes in [`references/gotchas/apple-t2.md`](file:///home/java1127/.agents/skills/system-personalization/references/gotchas/apple-t2.md#L7-L23).

## [2.8.0] - 2026-08-14
### Added
- **Automatic Screen Dimming & Sleep Daemon (`hypridle`)**: Installed `hypridle` and `hyprlock`, configured [`~/.config/hypr/hypridle.conf`](file:///home/java1127/.config/hypr/hypridle.conf), and added autostart into [`~/.config/hypr/config/autostart.lua`](file:///home/java1127/.config/hypr/config/autostart.lua).
  - 2.5 min inactivity: Dims display brightness to 10% (`brightnessctl -s set 10%`).
  - 5.0 min inactivity: Cuts display backlight signal (`hyprctl dispatch dpms off`, 0W backlight).
  - 15 min inactivity: Automatically suspends machine to S3 deep sleep.
  - Fully integrated with Noctalia's Caffeine toggle (`SUPER + CTRL + I`) via Wayland `ext_idle_notifier_v1` and DBus idle inhibitors.
- **PCIe ASPM Low-Power Switching**: Enhanced [`/usr/local/bin/amdgpu-power-switch.sh`](file:///usr/local/bin/amdgpu-power-switch.sh) to automatically set PCIe Active State Power Management to `powersupersave` on battery and restore `default` on AC.

## [2.7.0] - 2026-08-14
### Fixed
- **Apple T2 Audio Subsystem Recovery & Sleep Queue Integrity**:
  - Diagnosed missing YouTube audio caused by Apple T2 BridgeOS queue corruption (`apple-bce: SQ registration failed (34/74)`) after waking from suspend, which caused PipeWire to fall back to `Dummy Output`.
  - Reloaded the `apple_bce` kernel module to reset the BridgeOS communication channels, immediately restoring the ALSA `Apple Audio Device Speakers` sink (`alsa_output.pci-0000_02_00.3.Speakers`) and `BuiltinMic` source in PipeWire.
  - Updated [`/usr/local/bin/t2-sleep-helper`](file:///usr/local/bin/t2-sleep-helper) to preserve `apple_bce` and `aaudio` attachments across suspend/resume instead of unbinding them, maintaining BridgeOS Submission Queue integrity.
  - Documented the root cause and module reload recovery procedures in [`references/gotchas/apple-t2.md`](file:///home/java1127/.agents/skills/system-personalization/references/gotchas/apple-t2.md#L30-L42).

## [2.6.0] - 2026-08-14
### Added
- **Brave Browser GPU & Wayland Flags**: Created [`~/.config/brave-origin-flags.conf`](file:///home/java1127/.config/brave-origin-flags.conf) and [`~/.config/brave-flags.conf`](file:///home/java1127/.config/brave-flags.conf) enabling native Wayland surfaces (`--ozone-platform-hint=auto`), VA-API video decode & encode (`VaapiVideoDecodeLinuxGL`), zero-copy rasterization, and GPU acceleration for both the browser and all installed WebApps.
- **Zen Browser WebRender & VA-API Configuration**: Created [`user.js`](file:///home/java1127/.zen/Profiles/80a9d579.Default%20%28release%29/user.js) in the active profile enabling WebRender GPU compositing (`gfx.webrender.all = true`), direct VA-API hardware video decode (`media.ffmpeg.vaapi.enabled = true`), XDG Desktop Portal file picker, calibrated smooth scrolling, and 512 MB memory caching.

## [2.5.0] - 2026-08-14
### Added
- **Dynamic AMD GPU Power Management (`udev`)**: Created `/usr/local/bin/amdgpu-power-switch.sh` and `/etc/udev/rules.d/99-amdgpu-power.rules` to automatically switch AMD Radeon Pro 560X PowerPlay profile modes based on AC adapter state:
  - **On Battery (`online == 0`)**: Automatically engages `POWER_SAVING` (`pp_power_profile_mode = 2` / `power_dpm_force_performance_level = manual`), allowing core clocks to idle at 214 MHz (saving ~10–12 W continuous).
  - **On AC (`online == 1`)**: Restores `BOOTUP_DEFAULT` (`pp_power_profile_mode = 0` / `power_dpm_force_performance_level = auto`) for peak graphics throughput.

## [2.4.0] - 2026-08-14
### Changed
- **Disabled Hyprland Window Swallowing**: Set `enable_swallow = false` in [`~/.config/hypr/config/misc.lua`](file:///home/java1127/.config/hypr/config/misc.lua). Prevents child processes (such as elevated sudo/password prompts and agent subshells) from swallowing the parent Kitty terminal, ensuring all newly opened windows tile side-by-side cleanly in the dwindle layout.
- **Hyprland Troubleshooting Documentation**: Documented window swallowing gotcha and fix in [`references/gotchas/hyprland.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/hyprland.md#L75-L84).

## [2.3.0] - 2026-08-14
### Added
- **AMD GPU Video Acceleration & Compute**: Configured explicit `LIBVA_DRIVER_NAME=radeonsi`, `VDPAU_DRIVER=radeonsi`, and `RUSTICL_ENABLE=radeonsi` in [`~/.config/uwsm/env`](file:///home/java1127/.config/uwsm/env) and [`~/.config/hypr/config/environment.lua`](file:///home/java1127/.config/hypr/config/environment.lua) to route hardware video decoding and OpenCL directly to the AMD Radeon Pro 560X (`amdgpu`).
- **Diagnostics Tools**: Installed `libva-utils` (`vainfo`) and `vulkan-tools` (`vulkaninfo`) for GPU capability auditing.
- **Terminal Greeting Banner**: Fixed `fastfetch-custom` key parsing to dynamically discover single-GPU setups (`GPU: AMD Radeon Pro 560X (dGPU)`), Apple Retina display, battery status, and audio devices without hardcoded dual-GPU ASUS keys.

## [2.2.0] - 2026-08-14
### Added
- **Thermals & Fan Management**: Configured `/etc/t2fand.conf` with exponential fan curves (`low_temp=50`, `high_temp=78`) and enabled `t2fanrd.service` to prevent thermal throttling on the 8-core Intel Core i9-9880H.
- **Touch Bar OLED Protection**: Enabled `EnablePixelShift = true` in `/etc/tiny-dfr/config.toml` and restarted `tiny-dfr.service` to prevent burn-in on the OLED Touch Bar.
- **Audio Diagnostics & Clean Baseline**: Diagnosed EasyEffects 8.2 plugin range validation conflicts on `mbp.json` and reverted to a clean, direct PipeWire + WirePlumber routing for `Apple Audio Device Speakers` (`alsa_output.pci-0000_02_00.3.Speakers`) with verified playback.


## [2.1.0] - 2026-08-14

### Changed
- Audited and updated the `system-personalization` skill for **`cachyos-cu`** (**Apple MacBook Pro 15,1**):
  - Updated hardware reference with Intel Core i9-9880H CPU, AMD Radeon Pro 560X discrete GPU, 16 GiB RAM, and Apple Retina 2880x1800 display.
  - Documented Apple T2 chip subsystems (`apple-bce`, Touch Bar via `tiny-dfr`, Apple Audio via `aaudio`, Broadcom BCM4364 Wi-Fi, and `suspend-fix-t2.service`).
  - Removed obsolete ASUS ROG / NVIDIA PRIME / AniMe Matrix documentation and gotchas.
  - Removed nonexistent offline docs references from `SKILL.md`.
  - Updated `scripts/snapshot.sh` with automatic `HYPRLAND_INSTANCE_SIGNATURE` socket discovery and full package auditing.

## [2.0.0] - 2026-08-13
### Added
- Multi-compositor support for **Niri** in `hyprland-dots` dotfiles repository:
  - Created `niri/.config/niri/cfg/keybinds.kdl` linking **`Alt + Space`** to toggle Noctalia wallpaper selector (`qs -c noctalia-shell ipc call wallpaper toggle || waypaper`).
  - Added `niri` to `STOW_PKGS` in `scripts/02-stow.sh` for automatic deployment and conflict backups.
- Successfully deployed and validated `hyprland-dots` on remote MacBook Pro running CachyOS Niri (`10.0.0.2`).

## [1.15.0] - 2026-08-10
### Added
- Configured Hyprland `cursor` settings in [`~/.config/hypr/config/inputs.lua`](file:///home/java1127/.config/hypr/config/inputs.lua):
  - Enabled `inactive_timeout = 3` to automatically hide the mouse cursor after 3 seconds of inactivity.
  - Enabled `hide_on_key_press = true` to automatically hide the cursor when typing.

## [1.14.0] - 2026-07-30
### Changed
- Created dedicated diagnostics profile container directory (`~/.config/brave-webapps/containers/diagnostics`) allowing persistent history, cookies, and local session data across launches while remaining isolated from the primary Brave profile.

## [1.13.0] - 2026-07-28
### Added
- Installed **`swayimg`** for instant Wayland image and vector previews.
- Created `~/.local/bin/hypr-quicklook` script to trigger floating Quick Look previews over Dolphin.
- Set **Satty** (`satty.desktop`) as default image viewer across standard MIME types.
- Configured floating window rules for `swayimg` in [`~/.config/hypr/config/windowrules.lua`](file:///home/java1127/.config/hypr/config/windowrules.lua).
- Mapped **`ALT` + `Return`** (`Alt+Enter`) in [`~/.config/hypr/config/binds.lua`](file:///home/java1127/.config/hypr/config/binds.lua) to trigger Quick Look preview overlay.
- Configured **Kitty** as default terminal in `~/.config/kdeglobals` and mapped **`F4`** in Dolphin to launch Kitty in the active folder.

## [1.12.0] - 2026-07-28
### Added
- Installed **LocalSend** (`localsend` v1.17.0-4) via `pacman` for cross-platform local network file sharing.
- Configured **UFW Firewall** rules (`53317/tcp` and `53317/udp`) to allow LocalSend discovery and transfer across the local network.

## [1.10.0] - 2026-07-25
### Changed
- Mapped `SUPER + C` (`CTRL, SHIFT, C`), `SUPER + V` (`CTRL, V`), `SUPER + X` (`CTRL, X`), `SUPER + Z` (`CTRL, Z`), and `SUPER + SHIFT + Z` (`CTRL, SHIFT, Z`) directly in `binds.lua` using native `hl.dsp.send_shortcut`.
- Remapped Noctalia Control Center toggle to `SUPER + E` (`noctalia msg panel-toggle control-center`).
- Remapped Noctalia Settings toggle to `SUPER + ,` (`noctalia msg settings-toggle`).

## [1.2.0] - 2026-07-21
### Added
- Added `SUPER` + `CONTROL` + `I` keybinding to `~/.config/hypr/config/binds.lua` to toggle Noctalia Caffeine (`noctalia msg caffeine-toggle`), preventing automatic screen lock and system sleep during inactivity.

## [1.1.0] - 2026-07-20
### Added
- Created native macOS text navigation bindings in `binds.lua` (`SUPER+Left/Right` for Home/End, `SUPER+Up/Down` for Doc Top/Bottom, `ALT+Left/Right` for word jump, `SUPER+Backspace` / `ALT+Backspace` for line/word deletion).
- Created `~/.local/bin/hypr-window-pop` for window pop-out and pin (`SUPER+O`).
- Created `~/.local/bin/hypr-toggle-altwin` and mapped `SUPER+ALT+K` to toggle Mac vs PC layout.
- Installed Waypaper and bound `ALT+Space` to launch wallpaper selector GUI.

## [1.0.0] - 2026-08-10 — Automated Dotfiles Repository & GNU Stow Setup
### Added
- Installed `stow` and created the `~/dotfiles` Git repository for automated machine provisioning.
- Modularized configurations into Stow package groups (`hypr`, `noctalia`, `kitty`, `alacritty`, `fish`, `btop`, `waypaper`, `gtk`, `swayimg`, `bin`, `agents`, `webapps`, `zigoku`).
- Built automated 1-command installer `install.sh` and modular provisioning scripts.
- Published repository to GitHub as [`JValdivia23/hyprland-dots`](https://github.com/JValdivia23/hyprland-dots).



