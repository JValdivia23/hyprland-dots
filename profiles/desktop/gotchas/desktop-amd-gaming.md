# Desktop Workstation Hardware & Gaming Gotchas (`cachyos-obsidian` / MSI MS-7D75)

Curated hardware quirks, audio fixes, peripheral workarounds, and gaming optimizations for the AMD Ryzen 5 7600X + Radeon RX 7700 XT (RDNA 3) desktop workstation running CachyOS Linux with Hyprland.

---

## 1. DisplayPort Screen Blanking (1–2s Black Screen) on AMD RDNA 3 (`RX 7700 XT`)

- **Symptom**: Primary 4K DisplayPort monitor (`DP-1`, KTC A32Q8) goes black for 1–2 seconds intermittently. No errors appear in `dmesg` or `journalctl`.
- **Root Cause**: The `amdgpu` Display Core (DC) driver aggressively manages DP link power, triggering link re-training that briefly drops the video signal. Scatter-gather display mode can also cause instability on RDNA 3 GPUs.
- **Fix**: Add `amdgpu.dcdebugmask=0x10 amdgpu.sg_display=0` to kernel boot parameters:
  - On CachyOS (`systemd-boot`), edit `LINUX_OPTIONS` in `/etc/sdboot-manage.conf`, then run `sudo sdboot-manage gen` and reboot.
  - On Limine, append to `KERNEL_CMDLINE[default]` in `/etc/default/limine` and run `sudo limine-update`.

---

## 2. AMDGPU GTT Memory Pinning / Leak Under Heavy Vulkan Games

- **Symptom**: System RAM reaches 100% or OOM-killer terminates background apps (browsers, Steam Web Helper) after extended Vulkan gaming sessions (e.g. Dota 2).
- **Root Cause**: `amdgpu` dynamically maps up to 50% of system RAM as GTT (Graphics Translation Table). Under certain Vulkan workloads, memory mapped during gameplay remains pinned as `gpu_active` in system RAM after exiting the game.
- **Troubleshooting & Mitigation**:
  1. Monitor GPU/GTT memory allocation with `amdgpu_top` or check `journalctl -k` for `gpu_active`.
  2. Close memory-heavy browser instances before launching resource-intensive Vulkan titles on 16 GB RAM configurations, or customize GTT limits via `amdgpu.gttsize=X` in kernel boot parameters if needed.

---

## 3. Dual AMD GPU Telemetry (Ryzen 7600X `Raphael` iGPU vs `RX 7700 XT` dGPU)

- **Quirk**: The Ryzen 5 7600X includes an integrated AMD Raphael GPU (`12:00.0`) alongside the discrete Radeon RX 7700 XT (`03:00.0`).
- **Symptom**: Scripts or bars hardcoding `/sys/class/drm/card0/` may query the idle integrated CPU GPU instead of the active discrete card. Similarly, AMD CPU temperature is exposed at `/sys/class/hwmon/hwmon*/temp1_input` (`k10temp` `Tctl`), **not** `/sys/class/thermal/thermal_zone0/temp`.
- **Fix**: Filter DRM cards by checking `mem_info_vram_total` (> 2 GB) to select the discrete GPU (`RX 7700 XT`), or inspect live metrics via `amdgpu_top`.

---

## 4. Logitech G903 LIGHTSPEED Scroll Wheel Broken in XWayland Games & `hidpp_battery_0` Laptop Misclassification

