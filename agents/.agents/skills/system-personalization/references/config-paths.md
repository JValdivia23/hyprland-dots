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
| `hypr-window-pop` | Window Pop-out & Pin Script | Triggered by `SUPER+O` to float, resize to 1300x900, center, and pin active window across workspaces. |
| `hypr-toggle-altwin` | Alt/Super Layout Toggle | Triggered by `SUPER+ALT+K` to dynamically toggle `kb_options` between Mac (Swapped) and PC (Normal) layouts on the fly. |

---

## System Configs (Require Sudo Approval)

These commands will prompt the user for confirmation and password access.

| Path | Purpose | Edit Rule |
|------|---------|-----------|
| `/etc/pacman.conf` | Pacman configuration and repository listings | Patch lines only. |
| `/etc/fstab` | File systems and mount configurations | Append or patch only; always verify partition UUIDs. |
