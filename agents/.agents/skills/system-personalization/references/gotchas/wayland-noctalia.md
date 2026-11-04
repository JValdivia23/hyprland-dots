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

- **Symptom**: Opening wallpaper selectors or scrolling through 1,600+ wallpapers suffers from latency, loading placeholders, or stuttering.
- **Root Cause**:
  1. Noctalia v5 generates thumbnails lazily on-demand as wallpapers scroll into view.
  2. Each uncached image requires full-size CPU decode, scale-down to 361px, and WebP encoding.
  3. Legacy `waypaper` had Python single-threaded overhead and GTK list stalls.
- **Architecture & Solution**:
  1. **Native Noctalia Panel**: Both `ALT + Space` and `SUPER + SHIFT + W` route to `noctalia msg panel-toggle wallpaper`.
  2. **Cache Hash Key**: Noctalia v5 hashes `path + "\n" + file_size + "\n" + last_write_time ticks + "\n" + targetPx + "\nthumbnail-service-v2"` (64-bit FNV-1a, 16-hex `.webp` in `~/.cache/noctalia/thumbnails/`). Ticks = `fs::last_write_time().time_since_epoch().count()` verbatim — do NOT convert to Unix nanos.
  3. **High-Performance Pre-cacher**: Run `noctalia-precache-wallpapers` (C++20 utility utilizing `vipsthumbnail` across all cores) to batch-generate thumbnails (~30s on 16 threads, ~135s on 8-thread Surface for 1637 stills).
  4. Automatically invoked by `cachy-sync-wallpapers` upon syncing new wallpapers.
  5. **Random Shuffle**: Enabled via `sort = "random"` in `~/.local/state/noctalia/state.toml` (or by clicking the `arrows-random` sort icon in the panel header). Refreshing via the circular arrow icon re-shuffles instantly.
- **Gotcha (2026-09-16)**: `targetPx` is per-machine, not fixed 361 — it is the tile's physical px (`lround(max(cellW,cellH) * renderScale)`). `surface` needs `428 451 541`, `macbook-t2` needs `361`. Warm every width with demand (`cachy-sync-wallpapers` loops them; override via `NOCTALIA_THUMB_WIDTHS`). Verify with a live panel open (~0 new files), never with the tool's own "already cached" count.

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

---

## 8. StatusNotifierItem (SNI) Left-Click Activation in `libayatana-appindicator` & Noctalia

- **Symptom**: Left-clicking a tray icon created with `libayatana-appindicator` in Noctalia does nothing, while right-clicking opens the menu. Inspection with `busctl` reveals `Call failed: No handler for Activate`.
- **Root Cause**:
  1. Noctalia invokes `org.kde.StatusNotifierItem.Activate(x, y)` on primary click (left-click) and `ContextMenu(x, y)` / DBusMenu on secondary click (right-click).
  2. By default, `libayatana-appindicator` is designed as menu-only and rejects `Activate` D-Bus calls with `No handler for Activate` unless an explicit `activate` GObject signal handler is connected on the Indicator instance: `indicator.connect("activate", callback)`.
  3. `set_secondary_activate_target` only binds to middle-click (`SecondaryActivate`), not left-click (`Activate`).
- **Fix**: Connect the `"activate"` GObject signal directly on the indicator:
  ```python
  self.indicator.connect("activate", self._on_indicator_activate)
  ```
  This satisfies the D-Bus method call, returns success immediately, and triggers the tray drawer menu (`noctalia dmenu`).

---

## 9. SNI Tray Icon Sizing, `XAyatanaLabel`, and Dynamic Symbolic SVG Badges in Noctalia

- **Symptom**:
  1. Using Adwaita's `window-restore-symbolic` for a tray icon in Noctalia renders as a minuscule `~5.7px × 5.7px` square on the bar.
  2. Calling `indicator.set_label(str(count), "minimized")` in `libayatana-appindicator` shows no numeric badge on the Noctalia bar.
