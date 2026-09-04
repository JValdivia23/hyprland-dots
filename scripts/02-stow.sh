#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

STOW_PKGS=(
    "hypr"
    "niri"
    "noctalia"
    "kitty"
    "alacritty"
    "fish"
    "btop"
    "waypaper"
    "gtk"
    "swayimg"
    "zigoku"
    "bin"
    "agents"
    "webapps"
    "easyeffects"
)

echo "==> [2/4] Deploying dotfiles with GNU Stow..."

if ! command -v stow &>/dev/null; then
    echo "Error: stow is not installed." >&2
    exit 1
fi

# Ensure base target directories exist
mkdir -p "$HOME/.config" \
         "$HOME/.local/bin" \
         "$HOME/.local/share/applications/icons" \
         "$HOME/Pictures/Wallpapers" \
         "$HOME/.agents/skills/system-personalization/references/gotchas"

# Check and backup existing real files/directories that would conflict with stow
backup_needed=false

check_and_backup() {
    local target="$1"
    # Skip if target doesn't exist or is already a symlink
    if [ ! -e "$target" ] || [ -L "$target" ]; then
        return 0
    fi
    # Also skip if target is located inside an existing symlink directory
    local p="$target"
    while [ "$p" != "$HOME" ] && [ "$p" != "/" ]; do
        p="$(dirname "$p")"
        if [ -L "$p" ]; then
            return 0
        fi
    done

    if [ "$backup_needed" = false ]; then
        echo "--> Backing up existing non-symlink configs to $BACKUP_DIR..."
        mkdir -p "$BACKUP_DIR"
        backup_needed=true
    fi
    local rel_path="${target#$HOME/}"
    mkdir -p "$BACKUP_DIR/$(dirname "$rel_path")"
    mv "$target" "$BACKUP_DIR/$rel_path"
    echo "    Backed up: ~/$rel_path"
}


# Check all target config paths
check_and_backup "$HOME/.config/hypr"
check_and_backup "$HOME/.config/noctalia"
check_and_backup "$HOME/.config/kitty"
check_and_backup "$HOME/.config/alacritty"
check_and_backup "$HOME/.config/fish/config.fish"
check_and_backup "$HOME/.config/btop"
check_and_backup "$HOME/.config/waypaper"
check_and_backup "$HOME/.config/gtk-3.0"
check_and_backup "$HOME/.config/gtk-4.0"
check_and_backup "$HOME/.config/nwg-look"
check_and_backup "$HOME/.config/niri/cfg/keybinds.kdl"
check_and_backup "$HOME/.config/swayimg"
check_and_backup "$HOME/.config/zigoku"
check_and_backup "$HOME/.config/easyeffects"


# Check binary scripts
for script in anime-lid-charging cachy-webapp-install cachy-webapp-remove dolphin-key-helper fastfetch-custom hypr-kbd-brightness hypr-quicklook hypr-toggle-altwin hypr-window-pop mac-key-helper; do
    check_and_backup "$HOME/.local/bin/$script"
done

# Check agent skill documentation files
check_and_backup "$HOME/.agents/skills/system-personalization/SKILL.md"
check_and_backup "$HOME/.agents/skills/system-personalization/references/changelog.md"
check_and_backup "$HOME/.agents/skills/system-personalization/references/config-paths.md"
check_and_backup "$HOME/.agents/skills/system-personalization/references/current-state.md"
check_and_backup "$HOME/.agents/skills/system-personalization/references/gotchas.md"
check_and_backup "$HOME/.agents/skills/system-personalization/references/gotchas/hyprland.md"
check_and_backup "$HOME/.agents/skills/system-personalization/references/gotchas/wayland-noctalia.md"
check_and_backup "$HOME/.agents/skills/system-personalization/references/gotchas/apple-t2.md"
check_and_backup "$HOME/.agents/skills/system-personalization/references/gotchas/networking.md"
check_and_backup "$HOME/.agents/skills/system-personalization/references/gotchas/terminal-ssh.md"
check_and_backup "$HOME/.agents/skills/system-personalization/references/hardware.md"
check_and_backup "$HOME/.agents/skills/system-personalization/references/keybindings.md"
check_and_backup "$HOME/.agents/skills/system-personalization/scripts/snapshot.sh"
check_and_backup "$HOME/.agents/skills/system-personalization/templates/change-entry.md"


# Check webapps desktop entries & icons
for app in AllAnime AniMatrix Hanime PH YouTube; do
    check_and_backup "$HOME/.local/share/applications/$app.desktop"
    check_and_backup "$HOME/.local/share/applications/icons/$app.png"
done
check_and_backup "$HOME/.local/share/applications/icons/Phub.png"

# Stow all modules
echo "--> Stowing configuration packages to $HOME..."
cd "$DOTFILES_DIR"
for pkg in "${STOW_PKGS[@]}"; do
    if [ -d "$DOTFILES_DIR/$pkg" ]; then
        stow -v -R -d "$DOTFILES_DIR" -t "$HOME" "$pkg"
    fi
done

# Link custom icons to ~/.local/share/icons, hicolor, and pixmaps for universal XDG icon lookup
mkdir -p "$HOME/.local/share/icons" \
         "$HOME/.local/share/pixmaps" \
         "$HOME/.local/share/icons/hicolor/512x512/apps" \
         "$HOME/.local/share/icons/hicolor/scalable/apps"

for icon in "$DOTFILES_DIR"/webapps/.local/share/applications/icons/*; do
    if [ -f "$icon" ]; then
        filename="$(basename "$icon")"
        ln -sf "$icon" "$HOME/.local/share/icons/$filename" 2>/dev/null || true
        ln -sf "$icon" "$HOME/.local/share/pixmaps/$filename" 2>/dev/null || true
        if [[ "$filename" == *.png ]]; then
            ln -sf "$icon" "$HOME/.local/share/icons/hicolor/512x512/apps/$filename" 2>/dev/null || true
        elif [[ "$filename" == *.svg ]]; then
            ln -sf "$icon" "$HOME/.local/share/icons/hicolor/scalable/apps/$filename" 2>/dev/null || true
        fi
    fi
done

# Update desktop application and icon database
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons" 2>/dev/null || true
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

echo "==> GNU Stow deployment complete."
