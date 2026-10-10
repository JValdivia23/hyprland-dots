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

# Ensure sudo is available
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo &>/dev/null; then
        SUDO="sudo"
    else
        echo "    Error: Root privileges required but sudo is not installed." >&2
        exit 1
    fi
fi

# 1. Deploy T2 Touch Bar sleep/resume fix and tiny-dfr / kait2en-touchbar
if [ -f "/etc/udev/rules.d/99-touchbar-tiny-dfr.rules" ] && [ -f "/etc/systemd/system/tiny-dfr.service" ]; then
    echo "    [Touch Bar] udev rules and services already deployed."
else
    echo "    [Touch Bar] Deploying Touch Bar udev rules and fixes..."
    $SUDO bash "$SCRIPT_DIR/scripts/deploy-t2-touchbar-fix.sh" || echo "    Warning: Could not automatically deploy touch bar fixes."
fi

# 2. Deploy T2 Sleep / Suspend Helper
if [ -f "$SCRIPT_DIR/scripts/t2-sleep-helper" ]; then
    echo "    [Sleep/Resume] Deploying T2 sleep helper and suspend-fix service..."
    $SUDO cp -v "$SCRIPT_DIR/scripts/t2-sleep-helper" /usr/local/bin/t2-sleep-helper
    $SUDO chmod 0755 /usr/local/bin/t2-sleep-helper
    if [ -f "$SCRIPT_DIR/scripts/suspend-fix-t2.service" ]; then
        $SUDO cp -v "$SCRIPT_DIR/scripts/suspend-fix-t2.service" /etc/systemd/system/suspend-fix-t2.service
        $SUDO systemctl daemon-reload
        $SUDO systemctl enable suspend-fix-t2.service 2>/dev/null || true
    fi
fi

# 3. Deploy Dual-GPU (Apple GMUX iGPU Boot & AMD dGPU Power Management)
echo "    [GPU] Configuring Apple GMUX dual-GPU and power-saving subsystem..."

# Modprobe: Force GMUX to switch internal display to Intel UHD 630
if [ -f "$SCRIPT_DIR/scripts/apple-gmux.conf" ]; then
    echo "    [GPU] Deploying apple-gmux force_igd=y to /etc/modprobe.d/..."
    $SUDO cp -v "$SCRIPT_DIR/scripts/apple-gmux.conf" /etc/modprobe.d/apple-gmux.conf
fi

# Libexec helpers: t2-dgpu-control-helper and t2-dgpu-control-status
$SUDO mkdir -p /usr/local/libexec
if [ -f "$SCRIPT_DIR/scripts/t2-dgpu-control-helper" ]; then
    echo "    [GPU] Deploying t2-dgpu-control-helper to /usr/local/libexec/..."
    $SUDO cp -v "$SCRIPT_DIR/scripts/t2-dgpu-control-helper" /usr/local/libexec/t2-dgpu-control-helper
    $SUDO chmod 0755 /usr/local/libexec/t2-dgpu-control-helper
fi
if [ -f "$SCRIPT_DIR/scripts/t2-dgpu-control-status" ]; then
    $SUDO cp -v "$SCRIPT_DIR/scripts/t2-dgpu-control-status" /usr/local/libexec/t2-dgpu-control-status
    $SUDO chmod 0755 /usr/local/libexec/t2-dgpu-control-status
fi

# Systemd services: kait2en-dgpu-off and kait2en-dgpu-suspend
if [ -f "$SCRIPT_DIR/scripts/kait2en-dgpu-off.service" ]; then
    echo "    [GPU] Deploying kait2en-dgpu-off.service and kait2en-dgpu-suspend.service..."
    $SUDO cp -v "$SCRIPT_DIR/scripts/kait2en-dgpu-off.service" /etc/systemd/system/kait2en-dgpu-off.service
    $SUDO cp -v "$SCRIPT_DIR/scripts/kait2en-dgpu-suspend.service" /etc/systemd/system/kait2en-dgpu-suspend.service
    $SUDO systemctl daemon-reload
    $SUDO systemctl enable kait2en-dgpu-off.service kait2en-dgpu-suspend.service 2>/dev/null || true
