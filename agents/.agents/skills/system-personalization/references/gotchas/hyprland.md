# Hyprland Lua Gotchas & Pitfalls

Curated troubleshooting issues, rules, and fixes for Hyprland compositor configuration on `cachyos-cu`.

---

## 1. Lua Config Validation Errors (`hyprctl configerrors`)

- **Symptom**: Hyprland displays a red error banner across the screen after modifying `.lua` configuration files. Standard system logs (`journalctl`) do **not** capture config syntax or key errors.
- **Root Cause**: Hyprland dynamically parses Lua configurations at runtime and presents syntax errors directly in an on-screen overlay instead of logging them to journald.
- **Fix**: ALWAYS run Hyprland's built-in error diagnostics first when troubleshooting:
  ```bash
  hyprctl configerrors
  ```
  *(Note: If running outside an active Hyprland terminal, export `HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/$UID/hypr/ | head -1)` first).*

---

## 2. `hl.dsp.send_shortcut` Requires Explicit `window` Selector

- **Symptom**: Calling `hl.dsp.send_shortcut({ mods = "CTRL", key = "Left" })` returns `ok` but fails to trigger key events in the focused application.
- **Root Cause**: Hyprland's C++ IPC dispatcher requires an explicit target window selector parameter. If omitted, the shortcut is dropped or targeted to nothing.
- **Fix**: Always specify `window = "activewindow"` in `hl.dsp.send_shortcut`:
  ```lua
  hl.dsp.send_shortcut({ mods = "CTRL", key = "Left", window = "activewindow" })
  ```

---

## 3. Modifier Key Repetition on Hold (`repeating = true`)

- **Symptom**: Holding down shortcuts like `SUPER + Left` (Home) or `ALT + Left` (Word Jump) triggers once on keydown and fails to repeat across lines or words.
- **Root Cause**: Hyprland bindings default to single-trigger events unless explicitly marked as repeating.
- **Fix**: Pass `{ repeating = true }` in the options table of `hl.bind`:
  ```lua
  hl.bind("ALT + Left", hl.dsp.send_shortcut({ mods = "CTRL", key = "Left", window = "activewindow" }), { repeating = true })
  ```

---

## 4. Terminal `SUPER + C` Copy vs. `SIGINT` (`CTRL+SHIFT+C`)

- **Symptom**: Pressing `SUPER + C` in CLI tools (Fish shell, Python REPL, Node.js, `btop`, `agy`) prints `press ctrl+c again to exit.` or cancels the running process instead of copying text.
- **Root Cause**: Sending bare `CTRL + C` generates a POSIX `SIGINT` (Interrupt) signal.
- **Fix**: In `binds.lua`, dispatch `CTRL, SHIFT, C` for `SUPER + C`:
  ```lua
  hl.bind(mainMod .. " + C", hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "C", window = targetWin }))
  ```
  `CTRL+SHIFT+C` is the universal terminal copy shortcut across Kitty, Ghostty, Alacritty, and Foot without triggering `SIGINT`. It also functions natively as Copy across modern Wayland GUI applications.

---

## 5. Dynamic Alt / Super Key Position Toggle (`SUPER + ALT + K`)

- **Symptom**: Muscle memory when switching between built-in MacBook keyboard (Command next to Spacebar) and external standard PC keyboards requires swapping modifier keys.
- **Fix**: Toggle `kb_options` dynamically via `SUPER + ALT + K` or `SUPER + SHIFT + K` (executes `~/.local/bin/hypr-toggle-altwin`):
  ```bash
  hyprctl eval 'hl.config({ input = { kb_options = "altwin:swap_lalt_lwin" } })'
  ```

---

## 6. Absolute PATH Required for Helper Scripts

- **Symptom**: Custom helper scripts in `~/.local/bin/` (e.g. `hypr-window-pop`, `mac-key-helper`) fail when executed with bare command names via `hl.dsp.exec_cmd`.
- **Root Cause**: The compositor process environment PATH is set at session start and may not include `~/.local/bin/`.
- **Fix**: Always construct full absolute paths in `binds.lua`:
  ```lua
  local homeDir = os.getenv("HOME") or "/home/user"
  hl.bind("SUPER + O", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-window-pop"))
  ```

---

## 7. Window Resizing API (`hl.dsp.window.resize`)

