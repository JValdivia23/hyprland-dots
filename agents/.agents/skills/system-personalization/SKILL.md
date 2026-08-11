---
name: system-personalization
description: "Comprehensive system personalization tracker for cachy-asus — OS, hardware, configs, keybindings, gotchas, offline documentation (CachyOS Wiki & Noctalia), and changelog. Self-improving: update after every change."
version: 1.0.0
created: 2026-07-20
tags: [system, personalization, dotfiles, desktop, hyprland, lua, cachyos, noctalia, fish, keybindings, gotchas, offline-docs]
---

# System Personalization (`cachy-asus`)

Complete documentation of this machine's configuration and personalization. This is a **self-improving skill** — after any system configuration change, software install, or gotcha discovery, update this skill's references (`references/changelog.md` and `references/gotchas.md`).

---

## Core Rules

1. **NEVER overwrite config files.** Use targeted edits (`patch`, append) to modify what's needed. Overwriting deletes previous settings from themes, packages, or other tools.
2. **Respect the modular Lua configuration.** Hyprland on this machine is configured in Lua. All config files are loaded by `~/.config/hypr/hyprland.lua` and reside in `~/.config/hypr/config/`. Never append traditional Hyprland `.conf` syntax.
3. **Noctalia panel integration.** The Wayland shell is Noctalia. After modifying `~/.config/noctalia/config.toml`, reload it via `noctalia msg reload` or restart it via `noctalia msg restart`.
4. **Fish Shell environment.** The system shell is `fish`. Do not write `bash`/`zsh` syntax to shell scripts without a proper shebang. Keep aliases and commands fish-compatible.
5. **Self-improving.** After every config change, software install, bug fix, or gotcha discovery, update this skill — specifically `references/changelog.md` and `references/gotchas.md` if relevant.
6. **Explain -> Ask -> Act.** Always explain the situation and ask if the user agrees with the solution before making changes to the system or installing anything.
7. **Hyprland Error Diagnostics.** When the user reports a desktop error, red banner, or system error after modifying Hyprland configs, `journalctl` does NOT log config validation errors. ALWAYS run `hyprctl configerrors` first to inspect the exact line number and error message.
8. **Elevated Password & Interactive Prompts (`kitty -e`).** When a system command requires user password authentication (such as `sudo pacman` package installations), launch an interactive terminal window using `kitty -e bash -c "sudo <command>; echo 'Done! Press Enter to close...'; read"` so the user can securely enter their password directly.


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
| **OS** | CachyOS Linux (Arch-based rolling release), kernel `7.1.3-2-cachyos` |
| **WM** | Hyprland 0.55.4 (Lua-based configuration) |
| **Wayland Shell** | Noctalia 5.0.0_beta.3-2 (bar, launcher, system menus) |
| **Primary Display** | `eDP-1` (Internal Monitor, 2560x1440@60Hz, scale 1.33) |
| **GPUs** | NVIDIA GeForce RTX 2060 Max-Q & AMD Renoir (Vega) |
| **CPU** | AMD Ryzen 9 4900HS (8 Cores, 16 Threads) |
| **Shell** | `/bin/fish` |
| **Terminal** | `kitty` (primary), `alacritty` (installed) |
| **Package Manager**| `pacman` |

---

## Reference Files

| File | Content |
|------|---------|
| `references/current-state.md` | Live system snapshot (OS, active packages, version checks) |
| `references/hardware.md` | CPU, GPU, RAM, monitor, and system specification logs |
| `references/config-paths.md` | Every config file, what it controls, and custom editing rules |
| `references/keybindings.md` | Comprehensive list of keyboard shortcuts from `config/binds.lua` |
| `references/changelog.md` | Dated log of every system configuration change |
| `references/gotchas.md` | Curated troubleshooting issues, failures, and their fixes |
| `templates/change-entry.md` | Template for changelog updates |
| `scripts/snapshot.sh` | Bash script to capture current system state to stdout |

---

## Offline Documentation Search

To assist in solving issues offline, this skill contains shallow clones of the official CachyOS Wiki and the Noctalia Documentation. You can search these files directly to find setup guides, commands, or configurations.

### Directory Structure
- **CachyOS Wiki**: `references/cachyos-wiki/src/content/docs/`
- **Noctalia Docs**: `references/noctalia-docs/`

### Searching the Docs
Use `grep_search` to query these folders. Examples:

*   *Search for how to configure Noctalia widgets:*
    - Query: `widget`
    - SearchPath: `~/.agents/skills/system-personalization/references/noctalia-docs/`
*   *Search for systemd service setup in CachyOS:*
    - Query: `systemd`
    - SearchPath: `~/.agents/skills/system-personalization/references/cachyos-wiki/src/content/docs/`
