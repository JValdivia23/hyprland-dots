# Quick Spotify (`JValdivia23/Quick-Spotify`) Gotchas & Architecture

## 1. Dual-Mode Architecture (Standalone Linux + Omarchy 4 Plugin)

[JValdivia23/Quick-Spotify](https://github.com/JValdivia23/Quick-Spotify) (`~/dev/Quick-Spotify`) adapts `stappmus/Omarchy-Spotify` so the ~60 MB Quickshell + Rust `librespot` client works standalone on any Linux Wayland distro and desktop shell (Noctalia, Waybar, Hyprland, Sway, Niri, KDE, GNOME) while remaining 100% compatible with `omarchy plugin add`:

- **Root directory**: Retains `manifest.json` (`schemaVersion: 1`, `id: "quickshell.spotify"`) and root entrypoints (`Service.qml`, `BarWidget.qml`, `Panel.qml`) with **zero symlinks** outside `.git` (enforced by `standalone/validate-manifest.sh` to match `omarchy-plugin-validate`).
- **`standalone/` directory**:
  - `standalone/shell.qml`: Standalone `ShellRoot` providing persistent settings (`~/.config/quick-spotify/settings.json`), per-monitor zero-input-mask (`mask: Region {}`) top anchors (`36px`) for the dropdown mini-player (`KeyboardPanel`), the 980×720 floating full player (`Panel.qml`), and `IpcHandler { target: "quick.spotify" }`.
  - `standalone/Commons/` & `standalone/Ui/`: Bundled MIT-licensed Omarchy QML UI kit (24 components, excluding `BackgroundVideo` so `QtMultimedia` is not required).
  - `standalone/bin/quick-spotify`: CLI controller (`toggle`, `full`, `mini`, `play-pause`, `next`, `previous`, `volume-up`, `volume-down`, `mute`, `status`, `restart`, `quit`).

---

## 2. Qt 6.12 `QtQuick.Color` Namespace Shadowing Gotcha

- **Symptom**: On CachyOS / Arch systems with `qt6-declarative >= 6.12.0`, running Quickshell components that combine `import QtQuick` and `import qs.Commons` prints `TypeError: Cannot read property 'background' of undefined` and `Unable to assign [undefined] to QColor` whenever unqualified `Color.foreground` or `Color.tooltip.background` is evaluated.
- **Root Cause**: Qt 6.12 introduced a built-in `Color` value-type gadget in `QtQuick`, which shadows the `singleton Color` exported by `qs.Commons/qmldir` (and same-directory `Color.qml` inside `Commons/`).
- **Fix**: Always qualify palette singleton references:
  - In `standalone/Ui/*.qml`: `import qs.Commons as Theme` and reference `Theme.Color.*`.
  - In `standalone/Commons/Border.qml` & `Style.qml`: `import "." as Self` and reference `Self.Color.*`.

---

## 3. Noctalia Live Wallpaper / M3 Palette Sync

- `standalone/Commons/Color.qml` watches `~/.config/quick-spotify/colors.toml` (`watchChanges: true`, `onFileChanged: reload()`) with automatic fallback to `~/.local/state/omarchy/current/theme/colors.toml`.
- `core/.config/noctalia/quick-spotify.toml` registers `[theme.templates.user.quick_spotify]` using `core/.config/noctalia/templates/quick-spotify-colors.toml`, so Noctalia writes updated hex tokens into `~/.config/quick-spotify/colors.toml` on every wallpaper or theme switch and Quick Spotify recolors live without restarting.

---

## 4. Universal `core/` Integration & Keybindings

- **Wrapper (`core/.local/bin/quick-spotify`)**: Auto-clones `JValdivia23/Quick-Spotify` to `~/dev/Quick-Spotify` and compiles `~/.local/lib/omarchy-spotify/omarchy-spotify-backend` on first run when deployed to a fresh machine (`surface`, `cachyos-cu`).
- **Keybindings (`core/.config/hypr/config/binds.lua`)**:
  - `SUPER + SHIFT + M`: Toggle Quick Spotify (`quick-spotify toggle`).
  - `SUPER + CONTROL + ALT + M`: Toggle Quick Spotify Mini Player (`quick-spotify mini`).
  - `SUPER + CONTROL + M`: Restore last minimized window from tray drawer (`hypr-tray-drawer restore`, moved from `SUPER + SHIFT + M` to avoid collision).
- **In-Window `Ctrl + Arrow` Note**: Global Hyprland focus bindings (`CONTROL + Left/Right/Up/Down`) intercept Quick Spotify's internal `Ctrl+Left/Right` (prev/next) and `Ctrl+Up/Down` (volume) chords; use hardware media keys (`XF86Audio*`), `Space`, `Shift+Left/Right` (seek), or `quick-spotify` CLI subcommands instead.

---

## 5. Quickshell Config Folder Sandbox (`qs-blackhole`) & `qs ipc` Flag Order

- **Symptom 1**: Launching `qs -p standalone` when `standalone/shell.qml` contains `import ".." as Plugin` fails at startup with `WARN quickshell.qmlscanner: Module path ... is outside of the config folder` and `qrc:/qs-blackhole: No such file or directory`.
- **Root Cause & Fix**: Quickshell's QML scanner blocks relative directory imports that escape `-p <config_dir>`. `standalone/bin/quick-spotify` stages the root `.qml`/`.js` files + `Commons/` + `Ui/` + `shell.qml` inside `~/.cache/quick-spotify/shell/` (`import "plugin" as Plugin`) and exports `QUICK_SPOTIFY_ROOT` so `Service.qml` resolves `scripts/`, `systemd/`, and `config/` in the real checkout while keeping zero symlinks inside the git repo.
- **Symptom 2**: Running `qs -p <dir> ipc call ...` fails silently when `ipc` subcommand expects `-p` after `ipc`.
- **Fix**: Always pass `-p` to the `ipc` subcommand: `qs ipc -p "$SHELL_DIR" call quick.spotify <method>`.
- **Symptom 3 (Generic Quickshell Icon in Noctalia Bar)**: Without `QS_APP_ID`, Quickshell sets Wayland `app_id` / Hyprland `class` to `org.quickshell`, causing Noctalia to render `/usr/share/icons/hicolor/scalable/apps/org.quickshell.svg` instead of `quick-spotify.svg`.
- **Fix**: `standalone/bin/quick-spotify` exports `QS_APP_ID="${QS_APP_ID:-quick-spotify}"`, `quick-spotify.desktop` sets `StartupWMClass=quick-spotify`, and `windowrules.lua` matches `^(quick-spotify|org\\.quickshell)$`.

---

## 6. Managed Spotify Soloist Local Receiver (`error audio key 0 1` Fix & Lossless)

- **Symptom**: Playing a track on the built-in `librespot` receiver fails with `Spotify did not provide the audio key required to play this track on this computer` (`[ERROR librespot_core::audio_key] error audio key 0 1`) due to Spotify phasing out eSDK v1 audio keys on newer/migrated accounts (`librespot-org/librespot#1649`).
- **Built-in Solution (`SoloistManager.qml` + `scripts/soloist-runtime.sh`)**:
  1. Pre-installed official `soloist 1.4.0.15` (`Core Playback SDK 2.10.0`) into `~/.local/lib/quick-spotify/soloist` supervised on-demand by `~/.config/systemd/user/quick-spotify-soloist.service` (`Conflicts=omarchy-spotify.service`, `-w 127.0.0.1:0`, ~6 MB RAM, sleeps after idle timeout).
  2. In **Quick Spotify $\rightarrow$ Settings $\rightarrow$ Spotify Soloist** (or via CLI `quick-spotify setup-soloist`): click **1. Get Soloist API Key** (`https://developer.spotify.com/documentation/soloist`), click **Paste**, and click **2. Save & Activate**.
  3. **Directory Permission Gotcha (`credentials/` `u+rwX`)**: `soloist setup-api-key` stores the key inside a subdirectory (`~/.local/share/soloist/credentials/api_key`). Never run `chmod 600 "$soloist_data_dir"/*`, which strips `+x` from `credentials/` (`drw-------`) and causes subsequent reads/writes to fail with `Permission denied`; always use `chmod -R u+rwX,go= "$soloist_data_dir"`.
  4. **One-Time DPoP Connect Pairing Gotcha**: `soloist 1.4.0.15` uses DPoP-bound Connect authorization (`AuthInfo.DpopBoundAuthCodeInfo` in ZeroConf `getInfo`) and ignores legacy `librespot` `addUser` blobs (`logged in: no`). To store Soloist's refreshable session (`~/.local/share/soloist/settings`) permanently:
     - **Zero-firewall desktop method**: Click **3. Open Spotify Desktop to Pair** (`spotify-launcher`), select **Quick Spotify** in the Devices menu once over local loopback (`lo`), wait ~3 seconds for Quick Spotify to report `Soloist receiver active & paired`, then close `spotify-launcher`.
     - **Mobile LAN method (if `ufw` is active)**: Temporarily allow `5353/udp` (mDNS) and Soloist's ephemeral ZeroConf TCP port (from `journalctl --user -u quick-spotify-soloist.service`) on LAN, select **Quick Spotify** once on your phone, then close the port.
  5. Once paired (`loggedIn: true`), `soloist-runtime.sh activate` invokes `soloist ctl activate` over local WebSocket (`127.0.0.1:<ws.port>`), `SoloistManager.qml` streams `soloist ctl trace` for 0ms real-time playback updates, and transport/volume controls execute directly via `soloist ctl` (zero Spotify Web API rate limit).
  6. **`isLocalPlaybackDevice` vs Soloist Gotcha**: `Service.qml` must guard `Api.isLocalPlaybackDevice(...)` with `builtInReceiverEnabled`; otherwise when `builtInReceiver` is `"Off"` and Soloist shares `deviceName` (`"Quick Spotify"`), `remotePlaybackIsLocal` evaluates `true`, clearing `useRemotePlayback` and leaving the UI blank while Soloist is actively playing.
  7. **MPRIS2 Bridge (`org.mpris.MediaPlayer2.quick_spotify`)**: Because Spotify Soloist does not publish MPRIS2 natively, `~/.local/lib/quick-spotify/run-soloist` launches `~/.local/lib/quick-spotify/soloist-mpris-bridge.py` (`scripts/soloist-mpris-bridge.py`, Python + `gi.repository.Gio`) alongside `soloist`. This exposes live metadata, cover art, seek/position, volume, shuffle, loop, and transport controls (`Play`/`Pause`/`PlayPause`/`Next`/`Previous`/`Seek`/`SetPosition`) to Noctalia Media (bar, Control Center, Lock Screen), hardware `XF86Audio*` keys, and any Linux DE/bar without colliding with `Service.qml`'s `isSpotifyd()` filter.


