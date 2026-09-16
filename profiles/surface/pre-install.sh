#!/usr/bin/env bash
# Microsoft Surface pre-install hook: configure [linux-surface] repository
set -euo pipefail

echo "==> [Surface] Checking linux-surface package repository..."

if ! grep -q "\[linux-surface\]" /etc/pacman.conf 2>/dev/null; then
    echo "--> Adding [linux-surface] official repository to /etc/pacman.conf..."
    if command -v curl &>/dev/null && command -v pacman-key &>/dev/null; then
        curl -s https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc | sudo pacman-key --add -
        sudo pacman-key --finger 56C464BAAC421453
        sudo pacman-key --lsign-key 56C464BAAC421453
    fi

    sudo bash -c 'cat >> /etc/pacman.conf << '\''REPO_EOF'\''

[linux-surface]
Server = https://pkg.surfacelinux.org/arch/
REPO_EOF'
    sudo pacman -Sy
    echo "--> [linux-surface] repository configured successfully."
else
    echo "    [linux-surface] repository already present in /etc/pacman.conf."
fi