fi

# AMDGPU fallback power profile switch rules (for when dGPU is powered)
if [ -f "$SCRIPT_DIR/scripts/amdgpu-power-switch.sh" ]; then
    $SUDO cp -v "$SCRIPT_DIR/scripts/amdgpu-power-switch.sh" /usr/local/bin/amdgpu-power-switch.sh
    $SUDO chmod 0755 /usr/local/bin/amdgpu-power-switch.sh
    $SUDO cp -v "$SCRIPT_DIR/scripts/99-amdgpu-power.rules" /etc/udev/rules.d/99-amdgpu-power.rules
    $SUDO udevadm control --reload-rules 2>/dev/null || true
    $SUDO cp -v "$SCRIPT_DIR/scripts/amdgpu-power-setup.service" /etc/systemd/system/amdgpu-power-setup.service
    $SUDO systemctl enable amdgpu-power-setup.service 2>/dev/null || true
fi

# Initramfs: mkinitcpio drop-in for i915
if [ -d "/etc/mkinitcpio.conf.d" ] && [ -f "$SCRIPT_DIR/scripts/20-apple-igpu.conf" ]; then
    echo "    [GPU] Ensuring i915? module is configured in /etc/mkinitcpio.conf.d/..."
    $SUDO cp -v "$SCRIPT_DIR/scripts/20-apple-igpu.conf" /etc/mkinitcpio.conf.d/20-apple-igpu.conf
fi

# Bootloader: Limine i915.enable_guc=3 kernel commandline
if [ -f "/etc/default/limine" ]; then
    if ! grep -q "i915.enable_guc=3" /etc/default/limine; then
        echo "    [Limine] Adding i915.enable_guc=3 to KERNEL_CMDLINE[default]..."
        $SUDO sed -i 's/\(KERNEL_CMDLINE\[default\]+="[^"]*\)/\1 i915.enable_guc=3/' /etc/default/limine
        if command -v limine-update &>/dev/null; then
            echo "    [Limine] Running limine-update to refresh boot entries..."
            $SUDO limine-update || true
        fi
    else
        echo "    [Limine] i915.enable_guc=3 already present in /etc/default/limine."
    fi
fi

# Bootloader: rEFInd spoof_osx_version 10.9 (apple-set-os protocol) & entry deduplication
if [ -f "/boot/EFI/refind/refind.conf" ]; then
    # Enable macOS version spoofing for Intel iGPU unhide
    if ! grep -Eq '^[[:space:]]*spoof_osx_version[[:space:]]+10\.9' /boot/EFI/refind/refind.conf; then
        echo "    [rEFInd] Configuring spoof_osx_version 10.9 in /boot/EFI/refind/refind.conf..."
        $SUDO sed -i 's/^[[:space:]]*spoof_osx_version.*/# &/' /boot/EFI/refind/refind.conf
        echo "spoof_osx_version 10.9" | $SUDO tee -a /boot/EFI/refind/refind.conf >/dev/null
    else
        echo "    [rEFInd] spoof_osx_version 10.9 already enabled."
    fi

    # Ignore factory EFI partition (prevents duplicate Arch/Limine entries)
    if ! grep -Eq '^[[:space:]]*dont_scan_volumes[[:space:]]+.*"EFI"' /boot/EFI/refind/refind.conf; then
        echo "    [rEFInd] Configuring dont_scan_volumes \"EFI\" to eliminate duplicate entries..."
        echo 'dont_scan_volumes "EFI"' | $SUDO tee -a /boot/EFI/refind/refind.conf >/dev/null
    fi

    # Ignore fallback bootloader in EFI/BOOT
    if ! grep -Eq '^[[:space:]]*dont_scan_dirs[[:space:]]+.*"EFI/BOOT"' /boot/EFI/refind/refind.conf; then
        echo "    [rEFInd] Configuring dont_scan_dirs \"EFI/BOOT\" to hide fallback loader..."
        echo 'dont_scan_dirs "EFI/BOOT"' | $SUDO tee -a /boot/EFI/refind/refind.conf >/dev/null
    fi

    # Safety guard: ensure invalid apple_set_os.efi is not in drivers_x64 (prevents boot hang)
    if [ -f "/boot/EFI/refind/drivers_x64/apple_set_os.efi" ]; then
        echo "    [rEFInd] Removing hazardous apple_set_os.efi from drivers_x64..."
        $SUDO rm -f "/boot/EFI/refind/drivers_x64/apple_set_os.efi"
    fi
