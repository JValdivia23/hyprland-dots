# System Personalization Changelog

A dated log of all package changes, configurations, script modifications, and hardware upgrades.

## [1.15.0] - 2026-08-10
### Added
- Configured Hyprland `cursor` settings in [`~/.config/hypr/config/inputs.lua`](file:///home/user/.config/hypr/config/inputs.lua):
  - Enabled `inactive_timeout = 3` to automatically hide the mouse cursor after 3 seconds of inactivity (resolving video player cursor visibility issues on websites like Pornhub without breaking games or desktop apps).
  - Enabled `hide_on_key_press = true` to automatically hide the cursor when typing.

## [1.14.0] - 2026-07-30
### Changed
- Replaced `--incognito` flag in [`~/.local/share/applications/Hanime.desktop`](file:///home/user/.local/share/applications/Hanime.desktop) and [`~/.local/share/applications/PH.desktop`](file:///home/user/.local/share/applications/PH.desktop) with `--user-data-dir=/home/user/.config/brave-webapps/containers/diagnostics`.
- Created dedicated diagnostics profile container directory (`~/.config/brave-webapps/containers/diagnostics`) allowing persistent history, cookies, and local session data across launches while remaining completely isolated from the primary user Brave profile.

## [1.13.0] - 2026-07-28
### Added
- Installed **`swayimg`** (`5.4-2.1`) for instant Wayland image and vector previews.
- Created `~/.local/bin/hypr-quicklook` and `~/.local/bin/dolphin-key-helper` scripts to trigger floating Quick Look previews over Dolphin.
- Added KDE Service Menu [`~/.local/share/kio/servicemenus/quicklook.desktop`](file:///home/user/.local/share/kio/servicemenus/quicklook.desktop) for Quick Look context menu action in Dolphin.

### Configured
- Set **Satty** (`satty.desktop`) as the default image viewer across standard MIME types (`image/png`, `image/jpeg`, `image/webp`, `image/gif`, `image/svg+xml`, `image/bmp`) using `xdg-mime default`.
- Configured floating window rules for `swayimg` in [`~/.config/hypr/config/windowrules.lua`](file:///home/user/.config/hypr/config/windowrules.lua#L49).
- Mapped **`ALT` + `Return`** (`Alt+Enter`) in [`~/.config/hypr/config/binds.lua`](file:///home/user/.config/hypr/config/binds.lua#L130) to trigger Quick Look preview overlay ([`~/.local/bin/hypr-quicklook`](file:///home/user/.local/bin/hypr-quicklook)).
- Configured macOS-style **Arrow key navigation** (`Right`/`Down` for next file, `Left`/`Up` for previous file) in [`~/.config/swayimg/config.lua`](file:///home/user/.config/swayimg/config.lua#L6-L10).
- Configured **Kitty** (`kitty.desktop`) as default terminal in [`~/.config/kdeglobals`](file:///home/user/.config/kdeglobals#L4-L5) & [`~/.config/kiorc`](file:///home/user/.config/kiorc#L4-L5), and mapped **`F4`** in Dolphin ([`~/.config/dolphinrc`](file:///home/user/.config/dolphinrc#L15-L17)) to launch Kitty in current folder.
- Preserved Dolphin's native `Space` key behavior for multi-item selection mode.

## [1.12.0] - 2026-07-28
### Added
- Installed **LocalSend** (`cachyos/localsend` v1.17.0-4) via `pacman` for cross-platform local network file sharing.

### Configured
- Configured **UFW Firewall** rules (`53317/tcp` and `53317/udp`) to allow LocalSend discovery broadcast and file receiving across the local network.

## [1.11.0] - 2026-07-26
### Added
- Built and installed **AniMatrix Studio** (`/home/user/Projects/animatrix-gui`), a versatile PySide6 (Qt6) GUI application for the ASUS ROG AniMe Matrix LED display combining features from `AniMeScroller` and `anime-matrix-clock`.
- Features: Live interactive LED matrix preview, customizable Clock Faces (digital, bold stacked, analog), Text Scroller & Banner ticker, System Hardware Monitor & MPRIS Media ticker, Image/GIF viewer, and `asusctl` power policy controls.
- Created desktop launcher `~/.local/share/applications/AniMatrix.desktop` with a custom cyberpunk neon LED matrix app icon in `~/.local/share/applications/icons/AniMatrix.png` for on-demand menu launching.
- Upgraded live preview widget into an authentic **ROG Zephyrus G14 Laptop Lid Simulator** featuring metallic dark brushed aluminum chassis, ROG badge plate, diagonal CNC micro-perforation LED mask, and radial LED glow rendering. Includes a toggle checkbox to switch between physical G14 Lid CNC Mask and raw rectangular grid.

### Fixed
- Implemented physical **Diagonal LED Lattice Coordinate Engine** in [`gui/matrix_widget.py`](file:///home/user/Projects/animatrix-gui/gui/matrix_widget.py), mapping individual simulated LEDs along the slanted diagonal rows of the physical ROG Zephyrus G14 laptop lid. Verified layout precision by capturing offscreen GUI screenshots and visually inspecting the rendered LED matrix preview.
- Added configurable Scale, Vertical (Y Offset), Horizontal (X Offset), and Diagonal Tilt Angle controls with one-click alignment presets in Settings.

## [1.2.0] - 2026-07-21
### Added
- Added `SUPER` + `CONTROL` + `I` keybinding to `~/.config/hypr/config/binds.lua` to toggle Noctalia Caffeine (`noctalia msg caffeine-toggle`), preventing automatic screen lock and system sleep during inactivity.

## [1.0.0] - 2026-07-20
### Added
- Initial setup of the `system-personalization` skill under `~/.agents/skills/system-personalization/`.
- Configured local system specs snapshot script (`snapshot.sh`).
- Documented hardware configurations and fractional scaling factors.
- Outlined edit rules for Hyprland Lua configuration modules and Noctalia Wayland Shell TOML settings.
- Documented all active keyboard shortcuts.
- Shallow-cloned the official CachyOS Wiki and Noctalia Docs to `references/` for offline searchability.

### Changed
- Customized touchpad controls in `~/.config/hypr/config/inputs.lua` for macOS-like trackpad behavior:
  - Enabled `natural_scroll`, `tap_to_click`, `clickfinger_behavior`, and `middle_button_emulation`.
  - Switched pointer acceleration profile to `adaptive`.
  - Configured 3-finger horizontal workspace gestures, 3-finger up fullscreen gesture, 3-finger down close gesture, and 4-finger horizontal workspace gesture.
- Documented full Hyprland 0.55+ Lua touchpad option keys, gesture API syntax, and `input.touchpad.tap_to_drag` pitfall in `references/config-paths.md` and `references/gotchas.md`.
- Added Core Rule 7 to `SKILL.md` requiring `hyprctl configerrors` as the first diagnostic step when users report Hyprland system/desktop errors (explaining why `journalctl` does not capture config validation errors).

## [1.1.0] - 2026-07-20
### Added
- Created native Lua `macShortcut` helper function directly in `~/.config/hypr/config/binds.lua` to inspect active window classes (`kitty`, `ghostty`, `alacritty`, etc.) and send context-appropriate key events (`Home`, `End`, `ALT+Left/Right`, `CTRL+Left/Right`, `CTRL+U`, `CTRL+Backspace`) with zero subprocess overhead or modifier bleed.
- Updated `~/.local/bin/hypr-window-pop` toggle logic to use `pinned` and `floating` window state properties directly, fixing toggle-back behavior for `SUPER + O` and `SUPER + SHIFT + O` (PiP mode).
- Added `SHIFT + Print` (Window / Pick screenshot) and `CTRL + Print` (Fullscreen screenshot), perfectly matching `jairo`'s screenshot bindings.
- Created `~/.local/bin/hypr-kbd-brightness` and bound `XF86KbdBrightnessUp` / `XF86KbdBrightnessDown` (`Fn + Up / Down`) to control keyboard backlight brightness (0-3) with custom notifications.
- Added `SHIFT` and `CONTROL` modifiers to screen brightness controls (`XF86MonBrightnessUp / Down`) for fine-tuning (1% steps) and coarse-tuning (10% steps).
- Updated default `kb_options` in `~/.config/hypr/config/inputs.lua` to `""` (Normal PC keyboard layout). Users can manually toggle to Mac layout anytime using `SUPER + ALT + K`.
- Configured `SUPER + K` to open the searchable dynamic keybindings cheat sheet file directly inside a floating, centered terminal.
- Installed Waypaper and bound `ALT + Space` to launch its GUI (with folder/subfolder scanning, random selection, auto-rotate timer, and Noctalia IPC `post_command` integration). Kept `SUPER + SHIFT + W` as the native Noctalia panel.
- Added Core Rule 8 to `SKILL.md` and documented gotcha pattern for launching interactive Kitty terminal windows (`kitty -e bash -c "sudo <command>; ...; read"`) whenever elevated password authentication is required.
- Patched Waypaper's `app.py` with a two-stage progressive rendering engine: Stage 1 renders the first 20 visible wallpapers instantly (< 0.05s) upon launch, while Stage 2 streams the remaining thumbnails asynchronously in the background.



### Changed
- Ported keybindings from `ssh jairo` into `~/.config/hypr/config/binds.lua`:
  - **Convention**: Set `SUPER + <key>` for system operations (Notifications on `SUPER+A`, Session Lock on `SUPER+L`, Float toggle on `SUPER+T`) and `SUPER + SHIFT + <key>` for applications (Zen Browser on `SUPER+SHIFT+B`, LazyGit on `SUPER+SHIFT+A`, LazyDocker on `SUPER+SHIFT+D`, Dolphin on `SUPER+SHIFT+F`, Notes on `SUPER+SHIFT+N`, Yazi on `SUPER+SHIFT+Y`).
- Changed workspace switching in `binds.lua` to match `jairo` layout: `SUPER + 1..9, 0` switches to workspace 1..10, `SUPER + SHIFT + 1..9, 0` moves active window to workspace 1..10, and monitor focus moved to `SUPER + ALT + 1..3`.
  - **Navigation**: Changed focus direction to `CTRL + Arrows`, window position swap to `SUPER + ALT + Arrows`, and workspace cycling to `SUPER + Tab` / `SUPER + SHIFT + Tab`.
  - **macOS Editing**: Enabled `SUPER+Left/Right` (HOME/END), `SUPER+Up/Down` (Doc Top/Bottom), `SUPER+Backspace` (Line backspace), `ALT+Backspace` (Word backspace), `ALT+Left/Right` (Word nav), `ALT+SHIFT+Left/Right` (Word select), `SUPER+C/V/X` (macOS Copy/Paste/Cut).
- Updated `references/keybindings.md` reference sheet with all new mappings.

## [1.2.0] - 2026-07-20
### Added
- Installed **Neovim** (v0.12.4 release) and **LazyGit** (v0.63.1 release) into `~/.local/bin`.
- Cloned and initialized **LazyVim** starter configuration in `~/.config/nvim`.
- Synchronized initial LazyVim plugins and Tree-sitter parsers via headless Neovim execution.

## [1.3.0] - 2026-07-20
### Fixed
- Fixed ZSH character duplication and line corruption (`ccd zigokucdcdd d zzziiggookku`) when SSHing to `jairo`.
- Transferred local `xterm-kitty` terminfo database to `jairo` via `infocmp -a xterm-kitty | ssh jairo "tic -x -"`.
- Added troubleshooting guide for missing terminal terminfo entries over SSH to `references/gotchas.md`.

## [1.4.0] - 2026-07-20
### Added
- Installed `brave-origin-bin` package for native Wayland standalone PWA/Web App support.
- Created Omarchy-compatible CLI scripts `~/.local/bin/cachy-webapp-install` and `cachy-webapp-remove` (with `omarchy-webapp-install` & `omarchy-webapp-remove` symlinks).
- Installed **YouTube** Web App launcher (`~/.local/share/applications/YouTube.desktop`) using Brave Origin engine in Wayland mode.
- Transferred YouTube PNG icon from `jairo` to `~/.local/share/applications/icons/YouTube.png`.
- Bound **YouTube Web App** to `SUPER + SHIFT + Y` in `~/.config/hypr/config/binds.lua` (and moved `yazi` to `SUPER + SHIFT + U`).
- Installed **PH Incognito** Web App launcher (`~/.local/share/applications/PH.desktop`) using Brave Origin engine in Wayland mode (`--incognito`).
- Transferred PH PNG icon from `jairo` to `~/.local/share/applications/icons/Phub.png`.

## [1.5.0] - 2026-07-20
### Added
- Added battery widget to Noctalia top bar in `~/.config/noctalia/config.toml`:
  - Added `"battery"` to `bar.default.end` widgets array.
  - Configured `[widget.battery]` with `display_mode = "graphic"` (animated fill level with percentage overlay).

## [1.6.0] - 2026-07-21
### Added
- Created custom fastfetch layout script `~/.local/bin/fastfetch-custom` featuring a compact layout, 2-column grid for bottom specs, logo padding pushed by 2 spaces for long CPU lines, top vertical separator removed next to logo, full ANSI color palette, bold cyan key styling, and the 16-color palette block line at the bottom.
- Updated `fish_greeting` in `~/.config/fish/config.fish` to launch `fastfetch-custom` on terminal startup, preventing text line-wrapping in split-screen tiled windows while preserving all 21 system specs.

## [1.7.0] - 2026-07-21
### Added
- Created **Hanime** Incognito Web App launcher (`~/.local/share/applications/Hanime.desktop`) using Brave Origin engine in Wayland mode (`--incognito` on `https://hanime.tv/`).
- Created **AllAnime** Web App launcher (`~/.local/share/applications/AllAnime.desktop`) using Brave Origin engine in Wayland mode (updated to `https://allmanga.to/anime`).
- Generated high-resolution custom dark-mode app icons for `Hanime.png` and `AllAnime.png` in `~/.local/share/applications/icons/`.

## [2.0.0] - 2026-07-27
### Added
- Created `~/.local/bin/anime-lid-charging` daemon script to automatically monitor ACPI charger status (`/sys/class/power_supply/AC0/online`) and lid state (`/proc/acpi/button/lid/*/state`).
- Designed a custom pixel-art battery charging animation with live battery capacity percentage (`BAT0/capacity`) and animated lightning bolt pulse.
- Configured user systemd service `~/.config/systemd/user/anime-lid-charging.service` (enabled and running) so whenever the laptop lid is closed while connected to AC power, the AniMe Matrix dynamically displays the live battery percentage and charging animation.

## [1.9.0] - 2026-07-24
### Added
- Installed `supergfxctl` (5.2.7), `asusctl` (6.3.10), and `rog-control-center` (6.3.10) for ASUS ROG Zephyrus G14 hardware & GPU power management.
- Enabled and started `supergfxd.service` and verified `asusd.service` is active.
- Configured `/etc/modprobe.d/nvidia-pm.conf` with `options nvidia NVreg_DynamicPowerManagement=0x02` for fine-grained D3cold dGPU sleep (0 Watts when idle).
- Enabled `nvidia-suspend.service`, `nvidia-hibernate.service`, and `nvidia-resume.service` systemd services.
- Verified GPU switching mode set to `Hybrid` mode (`supergfxctl -g`), allowing applications like Dota 2 to run on the NVIDIA dGPU via `prime-run` while keeping the card sleeping at 0W during general desktop use.

## [1.10.0] - 2026-07-25
### Changed
- Resolved keybinding conflict between macOS text editing shortcuts and Noctalia system panels in `~/.config/hypr/config/binds.lua`.
- Mapped `SUPER + C` (`CTRL, SHIFT, C`), `SUPER + V` (`CTRL, V`), `SUPER + X` (`CTRL, X`), `SUPER + Z` (`CTRL, Z`), and `SUPER + SHIFT + Z` (`CTRL, SHIFT, Z`) directly in `binds.lua` using native `hl.dsp.send_shortcut`. This eliminates external shell invocation latency and avoids modifier key collisions.
- Remapped Noctalia Control Center toggle to `SUPER + E` (`noctalia msg panel-toggle control-center`).
- Remapped Noctalia Settings toggle to `SUPER + ,` (`noctalia msg settings-toggle`).
- Updated keybindings reference sheet in `references/keybindings.md`.

