#!/usr/bin/env bash
# Apply MacBookPro15,1 Suspend/Resume optimizations
set -euo pipefail

echo "==> [1/6] Disabling and masking kait2en-dgpu-suspend.service..."
systemctl disable --now kait2en-dgpu-suspend.service 2>/dev/null || true
systemctl mask kait2en-dgpu-suspend.service 2>/dev/null || true

echo "==> [2/6] Updating /usr/local/bin/t2-sleep-helper..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp -v "$SCRIPT_DIR/t2-sleep-helper" /usr/local/bin/t2-sleep-helper
chmod 0755 /usr/local/bin/t2-sleep-helper

echo "==> [3/7] Enforcing systemd MemorySleepMode=s2idle..."
mkdir -p /etc/systemd/sleep.conf.d
cp -v "$SCRIPT_DIR/s2idle.conf" /etc/systemd/sleep.conf.d/s2idle.conf
if [ -w /sys/power/mem_sleep ]; then
    echo s2idle > /sys/power/mem_sleep
fi

echo "==> [4/6] Updating Limine bootloader with mem_sleep_default=s2idle..."
cp -v "$SCRIPT_DIR/t2-mac.conf" /etc/limine-entry-tool.d/t2-mac.conf
if command -v limine-entry-tool &>/dev/null; then
    limine-entry-tool || true
elif command -v limine-update &>/dev/null; then
    limine-update || true
fi

echo "==> [5/6] Deploying plocate-updatedb.timer override (Persistent=false)..."
mkdir -p /etc/systemd/system/plocate-updatedb.timer.d
cp -v "$SCRIPT_DIR/plocate-timer-override.conf" /etc/systemd/system/plocate-updatedb.timer.d/override.conf
systemctl daemon-reload
systemctl restart plocate-updatedb.timer 2>/dev/null || true

echo "==> [6/6] Disabling IPv6 DAD on t2_ncm (instant Touch ID on wake)..."
cp -v "$SCRIPT_DIR/99-t2-ncm.conf" /etc/sysctl.d/99-t2-ncm.conf
sysctl -p /etc/sysctl.d/99-t2-ncm.conf 2>/dev/null || true

echo "==> Suspend speedup optimizations applied successfully!"
