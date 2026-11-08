#!/usr/bin/env bash
# Workstation Desktop Profile Setup (cachyos-obsidian / MSI MS-7D75 / AMD RDNA 3)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Initializing Workstation Desktop Profile..."

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo &>/dev/null; then
        SUDO="sudo"
    fi
fi

# 1. Deploy Logitech G903 LIGHTSPEED libinput quirks to /etc/libinput/
QUIRKS_SRC="$SCRIPT_DIR/.config/libinput/local-overrides.quirks"
QUIRKS_DEST="/etc/libinput/local-overrides.quirks"
if [ -f "$QUIRKS_SRC" ]; then
    if [ -f "$QUIRKS_DEST" ] && cmp -s "$QUIRKS_SRC" "$QUIRKS_DEST"; then
        echo "    [libinput] Logitech G903 scroll quirks already deployed at $QUIRKS_DEST."
    elif [ -n "$SUDO" ] || [ "$(id -u)" -eq 0 ]; then
        echo "    [libinput] Deploying Logitech G903 XWayland scroll quirks to $QUIRKS_DEST..."
        $SUDO mkdir -p /etc/libinput
        $SUDO cp -v "$QUIRKS_SRC" "$QUIRKS_DEST"
        $SUDO udevadm trigger --action=change 2>/dev/null || true
    else
        echo "    Notice: Run 'sudo cp $QUIRKS_SRC $QUIRKS_DEST && sudo udevadm trigger --action=change' to apply Logitech G903 libinput quirks."
    fi
fi

# 2. Check AMD RDNA 3 DisplayPort blanking mitigation parameters
if lspci 2>/dev/null | grep -qiE "Navi 3|RX 7[0-9]{3}"; then
    if ! grep -q "amdgpu.dcdebugmask=0x10" /proc/cmdline 2>/dev/null; then
        echo "    [AMDGPU] Notice: RDNA 3 GPU detected without 'amdgpu.dcdebugmask=0x10 amdgpu.sg_display=0' in kernel cmdline."
        echo "             If DisplayPort 1-2s blanking occurs, add those parameters to /etc/sdboot-manage.conf (or bootloader config)."
    else
        echo "    [AMDGPU] RDNA 3 DisplayPort stability parameters verified in kernel cmdline."
    fi
fi

echo "==> Workstation Desktop Profile setup complete."
