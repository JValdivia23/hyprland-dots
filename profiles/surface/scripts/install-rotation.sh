#!/usr/bin/env bash
# Install only the detached-rotation prerequisite and read-only base reporter.
# This intentionally does NOT run the profile's boot/sleep/driver setup.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo: $0 [--no-packages]" >&2
    exit 1
fi
if [[ $(cat /sys/class/dmi/id/product_name) != "Surface Book 3" ]]; then
    echo "Detached-only rotation is restricted to Surface Book 3." >&2
    exit 1
fi
if [[ $# -gt 1 || ( $# -eq 1 && $1 != --no-packages ) ]]; then
    echo "Usage: $0 [--no-packages]" >&2
    exit 1
fi

PROFILE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
sources=(
    "$PROFILE_DIR/scripts/surface-base-state.py"
    "$PROFILE_DIR/systemd/surface-base-state.service"
)
targets=(
    /usr/local/libexec/surface-base-state.py
    /etc/systemd/system/surface-base-state.service
)

# Refuse unrelated administrator files instead of silently overwriting them.
for i in "${!targets[@]}"; do
    target=${targets[$i]}
    if [[ -L "$target" || ( -e "$target" && ! -f "$target" ) ]]; then
        echo "Refusing unexpected target: $target" >&2
        exit 1
    fi
    if [[ -e "$target" ]] && ! cmp -s -- "${sources[$i]}" "$target"; then
        echo "Existing file differs; review a targeted update first: $target" >&2
        exit 1
    fi
done

if [[ ${1:-} != --no-packages ]]; then
    pacman -S --needed iio-sensor-proxy python-gobject
fi
pacman -Q iio-sensor-proxy python-gobject >/dev/null

for i in "${!targets[@]}"; do
    if [[ ! -e ${targets[$i]} ]]; then
        install -Dm644 -- "${sources[$i]}" "${targets[$i]}"
    fi
    cmp -- "${sources[$i]}" "${targets[$i]}"
done
systemd-analyze verify /etc/systemd/system/surface-base-state.service
systemctl daemon-reload
systemctl enable --now surface-base-state.service
echo "Detached-only rotation prerequisite and read-only base status installed."
echo "No DTX permissions, latch controls, boot files, or sleep hooks were changed."
