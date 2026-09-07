# System Personalization Changelog

A dated log of all package changes, configurations, script modifications, and hardware setups for `cachyos-cu`.

## [2.21.0] - 2026-09-07
### Changed
- **Full System Upgrade & Linux 7.2.3 Kernel (`7.2.3-1-cachyos`)**:
  - Upgraded kernel from `7.2.2-1-cachyos` to **`7.2.3-1-cachyos`** alongside `linux-cachyos-headers`, `cpupower`, and `bpf`.
  - Upgraded **Noctalia** Wayland shell from `5.0.0_beta.10-1.1` to **`5.0.1-1.1`** (official point release out of beta).
  - Updated Hyprland compositor stack: `hyprland` `0.56.2-2.1`, `aquamarine` `0.15.0-2.1`, `hypridle` `0.1.8-2.1`, `hyprlock` `0.9.6-3.1`, `hyprutils` `0.14.2-1.1`, and `xdg-desktop-portal-hyprland` `1.4.1-2.1`. Zero Hyprland config errors reported (`hyprctl configerrors`).
  - Updated **LuaJIT** to `2.1.1788460057+24c20c9-1.1` (underlying Hyprland Lua modular config engine).
  - Upgraded **Fish Shell** to **`4.9.2-1`** (from `4.8.1`).
  - Updated web browser suite: **Zen Browser `1.22b-1`**, **Firefox `155.0.1-1`**, and **Brave Origin `1:1.94.121-1`**.
  - Updated user & CLI utilities: **Swayimg `5.6-1.1`**, **Lazygit `0.65.0-1.1`**, **Yazi `26.9.1-2.1`**, and **scx-scheds `1.1.3-2`**.
  - Verified post-reboot hardware health: Apple T2 Bridge Controller, OLED Touch Bar (`tiny-dfr.service` active), fan daemon (`t2fanrd.service` active), and PipeWire direct ALSA routing for `Apple Audio Device Speakers`.

