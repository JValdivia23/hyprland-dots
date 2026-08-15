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

