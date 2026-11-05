# Flea File Explorer (`flea-cachyos`) Gotchas & Architecture

## 1. Upstream Flea vs. CachyOS / Non-Omarchy

Upstream [thisisgm/flea](https://github.com/thisisgm/flea) is designed specifically for David Heinemeier Hansson's **Omarchy** Linux environment. Its built-in `flea --default` command makes several Omarchy-specific assumptions:
- Hardcodes edits to `~/.config/hypr/bindings.lua` using Omarchy helper functions like `o.window(...)` and `omarchy-cmd-terminal-cwd`.
- Fails with Lua syntax errors when executed on non-Omarchy Hyprland installations (such as our modular `~/.config/hypr/config/` structure).
- Requires the `omarchy` package for asset symlinks in `/usr/share/omarchy/shell/`.
- Was removed from the Arch User Repository (AUR) because AUR policy disallows packages that depend on external, non-Arch distro repositories.

### Solution: `gcap0n1/flea-CachyOS`
We use the active public fork [gcap0n1/flea-CachyOS](https://github.com/gcap0n1/flea-CachyOS):
- Fully decouples Flea from `omarchy` and bundles standalone QML/asset files.
- Provides `dolphin` and conflicts with `dolphin`, cleanly replacing Dolphin while satisfying meta-packages like `cachyos-hypr-noctalia`.
- Distributed via a dedicated pacman repository configured in `/etc/pacman.conf` (`[flea-cachyos]`), enabling automatic updates through `sudo pacman -Syu` or `paru`.

---

## 2. Noctalia Dynamic Theming Integration

Flea's GPUI window reads its theme colors from `~/.local/state/omarchy/current/theme/colors.toml`.

To integrate seamlessly with the Noctalia Wayland shell without running Omarchy:
1. Noctalia loads every `*.toml` file located in `~/.config/noctalia/`.
2. `flea-cachyos-setup on` installs `~/.config/noctalia/flea.toml`, defining a custom user template:
   ```toml
   [theme.templates.user.flea]
   input_path = "/usr/share/flea/noctalia/flea-colors.toml"
   pre_hook = "sh -c 'mkdir -p \"$HOME/.local/state/omarchy/current/theme\"'"
   output_path = "~/.local/state/omarchy/current/theme/colors.toml"
   post_hook = "sh -c 'date +%s > \"$HOME/.local/state/omarchy/current/theme.name\"'"
   ```
3. Whenever Noctalia generates a new color scheme from wallpaper or settings, it automatically renders Flea's palette into `colors.toml`.
4. Flea watches `theme.name` and hot-reloads its colors live without needing a restart.

---

## 3. Modular Hyprland Lua Integration

### Default Application Variable (`core/.config/hypr/config/variables.lua`)
```lua
FILE_MANAGER = "flea"
```

### Launch or Focus (`core/.config/hypr/config/binds.lua`)
Flea's GPUI window class is `com.thisisgm.flea`. Our native `helpers.launch_or_focus` utility matches substring `"flea"`:
```lua
helpers.bind(mainMod .. " + SHIFT + F", "Launch or focus File Manager", helpers.launch_or_focus("flea", launchPrefix .. FILE_MANAGER))
```

### File Picker Modal Floating (`core/.config/hypr/config/windowrules.lua`)
When applications request an Open/Save dialog via `xdg-desktop-portal`, Flea spawns `com.thisisgm.flea.picker`. To ensure it floats and centers as a modal:
```lua
local modalMatches = {
    ...
    { class = "^(com\\.thisisgm\\.flea\\.picker)$" },
}
```

---

## 4. XDG MIME & Desktop Portal Integration

- **Default Directory Handler:**
  ```bash
  xdg-mime default com.thisisgm.flea.desktop inode/directory
  ```
- **XDG Desktop Portal:**
  `~/.config/xdg-desktop-portal/portals.conf` routes the file picker interface to Flea while maintaining the compositor default:
  ```ini
  [preferred]
  default=hyprland;gtk
  org.freedesktop.impl.portal.FileChooser=flea;gtk
  ```
- **D-Bus File Manager Service:**
  Flea registers `/usr/share/dbus-1/services/com.thisisgm.flea.FileManager1.service` to answer `org.freedesktop.FileManager1` ("Show in folder" calls from web browsers and external applications).
