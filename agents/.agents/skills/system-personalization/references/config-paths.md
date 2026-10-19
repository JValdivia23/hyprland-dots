# Configuration Paths

Every configuration file on this system, what it controls, and the editing rules.

## Core Rules

1. **NEVER Overwrite configuration files.** Use `patch` (targeted search and replace) or append. Overwriting a configuration file destroys settings placed there by other packages, themes, or the user.
2. **Respect the Lua config syntax.** Hyprland on this machine uses a Lua configuration API (`hl.config`, `hl.bind`, etc.). Do not append traditional Hyprland `.conf` syntax.
3. **Noctalia integration.** Changing `noctalia` configurations may require running `noctalia msg restart` or restarting the service.

---

## Hyprland Configs (`~/.config/hypr/`)

All configurations are modularized under `~/.config/hypr/config/` and loaded in order by the entrypoint.

| File | Controls | Edit Rule |
|------|----------|-----------|
| `hyprland.lua` | Main entrypoint — sources all sub-configs | Append `require("config.<module>")` calls only. |
| `config/animations.lua` | Curves, spring animations, leaf-specific speeds | Modify spring/bezier curves or add `hl.animation` rules. |
| `config/autostart.lua` | Auto-started programs (DBus envs, Noctalia, xhost) | Modify commands executed inside the `hl.on("hyprland.start", ...)` handler. |
| `config/binds.lua` | Global keyboard shortcuts, hardware controls, workspace binds | Modify or add `hl.bind(...)` key mappings. |
| `config/colors.lua` | Custom color constants (active/inactive border colors) | Edit color strings/rgba values inside the theme settings. |
| `config/decorations.lua` | Window rounding, active/inactive opacity, shadows, blurs | Patch configuration parameters inside `hl.config`. |
| `config/environment.lua` | Wayland & compositor environment variables | Append `hl.env("<VAR>", "<VAL>")` commands. |
| `config/inputs.lua` | Touchpad gesture profiles, cursor options, mouse parameters | Edit parameters inside `hl.config` or `hl.gesture`. |
| `config/misc.lua` | Miscellaneous settings (e.g., mouse focus, tearing) | Edit specific flags. |
| `config/monitors.lua` | Display panels, workspace associations, refresh rates | Patch monitors configurations via `hl.monitor`. |
| `config/variables.lua` | Default applications (`TERMINAL`, `BROWSER`, etc.) | Edit global string constants for applications or workspaces. |
| `config/windowrules.lua` | Window positioning rules, workspace routing rules | Append window rules or class matching rules. |
| `config/workspaces.lua` | Workspaces configuration rules | Edit workspace counts or layout settings. |
| `xdph.conf` | XDG Desktop Portal Hyprland configuration | Edit line parameters. |

### Touchpad & Input Customization (`~/.config/hypr/config/inputs.lua`)

#### Pointer Acceleration Profile
- `input.accel_profile = "adaptive"` (macOS-like velocity-based acceleration) or `"flat"` (linear 1:1 acceleration).

#### Supported `input.touchpad` Options (Hyprland 0.55+ Lua API)
| Option | Type | Description |
|--------|------|-------------|
| `natural_scroll` | `boolean` | Set `true` for reverse/natural scrolling (macOS standard). |
| `tap_to_click` | `boolean` | Set `true` to enable tap-to-click. |
| `clickfinger_behavior` | `boolean` | Set `true` for finger-count clicks (1 finger = left, 2 fingers = right, 3 fingers = middle). |
| `middle_button_emulation` | `boolean` | Set `true` to emulate middle click by pressing both buttons. |
| `scroll_factor` | `float` | Multiplier for trackpad scroll distance (default `1.0`). |
| `disable_while_typing` | `boolean` | Set `true` to disable trackpad input when typing. |
| `drag_lock` | `integer` | Drag lock duration / behavior (`0` = disabled). |

#### Cursor Settings (`cursor`)
| Option | Type | Description |
|--------|------|-------------|
| `inactive_timeout` | `float`/`integer` | Inactivity timeout in seconds before auto-hiding the cursor (`3` = 3s). `0` disables. |
| `hide_on_key_press` | `boolean` | Set `true` to automatically hide cursor when typing. |

> [!WARNING]
> Do NOT use `tap_to_drag` or `tap-to-drag` as option keys under `input.touchpad` in Hyprland 0.55. These are unsupported option keys that throw Hyprland configuration errors. Tap-to-drag is handled natively when `tap_to_click = true`.

#### Touchpad Gesture API (`hl.gesture`)
Syntax:
```lua
hl.gesture({ fingers = <N>, direction = "<dir>", action = "<action>" })
```
- **Fingers (`fingers`)**: `3`, `4`
- **Direction (`direction`)**: `"horizontal"`, `"vertical"`, `"up"`, `"down"`, `"left"`, `"right"`
- **Actions (`action`)**: `"workspace"`, `"fullscreen"`, `"close"`, `"float"`

---

## Noctalia Configs (`~/.config/noctalia/`)

| Path | Controls | Edit Rule |
|------|----------|-----------|
| `config.toml` | Main Wayland Shell settings: widgets, panels, tray icons, themes | Patch specific key-value pairs (TOML structure). Run `noctalia msg reload` or restart after editing. |

