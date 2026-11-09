# Changelog

Every system change, config edit, package install, and fix. Most recent first.

## 2026-11-08

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 18:22 | Completed full system package upgrade & reboot | Upgraded Linux CachyOS kernel to `7.3.3-1` (LTS to `6.18.60-2`), Hyprland to `0.57.1-1.1`, Mesa and Vulkan Radeon to `26.2.6-1`, PipeWire to `1.6.10-1`, and Ghostty to `1.4.0-1.1`. Verified system reboot: Hyprland 0.57.1 loaded modular Lua cleanly with zero config errors, dual monitors restored exact fractional scales and positions, Quickshell and SwayOSD operational, and all user configs in `~/.config` intact. | System packages, `~/.agents/skills/system-personalization/references/current-state.md` |
| 10:28 | Migrated live desktop to Hyprland native `.lua` configuration | Symlinked `hyprland.lua`, `helpers.lua`, `config/*.lua`, and `config/profile/*.lua` selectively into `~/.config/hypr/` while leaving all existing `.conf` files untouched for instant zero-risk fallback. Verified config with `Hyprland --verify-config` and reloaded live session (`hyprctl reload`) with zero config errors. Preserved Quickshell, Mako, SwayOSD, dual-monitor scales, and custom workspace assignments. | `~/.config/hypr/hyprland.lua`, `~/.config/hypr/helpers.lua`, `~/.config/hypr/config/`, `~/.config/hypr/config/profile/` |

## 2026-11-07

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 19:05 | Bundled personalized Quickshell bar + Omarchy bridge suite into `profiles/desktop/` and wired `SHELL_BACKEND="quickshell"` (`v2.88.1`) | Preserved 100% of this machine's personalized Quickshell bar (`desktop/`, `bar/` Rise layout, `palette-only/`), Omarchy hooks, systemd timers, and `~/.local/bin/omarchy-*` bridge scripts inside `profiles/desktop/`, while keeping standardized keybindings in `core/binds.lua` across all profiles (`SHELL_BACKEND="quickshell"` on `desktop`, `"noctalia"` on `macbook-t2`/`surface`/`laptop`). | `~/dev/dotfiles/core/.config/hypr/*`, `~/dev/dotfiles/profiles/desktop/*` |
| 18:38 | Fast-forwarded `~/dev/dotfiles` (`JValdivia23/hyprland-dots`) to `v2.87.0` and populated `profiles/desktop/` (`v2.88.0`) | Added this desktop workstation (`cachyos-obsidian` / MSI `MS-7D75`, Ryzen 5 7600X + Radeon RX 7700 XT, dual KTC monitors DP-1 4K@1.67x + HDMI-A-1 1440p@1.33x, Logitech G903, Attack Shark X85, Realtek ALC4080) to the 3-tier `hyprland-dots` repo (`profiles/desktop/`) in preparation for migrating to Hyprland native `.lua` configs. | `~/dev/dotfiles/profiles/desktop/*`, `~/dev/dotfiles/AGENTS.md`, `~/dev/dotfiles/README.md`, `~/dev/dotfiles/agents/.agents/skills/system-personalization/references/changelog.md` |

## 2026-10-20

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 17:54 | Completed full system package update via paru | Successfully updated 661 system and AUR packages (628 official repo + 33 AUR). Upgraded Linux kernel to 7.2.10-1 (LTS to 6.18.55-2), Mesa & Vulkan-Radeon to 26.2.4-1, Systemd to 262.1-1, Hyprland to 0.56.2-4.1, Quickshell to 0.3.2-1.1, Qt6 stack to 6.12.0, PipeWire to 1.6.9, WirePlumber to 0.5.18, Google Chrome to 155.0, Firefox to 158.0.1, Zen Browser to 1.23.3b, Zed to 1.24.4, VS Code to 1.142.0, Ollama to 0.40.6, Walker to 2.17.2, Elephant suite to 2.22.1, and Telegram Desktop to 7.3.1. Google Antigravity CLI updated to v1.4.3. Reboot verified; actively running 7.2.10-1. | System packages, `~/.local/bin/agy`, `~/.agents/skills/system-personalization/SKILL.md`, `~/.agents/skills/system-personalization/references/current-state.md` |

## 2026-09-12

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 21:38 | Fixed offline status detection in Quickshell bar and panels for IPv6/dual-stack networks | The network monitoring scripts hardcoded IPv4-only route queries (`ip route get 1.1.1.1`), causing active connections on IPv6-routed networks to report as offline (`NONE`). Updated `NetworkWidget.qml`, `NetworkPanel.qml`, and `Navbar.qml` with dual-stack IPv4/IPv6 fallback routing checks and address queries. | `~/.config/quickshell/bar/modules/NetworkWidget.qml`, `~/.config/quickshell/bar/panels/NetworkPanel.qml`, `~/.config/quickshell/desktop/Navbar.qml`, `~/.agents/skills/system-personalization/references/gotchas.md` |

