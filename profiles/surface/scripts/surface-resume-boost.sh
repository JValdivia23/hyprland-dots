#!/usr/bin/env bash
# Surface Book 3: temporary performance boost right after resume.
#
# Why: on battery (power-saver / platform_profile=low-power / EPP=power) the CPU
# idles at ~0.5-1 GHz and the lock screen echoes typed password dots several
# seconds late after hibernate. Verified 2026-10-22: with the performance
# profile the echo was immediate. This holds performance for a short window
# after resume and then restores the exact previous values.
#
#   surface-resume-boost run      boost, wait, restore (service ExecStart)
#   surface-resume-boost restore  restore only (service ExecStopPost); idempotent
#
# We write sysfs directly (no D-Bus/power-profiles-daemon) so it works inside the
# sleep-hook window. Values are only restored if they are still the ones we set,
# so a manual profile change during the window is respected.
set -u

PLATFORM_PROFILE="${SB_PLATFORM_PROFILE:-/sys/firmware/acpi/platform_profile}"
CPU_GLOB="${SB_CPU_GLOB:-/sys/devices/system/cpu/cpu[0-9]*/cpufreq/energy_performance_preference}"
STATE="${SB_STATE:-/run/surface-resume-boost.state}"
HOLD="${BOOST_SECONDS:-20}"
BOOST=performance

restore() {
    [[ -f "$STATE" ]] || return 0
    local kind path val
    while IFS='|' read -r kind path val; do
        [[ -w "$path" ]] || continue
        if [[ "$(cat "$path" 2>/dev/null)" == "$BOOST" && "$val" != "$BOOST" ]]; then
            echo "$val" > "$path" 2>/dev/null || true
        fi
    done < "$STATE"
    rm -f "$STATE"
    echo "surface-resume-boost: restored previous profile"
}

run() {
    # A stale state from an interrupted run holds the real original values: restore first.
    restore
    : > "$STATE"
    if [[ -w "$PLATFORM_PROFILE" ]]; then
        echo "platform|$PLATFORM_PROFILE|$(cat "$PLATFORM_PROFILE")" >> "$STATE"
        echo "$BOOST" > "$PLATFORM_PROFILE" 2>/dev/null || true
    fi
    local f
    for f in $CPU_GLOB; do
        [[ -w "$f" ]] || continue
        echo "epp|$f|$(cat "$f")" >> "$STATE"
        echo "$BOOST" > "$f" 2>/dev/null || true
    done
    echo "surface-resume-boost: boosted for ${HOLD}s (saved $(wc -l < "$STATE") values)"
    sleep "$HOLD"
    restore
}

case "${1:-run}" in
    run) run ;;
    restore) restore ;;
    *) echo "usage: $0 run|restore" >&2; exit 2 ;;
esac
