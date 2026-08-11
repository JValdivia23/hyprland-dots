#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_FILE="$DOTFILES_DIR/packages/pacman-packages.txt"

echo "==> [1/4] Installing system packages via pacman..."

if ! command -v pacman &>/dev/null; then
    echo "Error: pacman not found. This installation script is designed for Arch Linux / CachyOS." >&2
    exit 1
fi

if [ -f "$PACKAGES_FILE" ]; then
    echo "--> Installing explicitly defined packages from $PACKAGES_FILE..."
    sudo pacman -S --needed --noconfirm stow - < "$PACKAGES_FILE"
else
    echo "--> Installing core stow package..."
    sudo pacman -S --needed --noconfirm stow
fi

echo "==> Packages installation complete."
