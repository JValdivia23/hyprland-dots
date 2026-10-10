#!/usr/bin/env bash
# /usr/local/bin/amdgpu-power-switch.sh
# Dynamic power profile switcher for AMD GPU & Intel CPU on AC vs Battery (MacBookPro15,1 / CachyOS)

set -euo pipefail

TURBO_PREF_FILE="/etc/default/t2-battery-turbo"
INTEL_NO_TURBO="/sys/devices/system/cpu/intel_pstate/no_turbo"

notify() {
    local title="$1" msg="$2"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u normal -a "Power Manager" "$title" "$msg" 2>/dev/null || true
    fi
    echo "$title: $msg"
}

# Locate AMDGPU sysfs path
CARD_DIR=""
for dev in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
    if [ -f "$dev" ]; then
        CARD_DIR="$(dirname "$dev")"
        break
    fi
done

ACTION="${1:-auto}"

# Handle Explicit Turbo Boost & Performance Controls
case "$ACTION" in
    turbo-toggle|toggle-turbo|turbo)
        if [ ! -w "$INTEL_NO_TURBO" ]; then
            echo "Error: Cannot write to $INTEL_NO_TURBO (root privileges required, run with sudo)" >&2
            exit 1
        fi
        CURRENT_NO_TURBO=$(cat "$INTEL_NO_TURBO")
        if [ "$CURRENT_NO_TURBO" = "1" ]; then
            echo 0 > "$INTEL_NO_TURBO"
            echo "1" > "$TURBO_PREF_FILE" 2>/dev/null || true
            notify "CPU Turbo Boost" "Turbo Boost ENABLED (Burst Performance)"
        else
            echo 1 > "$INTEL_NO_TURBO"
            echo "0" > "$TURBO_PREF_FILE" 2>/dev/null || true
            notify "CPU Turbo Boost" "Turbo Boost DISABLED (Battery Saver)"
        fi
        exit 0
        ;;
    turbo-on)
        if [ ! -w "$INTEL_NO_TURBO" ]; then
            echo "Error: Cannot write to $INTEL_NO_TURBO (root privileges required, run with sudo)" >&2
            exit 1
        fi
        echo 0 > "$INTEL_NO_TURBO"
        echo "1" > "$TURBO_PREF_FILE" 2>/dev/null || true
        notify "CPU Turbo Boost" "Turbo Boost ENABLED"
        exit 0
        ;;
    turbo-off)
        if [ ! -w "$INTEL_NO_TURBO" ]; then
            echo "Error: Cannot write to $INTEL_NO_TURBO (root privileges required, run with sudo)" >&2
            exit 1
        fi
        echo 1 > "$INTEL_NO_TURBO"
        echo "0" > "$TURBO_PREF_FILE" 2>/dev/null || true
        notify "CPU Turbo Boost" "Turbo Boost DISABLED"
        exit 0
        ;;
    status)
        echo "=== Power & GPU Status ==="
        ONLINE=0
        for ac in /sys/class/power_supply/ADP* /sys/class/power_supply/AC* /sys/class/power_supply/ACAD*; do
            if [ -f "$ac/online" ]; then
                ONLINE=$(cat "$ac/online" 2>/dev/null || echo 0)
                break
            fi
        done
        if [ "$ONLINE" = "1" ]; then
            echo "Power Source       : AC Adapter"
        else
            echo "Power Source       : Battery"
        fi
        if [ -n "$CARD_DIR" ]; then
            echo "GPU Sysfs Path     : $CARD_DIR"
            echo "GPU DPM Perf Level : $(cat "$CARD_DIR/power_dpm_force_performance_level" 2>/dev/null || echo 'unknown')"
            echo "GPU Power Mode     : $(grep '\*' "$CARD_DIR/pp_power_profile_mode" 2>/dev/null || echo 'unknown')"
            echo "GPU Active sclk    : $(grep '\*' "$CARD_DIR/pp_dpm_sclk" 2>/dev/null || echo 'unknown')"
            echo "GPU Active mclk    : $(grep '\*' "$CARD_DIR/pp_dpm_mclk" 2>/dev/null || echo 'unknown')"
        else
            echo "GPU Status         : dGPU sysfs not present or powered off"
        fi
        if [ -f "$INTEL_NO_TURBO" ]; then
            NT=$(cat "$INTEL_NO_TURBO")
            if [ "$NT" = "0" ]; then
                echo "CPU Turbo Boost    : Active (no_turbo=0)"
            else
                echo "CPU Turbo Boost    : Disabled (no_turbo=1)"
            fi
        fi
        if [ -f "$TURBO_PREF_FILE" ]; then
            PREF=$(cat "$TURBO_PREF_FILE" 2>/dev/null || echo 0)
            if [ "$PREF" = "1" ]; then
                echo "Battery Turbo Pref : Allowed (User Override)"
            else
                echo "Battery Turbo Pref : Disabled (Power Saver)"
            fi
        else
            echo "Battery Turbo Pref : Default (Power Saver)"
        fi
        exit 0
        ;;
    game|gaming|performance)
        echo "--> Enabling High-Performance Gaming Mode..."
        if [ -n "$CARD_DIR" ] && [ -w "$CARD_DIR/power_dpm_force_performance_level" ]; then
            echo "manual" > "$CARD_DIR/power_dpm_force_performance_level" 2>/dev/null || true
        fi
        if [ -n "$CARD_DIR" ] && [ -w "$CARD_DIR/pp_power_profile_mode" ]; then
            echo "1" > "$CARD_DIR/pp_power_profile_mode" 2>/dev/null || true
        fi
        if [ -w "/sys/module/pcie_aspm/parameters/policy" ]; then
            echo "default" > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
        fi
        if [ -w "$INTEL_NO_TURBO" ]; then
            echo "0" > "$INTEL_NO_TURBO" 2>/dev/null || true
        fi
        notify "GPU Performance Mode" "3D_FULL_SCREEN (Mode 1) & CPU Turbo active"
        exit 0
        ;;
