#!/usr/bin/env bash
# /usr/local/bin/amdgpu-power-switch.sh
# Dynamic power profile switcher for AMD GPU & Intel CPU on AC vs Battery (MacBookPro15,1 / CachyOS)

set -euo pipefail

# Locate AMDGPU sysfs path
CARD_DIR=""
for dev in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
    if [ -f "$dev" ]; then
        CARD_DIR="$(dirname "$dev")"
        break
    fi
done

# Determine power state
STATE="${1:-auto}"
if [ "$STATE" = "auto" ]; then
    ONLINE=0
    for ac in /sys/class/power_supply/ADP* /sys/class/power_supply/AC* /sys/class/power_supply/ACAD*; do
        if [ -f "$ac/online" ]; then
            ONLINE=$(cat "$ac/online" 2>/dev/null || echo 0)
            break
        fi
    done
    if [ "$ONLINE" = "1" ]; then
        STATE="ac"
    else
        STATE="battery"
    fi
fi

if [ "$STATE" = "battery" ]; then
    # Battery Mode: Enable manual DPM and set POWER_SAVING profile (mode 2)
    if [ -n "$CARD_DIR" ] && [ -w "$CARD_DIR/power_dpm_force_performance_level" ]; then
        echo "manual" > "$CARD_DIR/power_dpm_force_performance_level" 2>/dev/null || true
    fi
    if [ -n "$CARD_DIR" ] && [ -w "$CARD_DIR/pp_power_profile_mode" ]; then
        # Mode 2 is POWER_SAVING, fallback to Mode 0 (BOOTUP_DEFAULT)
        echo "2" > "$CARD_DIR/pp_power_profile_mode" 2>/dev/null || echo "0" > "$CARD_DIR/pp_power_profile_mode" 2>/dev/null || true
    fi
    # PCIe Active State Power Management (ASPM) powersupersave
    if [ -w "/sys/module/pcie_aspm/parameters/policy" ]; then
        echo "powersupersave" > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
    fi
    # Disable Intel Turbo Boost on battery for maximum idle power savings
    if [ -w "/sys/devices/system/cpu/intel_pstate/no_turbo" ]; then
        echo "1" > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
    fi
else
    # AC Mode: Restore auto dynamic scaling and standard profile (mode 0)
    if [ -n "$CARD_DIR" ] && [ -w "$CARD_DIR/power_dpm_force_performance_level" ]; then
        echo "auto" > "$CARD_DIR/power_dpm_force_performance_level" 2>/dev/null || true
    fi
    if [ -n "$CARD_DIR" ] && [ -w "$CARD_DIR/pp_power_profile_mode" ]; then
        echo "0" > "$CARD_DIR/pp_power_profile_mode" 2>/dev/null || true
    fi
    # PCIe ASPM restore default
    if [ -w "/sys/module/pcie_aspm/parameters/policy" ]; then
        echo "default" > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
    fi
    # Re-enable Intel Turbo Boost on AC
    if [ -w "/sys/devices/system/cpu/intel_pstate/no_turbo" ]; then
        echo "0" > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
    fi
fi
