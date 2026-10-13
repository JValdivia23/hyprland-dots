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

# 2. Limine boot order: linux-cachyos (7.x + DKMS ipts, see step 10) first,
#    linux-surface kept second as the fully patched fallback.
SURFACE_BOOT_ORDER="linux-cachyos, linux-surface*, *, *lts, *fallback, Snapshots"
if [ -d "/etc/limine-entry-tool.d" ]; then
    echo "--> Configuring Limine bootloader default kernel for Surface..."
    sudo bash -c "cat > /etc/limine-entry-tool.d/zz-surface-kernel.conf << LIMINE_EOF
# Surface boot order: CachyOS kernel first, linux-surface fallback
BOOT_ORDER=\"$SURFACE_BOOT_ORDER\"
LIMINE_EOF"
elif [ -f "/etc/default/limine" ]; then
    echo "--> Setting Surface BOOT_ORDER in /etc/default/limine..."
    if grep -q '^BOOT_ORDER=' /etc/default/limine; then
        sudo sed -i "s/^BOOT_ORDER=.*/BOOT_ORDER=\"$SURFACE_BOOT_ORDER\"/" /etc/default/limine
    else
        echo "BOOT_ORDER=\"$SURFACE_BOOT_ORDER\"" | sudo tee -a /etc/default/limine >/dev/null
    fi
fi
if command -v limine-update &>/dev/null; then
    sudo limine-update 2>/dev/null || true
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
        if [ -f "$SCRIPT_DIR/scripts/surface-unplug-lid-handler.sh" ]; then
            echo "--> Deploying Surface AC unplug clamshell sleep handler..."
            sudo cp -v "$SCRIPT_DIR/scripts/surface-unplug-lid-handler.sh" /usr/local/bin/surface-unplug-lid-handler
            sudo chmod 755 /usr/local/bin/surface-unplug-lid-handler
        fi
        if [ -f "$SCRIPT_DIR/systemd/surface-unplug-lid.service" ]; then
            sudo cp -v "$SCRIPT_DIR/systemd/surface-unplug-lid.service" /etc/systemd/system/surface-unplug-lid.service
            sudo chmod 644 /etc/systemd/system/surface-unplug-lid.service
        fi
        if [ -f "$SCRIPT_DIR/systemd/98-surface-unplug-lid.rules" ]; then
            sudo cp -v "$SCRIPT_DIR/systemd/98-surface-unplug-lid.rules" /etc/udev/rules.d/98-surface-unplug-lid.rules
            sudo chmod 644 /etc/udev/rules.d/98-surface-unplug-lid.rules
            sudo udevadm control --reload-rules 2>/dev/null || true
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

# 5. Deploy IPTS asynchronous resume recovery & service timeout drop-in
if [ -d "$SCRIPT_DIR/systemd" ]; then
    if command -v sudo &>/dev/null; then
        if [ -f "$SCRIPT_DIR/scripts/surface-ipts-resume-recover.sh" ] && [ -f "$SCRIPT_DIR/systemd/surface-ipts-resume.service" ]; then
            echo "--> Deploying Surface IPTS asynchronous recovery worker..."
            sudo install -Dm755 "$SCRIPT_DIR/scripts/surface-ipts-resume-recover.sh" /usr/local/bin/surface-ipts-resume-recover
            sudo install -Dm644 "$SCRIPT_DIR/systemd/surface-ipts-resume.service" /etc/systemd/system/surface-ipts-resume.service
            sudo systemctl daemon-reload
        fi

        if [ -f "$SCRIPT_DIR/systemd/21-surface-ipts-resume.sh" ]; then
            echo "--> Deploying Surface IPTS resume hook..."
            sudo cp -v "$SCRIPT_DIR/systemd/21-surface-ipts-resume.sh" /etc/systemd/system-sleep/21-surface-ipts-resume.sh
            sudo chmod 755 /etc/systemd/system-sleep/21-surface-ipts-resume.sh

            # systemd-sleep scans /usr/lib only; keep the local dispatcher in /etc.
            ipts_dispatcher=/etc/systemd/system-sleep/21-surface-ipts-resume.sh
            ipts_hook=/usr/lib/systemd/system-sleep/21-surface-ipts-resume.sh
            if [[ -e "$ipts_hook" || -L "$ipts_hook" ]]; then
                if [[ ! -L "$ipts_hook" || "$(readlink -- "$ipts_hook")" != "$ipts_dispatcher" ]]; then
                    echo "Refusing to replace an unexpected IPTS sleep hook: $ipts_hook" >&2
                    exit 1
                fi
            else
                sudo mkdir -p /usr/lib/systemd/system-sleep
                sudo ln -s -- "$ipts_dispatcher" "$ipts_hook"
            fi
        fi

        if [ -f "$SCRIPT_DIR/systemd/iptsd-timeout.conf" ]; then
            echo "--> Deploying iptsd@.service timeout drop-in..."
            sudo mkdir -p /etc/systemd/system/iptsd@.service.d
            sudo cp -v "$SCRIPT_DIR/systemd/iptsd-timeout.conf" /etc/systemd/system/iptsd@.service.d/timeout.conf
            sudo chmod 644 /etc/systemd/system/iptsd@.service.d/timeout.conf
            sudo systemctl daemon-reload 2>/dev/null || true
        fi
    fi
fi

