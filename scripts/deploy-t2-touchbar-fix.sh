#!/bin/bash
set -e

echo "=== Deploying Apple T2 Touch Bar Boot & Sleep/Resume Fix ==="

# 1. Install blacklist
echo "[1/5] Installing modprobe blacklist for hid_appletb_kbd..."
cp -v /home/java1127/dotfiles/scripts/blacklist-touchbar.conf /etc/modprobe.d/blacklist-touchbar.conf

# 2. Install udev rules
echo "[2/5] Installing udev rules for Touch Bar USB Configuration 2..."
cp -v /home/java1127/dotfiles/scripts/99-touchbar-tiny-dfr.rules /etc/udev/rules.d/99-touchbar-tiny-dfr.rules
udevadm control --reload-rules

# 3. Install sleep helper
echo "[3/5] Installing updated /usr/local/bin/t2-sleep-helper..."
cp -v /home/java1127/dotfiles/scripts/t2-sleep-helper /usr/local/bin/t2-sleep-helper
chmod +x /usr/local/bin/t2-sleep-helper

# 4. Install systemd services
echo "[4/5] Installing and enabling systemd units..."
cp -v /home/java1127/dotfiles/scripts/tiny-dfr.service /etc/systemd/system/tiny-dfr.service
cp -v /home/java1127/dotfiles/scripts/t2-touchbar-setup.service /etc/systemd/system/t2-touchbar-setup.service
systemctl daemon-reload
systemctl enable t2-touchbar-setup.service

# 5. Run post initialization
echo "[5/5] Running live initialization..."
/usr/local/bin/t2-sleep-helper post

echo ""
echo "=== Deployment & Verification Complete! ==="
sleep 2
systemctl status tiny-dfr.service --no-pager
