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

# 4. Deploy Surface dual-battery UPower desync watchdog
if [ -f "$SCRIPT_DIR/scripts/surface-battery-watchdog.sh" ]; then
    echo "--> Deploying Surface dual-battery UPower watchdog..."
    if command -v sudo &>/dev/null; then
        sudo mkdir -p /etc/udev/rules.d /etc/systemd/system /etc/systemd/system-sleep
        sudo cp -v "$SCRIPT_DIR/scripts/surface-battery-watchdog.sh" /usr/local/bin/surface-battery-watchdog
        sudo chmod 755 /usr/local/bin/surface-battery-watchdog

        if [ -f "$SCRIPT_DIR/systemd/surface-battery-watchdog.service" ]; then
            sudo cp -v "$SCRIPT_DIR/systemd/surface-battery-watchdog.service" /etc/systemd/system/surface-battery-watchdog.service
            sudo chmod 644 /etc/systemd/system/surface-battery-watchdog.service
        fi
        if [ -f "$SCRIPT_DIR/systemd/surface-battery-watchdog.timer" ]; then
            sudo cp -v "$SCRIPT_DIR/systemd/surface-battery-watchdog.timer" /etc/systemd/system/surface-battery-watchdog.timer
            sudo chmod 644 /etc/systemd/system/surface-battery-watchdog.timer
            sudo systemctl daemon-reload 2>/dev/null || true
            sudo systemctl enable --now surface-battery-watchdog.timer 2>/dev/null || true
        fi
        if [ -f "$SCRIPT_DIR/systemd/99-surface-battery.rules" ]; then
            sudo cp -v "$SCRIPT_DIR/systemd/99-surface-battery.rules" /etc/udev/rules.d/99-surface-battery.rules
            sudo chmod 644 /etc/udev/rules.d/99-surface-battery.rules
            sudo udevadm control --reload-rules 2>/dev/null || true
        fi
        if [ -f "$SCRIPT_DIR/systemd/20-surface-battery-resume.sh" ]; then
            sudo cp -v "$SCRIPT_DIR/systemd/20-surface-battery-resume.sh" /etc/systemd/system-sleep/20-surface-battery-resume.sh
            sudo chmod 755 /etc/systemd/system-sleep/20-surface-battery-resume.sh
        fi
    fi
fi

echo "==> Microsoft Surface setup finished."