# 6. Configure ACPI lid wake quirk in Limine kernel command line
if [ -f "/etc/default/limine" ]; then
    if grep -q "button.lid_init_state=ignore" /etc/default/limine; then
        echo "--> Updating button.lid_init_state=ignore to button.lid_init_state=open in Limine cmdline..."
        sudo sed -i 's/button.lid_init_state=ignore/button.lid_init_state=open/' /etc/default/limine
        if command -v limine-entry-tool &>/dev/null; then
            echo "--> Updating Limine bootloader entries..."
            sudo limine-entry-tool || true
        fi
    elif ! grep -q "button.lid_init_state=open" /etc/default/limine; then
        echo "--> Appending button.lid_init_state=open to Limine cmdline..."
        sudo sed -i 's/\(resume=UUID=[^" ]*\)/\1 button.lid_init_state=open/' /etc/default/limine
        if command -v limine-entry-tool &>/dev/null; then
            echo "--> Updating Limine bootloader entries..."
            sudo limine-entry-tool || true
        fi
    fi
fi

# 7. Apply runtime kernel parameter for ACPI button lid_init_state if available
if [ -f "/sys/module/button/parameters/lid_init_state" ]; then
    echo "open" | sudo tee /sys/module/button/parameters/lid_init_state >/dev/null 2>&1 || true
fi

# 8. Restore the approved Surface-only LZ4 RAM-image default at each cold boot.
# This does not edit boot arguments, initramfs compression, or sleep timing.
if [ -f "$SCRIPT_DIR/scripts/surface-hibernate-compressor.sh" ] && [ -f "$SCRIPT_DIR/systemd/surface-hibernate-compressor.service" ]; then
    if command -v sudo &>/dev/null; then
        echo "--> Deploying Surface LZ4 hibernation compressor selection..."
        compressor_fragment="$(systemctl show surface-hibernate-compressor.service --value --property=FragmentPath)"
        if [[ -n "$compressor_fragment" && "$compressor_fragment" != /etc/systemd/system/surface-hibernate-compressor.service ]]; then
            echo "Refusing to shadow an unexpected compressor unit: $compressor_fragment" >&2
            exit 1
        fi
        for target in /usr/local/bin/surface-hibernate-compressor /etc/systemd/system/surface-hibernate-compressor.service; do
            if [[ -e "$target" || -L "$target" ]]; then
                if [[ "$target" == /usr/local/bin/* ]]; then
                    source="$SCRIPT_DIR/scripts/surface-hibernate-compressor.sh"
                else
                    source="$SCRIPT_DIR/systemd/surface-hibernate-compressor.service"
                fi
                if [[ -L "$target" ]] || ! cmp -s -- "$source" "$target"; then
                    echo "Refusing to replace an unexpected compressor file: $target" >&2
                    exit 1
                fi
            fi
        done
        if [[ ! -e /usr/local/bin/surface-hibernate-compressor ]]; then
            sudo install -Dm755 "$SCRIPT_DIR/scripts/surface-hibernate-compressor.sh" /usr/local/bin/surface-hibernate-compressor
        fi
        if [[ ! -e /etc/systemd/system/surface-hibernate-compressor.service ]]; then
            sudo install -Dm644 "$SCRIPT_DIR/systemd/surface-hibernate-compressor.service" /etc/systemd/system/surface-hibernate-compressor.service
        fi
        sudo systemctl daemon-reload
        sudo systemctl enable --now surface-hibernate-compressor.service
    fi
fi

# 9. Deploy Surface IPTSD touchscreen session uaccess rule for gesture daemon (lisgd)
if [ -f "$SCRIPT_DIR/systemd/71-iptsd-touchscreen-uaccess.rules" ]; then
    echo "--> Deploying Surface IPTSD touchscreen uaccess rule..."
    if command -v sudo &>/dev/null; then
        sudo cp -v "$SCRIPT_DIR/systemd/71-iptsd-touchscreen-uaccess.rules" /etc/udev/rules.d/71-iptsd-touchscreen-uaccess.rules
        sudo chmod 644 /etc/udev/rules.d/71-iptsd-touchscreen-uaccess.rules
        sudo udevadm control --reload-rules 2>/dev/null || true
        sudo udevadm trigger -s input 2>/dev/null || true
    fi
fi

# 10. IPTS touch/pen on non-linux-surface kernels (linux-cachyos 7.x):
#     DKMS-built out-of-tree ipts + udev-triggered mei_me binder for 8086:34e4.
IPTS_DKMS_SRC="$SCRIPT_DIR/dkms/ipts"
if [ -f "$IPTS_DKMS_SRC/dkms.conf" ] && command -v dkms &>/dev/null && command -v sudo &>/dev/null; then
    ipts_ver="$(sed -n 's/^PACKAGE_VERSION="\(.*\)"/\1/p' "$IPTS_DKMS_SRC/dkms.conf")"
    echo "--> Deploying DKMS ipts/$ipts_ver (CachyOS kernels only)..."
    sudo rm -rf "/usr/src/ipts-$ipts_ver"
    sudo cp -r "$IPTS_DKMS_SRC" "/usr/src/ipts-$ipts_ver"
    dkms status -m ipts -v "$ipts_ver" 2>/dev/null | grep -q . || sudo dkms add -m ipts -v "$ipts_ver"
    sudo dkms autoinstall || true

    if [ -f "$SCRIPT_DIR/scripts/surface-ipts-mei-bind.sh" ] && [ -f "$SCRIPT_DIR/systemd/72-surface-ipts-mei-bind.rules" ]; then
        echo "--> Deploying Surface iTouch mei_me binder..."
        sudo install -Dm755 "$SCRIPT_DIR/scripts/surface-ipts-mei-bind.sh" /usr/local/bin/surface-ipts-mei-bind
        sudo install -Dm644 "$SCRIPT_DIR/systemd/72-surface-ipts-mei-bind.rules" /etc/udev/rules.d/72-surface-ipts-mei-bind.rules
        sudo udevadm control --reload-rules 2>/dev/null || true
        sudo /usr/local/bin/surface-ipts-mei-bind || true
    fi
fi

echo "==> Microsoft Surface setup finished."
