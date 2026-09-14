#!/usr/bin/env bash
# init-skill.sh — Initialize and personalize system-personalization skill for the current machine
# Probes hardware, OS, monitors, and active profiles to generate:
#   1. references/hardware.md
#   2. references/current-state.md
#   3. SKILL.md (rendered from SKILL.md.template)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ACTIVE_PROFILES_ARG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profiles|-p)
            ACTIVE_PROFILES_ARG="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: ./init-skill.sh [OPTIONS] [PROFILES]"
            echo ""
            echo "Options:"
            echo "  -p, --profiles <list>   Comma-separated list of active profiles (e.g. 'macbook-t2, laptop')"
            echo "  -h, --help              Show this help message"
            exit 0
            ;;
        *)
            if [ -z "$ACTIVE_PROFILES_ARG" ]; then
                ACTIVE_PROFILES_ARG="$1"
                shift
            else
                echo "Unknown argument: $1" >&2
                exit 1
            fi
            ;;
    esac
done

echo "======================================================="
echo "   Personalizing System Skill for CachyOS Hyprland    "
echo "======================================================="

# 1. Hostname
SYS_HOSTNAME=$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "unknown-host")
echo "-> Hostname:         $SYS_HOSTNAME"

# 2. Product Name / Model
SYS_PRODUCT_NAME="Generic System"
if [ -f /sys/class/dmi/id/product_name ]; then
    SYS_PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null | xargs || echo "Generic System")
elif [ -f /sys/devices/virtual/dmi/id/product_name ]; then
    SYS_PRODUCT_NAME=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null | xargs || echo "Generic System")
fi
echo "-> Product Name:     $SYS_PRODUCT_NAME"

# 3. OS
SYS_OS="CachyOS Linux"
if [ -f /etc/os-release ]; then
    OS_PRETTY=$(grep -E "^PRETTY_NAME=" /etc/os-release | cut -d= -f2- | tr -d '"' || true)
    OS_NAME=$(grep -E "^NAME=" /etc/os-release | cut -d= -f2- | tr -d '"' || true)
    SYS_OS="${OS_PRETTY:-$OS_NAME}"
fi
echo "-> Operating System: $SYS_OS"

# 4. Kernel
SYS_KERNEL=$(uname -r)
echo "-> Kernel:           $SYS_KERNEL"

# 5. CPU
SYS_CPU="Unknown CPU"
if command -v lscpu &>/dev/null; then
    SYS_CPU=$(lscpu 2>/dev/null | grep -i "Model name" | sed -e 's/.*:[[:space:]]*//' | head -n 1 | xargs || true)
fi
if [ -z "$SYS_CPU" ] || [ "$SYS_CPU" = "Unknown CPU" ]; then
    SYS_CPU=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | sed -e 's/.*:[[:space:]]*//' | xargs || echo "Unknown CPU")
fi
echo "-> CPU:              $SYS_CPU"

# 6. GPU
SYS_GPU=""
if command -v lspci &>/dev/null; then
    SYS_GPU=$(lspci 2>/dev/null | grep -i -E "vga|3d" | sed -e 's/.*controller: //;s/.*controller [0-9a-fA-F:]* //;s/ (rev .*//' | tr '\n' ';' | sed -e 's/;$//;s/;/ \/ /g' || true)
fi
if [ -z "$SYS_GPU" ]; then
    SYS_GPU="Integrated Graphics"
fi
echo "-> GPU:              $SYS_GPU"

# 7. RAM & Swap
SYS_RAM=$(free -h 2>/dev/null | awk '/Mem:/ {print $2}' || echo "Unknown")
SYS_SWAP=$(free -h 2>/dev/null | awk '/Swap:/ {print $2}' || echo "None")
RAM_AND_SWAP="$SYS_RAM RAM, $SYS_SWAP swap"
echo "-> Memory:           $RAM_AND_SWAP"

# 8. Primary Display
SYS_PRIMARY_DISPLAY=""
if command -v hyprctl &>/dev/null && command -v jq &>/dev/null; then
    SYS_PRIMARY_DISPLAY=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0] | "\(.name) (\(.width)x\(.height)@\(.refreshRate | round)Hz, scale \(.scale))"' 2>/dev/null || true)
