#!/usr/bin/env bash
# Microsoft Surface Book sleep resume hook for battery calculation check
case "$1/$2" in
    post/*)
        /usr/local/bin/surface-battery-watchdog 2>/dev/null || true
        ;;
esac
