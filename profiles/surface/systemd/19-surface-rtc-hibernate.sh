#!/usr/bin/env bash
# Align Surface Book 3 CMOS rtc0 with SAM EC UEFI POST epoch across hibernation
# so kernel timekeeping_resume() injects the true hibernated duration.

phase="${1:-}"
action="${SYSTEMD_SLEEP_ACTION:-${2:-}}"

if [[ "$action" != "hibernate" && "$action" != "hybrid-sleep" ]]; then
    exit 0
fi

case "$phase" in
    pre|post)
        if [[ -x /usr/local/bin/surface-hibernate-rtc-sync ]]; then
            /usr/local/bin/surface-hibernate-rtc-sync "$phase" || true
        fi
        ;;
esac
