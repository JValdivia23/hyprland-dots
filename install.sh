#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================================="
echo "   CachyOS / Arch Dotfiles & Environment Installer     "
echo "   Hyprland (Lua) | Noctalia | Kitty | Fish | Stow    "
echo "======================================================="
echo ""

# Parse flags if any
DO_PACKAGES=true
DO_STOW=true
DO_SERVICES=true
DO_SHELL=true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --only-stow)
            DO_PACKAGES=false
            DO_SERVICES=false
            DO_SHELL=false
            shift
            ;;
        --only-packages)
            DO_STOW=false
            DO_SERVICES=false
            DO_SHELL=false
            shift
            ;;
        --help|-h)
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --only-stow      Only deploy symlinks with GNU Stow"
            echo "  --only-packages  Only install system packages"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
done

if [ "$DO_PACKAGES" = true ]; then
    bash "$DOTFILES_DIR/scripts/01-packages.sh"
    echo ""
fi

if [ "$DO_STOW" = true ]; then
    bash "$DOTFILES_DIR/scripts/02-stow.sh"
    echo ""
fi

if [ "$DO_SERVICES" = true ]; then
    bash "$DOTFILES_DIR/scripts/03-services.sh"
    echo ""
fi

if [ "$DO_SHELL" = true ]; then
    bash "$DOTFILES_DIR/scripts/04-shell.sh"
    echo ""
fi

echo "======================================================="
echo "  🎉 Installation & Dotfiles Deployment Complete!     "
echo "======================================================="
echo "Next steps:"
echo "  1. If Noctalia is running: run 'noctalia msg reload'"
echo "  2. Test your shortcuts: Super+Space (Launcher), Super+Return (Kitty)"
echo "  3. Log out and log back in to load all session variables."
echo "======================================================="
