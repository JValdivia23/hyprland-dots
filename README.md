# 🪐 Dotfiles & Automated System Setup

Automated dotfiles and environment provisioning for **CachyOS / Arch Linux** featuring **Hyprland (Lua API)**, **Noctalia Wayland Shell**, **Fish Shell**, **Kitty Terminal**, and **GNU Stow**.

---

## ⚡ Quick Start (Fresh Machine Installation)

On a fresh CachyOS or Arch Linux installation, run:

```bash
git clone https://github.com/JValdivia23/hyprland-dots.git ~/dotfiles
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
├── niri/                       # ~/.config/niri/ (Niri keybinds & configuration)
├── noctalia/                   # ~/.config/noctalia/ (Wayland bar, launcher, session)
├── kitty/                      # ~/.config/kitty/ (Terminal config & themes)
├── alacritty/                  # ~/.config/alacritty/ (Alacritty config)
├── fish/                       # ~/.config/fish/ (Fish config & greetings)
├── btop/                       # ~/.config/btop/ (Resource monitor)
├── waypaper/                   # ~/.config/waypaper/ (Wallpaper manager)
├── gtk/                        # ~/.config/gtk-3.0, gtk-4.0, nwg-look (GTK styling)
├── swayimg/                    # ~/.config/swayimg/ (Image viewer)
├── zigoku/                     # ~/.config/zigoku/ (Anime streaming app config)
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
stow -v -R -t ~ hypr niri noctalia kitty alacritty fish btop waypaper gtk swayimg zigoku bin webapps agents

# Stow a specific module (e.g. hyprland)
stow -v -R -t ~ hypr
```

---

## ⌨️ Custom Keybindings Quick Reference

### Applications & Terminals
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Super + Return`** | Terminal | Launches Kitty terminal emulator |
| **`Super + Shift + Return`** | Alt Terminal | Launches Ghostty terminal emulator |
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
| **`Alt + Space`** | Wallpaper App | Launches Waypaper / Noctalia dynamic wallpaper selector |
| **`Super + Shift + W`** | Wallpaper Gallery | Opens Noctalia interactive wallpaper carousel |
| **`Super + E`** | Control Center | Opens Noctalia control center & quick settings |
| **`Super + A`** | Notifications | Opens Noctalia notification center |
| **`Super + Escape`** | Power Menu | Opens Noctalia session and power menu |
| **`Super + L`** | Lock Session | Locks current session |
| **`Super + Shift + L`** | Suspend | Locks session and suspends machine |
| **`Super + K`** | Cheatsheet | Opens full keybindings reference in Neovim |

### Window Management & Pop-outs
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Super + O`** | Window Pop-out | Floats, centers (1100x700), and pins active window |
| **`Super + Shift + O`** | PiP Pop-out | Floats small Picture-in-Picture window |
| **`Alt + Enter`** | Quick Look | macOS-style floating file preview over Dolphin |
| **`Super + T`** | Toggle Float | Toggles active window floating mode |
| **`Super + F`** | Fullscreen | Toggles true fullscreen |
| **`Super + D`** | Maximize | Toggles monocle / maximize layout |
| **`Super + Q` / `Super + W`** | Close Window | Closes focused window |

### Navigation, Editing & Screenshots
| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Super + Alt + K`** | Toggle Layout | Dynamically toggles Mac (Command) vs PC (Ctrl) modifier keys |
| **`Super + C / V / X / Z`** | Edit Actions | Copy, Paste, Cut, Undo (Mac-style) |
| **`Super + Left / Right`** | Line Jump | Beginning / End of line (`Home` / `End`) |
| **`Alt + Left / Right`** | Word Jump | Jump word backward / forward |
| **`Print` / `Super + Shift + S`** | Snip Tool | Interactive region screenshot to Satty |
| **`Shift + Print`** | Fullscreen Snip | Fullscreen screenshot with output selector |


Whenever you modify any configuration in `~/.config/` or add a new script to `~/.local/bin/`, the symlinks update your `~/dotfiles/` directory automatically.

To push your updates to GitHub:

```bash
cd ~/dotfiles
git add .
git commit -m "Update desktop configuration"
git push origin main
```