fi
if [ -z "$SYS_PRIMARY_DISPLAY" ] || [ "$SYS_PRIMARY_DISPLAY" = "null" ]; then
    if command -v hyprctl &>/dev/null; then
        SYS_PRIMARY_DISPLAY=$(hyprctl monitors 2>/dev/null | grep -E "Monitor" | head -n 1 | awk '{print $2}' || true)
    fi
fi
if [ -z "$SYS_PRIMARY_DISPLAY" ]; then
    SYS_PRIMARY_DISPLAY="eDP-1 (Default Display)"
fi
echo "-> Primary Display:  $SYS_PRIMARY_DISPLAY"

# 9. Active Profiles
if [ -n "$ACTIVE_PROFILES_ARG" ]; then
    SYS_ACTIVE_PROFILES="$ACTIVE_PROFILES_ARG"
else
    DETECTED=()
    if [[ "${SYS_PRODUCT_NAME,,}" =~ macbook ]] || lspci 2>/dev/null | grep -qi "Apple.*T2"; then
        DETECTED+=("macbook-t2")
    fi
    if [[ "${SYS_PRODUCT_NAME,,}" =~ surface ]] || [[ "${SYS_KERNEL,,}" =~ surface ]]; then
        DETECTED+=("surface")
    fi
    if [ -d /sys/class/power_supply ] && ls /sys/class/power_supply/ 2>/dev/null | grep -q -E "BAT|battery"; then
        DETECTED+=("laptop")
    else
        DETECTED+=("desktop")
    fi
    SYS_ACTIVE_PROFILES=$(IFS=', '; echo "${DETECTED[*]}")
fi
echo "-> Active Profiles:  $SYS_ACTIVE_PROFILES"
echo ""

# 10. Generate references/hardware.md
echo "--> Generating references/hardware.md..."
HARDWARE_FILE="$SKILL_ROOT/references/hardware.md"
LSCPU_INFO=$(lscpu 2>/dev/null | grep -E "CPU max MHz|CPU min MHz|L3 cache" | sed 's/^[ \t]*/- **/' | sed 's/:[ \t]*/**: /' || true)
LSPCI_GPU_DETAILS=""
if command -v lspci &>/dev/null; then
    LSPCI_GPU_DETAILS=$(lspci -k 2>/dev/null | grep -A 2 -i -E "vga|3d" | sed 's/^/  /' || true)
fi
DISK_INFO=$(df -h / /home 2>/dev/null || true)
MONITOR_DETAILS=$(hyprctl monitors 2>/dev/null | grep -E 'Monitor|[0-9]+x[0-9]+@|scale|transform|make|model' || echo "Monitor details unavailable")

cat << HARDWARE_EOF > "$HARDWARE_FILE"
# Hardware Specifications (\`$SYS_HOSTNAME\` - $SYS_PRODUCT_NAME)

Live physical system specifications probed automatically.

