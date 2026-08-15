#!/usr/bin/env bash
# ==============================================================================
# snapshot.sh — Capture live system state for system-personalization skill
# Usage: bash ~/.agents/skills/system-personalization/scripts/snapshot.sh
# ==============================================================================
set -euo pipefail

# Ensure Hyprland socket signature is set
if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    HYPR_SIG=$(ls -1 "/run/user/$(id -u)/hypr/" 2>/dev/null | head -n1 || true)
    if [ -n "$HYPR_SIG" ]; then
        export HYPRLAND_INSTANCE_SIGNATURE="$HYPR_SIG"
    fi
fi

echo "=== System Snapshot: $(date -Iseconds) ==="
echo "Host: $(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || uname -n)"
echo "Kernel: $(uname -r)"
echo "CPU: $(lscpu 2>/dev/null | grep 'Model name' | cut -d: -f2 | xargs)"
echo "GPU: $(lspci 2>/dev/null | grep -i vga | sed 's/.*: //')"
echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
echo "Shell: $SHELL ($($SHELL --version 2>/dev/null | head -n1))"
echo "Compositor: $(hyprctl version 2>/dev/null | head -1 || echo 'Hyprland (not running)')"
echo "Wayland Shell: $(noctalia --version 2>/dev/null || echo 'Noctalia')"
echo ""
echo "=== Display & Monitor ==="
hyprctl monitors 2>/dev/null | grep -E "Monitor |description:|scale:|physical size" || echo "No active Hyprland monitors detected."
echo ""
echo "=== Hyprland Config Errors ==="
ERRS=$(hyprctl configerrors 2>/dev/null | grep -v "^$" | grep -v "Config error.*Config error" | sort -u || true)
if [ -z "$ERRS" ] || [ "$ERRS" = "ok" ]; then
    echo "None (Clean)"
else
    echo "$ERRS" | head -20
fi
echo ""
echo "=== Key Packages ==="
pacman -Q hyprland noctalia kitty alacritty zen-browser-bin firefox swayimg satty grim slurp jq wl-clipboard brightnessctl btop dolphin lazygit localsend 2>/dev/null | awk '{printf "%-22s %s\n", $1, $2}'
echo ""
echo "=== Disk Usage ==="
df -h / /boot 2>/dev/null | tail -n +2
