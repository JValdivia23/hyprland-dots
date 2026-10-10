# Hyprgrass Touch Plugin & Spacebar Keybind Hijacking Collision

Troubleshooting reference for keyboard collisions (Space key swallowing) when running the `hyprgrass` touchscreen gestures plugin under modern Hyprland (0.56+).

---

## 1. Symptom

- After compiling and loading `hyprgrass` (v0.8.2) and configuring touch bindings via `hl.plugin.hyprgrass.bind` or `hl.plugin.hyprgrass.gesture`, the physical keyboard's **Spacebar** key suddenly stops functioning in all applications.
- Tapping the Spacebar produces no spaces, while all other keys (`a-z`, numbers, modifiers) continue to emit characters normally.
- In chat interfaces or terminals, users are forced to use hyphens (`-`) instead of spaces.

---

## 2. Root Cause & Architectural Collision

1. **Hyprland `SKeybind` Hijacking**:
   - In `hyprgrass` (`src/main.cpp`), the plugin implements gesture bindings (`newBind`) by constructing Hyprland internal `SKeybind` structs and injecting them directly into Hyprland's `KeybindManager`.
   - Because gestures are defined by touch patterns (`kind = "edge"`, `kind = "swipe"`, `kind = "tap"`) rather than physical keyboard keys, the plugin instantiates `SKeybind` structs with an empty key name (`key = ""`) or keycode 0.
2. **Hyprland 0.55+ / 0.56+ Key Resolver Collision**:
   - In modern Hyprland versions, the key resolver refactor (`KeybindManager::Resolver`) matches incoming key events against registered `SKeybind` entries.
   - When key events for `XKB_KEY_space` are processed, empty keysym/keycode dummy entries registered by `hyprgrass` inadvertently match or shadow the key resolver lookup table.
   - Hyprland's key dispatcher assumes an internal bind was matched, consuming and swallowing the physical Space keystroke instead of passing it to Wayland client applications.

---

## 3. Immediate Recovery & Verification

1. **Unload `hyprgrass` from Compositor Memory**:
   ```bash
   hyprctl plugin unload /var/cache/hyprpm/$USER/hyprgrass/hyprgrass.so
   ```
2. **Kill any open virtual keyboards (`wvkbd`)**:
   ```bash
   killall wvkbd-mobintl
   ```
3. **Revert plugin configuration in `inputs.lua`**:
   Remove `hl.plugin.hyprgrass` calls from [`profiles/surface/.config/hypr/config/profile/inputs.lua`](file:///home/jmvp/dotfiles/profiles/surface/.config/hypr/config/profile/inputs.lua).
4. **Reload Hyprland**:
   ```bash
   hyprctl reload
   ```
   *The physical Space key immediately resumes normal typing.*

---

## 4. Alternative Approaches for Touchscreen Gestures

To avoid modifying or colliding with Hyprland's internal `KeybindManager`:

1. **Standalone Libinput Gesture Daemon (`lisgd`)**:
   - `lisgd` (`aur/lisgd`) monitors `/dev/input/event*` touch devices externally via libinput.
   - When gestures occur, it executes standard IPC calls (`hyprctl dispatch ...`) from userspace.
   - It **never** injects dummy structs into Hyprland's C++ keybind resolver, guaranteeing 0 keyboard interference.
2. **Native Hyprland Touchpad Gestures**:
   - Native `hl.gesture()` directives in `inputs.lua` handle multi-finger trackpad swipes cleanly without key collision.
3. **Dedicated On-Screen Keyboard (`wvkbd`)**:
   - Kept bound to `SUPER + ALT + V` via [`profiles/surface/.config/hypr/config/profile/binds.lua`](file:///home/jmvp/dotfiles/profiles/surface/.config/hypr/config/profile/binds.lua) without plugin dependencies.
