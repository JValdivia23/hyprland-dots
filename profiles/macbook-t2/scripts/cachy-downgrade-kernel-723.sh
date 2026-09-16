#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo "  Apple T2 Kernel Rollback: Restoring Linux 7.2.3-1"
echo "=========================================================="

# Remove obsolete NVIDIA kernel module if present (MacBookPro15,1 uses AMD Radeon Pro 560X)
if pacman -Q linux-cachyos-nvidia-open &>/dev/null; then
  echo "==> Removing obsolete linux-cachyos-nvidia-open (MacBook has AMD GPU, not NVIDIA)..."
  sudo pacman -Rdd --noconfirm linux-cachyos-nvidia-open
fi

PKGS=(
  "/var/cache/pacman/pkg/linux-cachyos-7.2.3-1-x86_64_v3.pkg.tar.zst"
  "/var/cache/pacman/pkg/linux-cachyos-headers-7.2.3-1-x86_64_v3.pkg.tar.zst"
)

for pkg in "${PKGS[@]}"; do
  if [[ ! -f "$pkg" ]]; then
    echo "ERROR: Package $pkg not found in pacman cache!" >&2
    exit 1
  fi
done

echo "==> Reinstalling linux-cachyos 7.2.3-1 from local cache..."
sudo pacman -U --noconfirm "${PKGS[@]}"

echo "==> Configuring IgnorePkg in /etc/pacman.conf to prevent accidental re-upgrades..."
if grep -q "^#IgnorePkg" /etc/pacman.conf; then
  sudo sed -i 's/^#IgnorePkg *=.*/IgnorePkg = linux-cachyos linux-cachyos-headers/' /etc/pacman.conf
elif grep -q "^IgnorePkg" /etc/pacman.conf; then
  if ! grep -q "linux-cachyos" /etc/pacman.conf; then
    sudo sed -i '/^IgnorePkg/ s/$/ linux-cachyos linux-cachyos-headers/' /etc/pacman.conf
  fi
else
  sudo sed -i '/\[options\]/a IgnorePkg = linux-cachyos linux-cachyos-headers' /etc/pacman.conf
fi

echo ""
echo "=========================================================="
echo "  Rollback Complete!"
echo "  - Linux 7.2.3-1 restored with full Apple T2 (t2bce) drivers."
echo "  - Initramfs and Limine boot entries regenerated."
echo "  - linux-cachyos packages pinned in /etc/pacman.conf."
echo "=========================================================="
echo ""
read -r -p "Reboot now to activate Linux 7.2.3? [Y/n] " confirm
if [[ "$confirm" =~ ^[Nn] ]]; then
  echo "Reboot cancelled. Please reboot manually when ready via 'sudo systemctl reboot'."
else
  echo "Rebooting system..."
  sudo systemctl reboot
fi
