#!/usr/bin/env bash
# Workstation Desktop Profile Setup (cachyos-obsidian / MSI MS-7D75 / AMD RDNA 3 / Personalized Quickshell)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Initializing Workstation Desktop Profile (Personalized Quickshell + AMD RDNA 3)..."

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo &>/dev/null; then
        SUDO="sudo"
    fi
fi

# 1. Deploy Logitech G903 LIGHTSPEED libinput quirks to /etc/libinput/
QUIRKS_SRC="$SCRIPT_DIR/.config/libinput/local-overrides.quirks"
QUIRKS_DEST="/etc/libinput/local-overrides.quirks"
if [ -f "$QUIRKS_SRC" ]; then
    if [ -f "$QUIRKS_DEST" ] && cmp -s "$QUIRKS_SRC" "$QUIRKS_DEST"; then
        echo "    [libinput] Logitech G903 scroll quirks already deployed at $QUIRKS_DEST."
    elif [ -n "$SUDO" ] || [ "$(id -u)" -eq 0 ]; then
        echo "    [libinput] Deploying Logitech G903 XWayland scroll quirks to $QUIRKS_DEST..."
        $SUDO mkdir -p /etc/libinput
        $SUDO cp -v "$QUIRKS_SRC" "$QUIRKS_DEST"
        $SUDO udevadm trigger --action=change 2>/dev/null || true
    else
        echo "    Notice: Run 'sudo cp $QUIRKS_SRC $QUIRKS_DEST && sudo udevadm trigger --action=change' to apply Logitech G903 libinput quirks."
    fi
fi

# 2. Ensure Quickshell weather location file and state directories exist
mkdir -p "$HOME/.config/omarchy/weather" \
         "$HOME/.local/state/quickshell-desktop"
[ -f "$HOME/.config/omarchy/weather/location" ] || touch "$HOME/.config/omarchy/weather/location"

# 3. Compile & enable G903 MOUSE5 double-V daemon + Quickshell Rise bar background timers
G903_SRC="$SCRIPT_DIR/scripts/g903-mouse5-daemon.c"
G903_BIN="$SCRIPT_DIR/.local/bin/g903-mouse5-daemon"
if [ -f "$G903_SRC" ] && command -v gcc &>/dev/null; then
    if [ ! -x "$G903_BIN" ] || [ "$G903_SRC" -nt "$G903_BIN" ]; then
        echo "    [G903] Compiling g903-mouse5-daemon..."
        gcc -O3 -Wall -Wextra -pthread "$G903_SRC" -lm -o "$G903_BIN"
    fi
fi

if command -v systemctl &>/dev/null; then
    systemctl --user daemon-reload 2>/dev/null || true
    if [ -f "$HOME/.config/systemd/user/g903-mouse5.service" ]; then
        systemctl --user enable --now g903-mouse5.service 2>/dev/null || true
    fi
    for timer in qs-aur-blacklist-fetch.timer qs-shell-update-check.timer; do
        if [ -f "$HOME/.config/systemd/user/$timer" ]; then
            systemctl --user enable --now "$timer" 2>/dev/null || true
        fi
    done
fi

# 4. Deploy RX 7700 XT (1002:747e) DPM udev rule & resume hook (prevents mixed-refresh MCLK/FCLK flicker)
DPM_RULE_SRC="$SCRIPT_DIR/scripts/99-amdgpu-rx7700xt-dpm.rules"
DPM_RULE_DEST="/etc/udev/rules.d/99-amdgpu-rx7700xt-dpm.rules"
DPM_SLEEP_SRC="$SCRIPT_DIR/scripts/amdgpu-rx7700xt-dpm-sleep"
DPM_SLEEP_DEST="/usr/lib/systemd/system-sleep/amdgpu-rx7700xt-dpm"
if [ -f "$DPM_RULE_SRC" ] && [ -f "$DPM_SLEEP_SRC" ]; then
    if [ -f "$DPM_RULE_DEST" ] && cmp -s "$DPM_RULE_SRC" "$DPM_RULE_DEST" && \
       [ -x "$DPM_SLEEP_DEST" ] && cmp -s "$DPM_SLEEP_SRC" "$DPM_SLEEP_DEST"; then
        echo "    [AMDGPU] RX 7700 XT DPM udev rule & sleep hook already deployed."
    elif [ -n "$SUDO" ] || [ "$(id -u)" -eq 0 ]; then
        echo "    [AMDGPU] Deploying RX 7700 XT DPM udev rule & resume hook..."
        $SUDO install -Dm644 "$DPM_RULE_SRC" "$DPM_RULE_DEST"
        $SUDO install -Dm755 "$DPM_SLEEP_SRC" "$DPM_SLEEP_DEST"
        $SUDO udevadm control --reload-rules 2>/dev/null || true
        $SUDO udevadm trigger --subsystem-match=drm --action=change 2>/dev/null || true
    else
        echo "    Notice: Run 'sudo install -Dm644 $DPM_RULE_SRC $DPM_RULE_DEST && sudo install -Dm755 $DPM_SLEEP_SRC $DPM_SLEEP_DEST && sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=drm --action=change'"
    fi
fi

# 5. Check AMD RDNA 3 DisplayPort blanking mitigation parameters
if lspci 2>/dev/null | grep -qiE "Navi 3|RX 7[0-9]{3}"; then
    if ! grep -q "amdgpu.dcdebugmask=0x10" /proc/cmdline 2>/dev/null; then
        echo "    [AMDGPU] Notice: RDNA 3 GPU detected without 'amdgpu.dcdebugmask=0x10 amdgpu.sg_display=0' in kernel cmdline."
        echo "             If DisplayPort 1-2s blanking occurs, add those parameters to /etc/sdboot-manage.conf (or bootloader config)."
    else
        echo "    [AMDGPU] RDNA 3 DisplayPort stability parameters verified in kernel cmdline."
    fi
fi

echo "==> Workstation Desktop Profile setup complete."
