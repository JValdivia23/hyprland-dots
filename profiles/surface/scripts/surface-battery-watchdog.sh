#!/usr/bin/env bash
# Surface Book dual-battery UPower desync watchdog
# Detects upstream UPower issue #336 where BAT2 EC timeout leads to energy-full=0 Wh
# and DisplayDevice percentage > 100%. Restores correct dual-battery state automatically.

set -euo pipefail

# Only relevant if BAT2 exists in sysfs
BAT2_DIR="/sys/class/power_supply/BAT2"
if [ ! -d "$BAT2_DIR" ]; then
    exit 0
fi

# Base must be physically attached
if [ ! -f "$BAT2_DIR/present" ] || [ "$(cat "$BAT2_DIR/present" 2>/dev/null || echo 0)" != "1" ]; then
    exit 0
fi

# sysfs must report a valid full capacity
sysfs_full="$(cat "$BAT2_DIR/energy_full" 2>/dev/null || echo 0)"
if [ "$sysfs_full" -le 0 ]; then
    exit 0
fi

# Query UPower over system D-Bus
bat2_upower_full="$(busctl get-property org.freedesktop.UPower /org/freedesktop/UPower/devices/battery_BAT2 org.freedesktop.UPower.Device EnergyFull 2>/dev/null | awk '{print $2}' || echo "0")"
display_pct="$(busctl get-property org.freedesktop.UPower /org/freedesktop/UPower/devices/DisplayDevice org.freedesktop.UPower.Device Percentage 2>/dev/null | awk '{print $2}' || echo "0")"

pct_int="${display_pct%%.*}"
upower_full_int="${bat2_upower_full%%.*}"

desync=0
if [ -z "$upower_full_int" ] || [ "$upower_full_int" -eq 0 ]; then
    desync=1
elif [ -n "$pct_int" ] && [ "$pct_int" -gt 100 ]; then
    desync=1
fi

if [ "$desync" -eq 1 ]; then
    # Rate limit restarts: at most once every 30 seconds
    LOCK_FILE="/run/surface-battery-watchdog.last-restart"
    now="$(date +%s)"
    if [ -f "$LOCK_FILE" ]; then
        last="$(cat "$LOCK_FILE" 2>/dev/null || echo 0)"
        if [ $((now - last)) -lt 30 ]; then
            logger -t surface-battery-watchdog "Desync detected but rate-limited (last restart was $((now - last))s ago)"
            exit 0
        fi
    fi
    echo "$now" > "$LOCK_FILE"

    logger -t surface-battery-watchdog "Surface dual-battery desync detected (UPower BAT2 EnergyFull=${bat2_upower_full}Wh, DisplayDevice=${display_pct}%). Restarting upower.service..."
    systemctl restart upower

    # Allow upower to re-poll and update D-Bus
    sleep 1

    # Reload Noctalia bar for active graphical sessions
    for uid_dir in /run/user/[0-9]*; do
        if [ -d "$uid_dir" ]; then
            uid="$(basename "$uid_dir")"
            user="$(id -un "$uid" 2>/dev/null || true)"
            if [ -n "$user" ] && ls "$uid_dir"/noctalia-wayland-*.sock &>/dev/null; then
                su - "$user" -c "XDG_RUNTIME_DIR=$uid_dir noctalia msg config-reload" 2>/dev/null || true
            fi
        fi
    done

    logger -t surface-battery-watchdog "UPower restart completed and Noctalia bar refreshed."
fi
