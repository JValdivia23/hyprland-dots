#!/usr/bin/env bash
set -euo pipefail

echo "==> [3/4] Configuring system services and firewall..."

# Enable Bluetooth if available
if systemctl list-unit-files bluetooth.service &>/dev/null; then
    echo "--> Enabling bluetooth.service..."
    sudo systemctl enable --now bluetooth.service || true
fi

# Enable UFW and configure LocalSend port rule (port 53317)
if command -v ufw &>/dev/null; then
    echo "--> Configuring UFW firewall rules..."
    sudo systemctl enable --now ufw.service || true
    sudo ufw allow 53317/tcp comment 'LocalSend TCP' || true
    sudo ufw allow 53317/udp comment 'LocalSend UDP' || true
    sudo ufw --force enable || true
fi

# Enable ASUS ROG / power management services if on ASUS hardware
if systemctl list-unit-files asusd.service &>/dev/null; then
    echo "--> Enabling asusd.service..."
    sudo systemctl enable --now asusd.service || true
fi

if systemctl list-unit-files supergfxd.service &>/dev/null; then
    echo "--> Enabling supergfxd.service..."
    sudo systemctl enable --now supergfxd.service || true
fi

echo "==> System services configuration complete."
