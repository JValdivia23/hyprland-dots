#!/usr/bin/env bash
# Microsoft Surface Unplug Clamshell Sleep Handler
# Re-engages suspend-then-hibernate if charger is disconnected while the lid is closed.

set -euo pipefail

# 1. Verify AC is offline (online == 0)
if [ -f "/sys/class/power_supply/ADP1/online" ]; then
    if [ "$(cat /sys/class/power_supply/ADP1/online 2>/dev/null)" != "0" ]; then
        exit 0
    fi
fi

# 2. Check if the lid is physically closed
is_lid_closed() {
    for state_file in /proc/acpi/button/lid/*/state; do
        if [ -f "$state_file" ] && grep -qi "closed" "$state_file"; then
            return 0
        fi
    done
    return 1
}

if ! is_lid_closed; then
    exit 0
fi

# 3. Debounce: give hardware & user 1.5 seconds to settle (in case user opened lid right after unplugging)
sleep 1.5

# Re-check lid state and AC state
if is_lid_closed && [ "$(cat /sys/class/power_supply/ADP1/online 2>/dev/null)" = "0" ]; then
    /usr/bin/systemctl suspend-then-hibernate
fi
