#!/bin/bash
# snapshot.sh — Capture current system state to stdout
# Used to refresh current-state.md periodically.
# Usage: bash ~/.agents/skills/system-personalization/scripts/snapshot.sh

echo "=== OS ==="
cat /etc/os-release | grep -E "^(NAME|VERSION|ID)=" 2>/dev/null

echo -e "\n=== KERNEL ==="
uname -r

echo -e "\n=== CPU ==="
lscpu 2>/dev/null | grep "Model name" | cut -d: -f2 | xargs

echo -e "\n=== GPU ==="
lspci 2>/dev/null | grep -i vga | sed 's/.*: //'

echo -e "\n=== RAM ==="
free -h | grep Mem | awk '{print $2}'

echo -e "\n=== DISPLAY ==="
echo "Session: $XDG_SESSION_TYPE"
hyprctl monitors 2>/dev/null | grep -E 'Monitor|resolution|scale|refresh' | head -6

echo -e "\n=== WM ==="
hyprctl version 2>/dev/null | head -1

echo -e "\n=== SHELL ==="
echo "$SHELL"

echo -e "\n=== KEY PACKAGES ==="
pacman -Q hyprland noctalia kitty alacritty firefox grim slurp satty jq wl-clipboard brightnessctl btop dolphin 2>/dev/null | awk '{printf "%-25s %s\n", $1, $2}'

echo -e "\n=== HYPRLAND ERRORS ==="
hyprctl configerrors 2>/dev/null | grep -v "^$" | grep -v "Config error.*Config error" | sort -u | head -20

echo -e "\n=== DISK ==="
df -h / /home 2>/dev/null | tail -2
