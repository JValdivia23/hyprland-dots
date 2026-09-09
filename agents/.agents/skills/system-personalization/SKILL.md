---
name: system-personalization
description: "Comprehensive system personalization tracker for cachyos-cu (Apple MacBookPro15,1) — OS, hardware, modular configs, keybindings, gotchas, and changelog. Self-improving: update after every change."
version: 2.22.0
created: 2026-08-14
tags: [system, personalization, dotfiles, desktop, hyprland, lua, cachyos, noctalia, fish, macbook, t2, keybindings, gotchas]
---

# System Personalization (`cachyos-cu`)

Complete documentation of this machine's configuration and personalization. This is a **self-improving skill** — after any system configuration change, software install, or gotcha discovery, update this skill's modular references (`references/changelog.md` and `references/gotchas.md`).

---

## Core Rules

1. **NEVER overwrite config files.** Use targeted edits (`patch`, append) to modify what's needed. Overwriting deletes previous settings from themes, packages, or other tools.
2. **Respect the modular Lua configuration.** Hyprland on this machine is configured in Lua. All config files are loaded by `~/.config/hypr/hyprland.lua` and reside in `~/.config/hypr/config/`. Never append traditional Hyprland `.conf` syntax.
3. **Noctalia panel integration.** The Wayland shell is Noctalia. If modifying `~/.config/noctalia/config.toml` or after restarting audio services, restart the shell daemon via `killall -TERM noctalia; sleep 0.5; hyprctl eval 'hl.exec_cmd("noctalia -d")'`.
4. **Fish Shell environment.** The system shell is `fish`. Do not write `bash`/`zsh` syntax to shell scripts without a proper shebang. Keep aliases and commands fish-compatible.
5. **Self-improving.** After every config change, software install, bug fix, or gotcha discovery, update this skill — specifically `references/changelog.md` and `references/gotchas.md` if relevant.
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
| **Machine** | Apple MacBook Pro 15,1 (Chassis Laptop) |
| **OS** | CachyOS Linux (Arch-based rolling release), kernel `7.2.3-1-cachyos` |
| **WM** | Hyprland 0.56.2 (Lua-based modular configuration) |
| **Wayland Shell** | Noctalia 5.0.1-1.1 (bar, launcher, system menus) |
| **Primary Display** | `eDP-1` (Apple Retina Color LCD, 2880x1800@60Hz, scale 1.33) |
| **GPU** | AMD Radeon Pro 560X (Baffin / Polaris 11, `amdgpu`) |
| **CPU** | Intel Core i9-9880H (8 Cores, 16 Threads, 2.30 - 4.80 GHz) |
| **RAM & Swap** | 16 GiB DDR4 RAM, 15.5 GiB zram swap |
| **Security / T2** | Apple T2 Bridge Controller, Touch Bar (`tiny-dfr`), Apple Audio (`aaudio`) |
| **Shell** | `/bin/fish` |
| **Terminal** | `kitty` (primary), `alacritty` (installed) |
| **Package Manager**| `pacman` |

---

## Modular Reference Files

| File / Folder | Content |
|---------------|---------|
| [`references/hardware.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/hardware.md) | Physical hardware specs, CPU, GPU, Apple T2 subsystem, displays, and audio |
| [`references/current-state.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/current-state.md) | Live snapshot (OS, kernel, active package versions, active helper scripts) |
| [`references/config-paths.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/config-paths.md) | Config files, Lua modules, touchpad gesture specs, and edit rules |
| [`references/keybindings.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/keybindings.md) | Complete keyboard shortcuts reference from `binds.lua` |
| [`references/gotchas/`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/) | **Topic-specific gotchas & troubleshooting**: |
| ├── [`hyprland.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/hyprland.md) | Hyprland Lua syntax, IPC window dispatchers, modifier repetition, copy shortcut |
| ├── [`wayland-noctalia.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/wayland-noctalia.md) | Noctalia messaging reload/restart, Satty screenshot piping, Quick Look |
| ├── [`apple-t2.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/apple-t2.md) | Apple Touch Bar `tiny-dfr`, T2 sleep fix (`suspend-fix-t2`), `aaudio` sound routing |
| ├── [`networking.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/networking.md) | LocalSend UFW firewall port rules (53317 TCP/UDP) |
| └── [`terminal-ssh.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/terminal-ssh.md) | Kitty SSH terminfo export, `kitty -e` interactive password prompts |
| [`references/changelog.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/changelog.md) | Dated log of system configuration changes |
| [`templates/change-entry.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/templates/change-entry.md) | Template for changelog updates |
| [`scripts/snapshot.sh`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/scripts/snapshot.sh) | Bash script to capture current system state to stdout |


