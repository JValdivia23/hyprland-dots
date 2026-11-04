#!/usr/bin/env bash
# Surface-only: start the short post-resume performance boost without blocking
# the system-sleep hook (uses a static unit + systemctl, like 21/22; no D-Bus).
# Skipped when the lid is closed (RTC wakes for the 30-minute hibernate step).
# NOTE: must also be symlinked into /usr/lib/systemd/system-sleep/ to run.
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
        # Stopping the unit runs ExecStopPost, restoring the previous profile.
        systemctl --no-block stop surface-resume-boost.service 2>/dev/null || true
        ;;
    post/*)
        if ! is_lid_closed; then
            systemctl --no-block restart surface-resume-boost.service \
                || echo "23-surface-resume-boost: failed to start boost unit" >&2
        fi
        ;;
esac