- **Root Cause**:
  1. `/usr/share/icons/Adwaita/symbolic/ui/window-restore-symbolic.svg` draws a `6×6` titlebar square centered inside a `16×16` viewBox (`5px` empty margin on all four sides — only `37.5%` linear size / `14%` area). Because Noctalia's `TrayWidget` renders bar tray icons at `16.0 * ui_scale` px, the visible square shrinks to `~5.7px`.
  2. Noctalia's `StatusNotifierHost` does not read Canonical's non-standard `XAyatanaLabel` D-Bus property.
  3. Disassembly of `/usr/bin/noctalia` (`TrayWidget`, `0x127e140` & `0x12863d2`) shows that Noctalia recursively scans `IconThemePath` **once** when a new `IconThemePath` is first seen, caches the resolved file map per `IconThemePath` (`0x6c8`), invalidates the per-item icon cache when `IconName` changes (`0x127f53f`), and rasterizes any icon whose filename contains `"symbolic"` via `librsvg` (`rsvg_handle_new_from_data`), automatically tinting its RGB to match the active theme's tray capsule foreground color (`on_secondary`).
- **Fix**:
  1. Pre-generate full-bleed `64×64` (`viewBox="0 0 64 64"`, spanning `x=2..62, y=1..62`) SVG icons with embedded geometric vector count digits (`hypr-tray-drawer-{0..9,9plus}-symbolic.svg`) into `$XDG_RUNTIME_DIR/hypr-tray-drawer-icons/` **before** setting `self.indicator.set_icon_theme_path(str(ICON_DIR))`.
  2. Switch `IconName` via `self.indicator.set_icon_full(f"hypr-tray-drawer-{key}-symbolic", ...)` whenever the minimized window count changes so Noctalia invalidates its per-item cache and renders the updated count badge with automatic theme color tinting.

---

## 10. Legacy Wine Fullscreen: Active Renderer and `steam_proton` Tiling

- **Symptom:** A legacy game has clipped content, uneven white/black padding, or an unexpectedly small tiled window despite fullscreen settings in adjacent INI files.
- **Diagnosis:** Identify the DLL actually selected by the launch arguments before editing configuration. A legacy `-3dfx` renderer can read `HKCU\Software\GLIDE3toOpenGL`, while `ddraw.ini` and `d2gl.ini` belong to different renderers. Inspect `hyprctl -j clients` as well: Bottles/Soda may use class `steam_proton`, which does not match the existing `steam_app.*|gamescope` gaming rules.
- **Scoped fix:** With user approval, use the active renderer's desktop-resolution fullscreen and aspect-ratio-preservation settings. Apply registry values through `bottles-cli reg`, not raw edits while Wine is running. A private per-game launcher can register a named Lua rule matching both that game's title and XWayland class, with `fullscreen = true`, `sync_fullscreen = true`, and `decorate = false`, before launch. Avoid globally forcing every `steam_proton` window fullscreen; it is shared by other Wine applications.
- **Geometry:** At display scale 2, a 3000x2000 panel is 1500x1000 logical pixels. Correct-aspect 4:3 content on a 3:2 panel necessarily retains matching black side borders; removing all borders requires stretching or engine-supported widescreen rendering. Desktop-resolution output is not the same as a native-resolution game viewport.
- **Verification (2026-10-24):** Renderer registry values persisted; live fullscreen geometry and a main-menu screenshot were checked, with no white strip or Hyprland errors. Gameplay and next-launch checks were still pending at documentation time. Keep private title mappings and paths in the encrypted SideQuest guide rather than these shared dotfiles.

---

## 11. Game-Scoped Touch-to-Mouse Bridge and Its Limits

