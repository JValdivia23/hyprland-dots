# 🪐 Dotfiles & Automated System Setup

Automated dotfiles and environment provisioning for **CachyOS / Arch Linux** featuring **Hyprland (Lua API)**, **Noctalia Wayland Shell**, **Fish Shell**, **Kitty Terminal**, and **GNU Stow**.

---

## ⚡ Quick Start (Fresh Machine Installation)

On a fresh CachyOS or Arch Linux installation, run:

```bash
git clone https://github.com/<YOUR-USERNAME>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### What `install.sh` Does Automatically:
1. **Installs System Packages**: Synchronizes all official/CachyOS packages (`hyprland`, `noctalia`, `kitty`, `fish`, `dolphin`, `satty`, `btop`, etc.) from `packages/pacman-packages.txt`.
2. **Safe Backup & Stow**: Backs up any conflicting default configs to `~/.dotfiles_backup_<timestamp>/` and creates clean symlinks with `stow`.
3. **Services & Firewall**: Enables `bluetooth.service`, configures UFW firewall rules (including LocalSend discovery on port `53317`), and ASUS ROG daemons if applicable.
4. **Shell Environment**: Sets `fish` as the default user shell with custom paths and fastfetch greeting.

---

## 📁 Repository Layout

```
~/dotfiles/
├── install.sh                  # One-line automated bootstrap entrypoint
├── packages/
│   └── pacman-packages.txt     # Explicit packages list
├── scripts/
│   ├── 01-packages.sh          # Package installer
│   ├── 02-stow.sh              # Stow deployment & backup handler
│   ├── 03-services.sh          # Systemd & firewall setup
│   └── 04-shell.sh             # Fish shell default configuration
│
├── hypr/                       # ~/.config/hypr/ (Modular Lua config)
├── noctalia/                   # ~/.config/noctalia/ (Wayland bar, launcher, session)
├── kitty/                      # ~/.config/kitty/ (Terminal config & themes)
├── alacritty/                  # ~/.config/alacritty/ (Alacritty config)
├── fish/                       # ~/.config/fish/ (Fish config & greetings)
├── btop/                       # ~/.config/btop/ (Resource monitor)
├── waypaper/                   # ~/.config/waypaper/ (Wallpaper manager)
├── gtk/                        # ~/.config/gtk-3.0, gtk-4.0, nwg-look (GTK styling)
├── swayimg/                    # ~/.config/swayimg/ (Image viewer)
├── bin/                        # ~/.local/bin/ (Custom helper scripts)
├── webapps/                    # ~/.local/share/applications/ (Web apps & custom icons)
└── agents/                     # ~/.agents/ (System personalization & AI documentation)
```

---

## 🛠️ Managing Dotfiles with GNU Stow

To apply or update symlinks individually:

```bash
# Stow all modules
cd ~/dotfiles
stow -v -R -t ~ hypr noctalia kitty alacritty fish btop waypaper gtk swayimg bin webapps agents


# Stow a specific module (e.g. hyprland)
stow -v -R -t ~ hypr
```

---

## ⌨️ Custom Keybindings Quick Reference

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Super + Space`** | App Launcher | Opens Noctalia application launcher |
| **`Super + Return`** | Terminal | Launches Kitty terminal emulator |
| **`Super + B`** | Browser | Launches Brave browser |
| **`Super + E`** | File Manager | Launches Dolphin |
| **`Super + O`** | Window Pop-out | Floats, centers (1300x900), and pins active window |
| **`Super + Shift + O`** | PiP Pop-out | Floats small Picture-in-Picture window |
| **`Super + Alt + K`** | Keyboard Layout | Dynamically toggles between Mac and PC modifier layouts |
| **`Super + C / V / X / Z / A`** | Edit Actions | Copy, Paste, Cut, Undo, Select All (Mac-style) |
| **`Super + Left / Right`** | Line Jump | Beginning / End of line (Home / End) |
| **`Alt + Left / Right`** | Word Jump | Jump word backward / forward |
| **`PrintScreen`** | Screenshot | Fullscreen snip to Satty |
| **`Super + Shift + 4`** | Snip Tool | Interactive area screenshot |
| **`Alt + Space`** | Wallpaper App | Launches Waypaper graphical wallpaper selector |
| **`Super + Shift + W`** | Wallpaper Panel | Opens Noctalia interactive wallpaper gallery |
| **`Super + Escape`** | Power Menu | Opens Noctalia session and power menu |

---

## 🔄 Syncing Changes Back to GitHub

Whenever you modify any configuration in `~/.config/` or add a new script to `~/.local/bin/`, the symlinks update your `~/dotfiles/` directory automatically.

To push your updates to GitHub:

```bash
cd ~/dotfiles
git add .
git commit -m "Update desktop configuration"
git push origin main
```
