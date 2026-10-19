# Current System State

Live system snapshot automatically generated for multi-PC environment.

## Operating System & Kernel
- **OS**: CachyOS Linux
- **Kernel (`surface`)**: `7.2.11-1-cachyos` (default since 2026-10-13; touch via DKMS `ipts`, see `gotchas/kernel-cachyos-ipts.md`). Fallback: `7.2.11.arch1-1` (linux-surface, kept installed).
- **Kernel (`cachyos-cu`)**: `7.2.9-1-cachyos` (active & verified; unpinned in `/etc/pacman.conf`)
- **Shell**: `/bin/fish` (version 4.9.3)
- **Compositor**: Hyprland 0.56.2 (package: `0.56.2-4.1`)
- **Active Profiles**: `surface` (Surface Book 3), `macbook-t2` (MacBookPro15,1)

## Boot & Sleep (`surface`)
- **Bootloader**: Active Limine 12.9.3; ESP mounted at `/boot`, configuration `/boot/limine.conf` (verified 2026-10-13).
- **Boot menu**: Hidden one-second countdown (`quiet: yes`, `timeout: 1`), replacing the visible five-second wait on 2026-10-08. Press Space during that second to reveal the menu.
- **Kernel selection (2026-10-13)**: `/etc/default/limine` `BOOT_ORDER="linux-cachyos, linux-surface*, *, *lts, *fallback, Snapshots"` (backup: `/etc/default/limine.bak-ipts`). Menu order: `linux-cachyos`, `linux-surface`, `linux-cachyos-lts`; `default_entry: 2` now resolves to `linux-cachyos`; `remember_last_entry: yes` remains enabled.
- **IPTS on CachyOS kernels (2026-10-13)**: DKMS `ipts/2024.04.16` (built for `7.2.11-1-cachyos` and `6.18.55-2-cachyos-lts`) + `/usr/local/bin/surface-ipts-mei-bind` via `/etc/udev/rules.d/72-surface-ipts-mei-bind.rules`.
- **Lid policy**: Suspend-then-hibernate, with 30-minute hibernation delay and `HibernateMode=shutdown`.
- **Hibernation compression & image size (2026-10-18)**: **LZ4 selected** (`/sys/module/hibernate/parameters/compressor = lz4`) and `/sys/power/image_size = 4800000000` (`~4.8 GB`, bypassing pre-snapshot `zram0` swap thrashing), applied at boot by `/usr/local/bin/surface-hibernate-compressor` (`surface-hibernate-compressor.service`).
- **Hibernation CMOS RTC epoch alignment (2026-10-18)**: `/usr/local/bin/surface-hibernate-rtc-sync` and `/etc/systemd/system-sleep/19-surface-rtc-hibernate.sh` (symlinked in `/usr/lib/systemd/system-sleep/`) shift `rtc0` to the SAM EC UEFI POST epoch (`-25,179s` in `/var/lib/surface-hibernate-rtc/offset_sec`) on `pre/hibernate` and restore UTC on `post/hibernate` so kernel `timekeeping_resume()` natively injects the true hibernated duration.
- **IPTS recovery (2026-10-18)**: `/usr/local/bin/surface-ipts-resume-recover` (with `0.5s` fast-path healthy check) and `/etc/systemd/system-sleep/21-surface-ipts-resume.sh` (symlinked in `/usr/lib/systemd/system-sleep/`, stopping active `iptsd@*.service` cleanly on `pre/*`).
- **Touch Gestures (`lisgd`)**: External gesture daemon with session uaccess rule `/etc/udev/rules.d/71-iptsd-touchscreen-uaccess.rules` active and automated.
- **Detached-only rotation (2026-10-19, Surface Book 3 only)**: `iio-sensor-proxy` + user `surface-autorotate.service`, gated by root-owned physical connection status from `surface-base-state.service`. Any attached base (including backwards) locks `eDP-1` to landscape. IPTS touch/pen transforms, lisgd edge directions and touch-resizer coordinates follow display rotation. User confirmed detached rotation, touch/keyboard gestures and landscape restoration on reattachment; both portrait transforms are logged. Pen, backwards attachment and resume remain untested. See `gotchas/screen-rotation.md`.
- **Idle Power Baseline (2026-10-19)**: Tool `profiles/surface/scripts/surface-idle-power.py` deployed (appends to `~/.local/state/surface-idle-power/log.jsonl`). Verified clean baseline on `7.2.11-1-cachyos`: **5.86 W** median draw (5.91 W mean, 95.5% C3 residency at 25% display brightness; documented in [`gotchas/power-baseline.md`](file:///home/jmvp/.agents/skills/system-personalization/references/gotchas/power-baseline.md)).

## Multi-PC System Specs & Display

### Microsoft Surface Book 3 (`surface`)
- **Product**: Surface Book 3 (`surface`)
- **CPU**: Intel(R) Core(TM) i5-1035G7 CPU @ 1.20GHz
- **GPU**: Intel Corporation Iris Plus Graphics G7
- **RAM**: 7.4Gi RAM, 16Gi swap
- **Primary Display**: eDP-1 (3000x2000@60Hz, scale 2)
- **Active Profile**: `surface`

### Apple MacBook Pro 15,1 (`cachyos-cu`)
- **Product**: MacBookPro15,1 (`cachyos-cu`)
- **CPU**: Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz
- **GPU**: Advanced Micro Devices, Inc. [AMD/ATI] Baffin [Radeon RX 460/560D / Pro 450/455/460/555/555X/560/560X] / Intel UHD 630 / Apple Inc. T2 Bridge Controller
- **RAM**: 15Gi RAM, 15Gi swap
- **Primary Display**: eDP-1 (2880x1800@60Hz, scale 1.6 / 1.33)
- **Active Profile**: `macbook-t2`

## Key Installed Packages & Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| hyprland | 0.56.2-4.1 | Core Desktop Compositor |
| noctalia | 5.3.0-1.1 | Wayland Shell & Panels |
| kitty | 0.49.2-1.1 | Primary Terminal Emulator |
| alacritty | 0.17.0-1.2 | Secondary Terminal Emulator |
| ani-cli | 5.1-1 | Anime Streaming CLI (mpv/fzf) |
| paru | 2.1.0-3 | AUR Helper (CachyOS Native) |
| fish | 4.9.3-1 | System Interactive Shell |
| btop | 1.4.7-1.1 | Process & System Monitor |
| satty | 0.22.0-1.1 | Screenshot Annotation Editor |
| swayimg | 5.6-2.1 | Image & Quick Look Viewer |
| dolphin | 26.08.2-1.1 | File Manager |
| zen-browser-bin | 1.23.3b-1 | Primary Web Browser |
| firefox | 157.0.1-1.1 | Secondary Web Browser |
| easyeffects | 8.3.0-1.1 | Audio Processing Backend (`surface-book-hybrid` DSP preset active with AutoGain volume leveling) |
| lsp-plugins-lv2 | 1.2.35-1.1 | LV2 Audio DSP Plugins (Equalizer, Limiter, High-Pass Filter) |
| calf | 0.90.9-2.1 | LV2 Audio Plugins (Bass Enhancer / Virtual Bass, Stereo Tools) |
| localsend | 1.17.0-4 | Local Network File Transfer |
| lisgd | 0.4.0-1 | Surface Libinput Synthetic Gesture Daemon |
| iio-sensor-proxy | 3.9-1.1 | Surface Book 3 detached-only orientation sensing |
| wvkbd | 0.20-1 | Surface Virtual Touch Keyboard |
| iptsd | 3.1.1-1 | Surface Precise Touch & Stylus Daemon |
| surface-dtx-daemon | 0.3.10-1 | Surface Clipboard Detachment Daemon |
| msr-tools | 1.3-4 | Intel MSR / RAPL Hardware Access |
| fprintd | 1.94.5-2.1 | Fingerprint Authentication Daemon |
| kait2en-touchbar | 0.1.0 | Advanced Apple T2 Touch Bar Daemon |
| t2-touchid | 0.1.0 | BridgeXPC Apple T2 Touch ID Daemon |
| t2-cpu-control | 0.02 | Intel Core i9 PL1/PL2 RAPL Limiter |
| t2-power-tune | 0.02 | Package C-State & PCIe ASPM Power Tuner |
| t2-power-explorer | 0.1.0 | PCIe Power Management & Lane Diagnostic |
| apple-t2-audio-config | 0.3-2 | T2 Audio Driver Topology |

## User-local Applications (current account)

- **VLCdots Alpha `0.1.0-alpha.1`**: installed at `~/.local/opt/vlcdots-alpha/current` (versioned release underneath); launch with `vlcdots-alpha` or the **VLCdots Alpha** application-menu entry. Own persistent profile under `~/.local/state/vlcdots-alpha/profile` (original XDG state base respected). System VLC, MIME defaults, and ani-cli history remain separate/unchanged. This is a universal app, not a hardware profile or system package.
- **Source/release**: private `JValdivia23/vlcdots`, main/tag `v0.1.0-alpha.1` at `81ae9d3`; runtime does not require its build/source checkout. Installer/uninstaller and limitations are documented in `/home/jmvp/work/vlcdots/README.md`. Uninstall preserves profile/count cache/history and refuses known mapped releases or modified owned files.

## Hardware Drivers & Subsystems (`macbook-t2`)
- **T2 Driver**: `t2bce_core` actively bound to PCI `02:00.1`
- **Virtual Input**: `t2bce_vhci` active (internal keyboard & trackpad)
- **Audio Routing**: `t2bce_audio` active -> PipeWire `Apple Audio Device Speakers`
- **Touch Bar**: `kait2en-touchbar.service` active + `appletbdrm` (dark-first OLED, multi-layer & gestures)
- **Touch ID**: Verified active & operational. 3 macOS fingers auto-bound via BridgeXPC over CDC-NCM (`t2_ncm`) -> `fprintd` -> PAM `sudo` / `hyprlock`
- **GPU Power**: AMD Radeon Pro 560X in `POWER_SAVING` DPM profile (mode 2) via `amdgpu-power-switch.sh`
- **CPU Limits**: PL1 = 45 W, PL2 = 60 W active via `t2-cpu-control.service` and `/etc/t2-cpu-control.conf`
- **Power Optimization**: `t2-power-tune` & `t2-power-explorer` deployed with Polkit privilege escalation
- **Thermals / Fans**: `t2fanrd.service` active with linear curve (45°C–72°C) via `/etc/t2fand.conf`

## Compositor Health
- **Hyprland Errors**: None (Clean)
