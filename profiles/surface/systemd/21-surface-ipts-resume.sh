#!/usr/bin/env bash
# Queue Surface-only IPTS recovery outside the blocking system-sleep hook.
# Stop a previous attempt before another sleep/hibernate transition.
is_lid_closed() {
    for state_file in /proc/acpi/button/lid/*/state; do
        if [[ -f "$state_file" ]] && grep -qi "closed" "$state_file"; then
            return 0
        fi
    done
    return 1
}

case "${1:-}/${2:-}" in
    pre/*)
        systemctl --no-block stop surface-ipts-resume.service
        systemctl stop 'iptsd@*.service' 2>/dev/null || true
        systemctl reset-failed 'iptsd@*.service' 2>/dev/null || true
        ;;
    post/*)
        if ! is_lid_closed; then
            systemctl --no-block restart surface-ipts-resume.service
        fi
        ;;
esac