## 2026-09-04

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 21:45 | Completed full system package update via paru | Successfully updated 74 system and AUR packages. Upgraded Linux kernel to 7.2.3-1, Mesa & Vulkan-Radeon to 26.2.2-2, Aquamarine to 0.15.0, WirePlumber to 0.5.17, Google Chrome to 152.0.7977.82, Firefox to 155.0.1, Zed to 1.18.0, VS Code to 1.136.1, and Telegram Desktop to 7.2.5. Reboot verified; actively running 7.2.3-1. | System packages, `~/.agents/skills/system-personalization/SKILL.md`, `~/.agents/skills/system-personalization/references/current-state.md` |

## 2026-09-01

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 21:50 | Completed full system package update via paru | Successfully updated 225 packages (222 official repo packages + 3 AUR). Upgraded Linux kernel to 7.2.2-1 (and LTS to 6.18.48), WirePlumber to 0.5.16, Ollama to 0.33.2 (with ROCm), Google Chrome to 152.0, Zen Browser to 1.21.16b, Zed to 1.17.2, and VS Code to 1.135.0. System reboot pending for new kernel. | System packages, `~/.agents/skills/system-personalization/SKILL.md`, `~/.agents/skills/system-personalization/references/current-state.md` |

## 2026-08-23

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 20:42 | Completed full system package update via paru | Successfully updated 440+ system and AUR packages. Upgraded Linux kernel to 7.2.0-1, Mesa & Vulkan-Radeon to 26.2.1-1, Hyprland to 0.56.2-1, Qt6 stack to 6.11.2, Quickshell to 0.3.1-1.1, Google Chrome to 151.0, Zen Browser to 1.21.15b, and Telegram Desktop to 7.1.1. System reboot pending for new kernel. | System packages, `~/.agents/skills/system-personalization/references/current-state.md` |

## 2026-08-14

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 19:53 | Added `~/.local/bin/spf` wrapper on CUdesk for Kitty graphics protocol | Fixed Superfile (`spf`) falling back to ANSI rendering inside `herdr` multiplexer panes over SSH/Ghostty. Superfile requires `TERM_PROGRAM` or `TERM` to match a known terminal name. Wrapper injects `TERM_PROGRAM=ghostty` transparently without modifying `~/.zshrc`. | `CUdesk:~/.local/bin/spf`, `~/.agents/skills/system-personalization/references/gotchas.md` |

## 2026-08-11

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 19:25 | Added Left Alt/Left Win layout toggle hotkeys and script | Evaluated and implemented keybindings `SUPER+Shift+K` and `SUPER+Alt+K` (matching `cachy-asus`) to run `hypr-toggle-altwin` for toggling Left Alt/Left Win layout with desktop notifications. Also fixed the device-monitor app to avoid injecting the deprecated `grp:alt_shift_toggle` option. | `~/.local/bin/hypr-toggle-altwin`, `~/.config/hypr/bindings/utilities.conf`, `~/dev/device-monitor/src/device_monitor/app.py`, `~/.agents/skills/system-personalization/references/` |

## 2026-07-27

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 17:34 | Completed full system package update via paru | Successfully updated system packages, upgrading running kernel from 7.1.3 to 7.1.5, Mesa to 26.1.5, and Hyprland to 0.56.1. Reboot pending. | System packages |
| 17:19 | Initiated full system package update via paru | Syncing and updating packages (Kernel, Mesa, Hyprland, etc.) to address AMDGPU GTT leaks and other stability fixes. | System packages |
| 17:15 | Documented AMDGPU memory leak gotcha | Investigated system OOM crash after playing Dota 2. Identified driver GTT memory (`gpu_active`) remaining pinned at ~7.4 GB after game exit, depleting RAM/Swap and causing system freezes. | `~/.agents/skills/system-personalization/references/gotchas.md` |
| 11:57 | Swapped layout to Latin American Spanish (`latam`) and updated status labels | Changed layout to Latin American Spanish (`us,latam` layout in `input.conf`) and updated layout labels on status bars to display `LA` instead of `ES` with accurate tooltips. | `~/.config/hypr/input.conf`, `~/.config/quickshell/bar/modules/KeyboardWidget.qml`, `~/.config/quickshell/desktop/Navbar.qml`, `~/.config/quickshell/desktop/Bar.qml`, `~/.config/quickshell/desktop/BarHacker.qml` |
| 11:55 | Added keyboard layout/language status indicator to Quickshell status bars (both rise and desktop layouts) | User wanted to see the active language layout ("US" or "ES") on their status bar, change it dynamically by clicking the widget, and have the layout state reflect consistently when toggled via `SUPER+Shift+L`. | `~/.config/quickshell/bar/modules/KeyboardWidget.qml`, `~/.config/quickshell/bar/BarSlot.qml`, `~/.config/quickshell/desktop/Navbar.qml`, `~/.config/quickshell/desktop/Bar.qml`, `~/.config/quickshell/desktop/BarHacker.qml` |

