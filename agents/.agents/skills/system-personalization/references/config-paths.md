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

## User Binaries & Helper Scripts (`~/.local/bin/`)

Custom shell scripts executed by Hyprland keybindings or desktop workflows.

| Path | Purpose | Description |
|------|---------|-------------|
| `mac-key-helper` | macOS Text Navigation Helper | Inspects active window class/floating state and dispatches context-aware shortcuts. |
| `hypr-window-pop` | Window Pop-out & Pin Script | Triggered by `SUPER+O` to float, resize to 1100x700, center, and pin active window across workspaces. |
| `hypr-toggle-altwin` | Alt/Super Layout Toggle | Triggered by `SUPER+ALT+K` to dynamically toggle `kb_options` between Mac (Swapped) and PC (Normal) layouts on the fly. |
| `hypr-quicklook` | Quick Look File Preview | Triggered by `ALT+Return` to render instant floating image/vector previews via `swayimg`. |
| `hypr-kbd-brightness` | Keyboard Backlight Control | Triggered by `Fn + Up / Down` to step keyboard brightness (0-3) with visual notification. |
| `hypr-lid-handler` | Laptop Clamshell & DPMS Handler | Triggered by `switch:on/off:Lid Switch` to manage DPMS power, keyboard light, and power profiles on lid close/open. |
| `fastfetch-custom` | Terminal Greeting Fetch Script | Triggered by `fish_greeting` in Fish; renders clean two-column system specs, hardware details, and mini CachyOS logo. |

---

## Audio & DSP Configs (`~/.config/`)

| Path | Purpose | Edit Rule |
|------|---------|-----------|
| `easyeffects/output/mbp.json` | MacBook Pro 15" DSP equalizer & speaker tuning profile | JSON format. Presets loaded via EasyEffects. |
| `easyeffects/autoloading/output.json` | Autoloading rules mapping `Apple Audio Device Speakers` -> `mbp` | JSON autoload configuration. |
| `pipewire/pipewire.conf.d/99-echo-cancel.conf` | WebRTC noise & echo cancellation module for microphone (`AppleT2_CleanMic`) | PipeWire SPA/module format. Restart PipeWire after editing. |

---

## System Helper Scripts & Daemons (`/usr/local/bin/`)

| Path | Purpose | Description |
|------|---------|-------------|
| `/usr/local/bin/amdgpu-power-switch.sh` | GPU & CPU Power Profile Switcher | Toggles AMD PowerPlay (`mode 2` vs `mode 0`), PCIe ASPM (`powersupersave`), and Intel Turbo Boost (`no_turbo`). |
| `/usr/local/bin/t2-sleep-helper` | T2 Sleep & Wakeup Helper | Manages pre-suspend and post-resume Touch Bar USB configuration cycling (`0 -> 2`) and DRM display re-attachment. |

---

## System Configs (Require Sudo Approval)

These commands will prompt the user for confirmation and password access.

| Path | Purpose | Edit Rule |
|------|---------|-----------|
| `/etc/t2fand.conf` | Fan curve thresholds (`low_temp`, `high_temp`, `speed_curve`) for `t2fanrd` | INI sections (`[Fan1]`, `[Fan2]`). Restart `t2fanrd.service` after editing. |
| `/etc/tiny-dfr/config.toml` | Touch Bar daemon settings (`EnablePixelShift`, `MediaLayerDefault`, `FontTemplate`) | TOML format. Restart `tiny-dfr.service` after editing. |
| `/etc/modprobe.d/blacklist-touchbar.conf` | Blacklists `hid_appletb_kbd` to prevent USB endpoint drops on T2 | Patch lines only. |
| `/etc/udev/rules.d/99-touchbar-tiny-dfr.rules` | Udev rules for Touch Bar USB Configuration 2 and device symlinks | Patch lines; run `udevadm control --reload-rules`. |
| `/etc/systemd/system/t2-touchbar-setup.service` | Boot service to initialize Touch Bar DRM device node | Systemd unit file. |
| `/etc/systemd/logind.conf.d/omarchy-lid.conf` | Configures systemd-logind to suspend on lid switch (battery/AC) and ignore only when docked | INI format. |
| `/etc/pacman.conf` | Pacman configuration and repository listings | Patch lines only. |
| `/etc/fstab` | File systems and mount configurations | Append or patch only; always verify partition UUIDs. |