- **Scroll Wheel Symptom**: Mouse wheel inputs are unresponsive inside XWayland games (Dota 2, CS2, Proton titles).
- **Scroll Wheel Root Cause**: Modern gaming mice like the Logitech G903 LIGHTSPEED emit high-resolution smooth scroll events (`REL_WHEEL_HI_RES`) under `libinput`, which XWayland drops when translating to legacy X11 discrete button clicks (Button 4/5).
- **Two-Layer Scroll Fix (Automated by `profiles/desktop/`)**:
  1. **Hyprland Input Config (`profiles/desktop/.config/hypr/config/profile/inputs.lua`)**: Sets `emulate_discrete_scroll = 2` globally inside `input` and configures `hl.device({ name = "logitech-g903-ls-1", scroll_factor = 1.0, natural_scroll = false })`.
  2. **System `libinput` Quirks (`profiles/desktop/.config/libinput/local-overrides.quirks`)**: Strips `REL_WHEEL_HI_RES` and `REL_HWHEEL_HI_RES` for G903 USB/LIGHTSPEED receivers (`046D:4087`). `profiles/desktop/setup.sh` copies this file to `/etc/libinput/local-overrides.quirks` and reloads `udevadm`.
- **`hidpp_battery_0` Laptop Detection Gotcha**:
  - The G903 LIGHTSPEED exposes `/sys/class/power_supply/hidpp_battery_0` (`type=Battery`, `scope=Device`).
  - Naive `ls /sys/class/power_supply/ | grep -i battery` checks misclassify desktop towers (`SYS_CHASSIS=3`) as laptops. `install.sh` and `init-skill.sh` explicitly check SMBIOS desktop chassis codes (`3|4|5|6|7|13|15|16`) and filter out `scope == "Device"` peripheral batteries.

---

## 5. Attack Shark X85 Mechanical Keyboard (`0c45:fefe` SONiX) Fn & Modifier Layout

- **Symptom**: In hardware Mac mode, raw function keys default to media controls, requiring `Fn` for F1–F12. In hardware Windows mode, F1–F12 work natively, but the bottom modifier row is `Ctrl - Super - Alt`.
- **Fix**: Keep the physical keyboard switch in **Windows Mode** (retaining native F1–F12 keys) and toggle Left Alt / Left Win in software whenever desired using `SUPER + Shift + K` or `SUPER + Alt + K` (`~/.local/bin/hypr-toggle-altwin`).
- **Layout Switching (`US` <-> `LATAM`)**: Use `SUPER + Alt + L` (`~/.local/bin/hypr-switch-layout`) to cycle layouts on `sonix-x85` and `2.4g-dongle` devices.

---

## 6. Realtek ALC4080 / ALC4082 Low Microphone Volume (`usb-Generic_USB_Audio`)

