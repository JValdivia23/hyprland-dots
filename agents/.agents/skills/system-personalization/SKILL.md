---
name: system-personalization
description: "Comprehensive system personalization tracker for surface (Surface Book 3) — OS, hardware, modular configs, keybindings, gotchas, and changelog. Self-improving: update after every change."
version: 2.24.0
tags: [system, personalization, dotfiles, desktop, hyprland, lua, cachyos, noctalia, fish, keybindings, gotchas]
---

# System Personalization (`surface` - Surface Book 3)

Complete documentation of this machine's configuration and personalization. This is a **self-improving skill** — after any system configuration change, software install, or gotcha discovery, update this skill's modular references (`references/changelog.md` and `references/gotchas/`).

---

## Core Rules

1. **NEVER overwrite config files.** Use targeted edits (`patch`, append) to modify what's needed. Overwriting deletes previous settings from themes, packages, or other tools.
2. **Respect the modular Lua configuration.** Hyprland on this machine is configured in Lua. Core universal configs reside in `~/.config/hypr/config/`, while hardware profile overrides reside in `~/.config/hypr/config/profile/`. Never append traditional Hyprland `.conf` syntax.
3. **Noctalia panel integration.** The Wayland shell is Noctalia. If modifying `~/.config/noctalia/config.toml` or after restarting audio services, restart or reload via `noctalia msg reload` or `killall -TERM noctalia; sleep 0.5; hyprctl eval 'hl.exec_cmd("noctalia -d")'`.
4. **Fish Shell environment.** The system shell is `fish`. Do not write `bash`/`zsh` syntax to shell scripts without a proper shebang. Keep aliases and commands fish-compatible.
5. **Self-improving.** After every config change, software install, bug fix, or gotcha discovery, update this skill — specifically `references/changelog.md` and `references/gotchas/` if relevant.
6. **Explain -> Ask -> Act.** Always explain the situation and ask if the user agrees with the solution before making changes to the system or installing anything.
7. **Hyprland Error Diagnostics.** When the user reports a desktop error, red banner, or system error after modifying Hyprland configs, `journalctl` does NOT log config validation errors. ALWAYS run `hyprctl configerrors` first to inspect the exact line number and error message.
8. **Elevated Password & Interactive Prompts (`hyprctl` / `kitty -e`).** When a system command requires user password authentication (such as `sudo pacman` package installations), background agent subshells must export `HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/$UID/hypr/ 2>/dev/null | head -n1)` and launch an interactive terminal window via Hyprland's IPC executor: `hyprctl eval 'hl.exec_cmd("kitty --title <Title> -e bash -c \"sudo <command>; echo Done!; read\"")'`. This ensures the terminal maps directly onto the active Wayland workspace so the user can securely enter their password directly.

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

| Category | Detail |
|----------|--------|
| **Machine** | Surface Book 3 |
| **Hostname** | `surface` |
| **OS** | CachyOS |
| **Kernel** | `6.19.8-arch1-3-surface` |
| **WM** | Hyprland (Lua modular API) |
| **Wayland Shell** | Noctalia |
| **Primary Display** | eDP-1 (3000x2000@60Hz, scale 2) |
| **GPU** | Intel Corporation Iris Plus Graphics G7 |
| **CPU** | Intel(R) Core(TM) i5-1035G7 CPU @ 1.20GHz |
| **RAM & Swap** | 7.4Gi RAM, 16Gi swap |
| **Active Profiles** | surface |
| **Shell** | `/bin/fish` |
| **Terminal** | `kitty` (primary), `alacritty` (installed) |
| **Package Manager**| `pacman` |

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
| ├── [`terminal-ssh.md`](references/gotchas/terminal-ssh.md) | Kitty SSH terminfo export, `kitty -e` interactive password prompts |
| └── [`battery-upower.md`](references/gotchas/battery-upower.md) | Surface dual-battery calculation desync (~300%) & UPower service recovery |
| [`references/changelog.md`](references/changelog.md) | Dated log of system configuration changes |
| [`templates/change-entry.md`](templates/change-entry.md) | Template for changelog updates |
| [`scripts/snapshot.sh`](scripts/snapshot.sh) | Bash script to capture current system state to stdout |

*(Note: Hardware-specific gotchas, such as Apple T2 or Microsoft Surface, are dynamically symlinked into `references/gotchas/` by the active profile.)*