esac

STATE="$ACTION"
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
        echo "2" > "$CARD_DIR/pp_power_profile_mode" 2>/dev/null || echo "0" > "$CARD_DIR/pp_power_profile_mode" 2>/dev/null || true
    fi
    # PCIe Active State Power Management (ASPM) powersupersave
    if [ -w "/sys/module/pcie_aspm/parameters/policy" ]; then
        echo "powersupersave" > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
    fi
    # Intel Turbo Boost on battery: check persistent preference
    BAT_TURBO=0
    if [ -f "$TURBO_PREF_FILE" ]; then
        BAT_TURBO=$(cat "$TURBO_PREF_FILE" 2>/dev/null || echo 0)
    fi
    if [ "$BAT_TURBO" = "1" ]; then
        if [ -w "$INTEL_NO_TURBO" ]; then
            echo "0" > "$INTEL_NO_TURBO" 2>/dev/null || true
        fi
    else
        if [ -w "$INTEL_NO_TURBO" ]; then
            echo "1" > "$INTEL_NO_TURBO" 2>/dev/null || true
        fi
    fi
else
    # AC Mode: Keep GPU in POWER_SAVING profile for thermal efficiency, with Intel Turbo Boost active
    if [ -n "$CARD_DIR" ] && [ -w "$CARD_DIR/power_dpm_force_performance_level" ]; then
        echo "manual" > "$CARD_DIR/power_dpm_force_performance_level" 2>/dev/null || true
    fi
    if [ -n "$CARD_DIR" ] && [ -w "$CARD_DIR/pp_power_profile_mode" ]; then
        echo "2" > "$CARD_DIR/pp_power_profile_mode" 2>/dev/null || true
    fi
    # PCIe ASPM restore default
    if [ -w "/sys/module/pcie_aspm/parameters/policy" ]; then
        echo "default" > /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
    fi
    # Re-enable Intel Turbo Boost on AC
    if [ -w "$INTEL_NO_TURBO" ]; then
        echo "0" > "$INTEL_NO_TURBO" 2>/dev/null || true
    fi
fi
