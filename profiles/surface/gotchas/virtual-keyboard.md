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
- **Properties**: Lightweight (~7.7 MB RSS, 0.0% idle CPU), written in C using Pango/Cairo and Wayland protocols (`zwlr_layer_shell_v1` + `zwp_virtual_keyboard_v1`).
- **Layer Integration**: Maps to Wayland Layer 3 (`overlay`) without stealing window focus (`keyboard_interactivity = none`). However, under Hyprland `0.56.2+`, `ext-session-lock-v1` lock screens hide all layer-shell surfaces and block touch hit-testing unless the layer surface has `above_lock = 2` (see Section 3E below).

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

### E. Post-Suspend / Hibernation Lock Screen (`above_lock = 2` Layer Rule)
- **Symptom**: After waking from suspend or hibernate with the Surface Book 3 base detached, swiping 1 finger up from the bottom edge triggers `lisgd` $\rightarrow$ `hypr-virtual-keyboard` (`pkill -RTMIN -x wvkbd-mobintl`), and `wvkbd-mobintl` compiles its XKB keymap, but the virtual keyboard does not appear on screen.
- **Root Cause**:
  1. When locked via `noctalia msg session lock` (`ext-session-lock-v1`), `Render::IHyprRenderer::renderLayer()` in Hyprland skips rendering **all** `zwlr_layer_shell_v1` surfaces (including `overlay` layer 3) if `m_aboveLock == 0` (the default).
  2. Furthermore, `Desktop::CViewHitTester::layerSurfaceAt()` ignores touch hit-testing on layer surfaces while locked unless `m_aboveLock == 2`.
- **Fix**: In [`dotfiles/profiles/surface/.config/hypr/config/profile/inputs.lua`](file:///home/jmvp/dotfiles/profiles/surface/.config/hypr/config/profile/inputs.lua), a dynamic layer rule sets `above_lock = 2` for `namespace = "^(wvkbd)$"`:
  ```lua
  hl.layer_rule({
      name = "surface-wvkbd-above-lock",
      match = { namespace = "^(wvkbd)$" },
      above_lock = 2,
  })
  ```
  This renders `wvkbd-mobintl` above the Noctalia lock screen and routes touch taps to `wvkbd` while keeping keyboard focus on the lock screen password field.

### F. Explicit `lisgd` Geometry (`-w 3000 -h 2000`) to Prevent Cold-Boot Segfault
- **Root Cause**: When `lisgd` is invoked without `-w` and `-h`, it calls `wl_display_connect(NULL)` if `$WAYLAND_DISPLAY` is set in the environment and passes the returned pointer unchecked to `wl_proxy_get_version()`, causing a `SIGSEGV` in `libwayland-client.so.0` if the Wayland socket is not yet ready.
- **Fix**: Passing `-w 3000 -h 2000` in [`hypr-lisgd`](file:///home/jmvp/dotfiles/profiles/surface/.local/bin/hypr-lisgd) skips `wl_display_connect()` entirely.

### G. Cold-Boot Pre-Login Greeter (`greetd` / `noctalia-greeter` Tablet Mode)
- **Root Cause**: On cold boot before any user logs in, `/usr/bin/noctalia-greeter-session` launches `/usr/bin/noctalia-greeter-compositor` as user `greeter` (`uid=961`). The bundled `noctalia-greeter-compositor` only implements `xdg_shell` and lacks `zwlr_layer_shell_v1` and `zwp_virtual_keyboard_v1`, nor does it run `lisgd` or `wvkbd-mobintl`.
- **Fix**:
  1. [`surface-greeter-session.sh`](file:///home/jmvp/dotfiles/profiles/surface/scripts/surface-greeter-session.sh) (`/usr/local/bin/surface-greeter-session`, configured in `/etc/greetd/config.toml`) starts a minimal Hyprland compositor using [`surface-greeter-hyprland.lua`](file:///home/jmvp/dotfiles/profiles/surface/scripts/surface-greeter-hyprland.lua) (`/etc/greetd/surface-hyprland.lua`), with automatic fail-safe fallback to `/usr/bin/noctalia-greeter-session` if Hyprland fails to initialize.
  2. [`surface-greeter-client.sh`](file:///home/jmvp/dotfiles/profiles/surface/scripts/surface-greeter-client.sh) (`/usr/local/bin/surface-greeter-client`) starts `wvkbd-mobintl -L 320 -H 320 --hidden`, a `lisgd` supervisor for the 1-finger bottom-up swipe (`1,DU,B/BL/BR,*,R`), and `/usr/bin/noctalia-greeter`, then exits Hyprland cleanly as soon as login succeeds.
  3. User `greeter` is added to the `input` group in [`profiles/surface/setup.sh`](file:///home/jmvp/dotfiles/profiles/surface/setup.sh) so `lisgd` can read `/dev/input/event*` (`IPTSD Virtual Touchscreen`).

---

## 4. Verification & Testing

1. Press **`SUPER + ALT + V`** or swipe 1 finger up from the bottom edge to spawn the on-screen keyboard docked at the bottom of the display.
2. Lock the session (`noctalia msg session lock` or wake from suspend/hibernate with base detached) and swipe 1 finger up from the bottom edge — `wvkbd-mobintl` renders above the lock screen (`above_lock = 2`) and types directly into the password field.
3. On cold boot at the `greetd` login screen, swipe 1 finger up from the bottom edge to toggle `wvkbd-mobintl` and log in without the keyboard base attached.