- **First distinguish hardware from application input:** Confirm desktop/browser touch and capture events during an explicitly coordinated tap test. A short trace with zero contacts, or merely seeing virtual input devices listed, does not establish whether touch is healthy. Do not restart working IPTSD services for an application-only issue.
- **Native-game fix verified on Surface (2026-10-24):** SideQuest's `goo-architect` launcher now runs a standard-library Python touch reader plus a small Wayland virtual-pointer client. The bridge uses the native game PID, only grabs a touchscreen for that focused/unlocked game, and restores native touch/buttons on focus loss, exit, or failure. The user confirmed taps/drags and browser touch after switching away. No global config, uinput permission, input group, system service, or kernel change was needed.
- **X11-polling native sequel (2026-10-24):** `goo-architect-2` retains its required X11/XWayland display but needs explicit `--backend x11` mouse input. Wayland clicks reached it while `XQueryPointer` stayed stale, leaving taps at the old pointer and preventing dragging. One-off diagnostic cursor movement was not a lasting fix; always retest after normal quit/reopen. The opt-in XTest backend sends motion and buttons on one connection using current root dimensions and `XSync` ordering. The user confirmed taps/drags after restart, regular mouse input, and browser touch restoration. The first game's Wayland default and installed helper are unchanged; X11 runtime libraries load only for the explicit backend. Rotation/mixed-scale multi-monitor behavior and gameplay lock/unlock were not physically tested.
- **Implementation gotchas:** Linux may omit unchanged MT coordinates on repeated taps. Snapshot MT slot positions before grabbing and retain inactive slot coordinates. Use actual evdev ranges and compositor scale/rotation/layout; never hardcode native display pixels as touch-axis ranges. Release a pressed button before relinquishing control, wait for finger lift before acquisition, fail closed when session lock state is unknown, and handle a busy device when another game's helper is releasing it.
- **Scope / limitations:** This is currently one-finger left-click/hold/drag, not full multitouch or right-click emulation. Desktop touch gestures are temporarily reserved while the game owns touch. `SIDEQUEST_TOUCH_MOUSE=0` bypasses the bridge for a launch. Non-Hyprland/non-Wayland launches fall back to the ordinary game command.
- **Wine is not equivalent:** The legacy RPG ignored the Wayland pointer; XTest produced movement but no reliable clicks/alignment, and an alternate renderer broke regular mouse behavior. Those tests were reverted, and that generic bridge remains disabled for the recipe. A later, separately verified game-local message helper, including held left/right gestures, is documented in section 12. Keep private title mappings and exact game paths in the encrypted SideQuest guide.

---

## 12. Legacy Wine Game-local Touch: Coordinates and Held-button Safety

- **Initial tap fix confirmed on Surface (2026-10-24):** A separate native Windows helper for `dark-wanderer` posts game-local mouse messages. The initial tap-only version passed menus, ground walking, normal restart, physical mouse input, original borders, and browser touch. It remains available with `SIDEQUEST_TOUCH_MODE=tap`.
- **Held/right extension confirmed (2026-10-24):** Default controls now use one-finger tap/hold for left and two-finger tap/hold for right; the first finger steers/aims. A 100 ms recognition window avoids accidental left clicks before two-finger gestures. Release left before switching to right, and require all fingers to lift after a right gesture ends. The user separately confirmed held walking/steering, right-button skills, release/app-switch cleanup, restart, and normal mouse/browser behavior. Skill repetition follows normal game behavior, not a click-spam macro.
- **Legacy coordinate trap:** The fullscreen output is 3000×2000, but the mod's native viewport is 1024×768. The original wrapper needed native game coordinates; an early trial combining output pixels with Windows cursor warping displaced the pointer. Continue rejecting native-aspect black-border taps and never compensate with global scaling/capture changes. The integrated graphics wrapper introduced by the later upgrade instead needs client-window message coordinates, as verified in section 14; do not apply the legacy conversion twice. Both modes use game-local messages, not desktop cursor warping.
- **Wine session trap:** A standalone `flatpak run` helper did not see the running game's Windows window. Use `flatpak enter` on the game's own instance, preserve its existing Wine prefix/runner environment, and match the host-side window by exact title/class and bottle prefix before tracking its PID. The Python controller authenticates its loopback helper connection with a random token and closes the listener after connection.
- **Scope / safety:** Touch is captured only for that focused/unlocked game and restored on focus loss/geometry changes/exit/failure. Wait for finger lift and snapshot MT slots before capture. Held movement must carry `MK_LBUTTON`/`MK_RBUTTON` without re-pressing the button. The Windows helper independently releases on focus loss, disconnect, or a 600 ms heartbeat lease timeout; stale state requires a reset before re-pressing. Keep socket writes bounded and complete any started atomic click. A versioned handshake prevents mismatched helper pairs. Keep physical mouse/keyboard input normal. `SIDEQUEST_TOUCH_MOUSE=0` gives a mouse-only launch. Do not substitute the failed generic Wine bridge for this game-local path.
- **Build / limits:** Uses existing clang/lld plus the selected 64-bit Bottles runner's Windows headers/import libraries; no MinGW install, root, uinput changes, service, game DLL hook, or game-memory access is required. Rotation/mixed-scale multi-monitor behavior and gameplay lock/unlock were not physically tested. The native viewport is explicit per-recipe configuration and must be revisited if the game engine changes it.

---

## 13. Native Mouse Clicks Desynchronize After Workspace Return