## System & Architecture
- **Product / Model**: $SYS_PRODUCT_NAME
- **Hostname**: \`$SYS_HOSTNAME\`
- **Architecture**: $(uname -m)
- **Active Profiles**: $SYS_ACTIVE_PROFILES

## CPU & Processing
- **Processor**: $SYS_CPU
- **Physical Cores / Threads**: $(nproc 2>/dev/null || echo 'Unknown')
$LSCPU_INFO

## Graphics Processing Units (GPUs)
- **Detected GPU(s)**: $SYS_GPU
$LSPCI_GPU_DETAILS

## Memory & Swap
- **Total System RAM**: $SYS_RAM
- **Swap Space**: $SYS_SWAP

## Storage & Filesystems
\`\`\`
$DISK_INFO
\`\`\`

## Displays & Monitors
- **Primary Display**: $SYS_PRIMARY_DISPLAY
\`\`\`
$MONITOR_DETAILS
\`\`\`
HARDWARE_EOF

# 11. Generate references/current-state.md
echo "--> Generating references/current-state.md..."
CURRENT_STATE_FILE="$SKILL_ROOT/references/current-state.md"
PACKAGE_TABLE=""
PACKAGES=(
    hyprland
    noctalia
    kitty
    alacritty
    fish
    btop
    waypaper
    swayimg
    dolphin
    easyeffects
    localsend
    tiny-dfr
    apple-t2-audio-config
)
for pkg in "${PACKAGES[@]}"; do
    line=$(pacman -Q "$pkg" 2>/dev/null | awk '{printf "| %s | %s | Core / Profile Utility |\n", $1, $2}' || true)
    if [ -n "$line" ]; then
        PACKAGE_TABLE="${PACKAGE_TABLE}${line}\n"
    fi
done

HYPR_ERRS=$(hyprctl configerrors 2>/dev/null || true)
HYPR_ERR_STATUS="None (clean)"
if [ -n "$HYPR_ERRS" ] && [ "$HYPR_ERRS" != "ok" ]; then
    HYPR_ERR_STATUS="Active errors detected (run 'hyprctl configerrors')"
fi

cat << STATE_EOF > "$CURRENT_STATE_FILE"
# Current System State

Live system snapshot automatically generated on $(date).

## Operating System & Kernel
- **OS**: $SYS_OS
- **Kernel**: \`$SYS_KERNEL\`
- **Shell**: \`${SHELL:-/usr/bin/fish}\`
- **Compositor**: $(hyprctl version 2>/dev/null | head -n 1 || echo "Hyprland")
- **Active Profiles**: $SYS_ACTIVE_PROFILES

## System Specs & Display
- **Product**: $SYS_PRODUCT_NAME (\`$SYS_HOSTNAME\`)
- **CPU**: $SYS_CPU
- **GPU**: $SYS_GPU
- **RAM**: $RAM_AND_SWAP
- **Primary Display**: $SYS_PRIMARY_DISPLAY

## Key Installed Packages & Utilities

| Package | Version | Purpose |
|---------|---------|---------|
$(echo -e "$PACKAGE_TABLE")

## Compositor Health
- **Hyprland Errors**: $HYPR_ERR_STATUS
STATE_EOF

# 12. Render SKILL.md from SKILL.md.template
echo "--> Generating SKILL.md from SKILL.md.template..."
TEMPLATE_FILE="$SKILL_ROOT/SKILL.md.template"
OUTPUT_FILE="$SKILL_ROOT/SKILL.md"

if [ -f "$TEMPLATE_FILE" ]; then
    python3 - "$TEMPLATE_FILE" "$OUTPUT_FILE" \
        "$SYS_HOSTNAME" \
        "$SYS_PRODUCT_NAME" \
        "$SYS_OS" \
        "$SYS_KERNEL" \
        "$SYS_CPU" \
        "$SYS_GPU" \
        "$SYS_PRIMARY_DISPLAY" \
        "$SYS_ACTIVE_PROFILES" \
        "$RAM_AND_SWAP" << 'PYTHON_SUB_EOF'
import sys

template_path = sys.argv[1]
output_path = sys.argv[2]

replacements = {
    "{{HOSTNAME}}": sys.argv[3],
    "{{PRODUCT_NAME}}": sys.argv[4],
    "{{OS}}": sys.argv[5],
    "{{KERNEL}}": sys.argv[6],
    "{{CPU}}": sys.argv[7],
    "{{GPU}}": sys.argv[8],
    "{{PRIMARY_DISPLAY}}": sys.argv[9],
    "{{ACTIVE_PROFILES}}": sys.argv[10],
    "{{RAM}}": sys.argv[11],
}

with open(template_path, "r", encoding="utf-8") as f:
    content = f.read()

for placeholder, val in replacements.items():
    content = content.replace(placeholder, val)

with open(output_path, "w", encoding="utf-8") as f:
    f.write(content)
PYTHON_SUB_EOF
fi

echo "======================================================="
echo "  Skill Personalized Successfully for $SYS_HOSTNAME! "
echo "======================================================="