fi

# 4. Deploy T2 Fan Control Configuration (t2fanrd)
if [ -f "$SCRIPT_DIR/scripts/t2fand.conf" ]; then
    echo "    [Thermals] Deploying /etc/t2fand.conf..."
    $SUDO cp -v "$SCRIPT_DIR/scripts/t2fand.conf" /etc/t2fand.conf
    if systemctl list-unit-files t2fanrd.service &>/dev/null; then
        $SUDO systemctl enable --now t2fanrd.service 2>/dev/null || true
    fi
fi

# 5. Deploy T2 CPU Control Configuration & Service
if [ -f "$SCRIPT_DIR/scripts/t2-cpu-control.conf" ]; then
    echo "    [CPU] Deploying /etc/t2-cpu-control.conf and service..."
    $SUDO cp -v "$SCRIPT_DIR/scripts/t2-cpu-control.conf" /etc/t2-cpu-control.conf
    if [ -f "$SCRIPT_DIR/scripts/t2-cpu-control.service" ]; then
        $SUDO cp -v "$SCRIPT_DIR/scripts/t2-cpu-control.service" /etc/systemd/system/t2-cpu-control.service
        $SUDO systemctl daemon-reload
        $SUDO systemctl enable t2-cpu-control.service 2>/dev/null || true
    fi
fi

# 6. Deploy T2 Touch ID Integration (t2-touchid)
if [ -f "$SCRIPT_DIR/scripts/t2-touchid.conf" ]; then
    echo "    [Touch ID] Deploying /etc/t2-touchid.conf..."
    $SUDO cp -v "$SCRIPT_DIR/scripts/t2-touchid.conf" /etc/t2-touchid.conf
    if [ -f "$SCRIPT_DIR/scripts/fprintd-kait2en-t2-touchid.conf" ]; then
        $SUDO mkdir -p /etc/systemd/system/fprintd.service.d
        $SUDO cp -v "$SCRIPT_DIR/scripts/fprintd-kait2en-t2-touchid.conf" /etc/systemd/system/fprintd.service.d/kait2en-t2-touchid.conf
    fi
    if [ -f "$SCRIPT_DIR/scripts/kait2en-t2-touchid.service" ]; then
        $SUDO cp -v "$SCRIPT_DIR/scripts/kait2en-t2-touchid.service" /etc/systemd/system/kait2en-t2-touchid.service
        $SUDO systemctl daemon-reload
        $SUDO systemctl enable kait2en-t2-touchid.service 2>/dev/null || true
    fi
    # Configure greetd for Touch ID fingerprint login
    if [ -f "/etc/pam.d/greetd" ]; then
        if ! grep -q "pam_fprintd.so" /etc/pam.d/greetd; then
            echo "    [Touch ID] Adding pam_fprintd.so to /etc/pam.d/greetd..."
            if grep -q "pam_nologin.so" /etc/pam.d/greetd; then
                $SUDO sed -i '/pam_nologin.so/a auth       sufficient   pam_fprintd.so' /etc/pam.d/greetd
            else
                $SUDO sed -i '1a auth       sufficient   pam_fprintd.so' /etc/pam.d/greetd
            fi
        fi
    fi
fi

echo "==> Apple MacBook Pro setup finished."
