#!/usr/bin/env bash
# Hardware setup script for Apple MacBook Pro 15,1 / T2 Subsystem
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Configuring Apple MacBook Pro / T2 Hardware Subsystem..."

# Verify if we are actually on Apple hardware
SYS_PRODUCT=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
if [[ ! "$SYS_PRODUCT" =~ MacBook ]]; then
    echo "    Notice: Host ($SYS_PRODUCT) is not an Apple MacBook. Skipping T2 hardware rules."
    exit 0
fi

# Deploy T2 Touch Bar sleep/resume fix and tiny-dfr if not yet installed
if [ -f "/etc/udev/rules.d/99-touchbar-tiny-dfr.rules" ] && [ -f "/etc/systemd/system/tiny-dfr.service" ]; then
    echo "    Apple T2 Touch Bar udev rules and services already deployed."
else
    echo "    Deploying Apple T2 Touch Bar fixes..."
    if command -v sudo &>/dev/null; then
        sudo bash "$SCRIPT_DIR/scripts/deploy-t2-touchbar-fix.sh" || echo "    Warning: Could not automatically deploy touch bar fixes."
    fi
fi

# Deploy AMDGPU AC/Battery power profile switch rule and boot service if AMD GPU present
if lspci 2>/dev/null | grep -iq "radeon"; then
    echo "    Deploying AMDGPU and PCIe ASPM power switching rules..."
    if command -v sudo &>/dev/null; then
        sudo cp -v "$SCRIPT_DIR/scripts/amdgpu-power-switch.sh" /usr/local/bin/amdgpu-power-switch.sh 2>/dev/null || true
        sudo chmod +x /usr/local/bin/amdgpu-power-switch.sh 2>/dev/null || true
        sudo cp -v "$SCRIPT_DIR/scripts/99-amdgpu-power.rules" /etc/udev/rules.d/99-amdgpu-power.rules 2>/dev/null || true
        sudo udevadm control --reload-rules 2>/dev/null || true
        sudo cp -v "$SCRIPT_DIR/scripts/amdgpu-power-setup.service" /etc/systemd/system/amdgpu-power-setup.service 2>/dev/null || true
        sudo systemctl daemon-reload 2>/dev/null || true
        sudo systemctl enable --now amdgpu-power-setup.service 2>/dev/null || true
    fi
fi

echo "==> Apple MacBook Pro setup finished."
