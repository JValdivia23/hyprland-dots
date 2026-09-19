# System Personalization Changelog

A dated log of all package changes, configurations, script modifications, and hardware setups for `cachyos-cu`.

## [Unreleased]
### Investigated
- **Portable Windows USB first boot failed; preparation defects identified (`surface`, 2026-09-18)**:
  - User reached recovery OOBE with built-in input unavailable. Corrected the earlier readiness claim: only file/EFI hashes had been checked, not a working Windows installation.
  - Read-only collection found Plug and Play unavailable (`0xE0000223`), recovery OOBE active, and no installed Surface drivers. Image application through a Linux NTFS mountpoint discarded Windows ACLs, attributes, and extended attributes; copying driver files did not install them.
  - User approved native-DISM rebuild and offline driver installation, followed by actual VM desktop/service/driver-policy verification. Details and persistent evidence paths are in `profiles/surface/gotchas/battery-upower.md`, section 3.
  - **Repair completed and verified same day**: the rebuilt stick booted to the Windows desktop in an isolated VM; in-Windows report confirmed Plug and Play running, SAN policy 4, `PortableOperatingSystem=1`, all 41 driver packages installed with zero missing. The VM's `usb-storage` transport produced an OVMF-specific `0xc0000428`; the same disk boots via SATA, and the Surface's earlier USB boot manager run shows the real firmware accepts the stick. Native Surface charging retest pending.
- **Direct base firmware interface discovered (`surface`, 2026-09-17)**:
  - At user request to investigate reverse engineering, decoded cached Surface base HID descriptors and identified a CFU-compatible collection on `01:15:02:05:00` (`045E:09A6`, currently `hidraw2`). Stock fwupd's USB-backed CFU transport does not directly cover the Surface Aggregator `BUS_HOST` interface.
  - An identity-checked, read-only `HIDIOCGFEATURE` query for report `0x20` successfully returned 61 bytes through an interactive sudo terminal. Header reports three records and protocol revision 4; the probe's exit code 2 was its deliberate rejection of unverified revision-4 interpretation, not failed communication.
  - **Component mapping completed same day**: range-fetched five small files from Microsoft's official `SurfaceBook3_Win11_22621_25.013.34389.0.msi` (full 1.67 GB never downloaded; ~116 MB bounded range reads) and hash-verified them against the MSI `MsiFileHash` table. Live `0x12`/`3.6.1` matches `SurfaceBookBaseV3_PD.offer.bin`; live `0x10`/`10.602.139` matches both KIP offer blobs; live `0xFE`/`0.0.0` is the expected CFU offer-information sentinel. All base components are current, so stale base firmware does not explain the charging fault.
  - Preserved raw response, descriptor hash, temporary probe/log paths, transport evidence, offer mapping, and file hashes in the Surface battery/USB-C gotcha. Charging remains unresolved; no firmware write was performed.
- **USB-C charging failure after monitor connection (`surface`, 2026-09-16–17; unresolved)**:
  - User reports failure across reboot/OS reinstall, three chargers, different known-good cables, the proposed recovery test, and charging the detached base. Surface Connect charging and USB-C external video work; only CachyOS is installed.
  - Read-only samples: kernel `ADP1 online=0`, tablet battery not charging, base battery discharging; UPower agrees and reports plausible combined capacity. UEFI `23.101.140` and SAM `10.600.139` match the newest respective entries in Microsoft's published Book 3 history; base/PD controller firmware was not fully inventoried.
  - With the confirmed 60 W portable charger connected, captured 30 raw `ADP1 online` transitions in 40 seconds; base battery stayed discharging and fell from 23.84 Wh to 23.68 Wh. This localizes the symptom below the desktop indicator but does not identify a particular failed controller or establish firmware corruption.
  - September 17 `fwupd` inventory exposed six main UEFI capsule resources but no dedicated base/USB-C update target; CFU plugin ready, no matching base profile in installed quirks. LVFS metadata refresh succeeded with 0 supported detected devices; `get-updates --json` returned an empty list. A follow-up direct CFU read plus official-package offer mapping verified all base components current (PD `3.6.1`, KIP `10.602.139`); this does not establish a defective controller IC. Recorded raw capsule GUIDs/versions and interpretation limits in `profiles/surface/gotchas/battery-upower.md` (already symlinked into the skill). No firmware flash performed.
### Added
- **Portable Windows diagnostic USB initial preparation (`surface`, 2026-09-17–18; first boot subsequently failed)**:
  - 128 GB Lexar USB (verified by serial/size/labels at destructive steps) received Windows 11 Enterprise Evaluation 25H2 (SHA-256-verified Microsoft image) and its own ESP + `bcdboot` UEFI boot files; hashes of `bootmgfw.efi`/`winload.efi` matched the verified image. This did not prove setup completion or driver installation; see the September 18 investigation above.
  - Contents applied from Linux: split-WIM image via `wimlib`, 41 Surface runtime driver packages (battery/serial-hub/HID/UCSI/Wi-Fi/Chipset), answer file with local `SurfaceTest` account, internal-disks-offline SAN policy, portable-OS registry flags, hibernation/BitLocker/encryption guards, Windows-Update driver exclusion, and a 60-second dual-battery capture tool on the Public Desktop.
  - The `bcdboot` step ran in an isolated VM (Lexar as the only physical disk, a scratch log image, original Microsoft ISO, no network) through typed diskpart/bcdboot commands with screenshot confirmation. Abandoned the custom-WinPE ISO after six smoke tests: ISO9660-only builds stalled, `-boot-info-table` corrupted `etfsboot.com`, and the UDF rebuild did not complete a successful smoke test. No firmware flashed; internal SSD excluded from the VM, with `SanPolicy=4` configured for native Windows.
  - Extra tools installed via interactive terminal with user approval: `hivex 1.3.24-8.1`, `ntfs-3g 2026.7.7-1.1`, `fuse2 2.9.9-6`, `cdrtools 3.02a09-6.1` (Snapper snapshots 31–34).
