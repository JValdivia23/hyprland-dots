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

---

## 7. Steam Launch Segmentation Fault (`libaudio.so` / `threaded-ml`) & 1.67x HiDPI Scaling

- **Symptom**: Steam crashes on launch with `Segmentation fault (core dumped)` (exit code 139) in `libpulse.so.0` / `libaudio.so` when PipeWire-Pulse or EasyEffects virtual sources are in a stale socket state, or renders with tiny UI on the 4K@1.67x primary monitor.
- **Fix (`profiles/desktop/.local/bin/steam` & `packages.txt`)**:
  1. `lib32-libpulse` is included in `profiles/desktop/packages.txt`.
  2. `~/.local/bin/steam` merges `~/.Xresources` (`Xft.dpi: 144`), exports `STEAM_FORCE_DESKTOPUI_SCALING=1.67` and `SDL_VIDEODRIVER=wayland`, and automatically catches exit code `139` to restart `pipewire`, `pipewire-pulse`, and `wireplumber` while preserving and re-linking the EasyEffects default microphone source before retrying launch.

---

## 8. Dota 2 Multi-Monitor Routing (`HDMI-A-1` Workspace 8) & F9 Dictation Passthrough

- **Workspace Routing**: Workspace `8` is bound to the secondary 1440p@120Hz monitor (`HDMI-A-1`) in `profiles/desktop/.config/hypr/config/profile/monitors.lua`, and `~/.local/bin/dota2-workspace` automatically moves and fullscreens (`fullscreen 0`) `dota2` / `gamescope` windows onto workspace `8`.
- **Fullscreen Alt+Tab Protection**: `on_focus_under_fullscreen = 1` in `inputs.lua` prevents fullscreen games from collapsing into dwindle tiles when Alt+Tabbing.
- **F9 Voice Dictation Passthrough**: `~/.local/bin/hypr-dictate` checks `hyprctl activewindow` for `class: dota2` and forwards `F9` directly to the game window (for match pause/unpause) instead of starting voice dictation.

---

## 9. Secondary 1440p FreeSync / VRR Gamma Flicker (`HDMI-A-1` KTC Q24T09)

- **Symptom**: Rapid brightness / gamma pulsing or flickering on the secondary 24" 1440p monitor (`HDMI-A-1`), especially noticeable across dark/gray backgrounds or while typing in terminal and Discord.
- **Root Cause**: The KTC Q24T09 panel supports Adaptive Sync / FreeSync (`vrrCapable: yes`). When Hyprland's `misc.vrr = 3` (adaptive sync) is active, desktop applications (which render on-demand rather than at constant framerates) cause the monitor refresh rate to oscillate rapidly between the panel's low threshold (~48Hz) and 120Hz. On LCD panels, liquid crystal voltage response shifts with refresh rate, producing visible brightness pulsing.
- **Fix**:
  1. Set `misc.vrr = 0` in `core/.config/hypr/config/misc.lua`.
  2. Explicitly enforce `vrr = 0` on `HDMI-A-1` in `profiles/desktop/.config/hypr/config/profile/monitors.lua`.
  3. Keep game-specific presentation overrides (`vblank_mode=0`, `RADV_PRESENT_MODE=mailbox`) scoped inside game launch commands rather than globally in `environment.lua` to maintain clean desktop VSync pacing.
