# 🪐 CachyOS / Arch Multi-PC Dotfiles

Automated, reproducible, and hardware-aware desktop environment configured for **CachyOS / Arch Linux**, powered by **Hyprland (Native Lua API)**, **Noctalia Wayland Shell**, **GNU Stow**, and a **Self-Improving AI System Skill**.

[![Hyprland Lua](https://img.shields.io/badge/Hyprland-Lua%20API-teal?style=flat-square)](https://hyprland.org/)
[![Noctalia Shell](https://img.shields.io/badge/Noctalia-Wayland%20Shell-blue?style=flat-square)](https://github.com/noctalia-dev/noctalia)
[![GNU Stow](https://img.shields.io/badge/GNU-Stow%20Managed-orange?style=flat-square)](https://www.gnu.org/software/stow/)
[![Multi PC](https://img.shields.io/badge/Multi--PC-Modular%20Profiles-purple?style=flat-square)](./profiles/)

---

## 🌟 3-Tier Multi-PC Architecture

This repository is built around a **3-Tier Architecture** that cleanly isolates universal desktop configurations from machine-specific hardware quirks and AI knowledge:

```
~/dotfiles/
├── core/                       # Tier 1: Universal configs (Hyprland master, Noctalia, Kitty, Fish, Webapps)
├── profiles/                   # Tier 2: Modular hardware profiles (MacBook T2, Desktop, Surface, Laptop)
│   ├── macbook-t2/             # Apple MacBook Pro 15,1 / T2 Subsystem
│   ├── desktop/                # Multi-monitor workstations & standard PCs
│   ├── surface/                # Microsoft Surface Book 3 / Surface Pro
│   └── laptop/                 # Generic laptop touchpads & power
└── agents/                     # Tier 3: Dynamic AI System Personalization Skill
    └── .agents/skills/system-personalization/
```

### 1. Universal Hyprland Lua Bootstrap (`core/`)
- Universal configuration (`core/.config/hypr/hyprland.lua`) loads common modules (`animations`, `colors`, `decorations`, `variables`, `windowrules`, `workspaces`, `binds`), provides neutral fallback defaults, and dynamically loads active profile overrides via `pcall(require, ...)`:
  - `config.profile.monitors`
  - `config.profile.environment`
  - `config.profile.inputs`
  - `config.profile.autostart`
  - `config.profile.binds`

### 2. Modular Hardware Profiles (`profiles/`)
| Profile | Target Hardware | Included Overrides |
| :--- | :--- | :--- |
| **`macbook-t2`** | Apple MacBook Pro 15,1 (T2) | 2880x1800 @ 1.33 scale, AMD `radeonsi` GPU flags, MacBook trackpad gestures, Touch Bar `tiny-dfr`, sleep/resume fixes. |
| **`desktop`** | Workstations / Generic PCs | Multi-monitor display templates (144Hz, portrait/landscape), flat mouse acceleration, audio routing (`pavucontrol`), gaming mode. |
| **`surface`** | Microsoft Surface Book / Pro | 3000x2000 @ 2.0 integer scaling, Intel Precise Touch (`iptsd`), tablet detach daemon (`surface-dtx-daemon`). |
| **`laptop`** | Generic Laptops | Touchpad natural scrolling, 3-finger & 4-finger gestures, battery power management. |

### 3. Self-Improving System Personalization Skill (`agents/`)
- Dynamically probes hostname, CPU, GPU, displays, and active profiles to generate personalized `SKILL.md` and `references/hardware.md`.
- Machine gotchas travel in `profiles/<name>/gotchas/` and are symlinked automatically.

---

## ⚡ Quick Start

### 1. Fresh Machine Installation
On any fresh CachyOS or Arch Linux installation, run:

```bash
git clone https://github.com/JValdivia23/hyprland-dots.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### 2. What `install.sh` Does Automatically:
1. **Hardware Detection**: Probes DMI, chassis type, and PCI devices to identify your machine profile (`macbook-t2`, `surface`, `desktop`, `laptop`).
2. **Package Synchronization**: Installs missing core tools (`stow`, `ripgrep`, `hyprland`, `noctalia`, `kitty`, `fish`, `dolphin`) and profile-specific utilities.
3. **Non-Destructive Backup**: Detects any existing non-symlink configuration files in `~/.config/` or `~/.local/bin/` and safely moves them to `~/.dotfiles_backup_<timestamp>/`.
4. **Deployment**: Links `core/`, active profiles, and `agents/` into your `$HOME` directory using GNU Stow with `--no-folding`.
5. **Post-Install Setup**: Runs profile setup scripts (e.g. enabling `tiny-dfr` on MacBook or `surface-dtx-daemon` on Surface), symlinks profile gotchas, and initializes the AI system personalization skill.

---

## 🎛️ Command-Line Options

The installer supports flexible flags for testing and targeted updates:

```bash
# Preview actions without modifying filesystem or installing packages
./install.sh --dry-run

# Manually force a specific hardware profile
./install.sh --profile macbook-t2
./install.sh --profile desktop
./install.sh --profile surface
./install.sh --profiles "desktop,gaming"

# Only backup conflicts and re-stow symlinks (skips package installation and setup)
./install.sh --only-stow

# Only install core and profile packages
./install.sh --only-packages

# Show usage help
./install.sh --help
```

---

## ➕ Adding a New Computer Profile

Adding support for a new laptop or workstation is simple:

1. **Create the profile folder**:
   ```bash
   mkdir -p profiles/my-pc/.config/hypr/config/profile
   mkdir -p profiles/my-pc/gotchas
   ```

2. **Add display and input overrides** (optional):
   - `profiles/my-pc/.config/hypr/config/profile/monitors.lua`:
     ```lua
     hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1 })
     ```
   - `profiles/my-pc/.config/hypr/config/profile/inputs.lua`:
     ```lua
     hl.config({ input = { accel_profile = "flat", sensitivity = 0.0 } })
     ```

3. **Specify required packages & setup script**:
   - Create `profiles/my-pc/packages.txt` (one package per line).
   - Create executable `profiles/my-pc/setup.sh`.
   - Create `profiles/my-pc/.stow-local-ignore`:
     ```
     ^packages\.txt$
     ^services\.txt$
     ^setup\.sh$
     ^gotchas
     ^\.stow-local-ignore$
     ```

4. **Deploy**:
   ```bash
   ./install.sh --profile my-pc
   ```

---

## ⌨️ Custom Keybindings Quick Reference

### Applications & Terminals
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Super + Return`** | Terminal | Launches Kitty terminal emulator |
| **`Super + Shift + B`** | Web Browser | Launches Zen Browser |
| **`Super + Shift + F`** | File Manager | Launches Dolphin |
| **`Super + Shift + U`** | Terminal Files | Launches Yazi file manager |
| **`Super + Shift + A`** | Git Manager | Launches LazyGit |
| **`Super + Shift + D`** | Docker Manager | Launches LazyDocker |
| **`Super + Shift + N`** | Quick Notes | Opens Neovim in `~/Documents/Notes` |
| **`Super + Shift + Y`** | Web App | Launches YouTube Web Application |
| **`Ctrl + Shift + Esc`** | Task Manager | Launches Btop resource monitor |

### Desktop & System Controls
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Super + Space`** | App Launcher | Opens Noctalia application launcher |
| **`Alt + Space`** | Wallpaper App | Launches Waypaper / dynamic wallpaper selector |
| **`Super + Shift + W`** | Wallpaper Gallery | Opens Noctalia interactive wallpaper carousel |
| **`Super + E`** | Control Center | Opens Noctalia control center & quick settings |
| **`Super + A`** | Notifications | Opens Noctalia notification center |
| **`Super + Escape`** | Power Menu | Opens Noctalia session and power menu |
| **`Super + L`** | Lock Session | Locks current session |
| **`Super + Shift + L`** | Suspend | Locks session and suspends machine |
| **`Super + K`** | Cheatsheet | Opens full keybindings reference in Neovim |