- **Symptom**: Microphone connected to the MSI MAG B650 TOMAHAWK WIFI (`MS-7D75`) front/rear 3.5mm jack is very quiet even at 100% ALSA gain.
- **Root Cause**: The Realtek ALC4080/ALC4082 is a USB-bridged audio controller whose hardware Microphone Boost amplifier (+10/+20/+30 dB) is not exposed by the Linux USB audio driver.
- **Fix**: Software amplification and noise suppression via **EasyEffects** (`easyeffects --gapplication-service`, autostarted in `profiles/desktop/.config/hypr/config/profile/autostart.lua`) with `lsp-plugins` (`autogain#0` + `rnnoise#0` stored in `profiles/desktop/.config/easyeffects/db/`).
- **Line Input vs. Microphone Priority Gotcha**: On `usb-Generic_USB_Audio`, PipeWire assigns `HiFi__Line__source` a higher `priority.session` (`1828`) than `HiFi__Mic__source` (`1812`), even when the Line jack is unplugged (`off`). With `easyeffects_source` as the PipeWire default source, leaving `useDefaultInputDevice` unset/enabled in `profiles/desktop/.config/easyeffects/db/easyeffectsrc` can cause EasyEffects to fall back to `HiFi__Line__source`. Pin `inputDevice=alsa_input.usb-Generic_USB_Audio-00.HiFi__Mic__source` and `useDefaultInputDevice=false` under `[StreamInputs]` (stop EasyEffects with `easyeffects -q` before editing so it doesn't flush stale state on exit).

---

## 7. Steam Launch Segmentation Fault (`libaudio.so` / `threaded-ml`) & 1.67x HiDPI Scaling

- **Symptom**: Steam crashes on launch with `Segmentation fault (core dumped)` (exit code 139) in `libpulse.so.0` / `libaudio.so` when PipeWire-Pulse or EasyEffects virtual sources are in a stale socket state, or renders with tiny UI on the 4K@1.67x primary monitor.
- **Fix (`profiles/desktop/.local/bin/steam` & `packages.txt`)**:
  1. `lib32-libpulse` is included in `profiles/desktop/packages.txt`.
  2. `~/.local/bin/steam` merges `~/.Xresources` (`Xft.dpi: 144`), exports `STEAM_FORCE_DESKTOPUI_SCALING=1.67` and `SDL_VIDEODRIVER=wayland`, and automatically catches exit code `139` to restart `pipewire`, `pipewire-pulse`, and `wireplumber` while preserving and re-linking the EasyEffects default microphone source before retrying launch.

---

## 8. Dota 2 Multi-Monitor Routing (`HDMI-A-1` Workspace 8) & F9 Dictation Passthrough

- **Workspace Routing & True Fullscreen**: Workspace `8` is bound to the secondary 1440p@144Hz monitor (`HDMI-A-1`) in `profiles/desktop/.config/hypr/config/profile/monitors.lua`, paired with the `dota2-ws8-fullscreen` `hl.window_rule` (`workspace = "8"`, `fullscreen = true`, `content = "game"`, `decorate = false`). `~/.local/bin/dota2-workspace` uses Hyprland Lua `hyprctl eval` (`hl.dsp.window.move` with `follow = false`, `hl.dsp.focus`, and `hl.dsp.window.fullscreen({ mode = "fullscreen", action = "set" })`) so `dota2` / `gamescope` windows always move to workspace `8` and enforce true fullscreen (`fullscreen = 2`, not maximized `1`).
- **Fullscreen Alt+Tab Protection**: `on_focus_under_fullscreen = 1` in `inputs.lua` prevents fullscreen games from collapsing into dwindle tiles when Alt+Tabbing.
- **F9 Voice Dictation Passthrough**: `~/.local/bin/hypr-dictate` checks `hyprctl activewindow` for `class: dota2` and forwards `F9` directly to the game window via `hyprctl eval 'hl.dispatch(hl.dsp.send_shortcut({ mods = "", key = "F9", window = "activewindow" }))'` (for match pause/unpause) instead of starting voice dictation.

---

## 9. Secondary 1440p Brightness Pulsing at 120Hz (`HDMI-A-1` KTC Q24T09)

- **Symptom**: Rapid brightness / gamma pulsing or flickering on the secondary 24" 1440p monitor (`HDMI-A-1`) when running at `2560x1440@120` (`119.998Hz`), especially noticeable across dark/gray backgrounds (Ghostty, Discord). Appeared after the `2026-11-08` kernel (`7.3.3-1-cachyos`) + Hyprland (`0.57.1` / Aquamarine `0.16.0`) upgrade.
- **Investigation Findings**:
  1. Even with Hyprland `misc.vrr = 0` (`VRR_ENABLED: 0`), `HDMI-A-1` still exposes `passive_vrr_capable: 1` and CRTC `PASSIVE_VRR_DISABLED: 0` in kernel `7.3.3` `amdgpu` (which Aquamarine `0.16.0` does not toggle).
  2. Live isolation confirmed the flicker was tied specifically to the `120Hz` mode (`497.75 MHz` pixel clock, 85-line vblank): disabling Hyprland blur, color management (`cm_enabled`), and software cursors (`no_hardware_cursors = 0`) did not stop it at `120Hz`, whereas both `60Hz` (`241.57 MHz`) and `144Hz` (`583.61 MHz`, 50-line vblank) ran completely flicker-free with default compositor settings.
- **Fix**:
  1. Switched `HDMI-A-1` mode from `2560x1440@120` to `2560x1440@144` in `profiles/desktop/.config/hypr/config/profile/monitors.lua` while keeping `vrr = 0` and `misc.vrr = 0` in `core/.config/hypr/config/misc.lua`.
  2. Keep game-specific presentation overrides (`vblank_mode=0`, `RADV_PRESENT_MODE=mailbox`) scoped inside game launch commands rather than globally in `environment.lua` to maintain clean desktop VSync pacing.

---

## 10. `hyprresume` Multi-Window Steam/Discord Restore & Deterministic BSP Reconstruction

- **Symptom**: On reboot, Discord + multi-window Steam (`Steam`, `Friends List`, chat windows) restore with flipped split orientation, Steam crushed to ~107px width, `Friends List` stuck floating (due to `core/windowrules.lua`), and Steam launched without `~/.local/bin/steam` HiDPI/PipeWire flags.
- **Root Causes**:
  1. Upstream `hyprresume` `v0.5.0` `[overrides]` only parsed `*`/`?` globs as patterns; regex keys like `"^steam$"` went into `exact_overrides` and failed to match `"steam"`.
  2. With `per_window_launch = true` and no saved window `title`, Steam was launched once per window (3×), `openwindow` matched transient updater splashes (`Discord Updater` / Steam xwin updater), and asynchronous bursts bypassed dwindle `preselect`.
  3. `apply_split_ratios()` sent `splitratio (ratio - 0.5)` instead of Hyprland dwindle's `[0.1, 1.9]` scale (`splitratio {2.0 * ratio} exact`), and `converge_tiled_sizes()` double-resized opposing sibling splits down to Hyprland's `0.1` minimum (~107px).
  4. `hyprresume` ran without `-v` with stdout/stderr at `/dev/null`, and periodic saves overwrote `last.toml` while slow apps were still restoring.
- **Fix (`~/hyprresume/lua-ipc-support.patch` + `~/.config/hypr/hyprresume.toml` + `profile/autostart.lua`)**:
  1. Patched `hyprresume` to persist window `title`, support `^...$` regex overrides, deduplicate launches for single-instance multi-window apps (`steam`, `discord`, `vesktop`, `spotify`), skip transient updater splashes, and deterministically reconstruct each workspace's dwindle BSP tree via `float(enable) -> focus(parent) -> preselect -> float(disable)` (which also re-tiles saved-tiled windows like `Friends List` that open floating via default window rules).
  2. Fixed `apply_split_ratios()` (`2.0 * ratio exact`), guarded `converge_tiled_sizes()` (`MIN_CONVERGED_TILE_DIM = 200`, `MAX_CONVERGE_DELTA = 400`, damped steps), clamped floating window positions to target monitor usable bounds, paused periodic saves while `watch_late_windows` is active, and skipped `restore_on_start` when windows are already open on mid-session restarts.
  3. Updated `~/.config/hypr/hyprresume.toml` (`"steam" = "/home/jairo/.local/bin/steam"`, `"discord" = "/usr/bin/discord"`) and launched `hyprresume` via `systemd-cat -t hyprresume -- ~/.local/bin/hyprresume -v` so boot logs are inspectable via `journalctl --user -t hyprresume`.

---

## 11. Intermittent Horizontal Black Lines / Top-Band Flickering on Dual Mixed-Refresh Displays (`RX 7700 XT` DPM Clock Switching)

- **Symptom**: Occasional, random horizontal black lines or faint black bands near the top of the screen, appearing on both monitors (`DP-1` 4K@60Hz and `HDMI-A-1` 1440p@144Hz) one at a time (unsynchronized). Started after the `2026-11-08` kernel `7.3.x` + `linux-firmware-amdgpu 1:20261019-1` (`DMUB 0x07003600`) + Noctalia migration.
- **Root Cause & Isolation**:
  1. Updating to `linux-cachyos 7.3.5-1`, `mesa 26.3.1-1`, `hyprland 0.57.2-1.1`, and `noctalia 5.5.0-1.1` did not stop the flicker.
  2. Live A/B isolation ruled out Hyprland blur (`decoration:blur:enabled = false`), software cursors (`cursor:no_hardware_cursors = 0`), VRR (`misc:vrr = 0`), and Noctalia (`killall -TERM noctalia` with zero active layer surfaces still flickered).
  3. Under `power_dpm_force_performance_level = auto`, `card1` (`0x1002:0x747e`) sat at `MCLK 772 MHz` (not max `1124 MHz`) with `FCLK` (`1200 <-> 1801 MHz`) and `SOCCLK` (`750 <-> 1200 MHz`) actively bouncing at idle. Because `60Hz` and `144Hz` vblanks rarely align, SMU clock transitions overrunning vblank starve the display FIFO at the start of active scanout (row 0 = top of display), producing brief black horizontal lines/bands on whichever monitor just exited vblank.
  4. Locking `power_dpm_force_performance_level = high` pinned `MCLK` (`1124 MHz`), `FCLK` (`2301 MHz`), and `SOCCLK` (`1500 MHz`) while `SCLK` still idled at `43 MHz` (`28W -> 36W` idle, `44°C`), completely eliminating the flickering for 1+ hour.
- **Fix (`profiles/desktop/scripts/` + `setup.sh`)**:
  1. Deployed `/etc/udev/rules.d/99-amdgpu-rx7700xt-dpm.rules` (from `profiles/desktop/scripts/99-amdgpu-rx7700xt-dpm.rules`) matching strictly `SUBSYSTEM=="drm", KERNEL=="card[0-9]", DRIVERS=="amdgpu", ATTRS{vendor}=="0x1002", ATTRS{device}=="0x747e"` to set `ATTR{device/power_dpm_force_performance_level}="high"` on boot without touching the Ryzen 7600X iGPU (`0x164e`).
  2. Deployed `/usr/lib/systemd/system-sleep/amdgpu-rx7700xt-dpm` (from `profiles/desktop/scripts/amdgpu-rx7700xt-dpm-sleep`) to re-apply `high` on `post` suspend/hibernate resume.
  3. Re-test `auto` mode after future `linux-firmware-amdgpu` (post-`20261019`) or kernel `7.4+` updates; remove both files if upstream resolves the `DMUB`/DPM vblank-overrun regression.

---

## 12. KTC A32Q8 Smart Monitor (`DP-1`) Custom Open-Source Launcher (`ktc-launcher`) & ADB Debloat

- **Hardware / Firmware**: Realtek `RTD2851F` (`kaisyuan`, quad-core Cortex-A55 `armv8l`, 1.83 GB RAM, Android 11 / SDK 30, locked AVB 1.1 bootloader). Monitor input switching, OSD, and DDC/CI depend on `com.realtek.*` system services (never disable `com.realtek.*` packages).
- **Network ADB**: Discovered via mDNS (`Bedroom TV` / `Eco Smart Monitor`, `10.0.0.144:5555`). Note that the monitor puts Wi-Fi into sleep when sitting on DisplayPort if idle; press Home on the remote to wake ADB if needed.
- **Custom Open-Source Launcher (`~/dev/MinimalTVLauncher`, GitHub: `JValdivia23/MinimalTVLauncher`)**:
  - Built with `jdk17-openjdk` + `~/Android/Sdk` (`platforms;android-34`, `build-tools;34.0.0`) via `~/dev/MinimalTVLauncher/build.sh --install 10.0.0.144:5555` (~25 KB APK, ~38 MB PSS).
  - Realtek hardware passthrough IDs: **DisplayPort** (`com.realtek.tv.passthrough/.dpinput.DPTvInputService/HW168624384`), **USB-C** (`HW168624128`), **HDMI 1** (`com.realtek.tv.passthrough/.hdmiinput.HDMITvInputService/HW151519232`), launched via `ACTION_VIEW` on `com.realtek.tv/.MainActivity`.
  - **Gotcha**: Never modify Android's `settings put secure tv_input_custom_labels` — Realtek's native OSD reads that key and overrides the native DP/Type-C icons in the monitor's own input switcher.
  - **Rollback**: To restore Google TV at any time, run `adb -s 10.0.0.144:5555 shell pm enable com.google.android.apps.tv.launcherx`.