- **Symptom**: Calling `exec_raw("resizeactive", ...)` from scripts fails to resize floating windows.
- **Root Cause**: In modern Hyprland, `resizeactive` has been replaced with the native Lua API `hl.dsp.window.resize()`.
- **Fix**: Dispatch `hl.dsp.window.resize({ x = width, y = height, exact = true })`:
  ```bash
  hyprctl dispatch 'hl.dsp.window.resize({ x = 560, y = 315, exact = true })'
  ```

---

## 8. Window Swallowing Hides Parent Terminal (`enable_swallow = true`)

- **Symptom**: When launching an interactive subshell or elevated terminal (such as `kitty -e bash -c "sudo ..."` or spawning child tools from a CLI agent), the newly opened terminal replaces the parent window and takes up the entire workspace, hiding the active conversation or parent process.
- **Root Cause**: `misc.enable_swallow = true` combined with `swallow_regex = "(kitty|...)"` causes Hyprland to swallow and hide any terminal window that spawns another terminal child process.
- **Fix**: In `~/.config/hypr/config/misc.lua`, disable window swallowing:
  ```lua
  enable_swallow = false,
  ```
  This ensures newly spawned windows always tile side-by-side cleanly in the dwindle layout.

---

## 9. Duplicate / Empty Monitor Move Keybindings (`SUPER + SHIFT + 1..3`)

- **Symptom**: Pressing `SUPER + SHIFT + 1`, `SUPER + SHIFT + 2`, or `SUPER + SHIFT + 3` to move an active window to workspace 1, 2, or 3 triggers a runtime Lua/Hyprland error banner: `[ERR] Monitor not found`. Workspaces 4–10 work normally.
- **Root Cause**: Early in `binds.lua`, `hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ monitor = MONITOR1 }))` (and 2, 3) was defined. Because `MONITOR1`..`MONITOR3` in `variables.lua` were set to `""`, the dispatcher attempted to move the window to an empty monitor name rather than delegating to the workspace move loop (`SUPER + SHIFT + [1-9, 0]`).
- **Fix**: In `~/.config/hypr/config/binds.lua`, remove the duplicate `monitor = MONITOR1..3` bindings. Workspace movements are handled by `SUPER + SHIFT + 1..10` (`hl.dsp.window.move({ workspace = tostring(i) })`), while multi-monitor window movement is handled by `SUPER + SHIFT + grave` (`monitor = "+1"`) or mouse wheel.

---

## 10. Clamshell / Lid Switch Low-Power Event Handling (`switch:on:Lid Switch`)

