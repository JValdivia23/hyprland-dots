---
name: system-personalization
description: "Comprehensive system personalization tracker — OS, hardware, modular configs, keybindings, gotchas, and changelog. Self-improving: update after every change."
version: 2.57.0
tags: [system, personalization, dotfiles, desktop, hyprland, lua, cachyos, noctalia, fish, keybindings, gotchas]
---

# System Personalization

Complete documentation of this machine's configuration and personalization. This is a **self-improving skill** — after any system configuration change, software install, or gotcha discovery, update this skill's modular references (`references/changelog.md` and `references/gotchas/`).

---

## Core Rules

1. **NEVER overwrite config files.** Use targeted edits (`patch`, append) to modify what's needed. Overwriting deletes previous settings from themes, packages, or other tools.
2. **Respect the modular Lua configuration.** Hyprland on this machine is configured in Lua. Core universal configs reside in `~/.config/hypr/config/`, while hardware profile overrides reside in `~/.config/hypr/config/profile/`. Never append traditional Hyprland `.conf` syntax.
3. **Noctalia panel integration.** The Wayland shell is Noctalia. If modifying `~/.config/noctalia/config.toml` or after restarting audio services, restart or reload via `noctalia msg reload` or `killall -TERM noctalia; sleep 0.5; hyprctl eval 'hl.exec_cmd("noctalia -d")'`.
4. **Fish Shell environment.** The system shell is `fish`. Do not write `bash`/`zsh` syntax to shell scripts without a proper shebang. Keep aliases and commands fish-compatible.
5. **Self-improving.** After every config change, software install, bug fix, or gotcha discovery, update this skill — specifically `references/changelog.md` and `references/gotchas/` if relevant.
6. **Explain -> Ask -> Act.** Always explain the situation and ask if the user agrees with the solution before making changes to the system or installing anything.
7. **Hyprland Error Diagnostics.** When the user reports a desktop error, red banner, or system error after modifying Hyprland configs, `journalctl` does NOT log config validation errors. Run `hyprctl configerrors` AND inspect `/run/user/$UID/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log` for `[Config::Lua::Bindings::Internal::reportError]` (Hyprland `0.57.0+` removes `.conf` parsing and reports Lua config errors via notifications + `hyprland.log`).
8. **Elevated Password & Interactive Prompts (`hyprctl` / `kitty -e`).** When a system command requires user password authentication (such as `sudo pacman` package installations), background agent subshells must export `HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/$UID/hypr/ 2>/dev/null | head -n1)` and launch an interactive terminal window via Hyprland's IPC executor: `hyprctl eval 'hl.dispatch(hl.dsp.exec_cmd("kitty --title <Title> -e bash -c \"sudo <command>; echo Done!; read\""))'`. This ensures the terminal maps directly onto the active Wayland workspace so the user can securely enter their password directly.
9. **Device-Specific vs. Universal Scope Identification.** Whenever installing a new feature, package, script, keybinding, or configuration setting, explicitly identify whether it is a **device-specific setting** (hardware-dependent: touchscreen/stylus, GPU power switching, battery/sleep hooks, machine-specific backlight keys, audio DSP) or a **general user setting** (universal desktop apps, shell aliases, core keybindings, global themes). Place device-specific items into `profiles/<profile>/` and general user items into `core/`. **If it is unclear whether a feature is hardware-dependent or universal, the agent MUST explicitly ask the user for clarification before applying or placing the configuration.**

---

## Triggers

- Making any system configuration change
- Installing or removing packages that affect the desktop environment
- Adding or removing keyboard shortcuts
- Changing hardware or monitor settings
- Discovering a new system pitfall or gotcha
- Troubleshooting desktop, compositor, or audio issues

---

## Quick Reference

| Category | Surface Book 3 (`surface`) | MacBook Pro 15,1 (`cachyos-cu`) | Desktop Workstation (`cachyos-obsidian`) |
| :--- | :--- | :--- | :--- |
| **Machine** | Surface Book 3 | MacBookPro15,1 | MSI MS-7D75 (PRO B650M-A WIFI) |
| **Hostname** | `surface` | `cachyos-cu` | `cachyos-obsidian` |
| **OS** | CachyOS | CachyOS | CachyOS |
| **Kernel** | `7.3.1-1-cachyos` (+DKMS ipts/ipu4p/usbc) | `7.2.9-1-cachyos` | `7.3.3-1-cachyos` (LTS `6.18.60-2`) |
| **WM** | Hyprland (Lua modular API) | Hyprland (Lua modular API) | Hyprland (Lua modular API) |
| **Wayland Shell** | Noctalia | Noctalia | Noctalia |
| **Displays** | eDP-1 (3000x2000@60Hz, scale 2) | eDP-1 (2880x1800@60Hz, scale 1.6) | DP-1 (4K@60Hz, 1.67x) + HDMI-A-1 (1440p@120Hz, 1.33x) |
| **GPU** | Intel Iris Plus Graphics G7 | Intel UHD 630 / AMD Radeon Pro 560X | AMD Radeon RX 7700 XT (RADV) |
| **CPU** | Intel Core i5-1035G7 @ 1.20GHz | Intel Core i9-9880H @ 2.30GHz | AMD Ryzen 5 7600X (6c/12t) |
| **RAM & Swap** | 7.4Gi RAM, 16Gi swap | 15Gi RAM, 15Gi swap | 31Gi RAM, 33Gi swap |
| **Active Profiles** | surface | macbook-t2 | desktop |
| **Shell** | `/bin/fish` | `/bin/fish` | `/bin/fish` |
| **Terminal** | `kitty` (primary) | `kitty` (primary) | `alacritty` (primary), `ghostty` |
| **Package Manager**| `pacman` | `pacman` | `pacman` / `paru` |