## [2.20.0] - 2026-09-03
### Changed
- **rEFInd Boot Theme Modernization (`rEFInd-minimal-black`)**:
  - Replaced the bright, high-glare `rEFInd-minimal` theme (light silver background `#eceee3`) with **`rEFInd-minimal-black`** in `/boot/EFI/refind/themes/rEFInd-minimal-black/`.
  - Configured a true solid black canvas (`#000000`) with subtle monochrome gray icons (~`RGB: 225, 225, 225`) and minimalist selection indicator.
  - Linked monochrome gray Arch Linux logo (`os_arch.png`) for CachyOS and Limine (`os_cachyos.png`, `os_limine.png`, `limine_x64.png`), paired with the gray Apple logo (`os_mac.png`) for macOS dual-boot.
  - Updated `/boot/EFI/refind/refind.conf` to include `themes/rEFInd-minimal-black/theme.conf` while retaining the 3-second auto-boot countdown and default CachyOS target.
  - Documented update in [`references/gotchas/apple-t2.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/apple-t2.md#L104-L114).

## [2.19.0] - 2026-09-03
### Fixed
- **Laptop Lid Suspend & Clamshell Thermal Overheating Prevention**:
  - Diagnosed battery exhaustion and extreme chassis heat when closed: [`/etc/systemd/logind.conf.d/omarchy-lid.conf`](file:///etc/systemd/logind.conf.d/omarchy-lid.conf) had `HandleLidSwitch=ignore` and `HandleLidSwitchExternalPower=ignore` enabled, preventing systemd-logind from suspending the laptop when the lid closed.
  - Reconfigured `omarchy-lid.conf` to `HandleLidSwitch=suspend` and `HandleLidSwitchExternalPower=suspend`, while retaining `HandleLidSwitchDocked=ignore` for external display clamshell workstations.
  - Reloaded `systemd-logind` configuration via `SIGHUP` (`systemctl kill -s HUP systemd-logind`).
  - Enhanced [`~/.local/bin/hypr-lid-handler`](file:///home/java1127/.local/bin/hypr-lid-handler) in dotfiles (`~/dotfiles/bin/.local/bin/hypr-lid-handler`):
    - Added Touch Bar OLED backlight (`appletb_backlight`) preservation: saves active level to `/tmp/hypr_tb_backlight_saved_${UID}` and shuts off OLED display on lid close, restoring brightness on lid open.
    - Integrated with `power-profiles-daemon`: saves current profile and enforces `powerprofilesctl set power-saver` on lid close, restoring previous profile on open.
  - Documented updated architecture in [`references/gotchas/hyprland.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/hyprland.md) and [`references/config-paths.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/config-paths.md).

## [2.18.0] - 2026-09-01
### Changed
- **Full System Upgrade & Linux 7.2 Kernel (`7.2.2-1-cachyos`)**:
  - Upgraded kernel from `7.1.8-1-cachyos` to **`7.2.2-1-cachyos`** alongside `linux-cachyos-lts` `6.18.48-1`.
  - Updated **Noctalia** shell to `5.0.0_beta.10-1.1`.
  - Updated web browser suite: **Firefox 154.0.1**, **Zen Browser 1.21.16b**, and **Brave Origin 1.94.117**.
  - Updated KDE Frameworks & Dolphin to **`26.08.0-5.1`** / Qt 6.11.2.
- **Apple T2 BCE Driver Transition & mkinitcpio Multi-Kernel Compatibility**:
  - Diagnosed `mkinitcpio` build failure on Linux 7.2 due to legacy hardcoded `MODULES+=(apple-bce)` in [`/etc/mkinitcpio.conf.d/11-chwd.conf`](file:///etc/mkinitcpio.conf.d/11-chwd.conf).
  - Modernized `11-chwd.conf` with optional `?` tags: `MODULES+=(apple-bce? t2bce_core? t2bce_vhci? t2bce_dma? applesmc-t2?)` to support both Linux 7.2+ modular `t2bce` drivers and LTS `apple-bce`.
  - Rebuilt all Limine UKI and initramfs boot images cleanly.
- **Keyboard Backlight Clamshell / Lid Preservation & Idle Dimming**:
  - Diagnosed keyboard backlight starting at 0% (off) after opening laptop lid: [`~/.local/bin/hypr-lid-handler`](file:///home/java1127/.local/bin/hypr-lid-handler) turned off `apple::kbd_backlight` on lid close without saving previous level.
  - Updated `hypr-lid-handler` to save active brightness level to `/tmp/hypr_kbd_backlight_saved_${UID}` on `close` and restore the saved level automatically on `open`.
  - Added 150s (2.5 min) idle listener to [`~/.config/hypr/hypridle.conf`](file:///home/java1127/.config/hypr/hypridle.conf) (`brightnessctl -s -d "apple::kbd_backlight" set 0%` and `brightnessctl -r`), turning off keyboard backlighting alongside screen and Touch Bar dimming.
- **Unified Noctalia On-Screen Display (OSD) for Screen & Keyboard Brightness**:
  - Deployed [`~/.local/bin/hypr-screen-brightness`](file:///home/java1127/.local/bin/hypr-screen-brightness) to route display brightness adjustments on `gmux_backlight` to `noctalia msg brightness-osd <percent>`, showing Noctalia's native progress bar on keypress.
  - Replaced `notify-send` in [`~/.local/bin/hypr-kbd-brightness`](file:///home/java1127/.local/bin/hypr-kbd-brightness) with `noctalia msg keyboard-backlight-osd <percent>`, replacing stacked notification cards with a single unified keyboard brightness OSD bar.
  - Updated [`~/.config/hypr/config/binds.lua`](file:///home/java1127/.config/hypr/config/binds.lua) hardware brightness bindings with `repeating = true`.
- **Skill Self-Improvement & Wayland IPC Dispatch**:
  - Updated [`SKILL.md`](file:///home/java1127/.agents/skills/system-personalization/SKILL.md) Rule 8, [`terminal-ssh.md`](file:///home/java1127/.agents/skills/system-personalization/references/gotchas/terminal-ssh.md), and [`hyprland.md`](file:///home/java1127/.agents/skills/system-personalization/references/gotchas/hyprland.md) to properly export `HYPRLAND_INSTANCE_SIGNATURE` and invoke Hyprland's native `hl.exec_cmd` for elevated background terminal prompts.

## [2.17.0] - 2026-08-20
### Changed
- **Graphics & Vulkan Driver Stack Update (Mesa 26.2.1)**:
  - Synchronized repository databases and updated graphics stack to **Mesa 26.2.1** (`mesa`, `lib32-mesa`, `vulkan-radeon`, `lib32-vulkan-radeon`, `vulkan-intel`, `lib32-vulkan-intel`, `opencl-mesa`, `lib32-opencl-mesa`, `vulkan-mesa-implicit-layers`, `lib32-vulkan-mesa-implicit-layers` `3:26.1.6-1` -> `3:26.2.1-1`).
  - Verified Vulkan 1.4 driver instance (`Mesa 26.2.1-arch3.1`, RADV POLARIS11) and VA-API hardware acceleration (`radeonsi`) on discrete AMD Radeon Pro 560X.

## [2.16.0] - 2026-08-17
### Added
- **Clamshell & Ultra-Low Idle Power Architecture (Lid-Closed Mode)**:
  - Configured system to allow background tasks (downloads, music, servers, SSH) to run with the laptop lid closed without forcing immediate sleep.
  - Set `HandleLidSwitch=ignore` and `HandleLidSwitchExternalPower=ignore` in [`/etc/systemd/logind.conf.d/omarchy-lid.conf`](file:///etc/systemd/logind.conf.d/omarchy-lid.conf).
  - Deployed [`~/.local/bin/hypr-lid-handler`](file:///home/java1127/.local/bin/hypr-lid-handler) in dotfiles (`~/dotfiles/bin/.local/bin/hypr-lid-handler`):
    - **Lid Close (`switch:on:Lid Switch`)**: Locks session via Noctalia/loginctl, powers off primary Retina display (`eDP-1`) via Wayland DPMS, powers down keyboard backlighting (`apple::kbd_backlight`), and sets power saving on GPU and CPU.
    - **Lid Open (`switch:off:Lid Switch`)**: Powers display (`eDP-1`) back on via Wayland DPMS and restores active power profiles.
  - Bound Hyprland switch directives in [`~/.config/hypr/config/binds.lua`](file:///home/java1127/.config/hypr/config/binds.lua) with `{ locked = true }`.
  - Enhanced [`/usr/local/bin/amdgpu-power-switch.sh`](file:///usr/local/bin/amdgpu-power-switch.sh) to toggle Intel Turbo Boost (`/sys/devices/system/cpu/intel_pstate/no_turbo`) on battery/clamshell, locking idle CPU draw to $\approx 1.0\text{W} - 1.8\text{W}$ and eliminating thermal spikes inside the closed chassis.

## [2.15.0] - 2026-08-17
### Fixed
- **Touch Bar Sleep/Resume Controller Recovery & Driver Blacklist**:
  - Diagnosed Touch Bar unresponsiveness: on wakeup or boot, setting USB device `05ac:8302` directly to Configuration 2 caused BridgeOS probe timeout (`-110` / `ETIMEDOUT: Failed to send message`). In addition, the in-tree `hid_appletb_kbd` driver auto-claimed the interface and dropped VHCI endpoints (`bce_vhci_drop_endpoint 6:11`).
  - Blacklisted `hid_appletb_kbd` in [`/etc/modprobe.d/blacklist-touchbar.conf`](file:///etc/modprobe.d/blacklist-touchbar.conf) and staged in `~/dotfiles/scripts/blacklist-touchbar.conf`.
  - Deployed [`/etc/udev/rules.d/99-touchbar-tiny-dfr.rules`](file:///etc/udev/rules.d/99-touchbar-tiny-dfr.rules) to manage Touch Bar input, display, and backlight aliases cleanly without change loops.
  - Updated [`/usr/local/bin/t2-sleep-helper`](file:///usr/local/bin/t2-sleep-helper) to cycle `bConfigurationValue` `0 -> 2`, allowing BridgeOS to open its readiness window before loading `appletbdrm`.
  - Created and enabled [`/etc/systemd/system/t2-touchbar-setup.service`](file:///etc/systemd/system/t2-touchbar-setup.service) to automatically run `t2-sleep-helper post` upon boot.
  - Hardened [`/etc/systemd/system/tiny-dfr.service`](file:///etc/systemd/system/tiny-dfr.service) with `BindsTo=dev-tiny_dfr_display.device` so `tiny-dfr` never mistakenly opens primary GPU cards.
  - Documented complete architecture and recovery cycle in [`references/gotchas/apple-t2.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/apple-t2.md#L7-L28).

## [2.14.0] - 2026-08-15
### Fixed
- **Apple Touch Bar Sleep & Resume Recovery (`tiny-dfr` & `appletbdrm`)**:
  - Diagnosed Touch Bar failure on MacBookPro15,1 (Apple T2 + discrete AMD Radeon Pro 560X): forcing experimental hardware mode (`hid-appletb-kbd`) caused BridgeOS transfer queue failures (`URB failed: 3`) and VHCI endpoint drops (`bce_vhci_drop_endpoint 6:11`).
  - Restored canonical T2 Userspace DRM architecture using native **`tiny-dfr`** and **`appletbdrm`** (Configuration 2 with `hid-multitouch`).
  - Updated [`/usr/local/bin/t2-sleep-helper`](file:///usr/local/bin/t2-sleep-helper):
    - **Pre-suspend**: Gracefully stops `tiny-dfr.service`, unloads `appletbdrm` and `hid_appletb_bl`, and saves backlight brightness to `/run/tb_brightness`.
    - **Post-resume**: Reloads `hid_appletb_bl` and `appletbdrm`, restores backlight brightness, and automatically restarts `tiny-dfr.service` upon DRM device appearance.
  - Documented root cause and architecture in [`references/gotchas/apple-t2.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/apple-t2.md#L9-L26).

## [2.13.0] - 2026-08-14
### Fixed
- **Web App High-Resolution Icons & XDG Multi-Resolution Hierarchy**:
  - Replaced corrupted/disguised JPEG web app icon files (`AllAnime.png`, `Hanime.png`) with clean, pixel-perfect 512x512 RGBA PNGs and vector SVGs.
  - Deployed official YouTube play button logo (SVG + 512x512 RGBA PNG on transparent background) as preferred by user.
  - Generated and installed multi-resolution icon assets across `~/.local/share/icons/hicolor/{16x16,24x24,32x32,48x48,64x64,128x128,256x256,512x512}/apps/` and `~/.local/share/pixmaps/`.
  - Updated [`scripts/02-stow.sh`](file:///home/java1127/dotfiles/scripts/02-stow.sh) and [`bin/.local/bin/cachy-webapp-install`](file:///home/java1127/dotfiles/bin/.local/bin/cachy-webapp-install) to automatically link web app icons to `hicolor` and `pixmaps` and rebuild GTK/XDG icon caches.
  - Documented troubleshooting in [`references/gotchas/wayland-noctalia.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/wayland-noctalia.md#L86-L98).

## [2.12.0] - 2026-08-14
### Added
- **Dual-Boot OS Picker & macOS APFS Auto-Discovery (`rEFInd` + `rEFInd-minimal`)**:
  - Installed `refind` boot manager to `/boot/EFI/refind/` and configured it as the primary UEFI boot priority (`Boot0001`, `BootOrder: 0001,0000,0080`).
  - Deployed the **`rEFInd-minimal`** theme with dark canvas, monochrome icons, and custom `os_cachyos.png` branding in `/boot/EFI/refind/themes/rEFInd-minimal/`.
  - Configured `/boot/EFI/refind/refind.conf` with `timeout 3` and `default_selection "limine,vmlinuz,cachyos"`, providing an automatic 3-second countdown to boot CachyOS while giving direct 1-click access to macOS APFS without requiring the hardware `Option` key.
  - Generated `/boot/refind_linux.conf` with optimized kernel parameters and installed `btrfs_x64.efi` driver.
  - Documented dual-boot architecture and fallback procedures in [`references/gotchas/apple-t2.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/apple-t2.md#L99-L111).

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