## 2026-07-16

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 23:12 | Fixed broken Walker theme import paths & added visual selection feedback | Corrected the `@import` statements from pointing to `omarchy-default.css` (which is a directory) to `omarchy-default/style.css` (the actual stylesheet), resolved tildes (`~`) to absolute paths for GTK compatibility, and added selection/hover feedback (a soft accent background highlight and bold text) to fix invisible keyboard and mouse selection. Copied the `keybindings` and `dmenu_150` theme directories to `~/.config/walker/themes/` so Walker can locate them. Created a custom `omarchy-menu-keybindings` script override in `~/.local/bin/` to parse bindings via tabs (preventing comma splits), clean up raw dispatchers into self-explanatory actions, and improve column alignment/paddings. | `~/.config/walker/themes/dmenu_250/style.css`, `~/.config/walker/themes/keybindings/`, `~/.config/walker/themes/dmenu_150/`, `~/.local/share/omarchy/default/walker/themes/keybindings/style.css`, `~/.local/share/omarchy/default/walker/themes/dmenu_150/style.css`, `~/.local/share/omarchy/default/walker/themes/dmenu_250/style.css`, `~/.local/share/omarchy/default/walker/themes/omarchy-default/style.css`, `~/.local/bin/omarchy-menu-keybindings` |

## 2026-07-15

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 22:31 | Corrected PATH precedence in uwsm session environment | Prepend ~/.local/bin/ after the shared Omarchy bin directory is loaded in uwsm/env. This ensures custom user script overrides (like our edited omarchy-menu with Hibernate support) take priority in the graphical environment. | `~/.config/uwsm/env` |
| 00:39 | Added Hibernate option to SUPER+Escape system menu | Updated omarchy-menu script to include a " Hibernate" option that executes systemctl hibernate, enabling easy hibernation triggering from the graphical menu. | `~/.local/bin/omarchy-menu` |
| 00:37 | Installed plymouth package | Resolved the pre-existing mkinitcpio build error "Hook 'plymouth' cannot be found" that was triggering warnings during initramfs updates. | System packages |
| 00:35 | Configured and enabled hibernation support with 16GB Btrfs swapfile | Set up system hibernation on Btrfs by creating a `/swap` subvolume with CoW disabled, allocating a 16GB swapfile (`/swap/swapfile`), configuring `/etc/fstab`, appending `resume` and `resume_offset` to `/etc/sdboot-manage.conf`, and regenerating systemd-boot and initramfs. | `/etc/fstab`, `/etc/sdboot-manage.conf`, `/swap/swapfile` |

