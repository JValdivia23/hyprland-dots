#!/usr/bin/env bash
# ==============================================================================
# CachyOS / Arch Linux Master Dotfiles & Multi-PC Environment Installer
# 3-Tier Architecture: Core (universal) + Profiles (hardware) + Agents (skill)
# ==============================================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Default switches
DO_PACKAGES=true
DO_STOW=true
DO_SETUP=true
DRY_RUN=false
MANUAL_PROFILES=""

show_help() {
    cat << 'HELP'
CachyOS Multi-PC Dotfiles Installer

Usage:
  ./install.sh [OPTIONS]

Options:
  --profile <name>         Manually specify a profile (e.g. --profile macbook-t2, --profile desktop)
  --profiles <p1,p2>       Manually specify comma-separated profiles (e.g. --profiles "macbook-t2,laptop")
  --dry-run                Simulate actions without writing files or installing packages
  --only-stow              Only backup conflicts and deploy GNU Stow symlinks
  --only-packages          Only install core and profile packages
  -h, --help               Display this help message

Examples:
  ./install.sh                           # Auto-detect hardware, install packages, stow, and configure
  ./install.sh --dry-run                 # Preview actions without changing system state
  ./install.sh --profile macbook-t2      # Force MacBook T2 profile deployment
  ./install.sh --profile desktop         # Force Desktop workstation deployment
  ./install.sh --only-stow               # Refresh symlinks without touching package manager
HELP
}

# --- 1. Parse Command Line Arguments ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            if [[ -z "${2:-}" || "$2" =~ ^-- ]]; then
                echo "Error: --profile requires a profile name argument." >&2
                exit 1
            fi
            MANUAL_PROFILES="$2"
            shift 2
            ;;
        --profiles)
            if [[ -z "${2:-}" || "$2" =~ ^-- ]]; then
                echo "Error: --profiles requires a profile list argument." >&2
                exit 1
            fi
            MANUAL_PROFILES="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --only-stow)
            DO_PACKAGES=false
            DO_STOW=true
            DO_SETUP=false
            shift
            ;;
        --only-packages)
            DO_PACKAGES=true
            DO_STOW=false
            DO_SETUP=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: Unknown argument '$1'" >&2
            echo "Run './install.sh --help' for usage." >&2
            exit 1
            ;;
    esac
done

echo "======================================================="
echo "   🐧 CachyOS / Arch Multi-PC Dotfiles Installer       "
echo "======================================================="
if [ "$DRY_RUN" = true ]; then
    echo "   [MODE: DRY-RUN SIMULATION — NO CHANGES APPLIED]     "
    echo "======================================================="
fi
echo ""

# --- 2. Hardware Detection Engine ---
echo "==> [1/4] Probing Hardware & Detecting Profiles..."

SYS_PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || true)
SYS_VENDOR=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || cat /sys/devices/virtual/dmi/id/sys_vendor 2>/dev/null || true)
SYS_CHASSIS=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null || cat /sys/devices/virtual/dmi/id/chassis_type 2>/dev/null || true)
KERNEL_RELEASE=$(uname -r 2>/dev/null || true)

echo "    Product:  ${SYS_PRODUCT_NAME:-Generic System}"
echo "    Vendor:   ${SYS_VENDOR:-Unknown Vendor}"
echo "    Chassis:  ${SYS_CHASSIS:-Unknown Chassis}"
echo "    Kernel:   $KERNEL_RELEASE"

# Laptop detection
IS_LAPTOP=false
case "$SYS_CHASSIS" in
    8|9|10|11|12|14|30|31|32)
        IS_LAPTOP=true
        ;;
    *)
        if [ -d /sys/class/power_supply ] && ls /sys/class/power_supply/ 2>/dev/null | grep -q -E "BAT|battery"; then
            IS_LAPTOP=true
        fi
        ;;
esac

# Auto-detect or use manual profiles
ACTIVE_PROFILES=""
if [ -n "$MANUAL_PROFILES" ]; then
    ACTIVE_PROFILES="$MANUAL_PROFILES"
    echo "    Selection: Manually specified by user -> '$ACTIVE_PROFILES'"
