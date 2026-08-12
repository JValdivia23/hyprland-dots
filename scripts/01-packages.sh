#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_FILE="$DOTFILES_DIR/packages/pacman-packages.txt"

echo "==> [1/4] Installing system packages via pacman..."

if ! command -v pacman &>/dev/null; then
    echo "Error: pacman not found. This installation script is designed for Arch Linux / CachyOS." >&2
    exit 1
fi

# Ensure pacman sandbox allows network hooks (e.g. in containers or custom setups)
if ! grep -q "DisableSandboxNetwork" /etc/pacman.conf; then
    sudo sed -i '/\[options\]/a DisableSandboxNetwork' /etc/pacman.conf 2>/dev/null || true
fi

# Enable multilib in /etc/pacman.conf if commented out
if grep -q "^#\[multilib\]" /etc/pacman.conf; then
    echo "--> Enabling [multilib] repository in /etc/pacman.conf..."
    sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf 2>/dev/null || true
    sudo pacman -Sy --noconfirm 2>/dev/null || true
fi

# Always ensure stow is installed first
echo "--> Ensuring GNU Stow is installed..."
sudo pacman -S --needed --noconfirm stow

if [ -f "$PACKAGES_FILE" ]; then
    echo "--> Installing desktop and system packages from $PACKAGES_FILE..."
    # Read packages and filter out empty lines or comments
    packages=()
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        packages+=("$line")
    done < "$PACKAGES_FILE"

    if [ ${#packages[@]} -gt 0 ]; then
        sudo pacman -S --needed --noconfirm "${packages[@]}" || {
            echo "Warning: Some packages could not be installed in one batch. Trying individual packages..."
            for pkg in "${packages[@]}"; do
                sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null || echo "  [Skip] Package '$pkg' not found in active repositories."
            done
        }
    fi
fi

echo "==> Packages installation complete."