---

## Modular Reference Files

| File / Folder | Content |
|---------------|---------|
| [`references/hardware.md`](references/hardware.md) | Physical hardware specs, CPU, GPU, displays, and audio |
| [`references/current-state.md`](references/current-state.md) | Live snapshot (OS, kernel, active package versions, active helper scripts) |
| [`references/config-paths.md`](references/config-paths.md) | Config files, Lua modules, touchpad gesture specs, and edit rules |
| [`references/keybindings.md`](references/keybindings.md) | Complete keyboard shortcuts reference from `binds.lua` |
| [`references/gotchas/`](references/gotchas/) | **Topic-specific gotchas & troubleshooting**: |
| ├── [`hyprland.md`](references/gotchas/hyprland.md) | Hyprland Lua syntax, IPC window dispatchers, modifier repetition, copy shortcut |
| ├── [`wayland-noctalia.md`](references/gotchas/wayland-noctalia.md) | Noctalia messaging reload/restart, Satty screenshot piping, Quick Look |
| ├── [`networking.md`](references/gotchas/networking.md) | LocalSend UFW firewall port rules (53317 TCP/UDP) |
| ├── [`flea-file-explorer.md`](references/gotchas/flea-file-explorer.md) | Flea file explorer on CachyOS, Noctalia wallpaper palette syncing, and portal picker |
| ├── [`terminal-ssh.md`](references/gotchas/terminal-ssh.md) | Kitty SSH terminfo export, `kitty -e` interactive password prompts |
| ├── [`zen-browser.md`](references/gotchas/zen-browser.md) | Zen Browser keybindings, Linux modifier mappings & in-memory overwrite gotchas |
| ├── [`opencode.md`](references/gotchas/opencode.md) | OpenCode TUI line navigation, TLS clock-drift recovery, packages keep-out |
| ├── [`battery-upower.md`](references/gotchas/battery-upower.md) | Surface dual-battery calculation desync (~200%) & UPower service recovery |
| ├── [`sleep-hibernate.md`](references/gotchas/sleep-hibernate.md) | Surface Modern Standby hibernation failure, ACPI S4 rejection & `HibernateMode=shutdown` |
| ├── [`touchscreen-iptsd.md`](references/gotchas/touchscreen-iptsd.md) | Surface touchscreen & stylus wake race condition (`iptsd` EAGAIN -11) & udev recovery |
| ├── [`kernel-cachyos-ipts.md`](references/gotchas/kernel-cachyos-ipts.md) | Surface touch/pen (IPTS) DKMS & mei_me runtime binding on Linux CachyOS 7.x |
| ├── [`touchscreen-hyprgrass.md`](references/gotchas/touchscreen-hyprgrass.md) | Hyprgrass touch plugin & spacebar keybind collision in Hyprland 0.56+ |
| ├── [`screen-rotation.md`](references/gotchas/screen-rotation.md) | Surface Book 3 physical-detachment-only rotation, read-only DTX status, touch/pen/gesture alignment |
| ├── [`camera-ipu4.md`](references/gotchas/camera-ipu4.md) | Surface Book 3 Intel IPU4 internal camera unsupported status & UVC workaround |
| ├── [`power-baseline.md`](references/gotchas/power-baseline.md) | Surface Book 3 dual-battery idle power tracking tool & kernel comparison baselines |
| └── [`virtual-keyboard.md`](references/gotchas/virtual-keyboard.md) | Surface on-screen touch keyboard (`wvkbd`) and compositor execution path |
| [`references/changelog.md`](references/changelog.md) | Dated log of system configuration changes |
| [`templates/change-entry.md`](templates/change-entry.md) | Template for changelog updates |
| [`scripts/snapshot.sh`](scripts/snapshot.sh) | Bash script to capture current system state to stdout |

*(Note: Hardware-specific gotchas, such as Apple T2 or Microsoft Surface, are dynamically symlinked into `references/gotchas/` by the active profile.)*
