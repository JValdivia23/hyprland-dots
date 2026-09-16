# AGENTS.md — Repository Architecture & AI Assistant Guide

Welcome to the **CachyOS / Arch Linux Multi-PC Dotfiles Repository** (`~/dotfiles`). This repository is designed for multi-machine Linux desktop automation, featuring CachyOS, Hyprland Lua configuration, Noctalia Wayland shell, GNU Stow orchestration, and a self-improving system personalization skill.

All AI coding assistants and developers modifying this repository MUST strictly follow the rules, architecture, and validation protocols detailed in this document.

---

## 🏛️ 3-Tier Repository Architecture

This repository organizes configuration into three decoupled, modular tiers to ensure clean separation of universal defaults, machine-specific hardware quirks, and dynamic AI knowledge:

```
~/dotfiles/
├── install.sh                  # Master orchestrator (hardware detection, packages, stow, skill init)
├── AGENTS.md                   # AI Assistant instructions & architectural rules (this file)
├── README.md                   # User-facing guide & quick reference
│
├── core/                       # ─── TIER 1: UNIVERSAL CONFIGURATIONS ──────────────────────
│   ├── .config/
│   │   ├── hypr/
│   │   │   ├── hyprland.lua    # Master Hyprland Lua entrypoint (loads core + pcalls profile overrides)
│   │   │   ├── config/         # Universal Lua modules (animations, binds, colors, decorations,
│   │   │   │                   # misc, variables, windowrules, workspaces)
│   │   │   │   ├── monitors.lua    # Generic fallback: hl.monitor({ output = "", scale = 1 })
│   │   │   │   ├── inputs.lua      # Standard base input
│   │   │   │   ├── environment.lua # Safe neutral environment (EDITOR=nvim, etc.)
│   │   │   │   └── autostart.lua   # Universal session autostart
│   │   │   ├── hypridle.conf   # Idle daemon configuration
│   │   │   └── xdph.conf       # XDG Desktop Portal Hyprland configuration
│   │   ├── noctalia/           # Noctalia Wayland shell (bar, launcher, widgets)
│   │   ├── kitty/              # Kitty terminal
│   │   ├── alacritty/          # Alacritty terminal
│   │   ├── fish/               # Fish shell & prompt
│   │   ├── btop/               # Btop system monitor
│   │   ├── gtk-3.0/ & gtk-4.0/ # GTK themes & styles
│   │   ├── swayimg/            # Swayimg image viewer
│   │   ├── zigoku/             # Zigoku anime streaming config
│   │   ├── easyeffects/        # EasyEffects audio presets & equalizer
│   │   └── niri/               # Niri scrollable WM configuration
│   ├── .local/bin/             # Universal CLI utilities (hypr-toggle-altwin, mac-key-helper, etc.)
│   ├── .local/share/applications/# Webapps (.desktop launchers & high-res icons)
│   ├── packages.txt            # Baseline packages required on any machine
│   └── .stow-local-ignore      # Prevents metadata from stowing to $HOME
│
├── profiles/                   # ─── TIER 2: MODULAR HARDWARE PROFILES ────────────────────
│   ├── macbook-t2/             # Apple MacBook Pro 15,1 / T2 Subsystem
│   │   ├── .config/hypr/config/profile/
│   │   │   ├── monitors.lua    # 2880x1800 @ 1.33 fractional scaling
│   │   │   ├── environment.lua # AMD radeonsi GPU hardware acceleration flags
│   │   │   └── inputs.lua      # Apple trackpad gestures & natural scrolling
│   │   ├── packages.txt        # apple-t2-audio-config, tiny-dfr, t2fanrd
│   │   ├── setup.sh            # Enables Touch Bar fixes & AMDGPU power management
│   │   ├── gotchas/            # Apple T2 hardware quirks & documentation
│   │   └── .stow-local-ignore
│   │
│   ├── desktop/                # Multi-Monitor Workstations & Generic Standard PCs
│   │   ├── .config/hypr/config/profile/
│   │   │   ├── monitors.lua    # Multi-head layout template (DP-1, DP-2, 144Hz)
│   │   │   ├── environment.lua # NVIDIA / generic Mesa acceleration template
│   │   │   └── inputs.lua      # Desktop mouse settings (flat accel, no gestures)
│   │   ├── packages.txt        # pavucontrol, gamemode
│   │   ├── setup.sh            # Workstation desktop setup
│   │   └── .stow-local-ignore
│   │
│   ├── surface/                # Microsoft Surface Devices (Surface Book 3 / Surface Pro)
│   │   ├── .config/hypr/config/profile/
│   │   │   ├── monitors.lua    # 3000x2000 @ 2.0 integer scaling
│   │   │   └── inputs.lua      # Touchscreen calibration & stylus rules
│   │   ├── packages.txt        # surface-dtx-daemon, iptsd
│   │   ├── setup.sh            # Enables surface-dtx-daemon & iptsd
│   │   ├── gotchas/            # Surface scaling & tablet detach quirks
│   │   └── .stow-local-ignore
│   │
│   └── laptop/                 # Generic Laptops (ThinkPad, Dell XPS, etc.)
│       ├── .config/hypr/config/profile/
│       │   └── inputs.lua      # Touchpad natural scroll & gestures
│       └── .stow-local-ignore
│
└── agents/                     # ─── TIER 3: DYNAMIC AI SYSTEM PERSONALIZATION SKILL ──────
    ├── .agents/skills/system-personalization/
    │   ├── SKILL.md.template   # Machine-agnostic template with {{HOSTNAME}}, {{CPU}}, etc.
    │   ├── SKILL.md            # Live rendered skill for active host
    │   ├── scripts/init-skill.sh # Probes hardware and generates SKILL.md + hardware.md
    │   ├── references/         # changelog.md, config-paths.md, keybindings.md, gotchas/
    │   └── templates/          # Standard templates for changes and gotchas
    └── .stow-local-ignore
```

---

## ⚠️ Core Agent Rules & Editing Guidelines

When modifying this repository or the live system, agents MUST adhere to these rules:

1. **Symlink Awareness**: Files in `~/.config/`, `~/.local/bin/`, and `~/.agents/` are live symlinks managed by GNU Stow pointing to `~/dotfiles/`. Editing files in either location updates the Git repository.
2. **Never Overwrite Configs Directly**: Always use targeted edits (`replace_file_content`, patch, append) to preserve existing customizations, themes, and tool settings.
3. **Hyprland Lua API Standards**:
   - Hyprland on this machine is configured in **Lua**. Never write legacy Hyprland `.conf` syntax to `~/.config/hypr/config/`.
   - Use `hl.bind` with native dispatcher objects (e.g. `hl.dsp.send_shortcut`, `hl.dsp.window.close()`).
   - Hardware-specific settings go in `profiles/<name>/.config/hypr/config/profile/`.
   - Always validate changes by running `hyprctl configerrors`.
4. **Noctalia Integration**:
   - After editing `noctalia/config.toml`, reload via `noctalia msg reload` or test via `noctalia msg status`.
5. **Interactive Elevated Prompts (`kitty -e`)**:
   - When running administrative commands requiring password authentication (e.g. `sudo pacman`), launch an interactive terminal:
     ```bash
     export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/$UID/hypr/ 2>/dev/null | head -n1)
     hyprctl eval 'hl.exec_cmd("kitty --title PasswordPrompt -e bash -c \"sudo <command>; echo Done!; read\"")'
     ```
6. **Self-Improving Protocol**:
   - After any configuration change, package installation, or bug fix, document the change in `agents/.agents/skills/system-personalization/references/changelog.md` and `references/gotchas/` if relevant.