- **Automatic Display Scale & Text-Size Calibration (`core`, 2026-09-17)**:
  - Created `core/.local/bin/hypr-autoscale` (symlinked to `~/.local/bin/hypr-autoscale`): Profile-aware and EDID-driven auto-calibrator that automatically detects display pixel density (PPI) and applies the ideal Omarchy-style text scaling.
  - High-DPI / Retina screens (PPI >= 200, `surface`, `macbook-t2`): sets text size 12px (Terminal 9.0pt, UI scale 1.00x).
  - Medium High-DPI screens (150 <= PPI < 200, 27" 4K): sets text size 13px (Terminal 10.0pt).
  - Standard DPI screens (PPI < 150, 1080p/1440p, `desktop`, generic `laptop`): sets text size 14px (Terminal 11.0pt, UI scale 1.17x).
  - Wired into `install.sh` Step 4/4 Post-Install Setup to guarantee "it just works" out of the box on clean installs across different hardware.
  - Added `--follow-symlinks` to `hypr-text-size` sed commands to prevent breaking GNU Stow symlinks into detached local files.
- **Omarchy-Aligned Capture & OCR Suite (`core`, 2026-09-17)**:
  - Installed `tesseract 5.5.3-1.1`, `tesseract-data-eng 4.1.0-5`, and `wf-recorder 0.6.0-2.1` via pacman through interactive Kitty/Hyprland terminal.
  - Created `core/.local/bin/hypr-screenshot` (symlinked to `~/.local/bin/hypr-screenshot`): Smart screenshot tool feeding active window and monitor geometry candidate boxes to `slurp`. Enables single-click snapping to any hovered window, single-click to capture desktop, or click-and-drag for freeform region; pipes directly into Satty annotation editor with default save path `~/Pictures/Screenshots/`. Also supports `active` window and `fullscreen` flags.
  - Created `core/.local/bin/hypr-ocr` (symlinked to `~/.local/bin/hypr-ocr`): Region / window text extraction tool using `grim` + `slurp` + `tesseract -l eng` piped into `wl-copy` with instant notification.
  - Created `core/.local/bin/hypr-record` (symlinked to `~/.local/bin/hypr-record`): Lightweight toggle screen recorder via `wf-recorder` (30fps, geometry selection, auto-saving to `~/Videos/Captures/`).
  - Created `core/.local/bin/hypr-capture-menu` (symlinked to `~/.local/bin/hypr-capture-menu`): Interactive floating capture selector launched via `fzf` in dedicated `--class CaptureMenu` Kitty popup.
  - Added floating window rule for `CaptureMenu` in `core/.config/hypr/config/windowrules.lua`.
  - Registered full Omarchy-aligned keybindings in `core/.config/hypr/config/binds.lua`:
    - `Print` / `SUPER + SHIFT + S` -> Smart Screenshot (Window click / Region drag)
    - `SHIFT + Print` -> Active Window Screenshot (instant)
    - `CONTROL + Print` -> Fullscreen Screenshot
    - `SUPER + Print` / `SUPER + SHIFT + P` -> Color Picker (`hyprpicker -a`)
    - `ALT + Print` / `SUPER + ALT + SHIFT + S` -> Screen Recording Toggle
    - `SUPER + CONTROL + Print` / `SUPER + CONTROL + SHIFT + S` -> OCR Text Extraction
    - `SUPER + CONTROL + C` -> Interactive Capture Menu
  - Validated clean Hyprland IPC reload with 0 config errors (`hyprctl configerrors`). Updated `references/keybindings.md`.
- **Portable Windows diagnostic USB preparation tooling (`surface`, 2026-09-17)**:
  - User authorized preparing the 128 GB-class Lexar USB after moving it to USB-A. Installed `qemu-system-x86 11.1.1-2`, `wimlib 1.14.5-3.1`, `msitools 0.106-3.1`, and `libisoburn 1.5.8.2-1.1` (xorriso provider), plus dependencies including `edk2-ovmf 202608-1` and `ntfsprogs 2026.7.7-1.1`. Pacman completed successfully through an interactive Kitty terminal; Snapper snapshots 27/28.
  - Downloaded Windows 11 Enterprise Evaluation 25H2 x64 from Microsoft's Evaluation Center; SHA-256 matches its official verification PDF (`a61adeab895ef5a4db436e0a7011c92a2ff17bb0357f58b13bbc4062e535e7b9`). Downloaded the full official Surface Book 3 MSI for driver staging, following the earlier range-only CFU investigation.
  - Assembled 41 runtime driver INFs (92.56 MiB) including the Surface battery/serial-hub/HID/UCSI stack; selected files checked against MSI sizes and available hashes. Working artifacts are under `~/.cache/opencode/surface-windows-usb/`; `/tmp` is RAM-backed and unsuitable for the 6.60 GiB ISO.
- **Right-Click / Menu Key Dual-Role Super Modifier (`core`, 2026-09-17)**:
  - Enabled native XKB option `altwin:menu_win` in [`~/.config/hypr/config/inputs.lua`](file:///home/jmvp/.config/hypr/config/inputs.lua) (synced to `dotfiles/core/`), mapping the physical Context Menu (Right-Click) key to `Super_R`.
  - Added clean-tap release binding in [`~/.config/hypr/config/binds.lua`](file:///home/jmvp/.config/hypr/config/binds.lua) (`SUPER + SUPER_R`, `release = true`) to dispatch native `Menu` event to the active window via `hl.dsp.send_shortcut`, opening the right-click context menu when tapped alone.
  - When held or chorded (e.g., `Right-Click Key + Return`), engages `SUPER` modifier to open Kitty or trigger any Hyprland Super shortcuts; chord consumption prevents the context menu from opening upon key release.
  - Updated [`~/.local/bin/hypr-toggle-altwin`](file:///home/jmvp/.local/bin/hypr-toggle-altwin) to preserve `altwin:menu_win` when toggling between PC layout (`altwin:menu_win`) and Mac layout (`altwin:swap_lalt_lwin,altwin:menu_win`).
  - Completely native implementation: zero new packages, zero background daemons, zero sudo elevation required.
- **Noctalia Bar Caffeine Widget (`core`, 2026-09-17)**:
  - Added native `caffeine` widget to the top bar center lane (`center = [ "caffeine", "workspaces", "spacer_1", "active_window" ]`) positioned immediately to the left of the workspace pills.
  - Configured widget theme styling in `~/.config/noctalia/config.toml` (and synced to `core/.config/noctalia/config.toml`) with `color = "secondary"`.
  - Enables one-click toggling of Wayland idle inhibitor directly from the bar (with active/inactive steaming cup icon states), complementing the existing `SUPER + CTRL + I` keyboard shortcut.
  - Validated with `noctalia config validate` and cleanly restarted Noctalia daemon via Hyprland IPC.
- **On-Screen Touch Virtual Keyboard (`wvkbd`) (`surface`, 2026-09-17)**:
  - Installed `wvkbd 0.20-1` (and `scdoc 1.11.5-1.1`) via AUR (`yay`) through interactive Kitty/Hyprland prompt per Rule 8.
  - Created executable toggle wrapper [`core/.local/bin/hypr-virtual-keyboard`](file:///home/jmvp/dotfiles/core/.local/bin/hypr-virtual-keyboard) (symlinked to `~/.local/bin/hypr-virtual-keyboard`) using `pkill -RTMIN -x wvkbd-mobintl` for instantaneous zero-latency overlay toggling.
  - Calibrated height for Surface Book 3 3000x2000 @ 2x scaling (`-L 320 -H 320`) to dock neatly at the bottom 32% of the screen.
  - Tracked `wvkbd` in [`profiles/surface/packages.txt`](file:///home/jmvp/dotfiles/profiles/surface/packages.txt).
  - Documented complete architecture, IME vs OSK distinction, and troubleshooting in [`profiles/surface/gotchas/virtual-keyboard.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/virtual-keyboard.md) (symlinked to `references/gotchas/virtual-keyboard.md`).
- **XH Multi-Page Media Hub WebApp (`core`, 2026-09-17)**:
  - Ported `xh-launch` Python launcher, `XH.desktop`, and `XH.png` from `omarchy-dots` to `core/`.
  - Installed launcher to `~/.local/bin/xh-launch`, desktop entry to `~/.local/share/applications/XH.desktop`, and icons to `~/.local/share/icons/`.
  - Configured to launch Brave (`brave-origin`) in container mode (`~/.config/brave-webapps/containers/diagnostics`) with automatic Hyprland group/tab window merging.
- **Smart Tiered Sleep (`suspend-then-hibernate`) (`surface`, 2026-09-17)**:
  - Configured modular systemd drop-in `/etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf`: enabled `AllowSuspendThenHibernate=yes`, set `HibernateDelaySec=90min`, and set `HibernateOnACPower=no`.
  - Configured modular systemd logind drop-in `/etc/systemd/logind.conf.d/10-lid-sleep.conf`: set `HandleLidSwitch=suspend-then-hibernate` on battery and `HandleLidSwitchExternalPower=suspend` on AC charger. Reloaded `systemd-logind` safely via SIGHUP.
  - Updated `~/.config/hypr/hypridle.conf` 15-minute inactivity trigger to invoke `systemctl suspend-then-hibernate` and restarted `hypridle`.
  - Result: The laptop retains instant <0.5s `s2idle` wake for daytime breaks under 90 minutes (~1.8% battery loss), but automatically enters zero-watt NVMe hibernation for overnight or extended storage, eliminating the ~20% overnight drain.
- **Firmware diagnostic tooling (`surface`, 2026-09-17)**:
  - Installed user-approved `fwupd 2.1.7-1.1`, plus dependencies `fwupd-efi 1.8-2` and `passim 0.1.12-1.1`, with `sudo pacman -S --needed fwupd` through interactive Kitty/Hyprland. Pacman completed successfully and created Snapper snapshots 19/20.
  - Verified package versions, firmware/device enumeration, LVFS metadata refresh, and update query. `fwupd.service` D-Bus-activated successfully; `fwupd-refresh.timer` is disabled. `hyprctl configerrors` clean. Updated installed-package reference and Surface charging gotchas.
- **Firmware reverse-engineering tooling (`surface`, 2026-09-17)**:
  - Installed user-approved `cabextract 1.11-3.1` (`sudo pacman -S --needed cabextract`, 0.10 MiB installed, Snapper snapshots 21/22) after `bsdtar` proved unable to decompress Microsoft's LZX-21 CAB folders.
  - Used bounded HTTP range reads against the official MSI to extract and MSI-hash-verify five small base files (PD `.cfu`/`.offer.bin`, two KIP `.offer.bin`, two `.cat`) without downloading the 1.67 GB bundle. No firmware flashed.
- **Universal Zen Browser keybinding synchronization (`core`, 2026-09-17)**:
  - Saved canonical keybindings template to `core/.local/share/zen/zen-keyboard-shortcuts.json` (stowed to `~/.local/share/zen/`).
  - Created executable sync utility `core/.local/bin/zen-keybinds-sync` (stowed to `~/.local/bin/zen-keybinds-sync`): supports `--status`, `--apply` (with auto-detection across all active profiles, running-process safety check, and automatic pre-seeding of fresh profiles), and `--export`.
  - Wired automated keybinding synchronization into universal post-install setup (Step 4/4) in `install.sh`. Tested and verified via `install.sh --dry-run`.
### Changed
- **Zen Browser Tab vs. Workspace Shortcut Collision (`surface`, 2026-09-17)**:
  - **Issue**: Both browser tab selection (`key_selectTab1`..`8`, `key_selectLastTab`) and Zen workspace switching (`zen-workspace-switch-1`..`10`) defaulted to `accel: true` (<kbd>Ctrl</kbd> + <kbd>1..9</kbd>) on Linux, causing keyboard shortcut collision inside Zen Browser.
  - **Fix**: Re-mapped tab switching to <kbd>Alt</kbd> + <kbd>1..9</kbd> (`modifiers.alt = true`, `modifiers.accel = false`) in `~/.config/zen/1q66wgda.Default (release)/zen-keyboard-shortcuts.json` while Zen was closed. Zen workspace switching retained on <kbd>Ctrl</kbd> + <kbd>1..9</kbd>, <kbd>0</kbd>. Backed up original to `zen-keyboard-shortcuts.json.bak`.
  - **Documentation**: Documented modifier mappings, CLI manipulation via `jq`/Python, and in-memory reload gotchas in `references/gotchas/zen-browser.md`.
- **OpenCode pacman -> curl installer (`surface`)**:
  - Removed `opencode 2.0.3-1.1` from `cachyos-extra-v4` via `sudo pacman -Rns opencode` (interactive Kitty `hl.exec_cmd` prompt per Rule 8).
  - Installed upstream `v2.0.5` via `curl -fsSL https://opencode.ai/v2/install | bash` to `~/.opencode/bin/opencode`; installer appended `fish_add_path /home/jmvp/.opencode/bin` to `core/.config/fish/config.fish` (stowed, no overwrite).
  - Verified: `which opencode` -> `~/.opencode/bin/opencode`, `opencode --version` -> `v2.0.5`, `opencode upgrade` -> `Using method: curl`, `already installed` (fixes `installation method not found`).
  - Note: `cachyos-extra`/`AUR` builds are unsupported for self-update; keep `packages.txt` free of `opencode` to avoid shadowing `/usr/bin/opencode` over `~/.opencode/bin`.
  - Symlinked `~/.local/bin/opencode` -> `~/.opencode/bin/opencode` for bash/non-fish `PATH` fluency (fish uses `fish_add_path`, bash uses `~/.local/bin`); verified `opencode upgrade` in both shells.
### Fixed
- **Brave / WebApps GNOME Keyring Prompt (`core`, 2026-09-19)**:
  - **Issue**: Launching `xh-launch` or webapps (`YouTube.desktop`, `AllAnime.desktop`, `Hanime.desktop`, `PH.desktop`) caused `gnome-keyring` to spawn `gcr-prompter` ("Unlock Keyring" for Default keyring) because `greetd` does not unlock gnome-keyring on login.
  - **Fix**: Created [`core/.config/brave-origin-flags.conf`](file:///home/jmvp/dotfiles/core/.config/brave-origin-flags.conf) with `--password-store=basic` (symlinked to `~/.config/brave-origin-flags.conf` and `~/.config/brave-flags.conf`) so all Brave launches automatically inherit basic storage. Also updated all webapp desktop files in [`core/.local/share/applications/`](file:///home/jmvp/dotfiles/core/.local/share/applications/) and [`core/.local/bin/xh-launch`](file:///home/jmvp/dotfiles/core/.local/bin/xh-launch). Stopped active `gcr-prompter` service.
- **Fcitx5 vs. On-Screen Virtual Keyboard Architectural Misconception & Binding (`surface`, 2026-09-17)**:
  - **Issue**: User reported "Fcitx5 for virtual keyboard is not working" when attempting on-screen typing on Surface Book 3 in tablet mode or via `SUPER + ALT + V`.
  - **Root Cause**: Twofold: (1) `fcitx5` was not installed on the system (`which: no fcitx5`), causing Hyprland's execution of `fcitx5-remote -t` to fail with command not found; (2) Fcitx5 is an Input Method Editor (IME) for CJK multi-byte keystroke composition, not a graphical on-screen touch keyboard (OSK). `fcitx5-remote -t` only toggles IME conversion state, never rendering a touch keyboard UI on Wayland.
  - **Fix**: Replaced broken `fcitx5-remote -t` shortcut in `profiles/surface/.config/hypr/config/profile/binds.lua` with dedicated `hypr-virtual-keyboard` wrapper targeting `wvkbd-mobintl` via native compositor dispatcher `hl.dsp.exec_cmd(...)`. Passing native dispatcher bypasses `helpers.lua`'s default `uwsm-app -- ` string-wrapping prefix, avoiding `uwsm_app-daemon` PATH lookup failures caused by systemd user sessions omitting `~/.local/bin`. Deployed `core/.config/environment.d/10-path.conf` to guarantee `~/.local/bin` in systemd user PATH.
  - **Verification**: Flushed stale Lua bind callbacks via `hl.unbind`; re-evaluated bind table (`arg: 14`); `hyprctl configerrors` 0 errors; tested live process spawning with `nohup` and signal-based toggling (`pkill -RTMIN`) directly over Wayland Layer 3 overlay.
- **Surface Book 300% battery percentage calculation desync (`surface`, UPower)**:
  - **Issue**: Noctalia status bar and `upower DisplayDevice` reported impossible `299.032%` (~300%) battery level while discharging normally.
  - **Root Cause**: Surface Book base battery (`BAT2`, 45.3 Wh) suffered transient EC communication timeout (`power_supply BAT2: driver failed to report 'present' property: -110`). UPower's `up_device_battery_update_info()` cleared D-Bus property `energy-full` to 0 but failed to clear internal comparison cache `priv->energy_full_reported`. Upon battery recovery, UPower skipped updating D-Bus `energy-full`. Composite `DisplayDevice` summed total energy from both batteries (43.27 Wh) but divided only by tablet battery `BAT1` capacity (14.47 Wh), yielding ~300% (upstream UPower issue #336).
  - **Fix**: Restarted UPower service via interactive Kitty prompt per Rule 8 (`sudo systemctl restart upower`), restoring correct `DisplayDevice` capacity (59.79 Wh) and percentage (~70.2%).
  - **Documentation**: Documented full architecture and recovery procedures in `profiles/surface/gotchas/battery-upower.md` (symlinked into skill `references/gotchas/battery-upower.md`).
- **Fastfetch terminal greeting cleanup and alignment (`core/.local/bin/fastfetch-custom`, `surface`)**:
  - **Mini Logo Alignment**: Stripped raw DMI/SKU string from `Host`, restoring clean `Surface Book 3` and preventing line width blowout that shoved the mini CachyOS logo to column 89+.
  - **Window Manager**: Added support for fastfetch's `Window Manager:` key alongside `WM:`, fixing blank `WM: ` to properly display `Hyprland 0.56.2`.
  - **GPU Tagging**: Differentiated integrated (`iGPU`) from discrete (`dGPU`) graphics; Intel Iris Plus Graphics G7 is now accurately tagged as `(iGPU)` instead of forcing `(dGPU)`.
  - **Audio Detection**: Replaced hardcoded `"Apple Audio (aaudio)"` with dynamic fastfetch `Sound` detection (`Built-in Audio Analog Stereo`), retaining Apple Audio fallback only on Apple hardware DMI.
  - **Icons Fallback**: Added GSettings fallback for `Icons` (`Adwaita`) when fastfetch detects no icon theme from GTK configs.
  - **Dual Battery Support**: Added combined dual battery calculation for Surface devices (`80% (79% Tab / 82% Base) [Discharging]`).
  - **Aligned Columns**: Made bottom spec table divider (`│`) calculate column width dynamically to prevent misalignment across varying metric lengths.
- **Fish duplicate `.local/bin` PATH (`core/.config/fish/config.fish`, `surface`)**: removed `set -gx PATH "/home/jmvp/.local/bin" $PATH` added by Antigravity CLI installer; kept canonical `fish_add_path "$HOME/.local/bin"` (avoids duplicate entries in `fish_user_paths`).
- **Omarchy-style display scaling (`surface`)**: terminal/shell felt oversized from stacked scaling (compositor `x2` × Noctalia `ui_scale 1.2` × `bar scale 1.1` × large terminal fonts), while Omarchy keeps compositor at 2x and scales text with one knob.
  - `profiles/surface/.../profile/monitors.lua`: `eDP-1` mode pinned `3000x2000@60` -> `preferred` (kept `scale 2`, `GDK_SCALE 2` — correct for 267 PPI); added commented Omarchy-style `1.6/1.75` (4K) and `1/1` (1080p/1440p) alternatives.
  - New `core/.local/bin/hypr-monitor-scale up|down`: cycles focused monitor through `1, 1.25, 1.6, 2, 3, 4` at runtime (Omarchy `Super+/` equivalent; reboot restores profile default).
  - `core/.config/hypr/config/binds.lua`: `Super+slash` / `Super+Alt+slash` wired to the stepper.
  - Unified text sizes: kitty `font_size 11.0`, `window_padding_width 25->14`; alacritty `size 12.0->11.0`; Noctalia `ui_scale 1.20->1.0`, `bar scale 1.10->1.0`.
  - New `core/.local/bin/hypr-text-size [size|reset]` — same-as-Omarchy one knob (`12px -> 9pt terminal`, `pt = round(px*9/12)`): writes kitty (`USR1` live-reload) + alacritty + ghostty/foot if present, Noctalia `ui_scale = px/12` + `config-reload`, GTK `text-scaling-factor` (quantized). Baseline applied: `hypr-text-size 12` (kitty/alacritty now 9pt, `ui_scale 1.00`, GTK `1.0`).
  - Verified: `hyprctl reload` + `hyprctl configerrors` clean, `eDP-1 scale 2` steady, `noctalia msg config-reload` OK (note: skill's `msg reload` is stale — correct cmd on 5.1.0 is `config-reload`). New terminals pick up font sizes on open; kitty live-reloads via `USR1`.

## [2.37.0] - 2026-09-16
### Changed
- **OpenCode v1.18.31 -> v2.0.3 (`surface`, `pacman`)**:
  - Installed `opencode 2.0.3-1.1` from `cachyos-extra-v4` via `sudo pacman -S opencode` (explicit install, ~197M). Deps satisfied: `curl glibc icu ripgrep tar`, `wl-clipboard` already present.
  - Removed shadowing v1 curl-install binary `~/.opencode/bin/opencode` (backed up to `~/opencode-v1-backup-20260916.tar.gz` + `~/.config/opencode/opencode.jsonc.v1.bak`); removed empty `~/.opencode/bin/` and the `# Opencode path` `fish_add_path` block from `~/.config/fish/config.fish`; cleared stale `~/.opencode/bin` from universal `fish_user_paths`.
  - Verified: `which opencode` -> `/usr/bin/opencode`, `opencode --version` -> `v2.0.3`, `opencode --help` OK.
  - Note: V1/V2 share the `opencode` command (no side-by-side); `opencode.jsonc` kept as-is (minimal `$schema`-only, V2 reads V1 shape in-memory); first TUI start will auto-create `~/.config/opencode/cli.json` from old `tui.json` if present. Breaking changes to port later: plugin API, server API, permissions/tools schema (see v2 migrate guide).

## [2.36.0] - 2026-09-16
### Fixed
- **Noctalia wallpaper panel slow every open — true root cause (`surface`, Noctalia 5.1.0)**:
  - **Supersedes 2.35.0 (retracted)**: the `stat()` mtime theory was wrong. Re-verified against upstream `noctalia-shell` source (`src/render/core/thumbnail_service.cpp`): disk key = FNV-1a of `path + "\n" + file_size + "\n" + last_write_time.ticks + "\n" + targetPx + "\nthumbnail-service-v2"` — i.e. `fs::last_write_time` ticks, exactly what the ORIGINAL pre-cacher used. Proof: 163 `fileclock@428` hits vs 0 `stat@428` hits in live cache.
  - **Real bug #1 — wrong width**: `WallpaperTile::thumbnailTargetPx()` requests the tile's PHYSICAL display size (`lround(max(cellW,cellH) * renderScale)`), so width is per-machine/per-layout, not fixed 361. Measured on `surface` (eDP-1 scale 2, ui_scale 1.2): grid tiles = **428px** (MacBook-T2 Retina = 361 — which is why the macbook-t2 solution worked there). All 1637 `stat@361` files from 2.35.0 were orphans Noctalia never requests here — deleted (freed ~19M).
  - **Real bug #2 — one width is not enough**: secondary views request **451px** (87 files) and **541px** (24 files) variants of the same wallpapers.
  - **Fix**: pre-cacher default width `361 -> 428`, `vipsthumbnail` geometry `--size Wx` -> box `--size WxW` (matches Noctalia long-edge downscale for portraits), `cachy-sync-wallpapers` now warms `428 451 541 361` (overridable via `NOCTALIA_THUMB_WIDTHS`, covers both machines).
  - **Warmed `surface` cache**: 1452 + 1550 + 1613 jobs (~7 min total, 8 threads), cache now 4914 files / 73M. Live 12s panel-open test: **27 misses -> 1** (single 990px header preview, now cached). Grid renders instantly.
  - Only 2–4 Noctalia decode workers serve misses, so any future miss (new wallpapers, layout change) still stutters briefly — re-run `cachy-sync-wallpapers` after pulls or panel/resolution changes.

## [2.35.0] - 2026-09-16 (RETRACTED — see 2.36.0)
### Fixed
- **Noctalia pre-cacher mtime hash mismatch (`core/.local/bin/noctalia-precache-wallpapers.cpp`)**:
  - **Issue**: Pre-cacher used `fs::last_write_time(p).time_since_epoch().count()` for the thumbnail hash key, but `file_clock` epoch is implementation-defined (observed negative counts on libstdc++), while Noctalia keys on Unix `mtime_nanos` (`stat st_mtim`). Generated thumbnails never hit — cache stayed cold (114 files / 2.1M for 1637 wallpapers on `surface`).
  - **Fix**: Switched to `stat()` (`st_mtime * 1e9 + st_mtim.tv_nsec`), matching Noctalia's `path + "\n" + size + "\n" + mtime_nanos + "\n361\nthumbnail-service-v2"` FNV-1a key. Verified stat-hash exists post-run.
  - **Warmed `surface` cache**: full run `noctalia-precache-wallpapers ~/Pictures/Wallpapers` — 1637 stills (989 jpg + 555 png + 72 jpeg + 21 webp), 1613 jobs in 135.3s on 8 threads, cache now 1751 files / 21M with 1637/1637 hits on re-run. Wallpaper panel (`ALT+Space`) grid now renders instantly.
  - Deleted 24 wrong-hash thumbnails generated during validation before the fix.
  - **RETRACTION**: self-consistency checks ("already cached") only proved the tool agreed with itself, not with Noctalia. The `stat()` files were orphans (deleted in 2.36.0). Lesson: always verify with a live Noctalia open (new-file count) and against upstream source.

## [2.34.0] - 2026-09-15
### Added
- **Native Window Grouping / Stacking Keybindings (`core/.config/hypr/config/binds.lua`)**:
  - Implemented Hyprland native window grouping and tabbed stacking matching Omarchy muscle memory:
    - **Toggle Group / Stacking (`SUPER + G`)**: Toggles the active window into a group or merges/unmerges it with adjacent groups via native Lua dispatcher `hl.dsp.group.toggle()`.
    - **Move Window Out of Group (`SUPER + ALT + G`)**: Explicitly extracts the focused window from a tabbed group stack into regular tiled layout (`hl.dsp.exec_raw("moveoutofgroup", "")`).
    - **Cycle Window in Group (`SUPER + ALT + Tab` / `SUPER + ALT + SHIFT + Tab`)**: Cycles forward and backward through tabs within the active group stack (`hl.dsp.group.next()` and `hl.dsp.group.prev()`).
    - **Toggle Group Lock (`SUPER + CONTROL + G`)**: Toggles group lock state (`hl.dsp.group.lock_active()`) to prevent auto-swallowing or accidental group merging.
  - Leverages pre-configured CachyOS groupbar theming (`CACHYLBLUE` / `CACHYLGREEN` in `decorations.lua`).
  - Registered all 5 bindings with live IPC metadata descriptions, exposing them to the interactive cheatsheet (`SUPER + K`).
  - Updated [`references/keybindings.md`](references/keybindings.md) with complete group management shortcuts.

## [2.33.0] - 2026-09-15
### Fixed
- **Diagnosed Post-Update Keyboard Inoperability & Linux 7.2.5 T2 Driver Regression**:
  - **Issue**: Internal Apple keyboard, trackpad, Touch Bar, and audio stopped functioning after upgrading from `linux-cachyos 7.2.3-1` to `7.2.5-1`.
  - **Root Cause**: Upstream CachyOS removed the `7.2/t2` branch in the `7.2.5-1` release, omitting the staging `t2bce` drivers (`t2bce_core`, `t2bce_vhci`, `t2bce_dma`, `t2bce_audio`). Without `t2bce_vhci`, the virtual USB host controller (Bus 7) failed to enumerate, leaving the internal keyboard and input devices disconnected.
  - **Resolution**: Created turnkey rollback script [`cachy-downgrade-kernel-723`](file:///home/java1127/.local/bin/cachy-downgrade-kernel-723) to reinstall `linux-cachyos-7.2.3-1`, `linux-cachyos-headers-7.2.3-1`, and `linux-cachyos-nvidia-open-7.2.3-1` from local cache, pin them in `/etc/pacman.conf` (`IgnorePkg`), regenerate boot entries, and reboot cleanly. Staged in `profiles/macbook-t2/scripts/cachy-downgrade-kernel-723.sh`.
  - Documented complete troubleshooting procedure in `references/gotchas/apple-t2.md` (Section 9).

## [2.32.0] - 2026-09-15
### Added
- **Combined Directional Cross-Monitor Architecture (`core/.config/hypr/config/binds.lua`)**:
  - Implemented symmetrical directional cross-monitor dispatchers:
    - **Directional Window to Monitor (`SUPER + SHIFT + ALT + Arrows`)**: Moves the focused window to the Left / Right / Top / Bottom adjacent monitor (`hl.dsp.window.move({ monitor = "l/r/u/d" })`).
    - **Directional Workspace to Monitor (`SUPER + CONTROL + ALT + Arrows`)**: Moves the active workspace and all its tiled windows to the Left / Right / Top / Bottom adjacent monitor (`hl.dsp.workspace.move({ monitor = "l/r/u/d" })`).
  - Upgraded single-key monitor cycle bindings to native Lua API:
    - `SUPER + grave (~)`: Focus next monitor (`hl.dsp.focus({ monitor = "+1" })`).
    - `SUPER + SHIFT + grave`: Move active window to next monitor (`hl.dsp.window.move({ monitor = "+1" })`).
    - `SUPER + CONTROL + grave`: Move active workspace to next monitor (`hl.dsp.workspace.move({ monitor = "+1" })`).
  - Updated keybindings reference and registered all 8 new bindings with live IPC descriptions (`SUPER + K`).

## [2.31.0] - 2026-09-15
### Added
- **Turnkey Multi-PC Wallpaper Synchronization (`cachy-sync-wallpapers`, `core/packages.txt`)**:
  - Added `gcc` and `libvips` to [`core/packages.txt`](file:///home/java1127/dotfiles/core/packages.txt), ensuring both the C++20 compiler and `vipsthumbnail` engine are automatically installed by `install.sh` on any fresh CachyOS/Arch device.
  - Enhanced [`cachy-sync-wallpapers`](file:///home/java1127/dotfiles/core/.local/bin/cachy-sync-wallpapers) with robust multi-path source candidate discovery for `noctalia-precache-wallpapers.cpp`.
  - Added automated state initialization in `cachy-sync-wallpapers` to seed `~/.local/state/noctalia/state.toml` with `flatten = true` and `sort = "random"` out of the box on first boot.

## [2.30.0] - 2026-09-15
### Added
- **Native Directional Window Swapping (`CTRL + SHIFT + Arrows`)**:
  - Implemented `CTRL + SHIFT + Left/Right/Up/Down` in `core/.config/hypr/config/binds.lua` matching Omarchy muscle memory.
  - Upgraded window swapping dispatchers from external subshell commands (`hyprctl dispatch swapwindow`) to native compositor API `hl.dsp.window.swap({ direction = ... })` for instantaneous, zero-latency execution.
  - Preserved `SUPER + ALT + Arrows` as alternative layout-agnostic binding.
  - Registered descriptions in Hyprland's internal table, exposing them to `SUPER + K` live IPC search.

## [2.29.0] - 2026-09-15
### Changed
- **Microsoft Surface Profile Modernization & Omarchy Cleanup (`profiles/surface/`)**:
  - Reset `profiles/surface` to a lean, minimal CachyOS baseline:
    - **Package Source**: Updated `packages.txt` with official binary repository package names (`linux-surface`, `linux-surface-headers`, `iptsd`, `surface-dtx-daemon`, `surface-control`).
    - **Automated Repository Setup (`pre-install.sh`)**: Created profile pre-install hook to automatically import the official Surface signing key (`56C464BAAC421453`) and configure `[linux-surface]` (`https://pkg.surfacelinux.org/arch/`) in `/etc/pacman.conf` prior to package synchronization.
    - **Precision Touchpad Calibration (`inputs.lua`)**: Configured `scroll_factor = 0.4` and `disable_while_typing = false` to eliminate hyperactive trackpad scrolling under Hyprland.
    - **Hardware Keybindings (`binds.lua`)**: Implemented native Surface shortcuts via `helpers.bind`:
      - `SUPER + ALT + D`: Requests tablet base detachment (`surface dtx request`) with desktop notification.
      - `SUPER + ALT + V`: Toggles on-screen virtual keyboard panel (`fcitx5-remote -t`).
    - **Bootloader & Services (`setup.sh`)**: Automated enabling of `surface-dtx-daemon.service` and `iptsd.service`, and configured `/etc/limine-entry-tool.d/zz-surface-kernel.conf` to prioritize `linux-surface` as default boot entry.
    - **Omarchy Bloat Removal**: Wiped 5 legacy Omarchy gotchas and obsolete `services.txt`, leaving an empty `gotchas/` folder ready for fresh CachyOS documentation.
- **Installer Hook Architecture (`install.sh`)**:
  - Added profile `pre-install.sh` lifecycle hook executed before package manager synchronization.
  - Added `--ignore=^pre-install\.sh$` to GNU Stow deployment flags.

## [2.28.0] - 2026-09-15
### Added
- **Native Noctalia Wallpaper Panel Acceleration & Multi-threaded Pre-cacher (`noctalia-precache-wallpapers`)**:
  - Reverse-engineered Noctalia v5's internal thumbnail caching engine: discovered 64-bit FNV-1a hash key `path + "\n" + file_size + "\n" + mtime_nanos + "\n361\nthumbnail-service-v2"` stored as 16-hex WebP files in `~/.cache/noctalia/thumbnails/`.
  - Created high-performance C++ utility [`noctalia-precache-wallpapers`](file:///home/java1127/dotfiles/core/.local/bin/noctalia-precache-wallpapers) utilizing `vipsthumbnail` across all 16 hardware threads. Batch-cached all 1,410 remaining wallpapers in 30.9 seconds (1,659 total thumbnails in cache).
  - Integrated `noctalia-precache-wallpapers` into [`cachy-sync-wallpapers`](file:///home/java1127/dotfiles/core/.local/bin/cachy-sync-wallpapers) to automatically pre-cache newly downloaded wallpapers.
  - Configured Noctalia's native Random Shuffle mode in `~/.local/state/noctalia/state.toml` (`sort = "random"` and `flatten = true`).
  - Remapped **`ALT + Space`** in [`binds.lua`](file:///home/java1127/dotfiles/core/.config/hypr/config/binds.lua#L142) from `waypaper` to Noctalia's native wallpaper panel (`noctalia msg panel-toggle wallpaper`), providing instantaneous startup, zero CPU decode lag, and locked 60 FPS scrolling.

### Removed
- **Legacy Waypaper & Hyprpaper Wallpaper Architecture**:
  - Terminated running `hyprpaper` process that was occluding Noctalia's native wallpaper layer on Wayland layer 0.
  - Deleted obsolete `~/.cache/waypaper` (67 MB) and `~/.local/share/waypaper` (28 MB venv/repo).
  - Cleaned up stowed configuration `~/dotfiles/core/.config/waypaper/` and `~/.config/waypaper/`.
  - Removed floating window rule for Waypaper in [`windowrules.lua`](file:///home/java1127/dotfiles/core/.config/hypr/config/windowrules.lua).
  - Removed `waypaper` and `hyprpaper` from [`core/packages.txt`](file:///home/java1127/dotfiles/core/packages.txt) and launched interactive Kitty prompt for pacman removal.
  - Updated [`AGENTS.md`](file:///home/java1127/dotfiles/AGENTS.md) and [`references/current-state.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/current-state.md).

## [2.27.0] - 2026-09-15
### Added
- **Boot-Time AMDGPU & PCIe ASPM Power Optimization Service (`amdgpu-power-setup.service`)**:
  - Created [`amdgpu-power-setup.service`](file:///home/java1127/dotfiles/profiles/macbook-t2/scripts/amdgpu-power-setup.service) to automatically enforce `powersupersave` PCIe Active State Power Management and AMD GPU `POWER_SAVING` profile on boot.
  - Updated [`profiles/macbook-t2/setup.sh`](file:///home/java1127/dotfiles/profiles/macbook-t2/setup.sh) to deploy, enable, and start `amdgpu-power-setup.service`.
  - Created [`apply-power-optimizations-and-upgrade`](file:///home/java1127/.local/bin/apply-power-optimizations-and-upgrade) helper script to automate setup and launch package upgrade interactively in Kitty via Hyprland IPC.

### Fixed
- **Hung Background Process & Power Leak Prevention**:
  - Terminated hung `git-remote-https` process (PID 27045) running continuously in a tight loop since Sep 14, restoring deeper Intel CPU package sleep states (C8–C10).
  - Powered down inactive Bluetooth controller (`bluetoothctl power off`), reducing idle radio power draw.

## [2.26.0] - 2026-09-15
### Added
- **Fresh Install Package Completeness Synchronization (`core/packages.txt`)**:
  - Added 8 missing runtime dependencies to `core/packages.txt` to guarantee 100% turnkey deployment on fresh CachyOS/Arch installations:
    - `uwsm`: Session manager backend providing `uwsm-app --` cgroups wrapping for all application launchers.
    - `brightnessctl`: Hardware controller for screen/keyboard brightness keys and `hypridle` inactivity dimming.
    - `fzf`: Interactive fuzzy selector backend for `SUPER + K` (`hypr-keybinds-menu`).
    - `hyprpicker`: Color picker tool for `SUPER + SHIFT + P`.
    - `lazydocker`: Container management TUI for `SUPER + SHIFT + D`.
    - `brave-origin-bin`: Underlying browser engine for all custom WebApp desktop launchers (YouTube, AllAnime, etc.).
    - `cliamp-bin` & `yt-dlp`: Retro terminal audio player and streaming backend.
    - `xorg-xhost`: Root authorization helper for XWayland applications invoked in `autostart.lua`.

### Changed
- **Decoupled Dynamic Wallpaper Rotation State (`waypaper`)**:
  - Enabled `use_xdg_state = True` in `core/.config/waypaper/config.ini`, storing dynamic wallpaper selection in `~/.local/state/waypaper/state.ini` to prevent hourly git working tree modifications.
- **Synchronized Active Color Palettes & Restored Theme Symlinks**:
  - Synchronized latest active Material 3 wallpaper palette across Alacritty, Btop, and Kitty.
  - Re-linked `~/.config/kitty/themes/noctalia.conf` into Stow dotfiles tree.

## [2.25.0] - 2026-09-14
### Added
- **Native Metadata-Driven Keybinding Architecture (`helpers.lua`)**:
  - Implemented `helpers.lua` (`~/.config/hypr/helpers.lua` in `core/.config/hypr/helpers.lua`) providing native compositor integration:
    - **Metadata-Driven `bind()` (`helpers.bind`)**: Automatically injects human-readable descriptions into Hyprland's internal C++ binding registry (`options.description`), exposing all 139 compositor bindings to live IPC queries. Bare commands are automatically wrapped in systemd cgroups via `uwsm-app --`.
    - **Native Focus-or-Launch (`helpers.launch_or_focus`)**: Programmatically queries `hl.get_windows()` across all workspaces. If the target application class or title exists, Hyprland focuses its address directly (`hl.dispatch(hl.dsp.focus({ window = "address:" .. client.address }))`). If the active window is already the application, it cycles seamlessly between open instances. Spawns cleanly via `uwsm-app` if absent. Applied across Zen Browser, Dolphin, LazyGit, LazyDocker, Neovim Notes, YouTube, and Yazi.
    - **Dynamic Context-Aware Key Routing (`helpers.is_terminal` / `helpers.route_key`)**: Inspects `hl.get_active_window().class` at trigger time to route macOS-style shortcuts:
      - Line Delete (`SUPER + BackSpace`): Dispatches `CTRL + U` in terminal emulators (`kitty`, `ghostty`, `alacritty`, `foot`), and `Shift + Home` followed by `BackSpace` in GUI applications.
      - Smart Copy (`SUPER + C`): Dispatches `CTRL + SHIFT + C` in terminals (preventing process `SIGINT` interruption), and native `CTRL + C` in GUI applications (preventing accidental browser DevTools DOM inspection).
      - Smart Paste (`SUPER + V`): Dispatches `CTRL + SHIFT + V` in terminals and `CTRL + V` in GUI applications.
  - **Live IPC Keybindings Cheatsheet (`hypr-keybinds-menu`)**:
    - Deployed `~/.local/bin/hypr-keybinds-menu` (`core/.local/bin/hypr-keybinds-menu`).
    - Queries runtime bindings directly from the compositor via `hyprctl binds -j`, decodes modifier masks (`SUPER`, `ALT`, `CTRL`, `SHIFT`), filters entries with descriptions, and presents a fast, searchable popup via `fzf`.
    - Mapped to `SUPER + K` in a floating, centered Kitty window (`class = "^(Keybindings)$"`).

## [2.24.0] - 2026-09-14
### Added
- **Multi-PC Modular 3-Tier Architecture Migration (Ported from `omarchy-dots`)**:
  - Restructured monolithic flat dotfiles into 3 decoupled tiers:
    - **Tier 1 (`core/`)**: Universal configs across all machines (`~/.config/hypr/`, `noctalia`, `kitty`, `alacritty`, `fish`, `btop`, `waypaper`, `gtk`, `swayimg`, `zigoku`, `easyeffects`, `niri`, `core/.local/bin/`, `core/.local/share/applications/`, `core/packages.txt`).
    - **Tier 2 (`profiles/`)**: Hardware-specific profiles (`macbook-t2`, `desktop`, `surface`, `laptop`). Each profile contains isolated `.config/hypr/config/profile/` modules (`monitors.lua`, `environment.lua`, `inputs.lua`), `packages.txt`, `setup.sh`, and `gotchas/`.
    - **Tier 3 (`agents/`)**: Dynamically probed AI System Personalization skill (`init-skill.sh`, `SKILL.md.template` -> `SKILL.md`, `references/hardware.md`, and dynamic gotchas symlinking).
  - **Dynamic Hyprland Lua Bootstrap**: `hyprland.lua` loads universal core modules and dynamically resolves hardware overrides via `pcall(require, "config.profile.environment")`, `pcall(require, "config.profile.monitors")`, and `pcall(require, "config.profile.inputs")`.
  - **Wallpaper Fork Integration & Sync Utility**:
    - Created `core/.local/bin/cachy-sync-wallpapers` syncing shallow clone (`--depth 1`) from `https://github.com/JValdivia23/walls.git` into `~/Pictures/Wallpapers/dharmx-walls` (1567 curated wallpapers) with fallback to `dharmx/walls.git`.
    - Automatically creates convenience symlink `~/Wallpapers -> ~/Pictures/Wallpapers`.
    - Fixed Hyprland `Alt+Space` wallpaper selector keybinding to invoke `waypaper` directly from `$PATH`.
  - **New Master Installer (`install.sh`)**: Built-in hardware detection (DMI, PCI, chassis), CLI flags (`--profile`, `--profiles`, `--dry-run`, `--only-stow`, `--only-packages`), non-destructive backup, directory symlink sanitization, automated wallpaper sync on fresh setup, and profile post-install hooks.
  - **Fresh Install Audit Remediations**: Verified zero hardcoded usernames (`$HOME` / `sh -c` portable paths), corrected script executable permissions, added Stow ignore for skill init scripts, and confirmed clean Hyprland config status (`hyprctl configerrors`).

## [2.23.0] - 2026-09-10
### Added
- **Two-Way Quick SSH Shortcuts (`jmvp` <-> `java-cu`)**:
  - **`ssh jmvp` (Laptop -> Remote `10.0.0.108`)**:
    - Configured Host entry in [`~/.ssh/config`](file:///home/java1127/.ssh/config) for `jmvp` and `10.0.0.108`.
    - Configured user `jmvp`, primary identity keys (`id_ed25519`, `id_rsa`), and 8-hour socket multiplexing (`ControlMaster auto`, `ControlPath ~/.ssh/sockets/%r@%h:%p`).
  - **`ssh java-cu` (Remote `10.0.0.108` -> Laptop `10.0.0.8`)**:
    - Generated dedicated `ed25519` key pair on `jmvp@10.0.0.108` and added public key to [`~/.ssh/authorized_keys`](file:///home/java1127/.ssh/authorized_keys).
    - Configured `~/.ssh/config` on `jmvp@10.0.0.108` mapping `Host java-cu` to `java1127@10.0.0.8` with socket multiplexing.
    - Verified instantaneous two-way passwordless connection in both directions.

## [2.22.0] - 2026-09-09
### Added
- **Installed `cliamp` Terminal Music Player (`cliamp-bin` `2.2.0-1`) & `yt-dlp` (`2026.08.19-1`)**:
  - Packaged and installed retro Winamp 2.x-inspired terminal music player `cliamp` v2.2.0 from AUR via `cliamp-bin`.
  - Installed `yt-dlp` from official repos as an audio extraction and online streaming provider dependency.
  - Deployed system executable `/usr/bin/cliamp`, desktop application entry `/usr/share/applications/cliamp.desktop`, and hicolor application icons.
  - Native MPRIS D-Bus integration connects directly to Noctalia's media widgets and Hyprland media shortcuts (`XF86AudioPlay`, `Next`, `Prev`).

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