else
    DETECTED=()
    # Check for Apple MacBook / T2
    if [[ "${SYS_PRODUCT_NAME,,}" =~ macbook ]] || lspci 2>/dev/null | grep -qi "Apple.*T2"; then
        DETECTED+=("macbook-t2")
    fi

    # Check for Surface
    if [[ "${SYS_PRODUCT_NAME,,}" =~ surface ]] || [[ "${SYS_VENDOR,,}" =~ microsoft && "${SYS_PRODUCT_NAME,,}" =~ surface ]] || [[ "${KERNEL_RELEASE,,}" =~ surface ]]; then
        DETECTED+=("surface")
    fi

    # If no specialized laptop profile was matched, check if generic laptop or desktop
    if [ ${#DETECTED[@]} -eq 0 ]; then
        if [ "$IS_LAPTOP" = true ]; then
            echo "    Generic laptop detected. Selecting 'laptop' profile."
            DETECTED+=("laptop")
        else
            echo "    Desktop chassis detected. Selecting 'desktop' profile."
            DETECTED+=("desktop")
        fi
    fi

    ACTIVE_PROFILES=$(IFS=','; echo "${DETECTED[*]}")
    echo "    Selection: Auto-detected -> '$ACTIVE_PROFILES'"
fi

# Parse active profiles into list of profile directories
IFS=',' read -ra RAW_PROFILES_ARRAY <<< "$ACTIVE_PROFILES"
STOWABLE_PROFILES=()
for raw in "${RAW_PROFILES_ARRAY[@]}"; do
    p="$(echo "$raw" | xargs)" # trim whitespace
    [ -z "$p" ] && continue
    if [ -d "$DOTFILES_DIR/profiles/$p" ]; then
        STOWABLE_PROFILES+=("$p")
    else
        echo "    Notice: Profile trait '$p' has no dedicated folder at profiles/$p."
    fi
done

echo "    Active Profile Directories to Stow: [${STOWABLE_PROFILES[*]:-none}]"
echo ""

# --- Helper Functions ---
backup_needed=false

check_and_backup_path() {
    local target="$1"
    local rel_path="${target#$HOME/}"

    [ ! -e "$target" ] && [ ! -L "$target" ] && return 0

    # If target is already a symlink pointing to dotfiles or obsolete dotfiles path
    if [ -L "$target" ]; then
        local link_dest
        link_dest=$(readlink "$target" 2>/dev/null || true)
        local target_real
        target_real=$(realpath -q "$target" 2>/dev/null || true)
        if [[ -n "$target_real" && "$target_real" == "$DOTFILES_DIR"* ]] || [[ "$link_dest" =~ (^\.\./)?dotfiles/ ]]; then
            if [ "$DRY_RUN" = false ]; then
                rm -f "$target"
            else
                echo "    [dry-run] Remove obsolete dotfiles symlink ~/$rel_path"
            fi
            return 0
        fi
    fi

    if [ "$backup_needed" = false ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "--> [dry-run] Existing non-dotfiles configurations detected! Would create backup at:"
        else
            echo "--> Existing non-dotfiles configurations detected! Creating backup at:"
        fi
        echo "    $BACKUP_DIR"
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "$BACKUP_DIR"
        fi
        backup_needed=true
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "    [dry-run] [Backup] ~/$rel_path -> $BACKUP_DIR/$rel_path"
    else
        echo "    [Backup] ~/$rel_path -> $BACKUP_DIR/$rel_path"
        mkdir -p "$BACKUP_DIR/$(dirname "$rel_path")"
        mv "$target" "$BACKUP_DIR/$rel_path"
    fi
}

sanitize_directory_symlinks() {
    local pkg_dir="$1"
    [ ! -d "$pkg_dir" ] && return 0

    while IFS= read -r -d '' src_d; do
        local rel_d="${src_d#$pkg_dir/}"
        if [[ "$rel_d" =~ ^(packages\.txt|services\.txt|setup\.sh|gotchas|scripts)($|/) ]] || [[ "$rel_d" =~ ^\.stow ]] || [[ "$rel_d" =~ __pycache__|\.seed$ ]]; then
            continue
        fi

        local target_d="$HOME/$rel_d"
        if [ -L "$target_d" ]; then
            local target_real
            target_real=$(realpath -q "$target_d" 2>/dev/null || true)
            local link_dest
            link_dest=$(readlink "$target_d" 2>/dev/null || true)
            if [[ -n "$target_real" && "$target_real" == "$DOTFILES_DIR"* ]] || [[ "$link_dest" =~ (^\.\./)?dotfiles/ ]]; then
                if [ "$DRY_RUN" = true ]; then
                    echo "    [dry-run] Convert directory symlink ~/$rel_d to real directory for Stow"
                else
                    rm -f "$target_d"
                    mkdir -p "$target_d"
                fi
            else
                check_and_backup_path "$target_d"
            fi
        fi
    done < <(find "$pkg_dir" -mindepth 1 -type d -print0)
}

scan_and_backup_package_conflicts() {
    local pkg_dir="$1"
    [ ! -d "$pkg_dir" ] && return 0

    while IFS= read -r -d '' src_item; do
        local rel_item="${src_item#$pkg_dir/}"
        if [[ "$rel_item" =~ ^(packages\.txt|services\.txt|setup\.sh|gotchas|scripts)($|/) ]] || [[ "$rel_item" =~ ^\.stow ]] || [[ "$rel_item" =~ __pycache__|\.pyc$ ]]; then
            continue
        fi

        local target="$HOME/$rel_item"
        if [ -e "$target" ] || [ -L "$target" ]; then
            check_and_backup_path "$target"
        fi
    done < <(find "$pkg_dir" -mindepth 1 \( -type f -o -type l \) -print0)
}

install_packages_list() {
    local pkg_file="$1"
    [ ! -f "$pkg_file" ] && return 0

    local pkgs=()
    while IFS= read -r line || [ -n "$line" ]; do
        line=$(echo "$line" | sed 's/#.*//' | xargs)
        [ -z "$line" ] && continue
        pkgs+=("$line")
    done < "$pkg_file"

    [ ${#pkgs[@]} -eq 0 ] && return 0

    local rel_path="${pkg_file#$DOTFILES_DIR/}"
    echo "--> Checking packages from $rel_path (${#pkgs[@]} items)..."

    local missing_repo_pkgs=()
    local missing_aur_pkgs=()

    for pkg in "${pkgs[@]}"; do
        if pacman -Q "$pkg" &>/dev/null; then
            continue
        fi
        if pacman -Si "$pkg" &>/dev/null; then
            missing_repo_pkgs+=("$pkg")
        else
            missing_aur_pkgs+=("$pkg")
        fi
    done

    if [ ${#missing_repo_pkgs[@]} -eq 0 ] && [ ${#missing_aur_pkgs[@]} -eq 0 ]; then
        echo "    All packages from $rel_path are already installed."
        return 0
    fi

    if [ ${#missing_repo_pkgs[@]} -gt 0 ]; then
        echo "    Installing official repository packages: ${missing_repo_pkgs[*]}..."
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] Would install via pacman: ${missing_repo_pkgs[*]}"
        else
            if (( EUID == 0 )); then
                pacman -S --needed --noconfirm "${missing_repo_pkgs[@]}" || true
            else
                sudo pacman -S --needed --noconfirm "${missing_repo_pkgs[@]}" || true
            fi
        fi
    fi

    if [ ${#missing_aur_pkgs[@]} -gt 0 ]; then
        echo "    Installing AUR packages: ${missing_aur_pkgs[*]}..."
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] Would install via yay/paru: ${missing_aur_pkgs[*]}"
        else
            if command -v yay &>/dev/null; then
                yay -S --needed --noconfirm "${missing_aur_pkgs[@]}" || true
            elif command -v paru &>/dev/null; then
                paru -S --needed --noconfirm "${missing_aur_pkgs[@]}" || true
            else
                echo "    Notice: Neither yay nor paru found to install AUR packages: ${missing_aur_pkgs[*]}" >&2
            fi
        fi
    fi
}

# --- 3. Packages Installation Step ---
if [ "$DO_PACKAGES" = true ]; then
    echo "==> [2/4] Synchronizing System & Profile Packages..."

    # Ensure GNU Stow is installed
    if ! command -v stow &>/dev/null; then
        echo "--> Ensuring GNU Stow is installed..."
        if [ "$DRY_RUN" = false ]; then
            if (( EUID == 0 )); then
                pacman -S --needed --noconfirm stow
            else
                sudo pacman -S --needed --noconfirm stow
            fi
        fi
    fi

    # 1. Core universal packages
    install_packages_list "$DOTFILES_DIR/core/packages.txt"

    # 2. Profile packages
    for p in "${STOWABLE_PROFILES[@]}"; do
        if [ -f "$DOTFILES_DIR/profiles/$p/packages.txt" ]; then
            install_packages_list "$DOTFILES_DIR/profiles/$p/packages.txt"
        fi
    done
    echo ""
else
    echo "==> [2/4] Skipping package synchronization (--only-stow specified)."
    echo ""
fi

# --- 4. Non-Destructive Backup & Stow Step ---
if [ "$DO_STOW" = true ]; then
    echo "==> [3/4] Deploying Dotfiles with GNU Stow (Non-Destructive)..."

    # Sanitize directory symlinks that point into repo so Stow can link individual files
    sanitize_directory_symlinks "$DOTFILES_DIR/core"
    for p in "${STOWABLE_PROFILES[@]}"; do
        sanitize_directory_symlinks "$DOTFILES_DIR/profiles/$p"
    done
    sanitize_directory_symlinks "$DOTFILES_DIR/agents"

    # Ensure required destination base directories exist
    if [ "$DRY_RUN" = false ]; then
        mkdir -p "$HOME/.config" \
                 "$HOME/.config/hypr" \
                 "$HOME/.config/hypr/config" \
                 "$HOME/.config/hypr/config/profile" \
                 "$HOME/.local/bin" \
                 "$HOME/.local/share/applications" \
                 "$HOME/.local/share/icons" \
                 "$HOME/Pictures/Wallpapers" \
                 "$HOME/.agents/skills/system-personalization/references/gotchas"
    fi

    # Check and backup conflicts across all deployment packages
    echo "--> Checking for conflicting configurations in ~/.config/, ~/.local/bin/, and ~/.agents/..."
    scan_and_backup_package_conflicts "$DOTFILES_DIR/core"
    for p in "${STOWABLE_PROFILES[@]}"; do
        scan_and_backup_package_conflicts "$DOTFILES_DIR/profiles/$p"
    done
    scan_and_backup_package_conflicts "$DOTFILES_DIR/agents"

    if [ "$backup_needed" = false ]; then
        echo "    No file conflicts found. Safe to link directly."
    fi

    STOW_IGNORE_FLAGS=(
        "--ignore=^packages\.txt$"
        "--ignore=^services\.txt$"
        "--ignore=^setup\.sh$"
        "--ignore=^scripts"
        "--ignore=^gotchas"
        "--ignore=^\.stow-local-ignore$"
        "--ignore=^SKILL\.md\.template$"
        "--ignore=^scripts/init-skill\.sh$"
        "--ignore=__pycache__"
        "--ignore=\.pyc$"
    )

    if command -v stow &>/dev/null; then
        echo "--> Stowing 'core' package..."
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] stow -v -R --no-folding -d \"$DOTFILES_DIR\" -t \"$HOME\" ${STOW_IGNORE_FLAGS[*]} core"
        else
            stow -v -R --no-folding -d "$DOTFILES_DIR" -t "$HOME" "${STOW_IGNORE_FLAGS[@]}" core
        fi

        for p in "${STOWABLE_PROFILES[@]}"; do
            echo "--> Stowing active profile '$p'..."
            if [ "$DRY_RUN" = true ]; then
                echo "    [dry-run] stow -v -R --no-folding -d \"$DOTFILES_DIR/profiles\" -t \"$HOME\" ${STOW_IGNORE_FLAGS[*]} \"$p\""
            else
                stow -v -R --no-folding -d "$DOTFILES_DIR/profiles" -t "$HOME" "${STOW_IGNORE_FLAGS[@]}" "$p"
            fi
        done

        echo "--> Stowing 'agents' package..."
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] stow -v -R --no-folding -d \"$DOTFILES_DIR\" -t \"$HOME\" ${STOW_IGNORE_FLAGS[*]} agents"
        else
            stow -v -R --no-folding -d "$DOTFILES_DIR" -t "$HOME" "${STOW_IGNORE_FLAGS[@]}" agents
        fi
    fi

    # Link custom webapp icons to standard XDG directories
    if [ -d "$DOTFILES_DIR/core/.local/share/applications/icons" ]; then
        for icon in "$DOTFILES_DIR"/core/.local/share/applications/icons/*; do
            if [ -f "$icon" ]; then
                filename="$(basename "$icon")"
                ln -sf "$icon" "$HOME/.local/share/icons/$filename" 2>/dev/null || true
            fi
        done
    fi

    # Update desktop application database
    if command -v update-desktop-database &>/dev/null; then
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    fi

    echo ""
else
    echo "==> [3/4] Skipping dotfile stowing (--only-packages specified)."
    echo ""
fi

# --- 5. Post-Install Setup Step ---
if [ "$DO_SETUP" = true ]; then
    echo "==> [4/4] Executing Post-Install Setup & Skill Initialization..."

    # 1. Profile setup scripts
    for p in "${STOWABLE_PROFILES[@]}"; do
        SETUP_SCRIPT="$DOTFILES_DIR/profiles/$p/setup.sh"
        if [ -f "$SETUP_SCRIPT" ]; then
            echo "--> Running setup script for profile '$p'..."
            if [ "$DRY_RUN" = true ]; then
                echo "    [dry-run] Would execute: bash $SETUP_SCRIPT"
            else
                chmod +x "$SETUP_SCRIPT"
                bash "$SETUP_SCRIPT"
            fi
        fi
    done

    # 2. Link profile-specific gotchas into system-personalization skill
    DEST_GOTCHAS_DIR="$HOME/.agents/skills/system-personalization/references/gotchas"
    for p in "${STOWABLE_PROFILES[@]}"; do
        PROFILE_GOTCHAS_DIR="$DOTFILES_DIR/profiles/$p/gotchas"
        if [ -d "$PROFILE_GOTCHAS_DIR" ]; then
            echo "--> Linking profile gotchas for '$p'..."
            for gotcha_file in "$PROFILE_GOTCHAS_DIR"/*; do
                [ -f "$gotcha_file" ] || continue
                gname="$(basename "$gotcha_file")"
                dest="$DEST_GOTCHAS_DIR/$gname"
                if [ "$DRY_RUN" = true ]; then
                    echo "    [dry-run] ln -sf \"$gotcha_file\" \"$dest\""
                else
                    mkdir -p "$DEST_GOTCHAS_DIR"
                    ln -sf "$gotcha_file" "$dest"
                    echo "    Linked gotcha: $gname"
                fi
            done
        fi
    done

    # 3. Run system-personalization skill initializer
    INIT_SKILL_SCRIPT="$DOTFILES_DIR/agents/.agents/skills/system-personalization/scripts/init-skill.sh"
    if [ -f "$INIT_SKILL_SCRIPT" ]; then
        echo "--> Initializing system-personalization AI skill..."
        if [ "$DRY_RUN" = true ]; then
            echo "    [dry-run] Would execute: bash $INIT_SKILL_SCRIPT --profiles \"$ACTIVE_PROFILES\""
        else
            chmod +x "$INIT_SKILL_SCRIPT"
            bash "$INIT_SKILL_SCRIPT" --profiles "$ACTIVE_PROFILES"
        fi
    fi

    # 4. Enable standard services (Bluetooth, UFW firewall)
    if command -v systemctl &>/dev/null; then
        if systemctl list-unit-files bluetooth.service &>/dev/null; then
            if ! systemctl is-enabled bluetooth.service &>/dev/null; then
                if sudo -n true 2>/dev/null; then
                    echo "--> Enabling bluetooth.service..."
                    sudo systemctl enable --now bluetooth.service 2>/dev/null || true
                else
                    echo "--> bluetooth.service is not active. (Run 'sudo systemctl enable --now bluetooth.service' to enable)."
                fi
            else
                echo "--> bluetooth.service is already enabled."
            fi
        fi
        if command -v ufw &>/dev/null; then
            if ! systemctl is-enabled ufw.service &>/dev/null; then
                if sudo -n true 2>/dev/null; then
                    echo "--> Configuring UFW firewall rules (LocalSend 53317)..."
                    sudo systemctl enable --now ufw.service 2>/dev/null || true
                    sudo ufw allow 53317/tcp comment 'LocalSend TCP' 2>/dev/null || true
                    sudo ufw allow 53317/udp comment 'LocalSend UDP' 2>/dev/null || true
                else
                    echo "--> ufw.service is not active. (To enable LocalSend firewall rules, run 'sudo systemctl enable --now ufw && sudo ufw allow 53317/tcp')."
                fi
            else
                echo "--> ufw.service is already enabled."
            fi
        fi
    fi

    # 5. Reload Hyprland and Noctalia if active
    if command -v hyprctl &>/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        echo "--> Reloading Hyprland configuration..."
        if [ "$DRY_RUN" = false ]; then
            hyprctl reload &>/dev/null || true
        fi
    fi
    if command -v noctalia &>/dev/null && pgrep -x noctalia &>/dev/null; then
        echo "--> Reloading Noctalia shell..."
        if [ "$DRY_RUN" = false ]; then
            noctalia msg reload &>/dev/null || true
        fi
    fi

    echo ""
else
    echo "==> [4/4] Skipping post-install setup."
    echo ""
fi

# --- 6. Summary ---
echo "======================================================="
if [ "$DRY_RUN" = true ]; then
    echo "  🔍 Dry-run simulation finished successfully!"
else
    echo "  🎉 CachyOS Multi-PC Installation & Setup Complete!   "
fi
echo "======================================================="
echo "Active Profile(s):   $ACTIVE_PROFILES"
if [ "$backup_needed" = true ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "Simulated Backup:    $BACKUP_DIR"
    else
        echo "Backup Location:     $BACKUP_DIR"
    fi
fi
echo ""
echo "Next Steps:"
echo "  1. Validate Hyprland Lua configuration:"
echo "     hyprctl configerrors"
echo "  2. Test your shortcuts:"
echo "     Super+Space (Launcher), Super+Return (Kitty)"
echo "======================================================="