- **Observed on Surface (2026-10-25):** In `dark-wanderer`, physical mouse hover looked correct while clicks landed elsewhere after a browser-workspace round trip. Game-local touch clicks stayed accurate. The fullscreen geometry/renderer values were unchanged and the touch helper had no errors.
- **Live isolation:** With approval, gracefully detached only the identified touch controller/Windows helper and confirmed its evdev FD was closed while preserving the running game. The user reproduced the bad physical clicks with touch fully detached. Reattached touch to the same game rather than restarting it. This rules out active helper events as necessary for the ongoing problem; it does not prove the provenance of already-corrupted native state.
- **Trigger narrowed to swipes:** After recovery, the user compared keyboard switching with their usual gesture and confirmed **“Keyboard works; swipe breaks.”** They accepted Super+number instead of further swipe experiments. In installed Hyprland 0.56.2, native workspace-swipe completion releases pointer constraints after switching, then refocuses; this plausibly explains the capture symptoms but does not fully prove the failing application layer. Ordinary workspace dispatches are not equivalent to the native interactive swipe path.
- **Temporary recovery, not a permanent fix:** The initial recovery used compositor plus PID-checked native focus. A later real compositor focus transition from another window to the game, without the native call, also restored clicks until another swipe. Re-focusing the already-active game did not. Normal compositor focus can warp the cursor as part of its implementation. Keyboard switching was tested to avoid the trigger from a recovered state, not to cure every already-corrupted state.
- **Rejected automatic actions:** Same-window native focus, take-focus notification, a short native None→game focus cycle, and a same-position pointer-refresh watcher did not fix normal swipe returns. The watcher issued refresh requests on three visits and was stopped; never promote its one-off diagnostic-assisted result as a working automatic fix. No watcher was installed.
- **Rejected confinement / rollback:** A separately approved, focused-game-only tagged confinement rule caused slow/unresponsive movement. It was disabled and its owned tag removed; the user confirmed normal movement returned but clicks remained misplaced. The disabled in-memory rule may remain registered until normal reload; do not re-enable it or reload the compositor solely to remove an inert registration while the user's game is open. A final targeted focus recovery was performed without a restart but not separately user-validated. No permanent source, launcher, gesture, renderer, registry, package, or driver changes remain.
- **Diagnostic cautions:** Do not infer corruption from raw compositor versus X11/Wine coordinates alone, or from a transient focus/`WM_HINTS` value; applications may have their own coordinate/focus paths. Do not blindly change global scaling, mouse drivers, capture registry settings, or the proven touch mapping. Do not restart a user's live game or stop an entire bottle/wineserver just to detach an input helper. Keep exact private commands/title mappings and session details in the encrypted guide.

---

## 14. Graphics-wrapper Upgrades Can Change Touch-message Coordinates

- **Confirmed on Surface (2026-10-26):** After the `dark-wanderer` upgrade, touch still worked in other applications but in-game contacts jumped into a restricted area. Both touch helpers were running and unchanged. The new wrapper unscales incoming window-message coordinates; the legacy helper was already converting to native game coordinates. Changing the helper to client pixels restored accurate touch in the live game.
- **Fix scope:** Preserve native viewport proportions and border rejection, but let the wrapper perform its own single client→game conversion. Read actual Windows client dimensions on each command; do not hardcode physical/logical monitor sizes, warp the desktop cursor, alter the renderer, or change global scaling/input drivers. Retain held-state movement flags, release-before-switch, focus/lock guards, disconnect cleanup, and the independent heartbeat lease.
- **Selection / compatibility:** The recipe uses automatic recognition of the integrated wrapper's MZ/PE headers and binary identity markers, not the mere existence of a graphics INI. Legacy wrappers keep native game coordinates. `SIDEQUEST_TOUCH_COORDINATES=game`/`client` explicitly override the recipe; direct helper invocation defaults to `game`. A versioned handshake now includes the selected coordinate space, so old/new Python and Windows helpers must not be mixed.
- **Deployment / validation:** Backed up the installed pair/launcher, gracefully detached only touch support, installed a matched pair, and attached to the existing game without losing progress or opening another copy. Renderer hashes, fullscreen command, shared generic bridge, and other games remained unchanged. The user confirmed taps across the picture, held left/right actions, release, physical mouse, and browser touch after Super+number switching. All 69 regression tests and the Windows SDK build pass.
- **Limits:** A normal quit/reopen of the new pair was not physically retested because the live game stayed open. Rotation, mixed-scale layouts, and gameplay lock/unlock remain untested. This is separate from section 13's workspace-swipe issue; do not re-enable the failed focus watcher or confinement rule. Keep private renderer/version mappings, exact commands, and backups in the encrypted guide.
