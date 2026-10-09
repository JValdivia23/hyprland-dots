# Zen Browser Configuration & Keybinding Gotchas

Gotchas and procedures for managing Zen Browser (`zen-browser-bin`) on `surface`.

---

## 1. Modifying Keybindings from Terminal

- **Config Path**: `~/.config/zen/<profile>/zen-keyboard-shortcuts.json`
  (Resolved from `~/.config/zen/profiles.ini`, e.g. `~/.config/zen/1q66wgda.Default (release)/zen-keyboard-shortcuts.json`).
- **Schema & Linux Modifiers**:
  - Shortcuts are stored in a top-level `"shortcuts"` list.
  - On Linux, Zen Browser internally normalizes the Primary Accelerator to `accel: true` (representing <kbd>Ctrl</kbd>).
  - Modifier mapping:
    - `accel: true` -> <kbd>Ctrl</kbd>
    - `alt: true` -> <kbd>Alt</kbd>
    - `shift: true` -> <kbd>Shift</kbd>
    - `meta: true` -> <kbd>Super</kbd> / <kbd>Win</kbd>
  - Single characters use `"key"` (e.g. `"1"`, `"t"`), while special keys use `"keycode"` (e.g. `"VK_F3"`, `"VK_LEFT"`, `"VK_ESCAPE"`).

### Gotcha: In-Memory Overwrite on Exit
- **Symptom**: Editing `zen-keyboard-shortcuts.json` while Zen Browser is running has no effect, and edits are overwritten with the previous state when Zen exits.
- **Root Cause**: Zen Browser reads `zen-keyboard-shortcuts.json` into memory (`_currentShortcutList`) at startup. It does not monitor the file on disk via inotify. On settings adjustments or shutdown, it dumps its in-memory list back to disk.
- **Fix**: **Always ensure Zen Browser is completely closed** (`pgrep -a zen` -> exit code 1) before modifying `zen-keyboard-shortcuts.json`.

---

## 2. Default Workspace vs. Tab Switching Conflict (<kbd>Ctrl</kbd> + <kbd>1..9</kbd>)

- **Symptom**: Pressing <kbd>Ctrl</kbd> + <kbd>1..9</kbd> in Zen Browser on Linux causes conflicts between switching browser tabs (`key_selectTab1..8`, `key_selectLastTab`) and switching Zen workspaces (`zen-workspace-switch-1..10`).
- **Root Cause**: On macOS, Zen defaults to `Cmd + 1..9` (`accel`) for tabs and `Ctrl + 1..9` (`control`) for workspaces. On Linux and Windows, `control` and `accel` both collapse to <kbd>Ctrl</kbd>, causing identical key definitions.
- **Fix (remap tabs to <kbd>Alt</kbd> + <kbd>1..9</kbd>)**:
  Set `modifiers.alt = true` and `modifiers.accel = false` on `key_selectTab1` through `key_selectTab8` and `key_selectLastTab`. Keep `zen-workspace-switch-1` through `10` on `modifiers.accel = true` (<kbd>Ctrl</kbd> + <kbd>1..9, 0</kbd>).
