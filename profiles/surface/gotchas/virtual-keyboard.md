# On-Screen Virtual Keyboard (wvkbd vs Fcitx5) on Surface Book 3

Detailed reference and troubleshooting for on-screen touch typing on the Microsoft Surface Book 3 under Wayland / Hyprland.

---

## 1. Symptom

When detaching the keyboard base (`SUPER + ALT + D`) or using the Surface Book 3 in tablet mode, physical keyboard input is unavailable. Previously, pressing **`SUPER + ALT + V`** did not open an on-screen keyboard, making text input impossible on the touchscreen.

---

## 2. Root Cause & Architectural Distinction

Two distinct issues caused this failure:

1. **Missing Binary (`fcitx5-remote`)**:
   - `fcitx5` was not installed on the system (`which: no fcitx5`), causing Hyprland's execution of `fcitx5-remote -t` to fail silently.
2. **IME vs. OSK Architectural Mismatch**:
   - **Fcitx5** is an **Input Method Editor (IME)** framework designed for converting Latin keystrokes into complex scripts (e.g. Japanese Mozc/Anthy, Chinese Pinyin/RIME, Korean Hangul). It is **not** a graphical on-screen touch keyboard (OSK).
   - Calling `fcitx5-remote -t` merely toggles the IME conversion state (active / inactive); it does **not** render an on-screen touch keyboard on Wayland.
   - Minimal Wayland compositors like Hyprland do not include a built-in OSK and require a dedicated Wayland layer-shell virtual keyboard.

---

## 3. Solution & Implementation

### A. Core Component: `wvkbd`
- **Package**: `wvkbd` (binary: `/usr/bin/wvkbd-mobintl`), installed from AUR via `yay`.
- **Properties**: Lightweight (~7.7 MB RSS, 0.0% idle CPU), written in C using Pango/Cairo and Wayland protocols.
- **Layer Integration**: Automatically maps to Wayland Layer 3 (`overlay`) directly over applications and the lockscreen without stealing window focus.

### B. Toggle Wrapper Script (`hypr-virtual-keyboard`)
Located at [`dotfiles/profiles/surface/.local/bin/hypr-virtual-keyboard`](file:///home/jmvp/dotfiles/profiles/surface/.local/bin/hypr-virtual-keyboard) (symlinked to `~/.local/bin/hypr-virtual-keyboard`):
```bash
#!/usr/bin/env bash
if ! command -v wvkbd-mobintl &>/dev/null; then
    notify-send -u critical "Virtual Keyboard" "wvkbd-mobintl is not installed."
    exit 1
fi

if pgrep -x "wvkbd-mobintl" >/dev/null; then
    pkill -RTMIN -x "wvkbd-mobintl"
else
    # Launch wvkbd detached (calibrated for Surface Book 3 touch display)
    nohup wvkbd-mobintl -L 320 -H 320 >/dev/null 2>&1 &
fi
```

### C. Surface Profile Keybinding & UWSM Gotcha
In [`dotfiles/profiles/surface/.config/hypr/config/profile/binds.lua`](file:///home/jmvp/dotfiles/profiles/surface/.config/hypr/config/profile/binds.lua):
```lua
local homeDir = os.getenv("HOME")
helpers.bind("SUPER + ALT + V", "Toggle on-screen virtual keyboard", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-virtual-keyboard"))
```
> [!IMPORTANT]
> **Why `hl.dsp.exec_cmd(...)` is required instead of a bare string**:
> In `helpers.lua`, passing a plain string to `helpers.bind(keys, desc, str)` causes the helper to automatically prepend `uwsm-app -- <cmd>`.
> `uwsm-app` invokes `uwsm_app-daemon` via the `systemd --user` session. Default systemd user `PATH` only searches `/usr/local/bin:/usr/bin` (omitting `~/.local/bin`), resulting in `Error: Command not found: "hypr-virtual-keyboard"`.
> Furthermore, `uwsm-app` isolates processes within transient systemd scopes, terminating child background daemons when the wrapper exits.
> Explicitly passing `hl.dsp.exec_cmd(...)` bypasses UWSM and executes directly within Hyprland's native compositor environment.
> Additionally, `~/.config/environment.d/10-path.conf` was deployed with `PATH=${HOME}/.local/bin:${PATH}` to ensure systemd user scopes also inherit `~/.local/bin`.

### D. Package Tracking
Added `wvkbd` to [`dotfiles/profiles/surface/packages.txt`](file:///home/jmvp/dotfiles/profiles/surface/packages.txt).

---

## 4. Verification & Testing

1. Press **`SUPER + ALT + V`** to instantly spawn the on-screen keyboard docked at the bottom of the display.
2. Tap keys directly via the touchscreen or stylus; characters emit into active Wayland applications (Kitty, Zen Browser, Noctalia panels).
3. Press **`SUPER + ALT + V`** again (or tap the hide key in `wvkbd`) to send `SIGRTMIN` and hide the keyboard.
