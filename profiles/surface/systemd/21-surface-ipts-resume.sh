#!/usr/bin/env bash
# Queue Surface-only IPTS recovery outside the blocking system-sleep hook.
# Stop a previous attempt before another sleep/hibernate transition.
case "${1:-}/${2:-}" in
    pre/*)
        systemctl --no-block stop surface-ipts-resume.service
        ;;
    post/*)
        systemctl --no-block restart surface-ipts-resume.service
        ;;
esac