---

## Terminal & Editor Configs (`~/.config/`)

| Path | Purpose | Edit Rule |
|------|---------|-----------|
| `alacritty/alacritty.toml` | Alacritty terminal emulator profile | Patch TOML values. |
| `kitty/kitty.conf` | Kitty terminal emulator configuration | Patch values; imports custom theme. |

---

## Shell Configs (`~/.config/fish/`)

The system uses `fish` as its default interactive shell.

| Path | Purpose | Edit Rule |
|------|---------|-----------|
| `config.fish` | Shell aliases, variables, interactive startup settings | Append functions or variables. Do not overwrite. |

---

## Universal User Binaries & Helper Scripts (`core/.local/bin/` -> `~/.local/bin/`)

Universal shell scripts executed by Hyprland keybindings or desktop workflows.

| Path | Purpose | Description |
|------|---------|-------------|
| `hypr-screenshot` | Smart Screenshot Capture | Piped window snap, region drag, and active window capture to Satty. |
| `hypr-ocr` | OCR Text Extraction | Extracts text from selected screen regions to clipboard via Tesseract. |
| `hypr-record` | Screen Recording | Toggle screen recording on/off to `~/Videos/Captures/` via `wf-recorder`. |
| `hypr-capture-menu` | Capture Menu Launcher | Interactive floating capture menu (`SUPER+CONTROL+C`). |
| `hypr-keybinds-menu` | Interactive Keybindings Cheatsheet & Launcher | Floating `fzf` menu (`SUPER+K`) querying live `hyprctl binds -j`; executes selected keybind on `Enter`. |
| `hypr-tray-drawer` | Minimized Window Tray Drawer Daemon & CLI | Manages minimized windows in `special:minimized` with full-bleed `64x64` dynamic SVG count-badge SNI icons and `noctalia dmenu` integration; supervised by `~/.config/systemd/user/hypr-tray-drawer.service`. |
| `kitty-focus-opacity` | Terminal Focus Opacity Daemon | Modulates Kitty opacity between `0.60` (unfocused) and `0.75` (focused) via Hyprland IPC. |
| `mac-key-helper` | macOS Text Navigation Helper | Dispatches context-aware line and word cursor navigation shortcuts. |
| `hypr-window-pop` | Window Pop-out & Pin Script | Triggered by `SUPER+O` to float, resize to 1100x700, center, and pin active window. |
| `hypr-toggle-altwin` | Alt/Super Layout Toggle | Triggered by `SUPER+ALT+K` to toggle `kb_options` between Mac and PC layouts. |
| `hypr-quicklook` | Quick Look File Preview | Triggered by `ALT+Return` to render instant floating previews via `swayimg`. |
| `hypr-screen-brightness` | Screen Brightness Control | Adjusts display backlight with Noctalia OSD. |
| `hypr-kbd-brightness` | Keyboard Backlight Control | Steps keyboard brightness (0-3) with visual OSD notification. |
| `hypr-lid-handler` | Universal Clamshell DPMS Handler | Clamshell lid close/open handler managing DPMS power and power profiles. |
| `fastfetch-custom` | Terminal Greeting Fetch Script | Renders two-column system specs and mini CachyOS logo in Fish. |

---

## Hardware Profile: Surface Book 3 (`profiles/surface/`)

Per Rule 9, all hardware-specific configurations, daemons, and system hooks are isolated within `profiles/surface/` and kept out of universal `core/`.

