#!/usr/bin/env bash
# Surface-only diagnostic: start the post-resume input-latency probe without
# blocking the system-sleep hook. Skipped when the lid is closed (RTC wakes).
# Uses a static unit + systemctl (private socket, like 21-surface-ipts-resume.sh);
# systemd-run needs D-Bus and silently failed during real hibernate resume.
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
        systemctl --no-block stop surface-resume-probe.service 2>/dev/null || true
        ;;
    post/*)
        if ! is_lid_closed; then
            systemctl --no-block restart surface-resume-probe.service \
                || echo "22-surface-resume-probe: failed to start probe unit" >&2
        fi
        ;;
esac
