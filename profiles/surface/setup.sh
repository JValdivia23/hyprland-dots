#!/usr/bin/env bash
# Microsoft Surface post-stow setup
set -euo pipefail

echo "==> Configuring Microsoft Surface Hardware Daemons..."

# 1. Enable Surface hardware services if installed
if systemctl list-unit-files surface-dtx-daemon.service &>/dev/null; then
    sudo systemctl enable --now surface-dtx-daemon.service 2>/dev/null || true
    echo "    Enabled surface-dtx-daemon.service"
fi

if systemctl list-unit-files iptsd.service &>/dev/null; then
    sudo systemctl enable --now iptsd.service 2>/dev/null || true
    echo "    Enabled iptsd.service"
fi

# 2. Prioritize linux-surface kernel in Limine bootloader if limine-entry-tool is present
if [ -d "/etc/limine-entry-tool.d" ]; then
    echo "--> Configuring Limine bootloader default kernel for Surface..."
    sudo bash -c 'cat > /etc/limine-entry-tool.d/zz-surface-kernel.conf << '\''LIMINE_EOF'\''
# Prioritize Surface kernel as default boot entry
BOOT_ORDER="linux-surface*, *, *fallback, Snapshots"
LIMINE_EOF'
    if command -v limine-update &>/dev/null; then
        sudo limine-update 2>/dev/null || true
    fi
fi

# 3. Deploy Surface tiered sleep & Modern Standby hibernate configurations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$SCRIPT_DIR/systemd" ]; then
    echo "--> Deploying Surface sleep & hibernation drop-ins..."
    if command -v sudo &>/dev/null; then
        sudo mkdir -p /etc/systemd/sleep.conf.d /etc/systemd/logind.conf.d
        if [ -f "$SCRIPT_DIR/systemd/10-suspend-then-hibernate.conf" ]; then
            sudo cp -v "$SCRIPT_DIR/systemd/10-suspend-then-hibernate.conf" /etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf
            sudo chmod 644 /etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf
        fi
        if [ -f "$SCRIPT_DIR/systemd/10-lid-sleep.conf" ]; then
            sudo cp -v "$SCRIPT_DIR/systemd/10-lid-sleep.conf" /etc/systemd/logind.conf.d/10-lid-sleep.conf
            sudo chmod 644 /etc/systemd/logind.conf.d/10-lid-sleep.conf
        fi
        sudo systemctl daemon-reload 2>/dev/null || true
    fi
fi

echo "==> Microsoft Surface setup finished."