| File / Component | Purpose | Description / Placement |
|------------------|---------|-------------------------|
| `.config/hypr/config/profile/binds.lua` | Surface Keybindings | Tablet detach (`SUPER+ALT+D`) and on-screen keyboard toggle (`SUPER+ALT+V`). |
| `.config/hypr/config/profile/inputs.lua` | Surface Touch, Stylus, Touchpad & Lock Screen OSK Rule | Maps touch/tablet to `eDP-1`, configures 3/4-finger touchpad gestures, and sets `above_lock = 2` on `namespace = "^(wvkbd)$"` so `wvkbd-mobintl` renders and accepts touch over `ext-session-lock-v1`. |
| `.local/bin/hypr-virtual-keyboard` | On-Screen Keyboard Wrapper | Launches `wvkbd-mobintl` touch keyboard bypassing systemd PATH lookups. |
| `.local/bin/hypr-lisgd` | Touchscreen Gesture Supervisor | Supervises `lisgd -w 3000 -h 2000` on `IPTSD Virtual Touchscreen` with auto-reconnect across sleep/hibernate. |
| `.local/bin/surface-autorotate` & `.config/systemd/user/surface-autorotate.service` | Detached-Only Screen Rotation | Surface Book 3 only: reads physical base status, claims IIO orientation only while detached, uses Hyprland Lua to rotate `eDP-1` and IPTS touch/pen; publishes geometry for gestures/resizing. |
| `scripts/surface-base-state.py` & `systemd/surface-base-state.service` | Read-Only Physical Base Status | Installed as `/usr/local/libexec/surface-base-state.py` and `/etc/systemd/system/surface-base-state.service`; publishes root-owned `/run/surface-base-state/state.json` without changing DTX permissions or touching latch controls. Deploy only with `scripts/install-rotation.sh`, not the complete boot/sleep setup. |
| `scripts/surface-greeter-session.sh`, `scripts/surface-greeter-client.sh` & `scripts/surface-greeter-hyprland.lua` | Pre-Login `greetd` Tablet OSK & Gesture Session | Deployed to `/usr/local/bin/surface-greeter-session`, `/usr/local/bin/surface-greeter-client`, and `/etc/greetd/surface-hyprland.lua`; runs `noctalia-greeter` + `wvkbd-mobintl --hidden` + `lisgd` bottom-up swipe in `greetd` with fail-safe fallback to `/usr/bin/noctalia-greeter-session`. |
| `scripts/surface-battery-watchdog.sh` | Dual-Battery Watchdog Daemon | Deployed to `/usr/local/bin/surface-battery-watchdog`; recovers UPower ~200% desync. |
| `scripts/surface-unplug-lid-handler.sh` | AC Disconnect Clamshell Handler | Deployed to `/usr/local/bin/surface-unplug-lid-handler`; triggers hibernate upon AC pull. |
| `systemd/10-suspend-then-hibernate.conf` | Sleep Configuration Drop-in | Deployed to `/etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf` (`HibernateMode=shutdown`, 30m delay, `HibernateOnACPower=yes`). |
| `systemd/10-lid-sleep.conf` | Logind Lid Action Drop-in | Deployed to `/etc/systemd/logind.conf.d/10-lid-sleep.conf` (`HandleLidSwitchExternalPower=suspend-then-hibernate`). |
| `systemd/surface-battery-watchdog.service` & `.timer` | Battery Watchdog Systemd Timer | Deployed to `/etc/systemd/system/`; runs watchdog every 2 minutes. |
| `systemd/surface-unplug-lid.service` | Clamshell Udev Trigger Service | Deployed to `/etc/systemd/system/`; triggered by AC disconnect udev rule. |
| `systemd/98-surface-unplug-lid.rules` | AC Disconnect Udev Rule | Deployed to `/etc/udev/rules.d/98-surface-unplug-lid.rules`; detects `ADP1` state switch. |
| `systemd/99-surface-battery.rules` | Battery Udev Rule | Deployed to `/etc/udev/rules.d/99-surface-battery.rules`; monitors `BAT2` change events. |
| `scripts/surface-hibernate-rtc-sync.sh` & `systemd/19-surface-rtc-hibernate.sh` | Hibernation CMOS RTC Epoch Alignment | Deployed to `/usr/local/bin/surface-hibernate-rtc-sync` and `/etc/systemd/system-sleep/19-surface-rtc-hibernate.sh` (symlinked in `/usr/lib/systemd/system-sleep/`); shifts `rtc0` by `-25,179s` on `pre/hibernate` and restores UTC on `post/hibernate`. |
| `systemd/20-surface-battery-resume.sh` | Sleep Resume Battery Hook | Deployed to `/etc/systemd/system-sleep/20-surface-battery-resume.sh` (symlinked in `/usr/lib/systemd/system-sleep/`). |
| `scripts/surface-ipts-resume-recover.sh`, `systemd/surface-ipts-resume.service` & `systemd/21-surface-ipts-resume.sh` | Sleep/Resume IPTS Hook & Fast-Path Recovery | Deployed to `/usr/local/bin/surface-ipts-resume-recover`, `/etc/systemd/system/surface-ipts-resume.service`, and `/etc/systemd/system-sleep/21-surface-ipts-resume.sh` (symlinked in `/usr/lib/systemd/system-sleep/`); cleanly stops `iptsd@*.service` on `pre/*` and recovers touch on open-lid `post/*`. |
| `systemd/iptsd-timeout.conf` | IPTS Daemon Timeout Drop-in | Deployed to `/etc/systemd/system/iptsd@.service.d/timeout.conf` (`TimeoutStopSec=3s`). |
| `scripts/surface-hibernate-compressor.sh` & `systemd/surface-hibernate-compressor.service` | Surface LZ4 & `image_size` Hibernation Default | Installed / enabled: helper `/usr/local/bin/surface-hibernate-compressor`, boot oneshot `/etc/systemd/system/surface-hibernate-compressor.service`; verifies `lz4` and sets `/sys/power/image_size = 4800000000` on Surface hardware. |

---

## Universal System Configs (Require Sudo Approval)

These system-level configuration files require elevated permissions to edit:

| Path | Purpose | Edit Rule |
|------|---------|-----------|
| `/etc/pacman.conf` | Pacman configuration and repository listings | Patch lines only. |
| `/etc/fstab` | File systems and mount configurations | Append or patch only; always verify partition UUIDs. |
| `/etc/chrony.conf` | Chrony NTP daemon configuration (`makestep 1 -1`, `rtcsync`) | Patch lines only. Restart `chronyd.service` after editing. |
| `/etc/default/limine` | Limine bootloader kernel parameters (`button.lid_init_state=open`) | Run `limine-snapper-sync` or initramfs sync after editing. |
