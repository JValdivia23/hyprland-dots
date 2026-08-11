# AGENTS.md — Repository Guide & Project Rules

Welcome to the **CachyOS / Arch Linux Automated Dotfiles Repository**. This repository is configured to be managed by AI coding assistants and developers to maintain a fully automated, reproducible desktop environment across machines.

---

## 🎯 Project Goal

The objective of this project is to provide **1-command automated provisioning and continuous dotfiles management** for a customized Linux setup featuring:
- **Hyprland Compositor** (Modular Lua-based configuration)
- **Noctalia Wayland Shell** (Top bar, application launcher, notifications, widgets)
- **Kitty & Alacritty Terminals** (Theme synchronization & typography)
- **Fish Shell** (Custom environment, fastfetch greetings, completions)
- **macOS Navigation Layer** (Custom keybinds & helper scripts for macOS text editing and window handling)
- **Self-Improving System Knowledge Base** (`.agents/skills/system-personalization/`)

---

## 📁 Project Layout & Architecture

This repository uses **GNU Stow** to manage symlinks from package directories directly into `$HOME`:

```
~/dotfiles/
├── AGENTS.md                   # AI Assistant instructions & repository guide (this file)
├── README.md                   # User-facing installation & quick reference
├── .gitignore                  # Exclusion list for credentials, caches, and backups
├── install.sh                  # Master 1-command installer entrypoint
│
├── packages/
│   └── pacman-packages.txt     # Explicit list of all official & CachyOS packages
│
├── scripts/
│   ├── 01-packages.sh          # Package installation script (pacman & stow)
│   ├── 02-stow.sh              # Stow deployment with non-destructive backup handler
│   ├── 03-services.sh          # Systemd units (bluetooth, ufw, LocalSend port 53317, ASUS daemons)
│   └── 04-shell.sh             # Fish shell default registration
│
├── hypr/                       # Stow package -> ~/.config/hypr/
│   └── .config/hypr/
│       ├── hyprland.lua        # Main Lua entrypoint
│       ├── xdph.conf           # Portal configuration
│       └── config/             # Modular Lua settings (binds, inputs, monitors, etc.)
│
├── noctalia/                   # Stow package -> ~/.config/noctalia/
│   └── .config/noctalia/
│       └── config.toml         # Bar widgets, launcher, and session settings
│
├── kitty/                      # Stow package -> ~/.config/kitty/
├── alacritty/                  # Stow package -> ~/.config/alacritty/
├── fish/                       # Stow package -> ~/.config/fish/
├── btop/                       # Stow package -> ~/.config/btop/
├── waypaper/                   # Stow package -> ~/.config/waypaper/
├── gtk/                        # Stow package -> ~/.config/gtk-3.0, gtk-4.0, nwg-look
├── swayimg/                    # Stow package -> ~/.config/swayimg/
│
├── bin/                        # Stow package -> ~/.local/bin/
│   └── .local/bin/             # Custom executable helper scripts:
│                               # mac-key-helper, hypr-window-pop, hypr-toggle-altwin, etc.
│
└── agents/                     # Stow package -> ~/.agents/
    └── .agents/skills/system-personalization/
        ├── SKILL.md            # System tracking skill definition
        └── references/         # changelog.md, config-paths.md, gotchas.md, keybindings.md
```

---

## ⚠️ Core Agent Rules & Editing Guidelines

When modifying this repository or the live system, agents MUST adhere to these rules:

1. **Symlink Awareness**: Files in `~/.config/` and `~/.local/bin/` are symlinked to `~/dotfiles/`. Editing files in either location updates the Git repository.
2. **Never Overwrite Configs Directly**: Always use targeted edits or search-and-replace to preserve existing customizations, themes, and tool settings.
3. **Hyprland Lua API Standards**:
   - Hyprland on this machine is configured in **Lua**. Never write legacy Hyprland `.conf` syntax to `~/.config/hypr/config/`.
   - Use `hl.bind` with native dispatcher objects (e.g. `hl.dsp.send_shortcut`, `hl.dsp.window.close()`).
   - Always validate changes by running `hyprctl configerrors`.
4. **Noctalia Integration**:
   - After editing `noctalia/config.toml`, apply changes via `noctalia msg templates-apply` or test via `noctalia msg status`.
5. **Interactive Elevated Prompts (`kitty -e`)**:
   - When running administrative commands requiring password authentication (e.g. `sudo pacman`), launch an interactive terminal:
     ```bash
     kitty -e bash -c "sudo <command>; echo 'Done! Press Enter to close...'; read"
     ```
6. **Self-Improving Protocol**:
   - After any configuration change, package installation, or bug fix, document the change in `agents/.agents/skills/system-personalization/references/changelog.md` and `references/gotchas.md` if relevant.

---

## 🔧 Common Agent Workflows

### Updating Stow Symlinks
```bash
cd ~/dotfiles
bash scripts/02-stow.sh
```

### Refreshing Exported Package List
```bash
pacman -Qne | awk '{print $1}' | sort > ~/dotfiles/packages/pacman-packages.txt
```

### Checking Compositor Configuration Status
```bash
hyprctl configerrors
```
