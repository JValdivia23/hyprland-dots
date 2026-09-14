# Wayland & Noctalia Shell Gotchas

Curated troubleshooting issues, rules, and fixes for Noctalia Wayland Shell and desktop utilities on `cachyos-cu`.

---

## 1. Noctalia Shell Process Restarting

- **Symptom**: Editing `~/.config/noctalia/config.toml` or restarting PipeWire leaves Noctalia holding a stale audio/widget connection.
- **Fix**: Restart the Noctalia daemon process:
  ```bash
  killall -TERM noctalia; sleep 0.5; hyprctl eval 'hl.exec_cmd("noctalia -d")'
  ```

---

## 2. Piped Screenshots via Satty

- **Symptom**: Pressing the PrintScreen key launches slurp/grim, but the screenshot editor fails to appear.
- **Root Cause**: The Noctalia configuration `clipboard_image_action_command = "satty -f -"` pipes raw screenshot data to Satty via stdin. If Satty is uninstalled or Wayland environment variables are missing, the pipe breaks silently.
- **Fix**: Verify Satty is installed:
  ```bash
  pacman -Q satty
  ```

## 3. Quick Look Image / Vector Preview Overlay (`ALT + Return`)

- **Symptom**: Pressing `ALT + Return` over a highlighted file in Dolphin does not display a preview.
- **Root Cause**: The Quick Look engine relies on `swayimg` floating window rules in `windowrules.lua` and the helper script `~/.local/bin/hypr-quicklook`.
- **Fix**: Ensure `swayimg` is installed (`pacman -Q swayimg`) and `~/.local/bin/hypr-quicklook` has executable permissions.

---

## 4. Volume Control & OSD after PipeWire Restart


- **Symptom**: Touch Bar volume keys do not change volume or trigger OSD popups after PipeWire is restarted (`noctalia msg volume-up` fails with `error: no default output`).
- **Root Cause**: Noctalia connects to the PipeWire / WirePlumber mixer API on startup. If PipeWire is restarted while Noctalia is running, Noctalia must be restarted to re-bind to the active default sink.
- **Fix**: Restart Noctalia in daemon mode:
  ```bash
  killall -TERM noctalia && noctalia -d
  ```

---

## 5. Wallpaper Selector (`ALT + Space`) Loading Latency & Caching

- **Symptom**: Pressing `ALT + Space` shows a `"Caching wallpapers..."` banner and freezes for 7–10 seconds before opening the wallpaper grid.
- **Root Cause**:
  1. Stock `/usr/bin/waypaper` unconditionally displays the caching label even when all thumbnails exist.
  2. Stock Waypaper loads all 1,700+ full thumbnail pixbufs into GTK widgets before showing the grid.
  3. Generating thumbnails for new wallpapers is single-threaded and sequential.
- **Fix**:
  1. Route `ALT + Space` in `~/.config/hypr/config/binds.lua` to the progressive rendering build in `~/.local/share/waypaper/venv/bin/waypaper` (which renders the first 20 items in `< 0.05s`).
  2. If thousands of new wallpapers are added, generate thumbnails in parallel using Python `ThreadPoolExecutor`:
     ```python
     python3 -c "
     import os, hashlib, pathlib
     from concurrent.futures import ThreadPoolExecutor
     from PIL import Image

     cache_dir = pathlib.Path('~/.cache/waypaper').expanduser()
     cache_dir.mkdir(parents=True, exist_ok=True)
     wallpapers_dir = pathlib.Path('~/Pictures/Wallpapers').expanduser()

     images = [os.path.join(r, f) for r, _, fs in os.walk(wallpapers_dir) for f in fs if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp', '.gif'))]

     def cache_one(img):
         try:
             real_path_bytes = bytes(os.path.realpath(img), encoding='UTF-8')
             out_path = cache_dir / f'{hashlib.md5(real_path_bytes, usedforsecurity=False).hexdigest()}.png'
             if not out_path.exists():
                 with Image.open(img) as im:
                     im.thumbnail((240, 240))
                     im.save(out_path, 'PNG')
         except Exception:
             pass

     with ThreadPoolExecutor(max_workers=16) as ex:
         list(ex.map(cache_one, images))
     "
     ```

---

## 6. Web App Launcher Icons Resolution & Format Requirements

- **Symptom**: Web app launchers (such as YouTube, AllAnime, Hanime) show a generic placeholder or broken icon in Noctalia launcher, Rofi, or task managers.
- **Root Cause**:
  1. Desktop entry `Icon=` specifies a name without full path (e.g. `Icon=YouTube`), but the icon was placed directly in `~/.local/share/icons/` without the standard XDG `hicolor/<size>/apps/` structure or `~/.local/share/pixmaps/`.
  2. The icon file was actually a JPEG image saved with a `.png` extension; Cairo and GTK/Wayland decoders strictly fail to decode disguised JPEGs via PNG loaders.
- **Fix**:
  1. Always convert icons to valid RGBA PNG (or scalable SVG) files.
  2. Populate multi-resolution sizes in `~/.local/share/icons/hicolor/{32x32,48x48,64x64,128x128,256x256,512x512}/apps/` and `~/.local/share/pixmaps/`.
  3. Run `gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor` and `update-desktop-database ~/.local/share/applications`.

---

## 7. Noctalia 5.0.1 Deprecated Config Keys Migration (`noctalia config validate`)

- **Symptom**: Noctalia displays an on-screen warning banner: *"There's an error in config.toml, Noctalia is applying the replacement"*.
- **Root Cause**: In Noctalia 5.0.1 (following upgrade from 5.0.0_beta), several widget schema keys were refactored:
  - `show_label` on widgets (`temp`, `sysmon_*`) was renamed to `show_value`.
  - `widget.workspaces.display = "none"` was replaced with `show_labels = false`.
  Noctalia detects deprecated keys at startup and applies automatic runtime replacements, alerting the user with an overlay banner.
- **Fix**:
  1. Run `noctalia config validate` to inspect all schema warnings.
  2. Update `~/.config/noctalia/config.toml` (in `~/dotfiles/core/.config/noctalia/config.toml`):
     - Change `show_label = false` to `show_value = false` under `[widget.temp]` and `[widget.sysmon_*]`.
     - Change `display = "none"` to `show_labels = false` under `[widget.workspaces]`.
  3. Restart Noctalia cleanly:
     ```bash
     killall -TERM noctalia; sleep 0.5; export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/$UID/hypr/ 2>/dev/null | head -n1); hyprctl eval 'hl.exec_cmd("noctalia -d")'
     ```

