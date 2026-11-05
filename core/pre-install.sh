#!/bin/bash
# Universal Core Pre-Install Hook
set -euo pipefail

# Configure flea-cachyos repository if not present
if ! grep -q '\[flea-cachyos\]' /etc/pacman.conf 2>/dev/null; then
    echo "--> [core/pre-install] Adding flea-cachyos repository to /etc/pacman.conf..."
    KEY_TMP=$(mktemp -t flea-key.XXXXXX.asc)
    if curl -fsSL "https://raw.githubusercontent.com/gcap0n1/flea-CachyOS/cachyos/packaging/repo/flea-cachyos.asc" -o "$KEY_TMP"; then
        if (( EUID == 0 )); then
            pacman-key --add "$KEY_TMP"
            pacman-key --lsign-key 324642F2730F085206D72AFE933E75887CEFE703
            tee -a /etc/pacman.conf > /dev/null << 'EOF'

[flea-cachyos]
SigLevel = Required
Server = https://github.com/gcap0n1/flea-CachyOS/releases/download/repo
EOF
        else
            sudo pacman-key --add "$KEY_TMP"
            sudo pacman-key --lsign-key 324642F2730F085206D72AFE933E75887CEFE703
            sudo tee -a /etc/pacman.conf > /dev/null << 'EOF'

[flea-cachyos]
SigLevel = Required
Server = https://github.com/gcap0n1/flea-CachyOS/releases/download/repo
EOF
        fi
        rm -f "$KEY_TMP"
        echo "--> [core/pre-install] Repository flea-cachyos configured."
    fi
fi