- **Architecture**:
  - **Standalone Mode (Battery or AC without external monitor)**: `systemd-logind` is configured with `HandleLidSwitch=suspend` and `HandleLidSwitchExternalPower=suspend` in [`/etc/systemd/logind.conf.d/omarchy-lid.conf`](file:///etc/systemd/logind.conf.d/omarchy-lid.conf). Closing the lid suspends the laptop immediately, preventing battery exhaustion and eliminating dangerous heat buildup when charging inside a closed chassis.
  - **Docked Clamshell Mode (External monitor connected)**: `HandleLidSwitchDocked=ignore` keeps the machine awake when docked to an external display.
- **Hyprland Lua Binding**: In [`~/.config/hypr/config/binds.lua`](file:///home/java1127/.config/hypr/config/binds.lua):
  ```lua
  hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd(lidHandler .. "close"), { locked = true })
  hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(lidHandler .. "open"),  { locked = true })
  ```
  The `{ locked = true }` flag is critical so switch events trigger even after the screen session is locked.
- **Helper Script (`~/.local/bin/hypr-lid-handler`)**:
  - Immediately cuts display power (`hyprctl dispatch dpms off eDP-1`), preventing wasted heat and light against the closed screen in docked mode.
  - Saves the active keyboard backlight brightness level (`apple::kbd_backlight`) to `/tmp/hypr_kbd_backlight_saved_${UID}` before shutting it off on lid close, and automatically restores it upon lid open.
  - Saves the active Touch Bar backlight brightness level (`appletb_backlight`) to `/tmp/hypr_tb_backlight_saved_${UID}` and shuts it off on lid close, restoring it upon lid open.
  - Saves the active CPU power profile and switches to `power-saver` via `powerprofilesctl` on close, restoring the saved profile on open.


---

## 11. External & Agent GUI Window Spawning (`hl.exec_cmd`)

- **Symptom**: Spawning GUI apps or interactive terminals (e.g. `kitty -e bash ... &`) from background scripts, system services, or detached agent subshells silently fails or does not attach a window to the active Hyprland workspace.
- **Root Cause**: Detached subshells do not inherit `HYPRLAND_INSTANCE_SIGNATURE`. Furthermore, legacy `hyprctl dispatch exec ...` expects Lua syntax in modular Hyprland.
- **Fix**: Export the active socket signature and execute via `hl.exec_cmd`:
  ```bash
  export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/$(id -u)/hypr/ 2>/dev/null | head -n1)
  hyprctl eval 'hl.exec_cmd("kitty --title <Title> -e bash -c \"<command>; read\"")'
  ```

---

## 12. Dynamic Monitor Scaling API (`hl.monitor` vs `hyprctl keyword`)

- **Symptom**: Calling `hyprctl keyword monitor "eDP-1,preferred,auto,..."` from the command line or scripts fails with error: `keyword can't work with non-legacy parsers. Use eval.`
- **Root Cause**: Hyprland configurations parsed via modular Lua reject legacy `keyword` dispatcher commands for monitors.
- **Fix**: Dispatch monitor settings using `hyprctl eval` and the native `hl.monitor` Lua API:
  ```bash
  hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.6 })'
  ```
  Runtime switcher scripts (such as `~/.local/bin/hypr-monitor-scale`) should attempt `hyprctl eval "hl.monitor(...)"` first and fall back to `hyprctl keyword` for backwards compatibility.

---

## 13. Submap Window Resizing: Tiled (`splitratio`) vs Floating (`resizeactive`) & Modifier Masks

- **Symptom**: Pressing `SUPER + R` enters a resize submap, but arrow keys (`Right`, `Left`, `Up`, `Down`) do not resize tiled windows or do nothing when the user keeps holding `SUPER`.
- **Root Cause**:
  1. **Tiled vs Floating Resizing**: Hyprland's `resizeactive <X> <Y>` dispatcher was designed for floating windows. On tiled windows in the `dwindle` layout, relative coordinate vectors frequently fail or get rejected with `"Invalid size provided"` when edges hit monitor bounds. In `dwindle`, tiled windows are sized by split ratios (`splitratio`).
  2. **Submap Modifier Masks**: When entering a submap via `SUPER + R`, users often keep holding `SUPER` while tapping arrow keys. If the submap only binds bare keys (`Right`, `modmask = 0`), pressing `SUPER + Right` (`modmask = 64`) does not match and is completely ignored.
- **Fix**:
  1. Inspect `win.floating` via `hl.get_active_window()`. If floating, dispatch `resizeactive dx dy`. If tiled, dispatch `hl.dsp.layout("splitratio <ratio>")`:
     ```lua
     local function resize_dir(dx, dy, ratio)
         local win = hl.get_active_window()
         if win and win.floating then
             hl.dispatch(hl.dsp.exec_raw("resizeactive", dx .. " " .. dy))
         else
             hl.dispatch(hl.dsp.layout("splitratio " .. ratio))
         end
     end
     ```
  2. In `hl.define_submap("resize", ...)`, register **both** bare keys (`Right`, `Left`, `Up`, `Down`, `h`, `j`, `k`, `l`) and `SUPER`-modified keys (`mainMod .. " + Right"`, etc.) with `{ repeating = true }`.
  3. Support `=` (`equal`) to reset the split ratio to 50/50 (`splitratio 1.0 exact`).

---

## 14. `hyprctl dispatch` Syntax Error in Lua Mode (`hl.dsp.exec_raw`)

- **Symptom**: Calling `hyprctl dispatch <dispatcher> <args>` (e.g. `hyprctl dispatch movetoworkspacesilent special:minimized,address:0x...`) fails with `error: [string "return hl.dispatch(...)"]:1: ')' expected near ... Note: dispatch in lua is a shorthand for hl.dispatch(...)`.
- **Root Cause**: In Hyprland 0.55+ with Lua configuration, `hyprctl dispatch` directly translates CLI arguments into a raw Lua call `return hl.dispatch(...)`. Complex CLI argument strings containing commas, colons, or whitespace fail Lua syntax parsing.
- **Fix**: In helper scripts and IPC calls, use `hyprctl eval` wrapping `hl.dsp.exec_raw`:
  ```bash
  hyprctl eval 'hl.dispatch(hl.dsp.exec_raw("<dispatcher>", "<args>"))'
  ```
  Example:
  ```bash
  hyprctl eval 'hl.dispatch(hl.dsp.exec_raw("movetoworkspacesilent", "special:minimized,address:0x55d30d..."))'
  ```