## 2026-07-13

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 22:10 | Configured Quickshell workspaces color for the second monitor to Tokyo Night green | Updated WorkspaceWidget.qml to use Tokyo Night's normal green (#9ece6a) for workspaces belonging to the second monitor, providing a beautiful Blue/Green contrast matching the system design. | `~/.config/quickshell/bar/modules/WorkspaceWidget.qml` |
| 22:05 | Updated Quickshell rice theme workspace colors fallback to use sealRaw | Changed the second monitor color fallback in WorkspaceWidget.qml to use root.sealRaw (Tokyo Night pink/red #f7768e) instead of root.indigo, providing a beautiful Blue/Pink contrast when "Use Theme Accent" is on. | `~/.config/quickshell/bar/modules/WorkspaceWidget.qml` |
| 21:56 | Color-coded workspaces belonging to the second monitor in Quickshell rice theme | Modified WorkspaceWidget.qml to dynamically check if a workspace is on HDMI-A-1 (monitor ID 1). Uses the theme's secondary accent color (accentHint/indigo) instead of primary accent (seal). | `~/.config/quickshell/bar/modules/WorkspaceWidget.qml` |
| 21:43 | Configured Dota 2 to launch on 24" monitor (HDMI-A-1) in true fullscreen | Bound workspace 8 to HDMI-A-1 in monitors.conf. Modified dota2-workspace script to toggle true fullscreen (fullscreen 0) instead of maximized (fullscreen 1) when launching the game. | `~/.config/hypr/monitors.conf`, `~/.local/bin/dota2-workspace` |
| 21:22 | Migrated keyboard layout toggle to conflict-free SUPER+Shift+L keybinding | Removed XKB `grp:alt_shift_toggle` from `input.conf` to stop accidental layout switching (caused by modifier release overlaps in other shortcuts). Added custom Hyprland shortcut `SUPER+Shift+L` to `utilities.conf` for a clean layout switch across US/ES layouts. | `~/.config/hypr/input.conf`, `~/.config/hypr/bindings/utilities.conf`, `~/.agents/skills/system-personalization/references/keybindings.md` |
| 12:36 | Configured dual monitor setup and added multi-monitor toggle keybindings | Connected new KTC Q24T09 1440p monitor on the left at 1.33x scale and 120Hz. Added Option B (Grave key) shortcut bindings to toggle focus, move active windows, and move workspaces between monitors. | `~/.config/hypr/bindings/tiling.conf`, `~/.config/hypr/monitors.conf`, `~/.agents/skills/system-personalization/references/keybindings.md`, `~/.agents/skills/system-personalization/references/hardware.md`, `~/.agents/skills/system-personalization/references/current-state.md` |

## 2026-07-11

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 16:16 | Configured auto-recovery for audio-related Steam segfaults | Steam's 32-bit `libaudio.so` can crash under PipeWire/PulseAudio socket state inconsistencies. Updated Steam launcher wrapper script to intercept segmentation faults (exit 139), restart core user audio services (`pipewire`, `pipewire-pulse`, `wireplumber`), and perform a single automatic launch retry. Added logic to preserve, restart, and re-apply EasyEffects default source settings on PipeWire restart to protect microphone volume/processing. | `~/.local/bin/steam`, `~/.agents/skills/system-personalization/references/gotchas.md` |

## 2026-07-09

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 22:58 | Added `com.mitchellh.ghostty` to `mac-key-helper` terminal class list | Ghostty's real Wayland app-id is `com.mitchellh.ghostty` (not `ghostty`), so `is_terminal` was `0` and macOS-sim keys (`SUPER+Backspace`, `ALT+Backspace`, word/doc nav) hit the GUI fallback (delete one char) in Ghostty. Now all those keys work identically to Alacritty. | `~/.local/bin/mac-key-helper`, `~/.agents/skills/system-personalization/references/gotchas.md` |
| 23:25 | Fixed OSC 52 clipboard on remote `casper` (Ghostty + tmux) | Remote `casper` had no `~/.tmux.conf`, no `Ms` capability in Ghostty's terminfo, and no vim/nvim OSC 52 provider — so copies from inside tmux (vim yank, OpenCode, tmux copy-mode) never reached the local clipboard under Ghostty. Created `~/.tmux.conf` (set-clipboard on + terminal-overrides `Ms` for ghostty/xterm-256color), `~/.vimrc` (`clipboard^=osc52`), and `~/.config/nvim/init.lua` (osc52 provider). Applies to new tmux sessions; live HPC sessions need `tmux source ~/.tmux.conf` + re-attach. | `casper:~/.tmux.conf`, `casper:~/.vimrc`, `casper:~/.config/nvim/init.lua`, `~/.agents/skills/system-personalization/references/gotchas.md` |
| 23:42 | Added OSC 52 clipboard shims on `casper` for superfile (`spf`) | superfile v1.6.0 copies paths via `golang.design/x/clipboard`, which needs `xsel`/`xclip`/`wl-clipboard` and silently fails on headless casper (no DISPLAY, none installed) — so `ctrl+p` copy-path never reached the local clipboard. Created OSC 52 shims (`xclip`/`wl-copy`/`xsel` emitting `\E]52;c;<b64>\007`) in `~/bin` + `~/.bashrc` PATH edit first, but herdr panes don't source `~/.bashrc` so spf still logged "No clipboard utilities". Copied the shims to `~/.local/bin` (already on the pane PATH, where `spf` lives) — this is the working fix; restart spf to pick them up. herdr's OSC 52 forwarder then delivers the path to the local Ghostty clipboard (chain validated with a manual OSC 52 test). | `casper:~/.local/bin/xclip`, `casper:~/.local/bin/wl-copy`, `casper:~/.local/bin/xsel`, `casper:~/bin/xclip`, `casper:~/.bashrc`, `~/.agents/skills/system-personalization/references/gotchas.md` |

## 2026-07-06

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 21:34 | Installed `easyeffects` + `lsp-plugins`, added to autostart | Resolve low headphone microphone volume on ALC4080 USB audio motherboard chip via software amplification. | System packages, `~/.config/hypr/autostart.conf` |
| 20:09 | Installed `lib32-libpulse` package | Resolve Steam client segmentation fault on startup. When missing on the host, Steam falls back to its legacy bundled 32-bit PulseAudio library, which crashes on the new DisplayPort audio layout due to PipeWire-Pulse inconsistent profile warnings. | System packages |

## 2026-07-05

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 19:42 | Added `amdgpu.dcdebugmask=0x10 amdgpu.sg_display=0` kernel boot params | Fix DisplayPort screen blanking (1-2s black screen) after switching from HDMI to DP. Disables DC link power optimization and scatter-gather display — common RDNA 3 DP fix on CachyOS/Arch. | `/etc/sdboot-manage.conf` |
| 19:36 | Switched display connection from HDMI-A-1 to DP-3 | Physical cable change. Monitor now connected via DisplayPort instead of HDMI. Kernel 7.1.1-2-cachyos (upgraded from 7.0.12-1). | Hardware change |

## 2026-07-04

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 15:05 | Configured keybindings for Ghostty and Zen Browser | Mapped Super+Shift+Return to Ghostty, set Zen Browser as default $browser, and bound Super+Shift+B to launch it. | `~/.config/hypr/bindings.conf`, `~/.agents/skills/system-personalization/references/keybindings.md` |
| 14:33 | Installed Ghostty | To provide a terminal emulator with native Kitty graphics protocol support while keeping Alacritty's minimalist GPU-accelerated feel. | System packages |

## 2026-07-03

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 23:41 | Fixed Logitech G903 Lightspeed scroll wheel in wireless mode | Corrected the invalid `AttrScrollWheelHiRes=0` quirk syntax to `AttrEventCode=-REL_WHEEL_HI_RES;-REL_HWHEEL_HI_RES;` in `/etc/libinput/local-overrides.quirks` and reloaded udev. | `~/.config/libinput/local-overrides.quirks`, `/etc/libinput/local-overrides.quirks`, `~/.agents/skills/system-personalization/references/gotchas.md` |

## 2026-07-02

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 19:22 | Restored Picture-in-Picture window rules using safe regex | Fixed commented-out rule in `pip.conf` due to Hyprland 0.55 regex parser syntax issue, replacing it with direct `windowrule` rules using modern unified match:title syntax with a comma. | `~/.config/hypr/apps/pip.conf` |

## 2026-06-29

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 22:52 | Fixed mouse cursor hiding/unhiding in OmniMenu | Initialize hideMouseCursor to true on menu open, track mouse coordinates in the blank cursor MouseArea with a 5px threshold to ignore synthetic events and subpixel adjustments, and reset coordinate anchors on visibleChanged to ensure the mouse hides reliably every time the user types. | `~/.config/quickshell/desktop/OmniMenu.qml` |

## 2026-06-26

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 21:23 | Blocked F9 dictation and forwarded F9 keypress to Dota 2 | Avoid global push-to-talk voice recording popping up when user attempts to pause/unpause inside Dota 2, instead sending key event directly via Hyprland's `sendshortcut` dispatcher. | `~/.local/bin/hypr-dictate`, `~/.agents/skills/system-personalization/references/gotchas.md` |
| 15:41 | Configured dynamic macOS keybindings simulation | Map word-level/document-level navigation and line deletion to work globally without browser conflicts, and dynamically toggle fine window resizing on floating windows vs text selection on tiled windows. | `~/.local/bin/mac-key-helper` (new), `~/.config/hypr/bindings.conf`, `~/.config/hypr/bindings/tiling.conf`, `~/.agents/skills/system-personalization/references/keybindings.md` |
| 11:49 | Upgraded 276 system and AUR packages using paru | Regular system maintenance. Key upgrades include Linux kernel (7.1.1-2), Hyprland (0.55.4), systemd, Mesa, VS Code, Zed, and Ollama. | System packages |

## 2026-06-23

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 22:56 | Installed Upscayl desktop GUI and NCNN CLI | Set up AI image upscaling application system-wide with both desktop interface and terminal capability. | `chaotic-aur/upscayl-desktop-git`, `chaotic-aur/upscayl-ncnn` |
| 22:18 | Restored Background Picker category navigation | Defined `backgroundCategory` constant in `desktop/Data.js`, replaced the leaf "Background" command under Style with a category navigator, and added "Backgrounds" to the root `categoryNav` categories list. This ensures selecting backgrounds inside OmniMenu goes to the wallpapers preview view instead of immediately running `omarchy-menu background`. | `~/.config/quickshell/desktop/Data.js` |
| 22:37 | Implemented GSettings background sync daemon | Enabled Nautilus's built-in "Set as background..." option to work under Hyprland by creating a monitor daemon script that listens to GSettings changes and triggers the Omarchy wallpaper apply command. | `~/.local/bin/omarchy-gsettings-bg-sync` (new), `~/.config/hypr/autostart.conf` |
| 22:41 | Implemented custom XDG Wallpaper Portal backend | Enabled Nautilus's "Set as background..." portal request by writing a python DBus service that implements the `org.freedesktop.impl.portal.Wallpaper` backend interface, routing wallpaper updates directly to `omarchy-theme-bg-set` under Hyprland. | `~/.local/bin/omarchy-portal-backend` (new), `~/.local/share/xdg-desktop-portal/portals/omarchy.portal` (new), `~/.config/xdg-desktop-portal/hyprland-portals.conf` (new), `~/.config/hypr/autostart.conf` |

## 2026-06-22

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 21:54 | Installed Quickshell Rise bar layout Option A | Configured Quickshell Rise (`quickshell-dots`) as an isolated, optional layout switching process. Copied QML/JS/shaders source files into `~/.config/quickshell/bar/`. Patched `~/.config/quickshell/desktop/Theme.qml` to manage starting/stopping the daemon process dynamically. Installed required icon fonts, set up systemd timers/services for updates & AUR blacklist checks, wrote wrapper launcher bridge scripts under `~/.local/bin/`, and added Rise Bar option to the local `omarchy-menu` override dispatcher. | `~/.config/quickshell/bar/` (new files), `~/.config/quickshell/desktop/Theme.qml`, `~/.local/bin/omarchy-menu`, `~/.local/bin/omarchy-theme-bg-set` (new), `~/.local/bin/omarchy-launch-audio` (new), `~/.local/bin/omarchy-launch-wifi` (new), `~/.local/bin/omarchy-launch-bluetooth` (new), `~/.local/bin/omarchy-launch-or-focus-tui` (new), `~/.config/omarchy/hooks/theme-set.d/50-quickshell-bar.sh` (new) |
| 20:50 | Persisted custom Waybar V3.1c theme changes | Saved active custom adjustments (language switcher module, font padding, MPRIS layout) to the source template folder so that personalizations survive layout and theme switches. | `~/.local/share/omarchy/waybar-themes/config/V3.1c/` |

## 2026-06-21

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 20:25 | Fixed Logitech G903 Lightspeed scroll wheel in XWayland games (Dota 2) | Added `emulate_discrete_scroll = 2` to the global `input` block in `~/.config/hypr/input.conf`. Discovered that libinput does not load user quirks, so copied the quirks file to `/etc/libinput/local-overrides.quirks` and reloaded devices via `udevadm trigger`. | `~/.config/hypr/input.conf`, `/etc/libinput/local-overrides.quirks` |

## 2026-06-16

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 12:05 | Simplified copy-path label and enabled Super+V clipboard paste in Alacritty | Changed right-click option to 'Copy full path' / 'Copy full paths' for cleanliness. Added Shift+Insert to Paste mapping in alacritty.toml to make global Super+V work for pasting copied paths in the terminal | `~/.local/share/nautilus-python/extensions/copy_path.py`, `~/.config/alacritty/alacritty.toml` |
| 11:58 | Promoted non-interactive sudo gotcha to Core Rules | Make the interactive sudo terminal dispatch workaround highly visible to all future agents | `SKILL.md`, `references/gotchas.md` |
| 11:57 | Installed nautilus-python and configured custom copy-path extension | Adds a "Path: <absolute_path>" right-click context menu item in Nautilus file explorer to see and copy the full path of selected items to clipboard | `~/.local/share/nautilus-python/extensions/copy_path.py` |
| 11:50 | Installed and configured Obscure SDDM Theme | Personalization; minimal, glassmorphic login screen matching the user's tactical aesthetic preference | `/etc/sddm.conf.d/theme.conf` |

## 2026-06-15

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 22:04 | Installed editxr v1.2.0 | Terminal-based WYSIWYG Markdown editor/viewer. Installed locally to `~/.local/bin/editxr` bypassing the buggy upstream install script which failed under bash `pipefail`. | `~/.local/bin/editxr` |
| 18:47 | Configured macOS-like text editing hotkeys in Alacritty | Mapped `Home` to `Ctrl+A` (`\u0001`), `End` to `Ctrl+E` (`\u0005`), and `SUPER+Backspace` to `Ctrl+U` (`\u0015`) in `alacritty.toml` to support standard macOS text editing key combinations in shells and TUIs. | `~/.config/alacritty/alacritty.toml` |
| 16:53 | Enabled copy-on-select in Alacritty | Set `save_to_clipboard = true` in Alacritty configuration so that dragging the mouse to select text automatically copies it to the system clipboard. This matches macOS/Ghostty selection copy behavior. | `~/.config/alacritty/alacritty.toml` |
| 16:30 | Configured tmux OSC 52 target overrides on CUdesk | Added terminal overrides to `~/.tmux.conf` on `CUdesk` to force all application-initiated OSC 52 sequences (like OpenCode's selection copies) to target the standard clipboard (`c`) instead of the primary selection (`s`). This enables seamless global pasting via `SUPER+V` on Linux. | `~/.tmux.conf` (remote on `CUdesk`) |
| 15:56 | Enabled OSC 52 clipboard support in Alacritty | Explicitly set `osc52 = "CopyPaste"` in Alacritty configuration to allow remote TUI applications (like OpenCode inside tmux over SSH) to successfully copy to the local system clipboard on Wayland. | `~/.config/alacritty/alacritty.toml` |
| 15:37 | Updated window-pop script to preserve pre-existing floating windows | Modified `omarchy-hyprland-window-pop` to check if a window is already floating. Toggling pinning on an already floating window now directly pins/unpins it without resizing, centering, or tiling. | `~/.local/bin/omarchy-hyprland-window-pop` |
| 15:31 | Documented upstream Omarchy repo & window pinning behavior | Added link to basecamp/omarchy repository to SKILL.md. Added gotcha detailing the omarchy-hyprland-window-pop script (bound to SUPER+O) to clarify how window pinning is implemented and avoid config search pitfalls. | `SKILL.md`, `references/gotchas.md` |
| 12:49 | Configured Waybar MPRIS music module layout | Enable displaying both song title and artist using a dynamic layout and truncation settings. | `~/.config/waybar/config.jsonc` |
| 12:38 | Fixed weather module and populated real data by touching location config | Resolved issue where Quickshell didn't fetch initial weather data because `~/.config/omarchy/weather/location` didn't exist. Created the empty file to trigger Quickshell's file loader immediately, and restarted Quickshell + Waybar persistently. | `~/.config/omarchy/weather/location` (new empty file) |
| 12:37 | Added an extra space separation to Volume and Weather modules | Make the Volume and Weather modules stand out with three-space separations for better visual balance per user request. | `~/.config/waybar/config.jsonc`, `~/.config/quickshell/desktop/Navbar.qml`, `~/.local/bin/wttrbar` |
| 12:31 | Increased spacing between icons and text in Waybar modules | Improve readability of hybrid Waybar modules (CPU, Memory, Backlight, Battery, Bluetooth, MPRIS, and Pacman updates) by adding consistent two-space separators. | `~/.config/waybar/config.jsonc` |
| 12:27 | Migrated Waybar layout indicator to native `hyprland/language` module & fixed duplicate Alt+Shift binds | Fix the issue where keyboard layout language (logo) wouldn't update when changed via Alt+Shift hotkey. Created a patch script and integrated it into the theme installer to preserve the module and styling across theme changes. Commented out the duplicate custom layout switch binding in `utilities.conf` that was causing layout switching to trigger twice and cancel itself out. | `~/.config/waybar/config.jsonc`, `~/.config/waybar/style.css`, `~/.local/bin/omarchy-waybar-patch-layout` (new), `~/.local/bin/omarchy-waybar-theme-set`, `~/.config/hypr/bindings/utilities.conf` |
| 12:20 | Added explanation rule to system-personalization skill | Require agents to explain the situation and proposed solution before making system changes or installations to ensure user alignment. | `SKILL.md` |
| 12:03 | Configured Omarchy logo as user avatar on login screen | Converted `/home/jairo/.local/share/omarchy/logo.svg` to PNG and copied it to `~/.face.icon` and `/usr/share/sddm/faces/jairo.face.icon`. This places the Omarchy logo above the username/password fields on the SDDM login screen. | `~/.face.icon`, `/usr/share/sddm/faces/jairo.face.icon` |
| 12:02 | Switched from seamless auto-login to standard SDDM login screen | Installed `sddm` and enabled it, while disabling `omarchy-seamless-login.service`. This ensures the user is prompted for a password at boot, allowing PAM to automatically decrypt and unlock GNOME Keyring. This resolves issues where Google Chrome prompted for a password on boot and the Antigravity CLI kept asking to log in every reboot. | System configuration (pacman, systemctl) |

## 2026-06-13

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 23:27 | Integrated Keyboard Layout module into Waybar | Included the custom/layout module in config.jsonc and added it to modules-right. Updated style.css to apply layout styles matching the current theme. | `~/.config/waybar/config.jsonc`, `~/.config/waybar/style.css` |
| 22:29 | Implemented Waybar Theme Switcher & Installer | Cloned HANCORE waybar-themes repo, created WaybarThemes.qml for desktop and palette-only configurations, wrote omarchy-waybar-theme-set script, and integrated category nav/install/update actions. | `~/.config/quickshell/desktop/WaybarThemes.qml`, `~/.config/quickshell/palette-only/WaybarThemes.qml`, `~/.config/quickshell/desktop/Data.js`, `~/.config/quickshell/palette-only/Data.js`, `~/.config/quickshell/desktop/OmniMenu.qml`, `~/.config/quickshell/palette-only/OmniMenu.qml`, `~/.config/quickshell/desktop/omni/PreviewPane.qml`, `~/.config/quickshell/palette-only/omni/PreviewPane.qml`, `~/.local/bin/omarchy-waybar-theme-set` |
| 23:20 | Integrated Quickshell weather cache into Waybar | Added getJson IPC method to Navbar.qml and created wttrbar script in ~/.local/bin/ to feed Quickshell's cached weather data directly to Waybar. | `~/.config/quickshell/desktop/Navbar.qml`, `~/.local/bin/wttrbar` |
| 21:55 | Linked absolute path of Waybar wrapper in hypridle.conf | Resolve PATH precedence issue where background hypridle daemon bypassed the user wrapper and executed the core script directly. | `~/.config/hypr/hypridle.conf` |
| 20:50 | Upgraded lock screen layout to tactical terminal design | Implement blurred screenshot background, digital clock/date labels, console auth greeting prompt, and default theme variable fallbacks. | `~/.config/hypr/hyprlock.conf` |
| 16:29 | Implemented Alt Key Layout toggle in Device Monitor app | Provide a simple web button to switch Left Alt/Win keys between Swapped (Mac) and Standard (Windows) layouts for playing video games | `~/dev/device-monitor/src/device_monitor/app.py`, `~/dev/device-monitor/src/device_monitor/static/style.css` |
| 16:00 | Overrode omarchy-restart-waybar with state-aware wrapper | Prevent Waybar from starting on wakeup or theme swaps if Quickshell bar (Hacker/Kanji) is selected. | `~/.local/bin/omarchy-restart-waybar` |
| 14:59 | Fixed spotify-launcher DNS resolution error on boot | Prevent spotify-launcher from crashing when started offline or during boot before DNS/network is ready, falling back to --skip-update. | `~/.local/bin/spotify`, `~/.local/bin/spotify-launcher` |

## 2026-06-12

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 13:58 | Implemented mouse cursor auto-hide in OmniMenu | Auto-hide mouse pointer when typing in OmniMenu and restore it on mouse movement without blocking clicks | `~/.config/quickshell/desktop/OmniMenu.qml` |
| 13:28 | Integrated original dense Hacker Bar layout | Bring upstream BarHacker.qml and HackerStat.qml into local configuration, map layout switching (Kanji, Hacker, Waybar, Hidden), and handle state persistence | `~/.config/quickshell/desktop/Bar.qml`, `~/.config/quickshell/desktop/BarHacker.qml`, `~/.config/quickshell/desktop/Navbar.qml`, `~/.config/quickshell/desktop/Theme.qml`, `~/.config/quickshell/desktop/Data.js`, `~/.local/share/omarchy/bin/omarchy-menu` |
| 13:53 | Created Radar web app using Brave Origin | Create borderless app launcher for personal radar page using the page's original high-res touch icon | `~/.local/share/applications/Radar.desktop` |
| 13:48 | Added SUPER+Shift+Y keybinding | Bind YouTube web app to hotkey for quick launching | `~/.config/hypr/bindings.conf` |
| 13:38 | Created custom webapp scripts with Brave/Chrome support | Fix browser launch mismatch due to missing chromium in CachyOS fork, supporting brave-origin and brave | `~/.local/bin/omarchy-webapp-install`, `~/.local/bin/omarchy-webapp-remove` |
| 12:58 | Swapped Left Alt and Left Win in software | Keep keyboard in Windows mode (F-keys default for voice keys) but retain Mac-style modifier layout (Ctrl, Alt, Super) | `~/.config/hypr/input.conf` |
| 12:07 | Installed Aether theme manager | Enable dynamic wallpaper-driven palette generation and blueprint picker inside quickshell | `paru -S aether` |
| 11:52 | Beautified background and theme titles | Strip extension from background filenames, replace hyphens and underscores with spaces, and capitalize theme words for presentation | `~/.config/quickshell/palette-only/Backgrounds.qml`, `~/.config/quickshell/palette-only/Themes.qml` |

## 2026-06-27

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 11:32 | Patched GPU detection in Quickshell CpuPanel | Dynamically select dedicated AMD GPU (card1 RX 7700 XT) instead of hardcoded idle iGPU (card0), enabling real-time GPU utilization, temperature, and VRAM monitoring. | `~/.config/quickshell/bar/panels/CpuPanel.qml` |
| 11:08 | Fixed `mac-key-helper` modifier bleed | Prevent `SUPER+Backspace` from switching to workspace 1 and fix terminal line deletion | `~/.local/bin/mac-key-helper` |

## 2026-06-11

| Time | What | Why | Files Touched |
|------|------|-----|---------------|
| 20:40 | Implemented Background Picker | Converted Style > Background menu item to a drill-down category, added Backgrounds.qml scanner, and implemented dynamic wallpaper previewing and execution | `~/.config/quickshell/palette-only/Backgrounds.qml` (new), `Data.js`, `OmniMenu.qml`, `PreviewPane.qml` |
| 20:33 | Fixed theme switcher background previews | Remove double slashes from paths generated by Themes.qml that cause Qt Image loading to fail | `~/.config/quickshell/desktop/Themes.qml` |
| 20:30 | Integrated Quickshell palette-only mode with CachyOS+Omarchy | Fix broken popups, IPC handlers, .lua configs, and missing launcher commands | `~/.config/quickshell/palette-only/shell.qml`, `Navbar.qml`, `Bar.qml`, `CalendarPopup.qml`, `DisplayPopup.qml`, `WeatherPopup.qml`, `Data.js` |
| 20:01 | Installed Zed editor | Code editor | `paru -S zed` |
| 19:00 | Created system-personalization skill | Baseline documentation, self-improving tracker | `~/.agents/skills/system-personalization/` (new) |
| 19:50 | Expanded tags in SKILL.md | Better agent matching: Omarchy, Install, Waybar, Quickshell, Omni | `SKILL.md` tags updated |
| 18:29 | Created `omarchy-hyprland-window-pop` script | Pop window out (SUPER+O float+pin) | `~/.local/bin/omarchy-hyprland-window-pop` (new), `bindings/tiling.conf` |
| 17:51 | Installed Google Antigravity CLI v1.0.7 | Development tool | `~/.local/bin/agy` (new), shell profile PATH entries |
| 17:37 | Installed Google Chrome 149 from AUR source | Browser; chaotic-aur binary cache was 404 | `paru -S --aur google-chrome`, sudo pacman -U |
| ~17:30 | Created Refresh Quickshell .desktop entry | Convenience launcher in palette | `~/.local/share/applications/refresh-quickshell.desktop` (new) |

## Pre-2026-06-11 (from memory/skills)

Key earlier milestones (approximate dates from config timestamps):

| When | What | Notes |
|------|------|-------|
| Jun 4 | Waybar battery fix (HID++ race) | Replaced native module with crash-proof script |
| Jun 3 | Dota 2 window rules broken in 0.55.2 | Polling script workaround, gamescope fullscreen pattern |
| Jun 2 | Hermes voice pipeline built | TTS, voice-to-voice pipeline in ~/dev/hermes-voice-pipeline/ |
| Jun 1 | whisper.cpp dictation setup | Replaced voxtype with local whisper.cpp |
| May 31 | Migrated to Quickshell palette-only | Replaced Walker+Waybar with Quickshell |
| May 30 | OCR tool set up | hypr-ocr with tesseract+grim+slurp |
| May 29 | Session persistence enabled | hyprresume installed |
| May 28 | Initial Omarchy setup | lentra0/omarchy-cachyos fork installed |
