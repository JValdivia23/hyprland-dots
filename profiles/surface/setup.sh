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

echo "==> Microsoft Surface setup finished."
