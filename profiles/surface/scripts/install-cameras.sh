#!/usr/bin/env bash
# Deploy native Intel IPU4P (8086:8a19) internal camera support for
# Surface Book 3 / Surface Pro 7:
#   1. Signed Intel IPU4P firmware (/usr/lib/firmware/intel/ipu/ipu4p_fw.bin)
#   2. DKMS modules (surface-ipu4p: intel-ipu6, intel-ipu6-isys, ov7251, ov5693)
#   3. libcamera simple IPA tuning (/etc/libcamera/ipa/simple/{ov5693,ov8865,ov7251}.yaml)
#   4. WirePlumber drop-in (/etc/wireplumber/wireplumber.conf.d/52-surface-ipu4p.conf)
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run with sudo: $0 [--no-packages]" >&2
    exit 1
fi

PRODUCT_NAME="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
if [[ "$PRODUCT_NAME" != "Surface Book 3" && "$PRODUCT_NAME" != "Surface Pro 7" ]]; then
    echo "Intel IPU4P camera stack is restricted to Surface Book 3 / Surface Pro 7 (found: $PRODUCT_NAME)." >&2
    exit 1
fi

if [[ $# -gt 1 || ( $# -eq 1 && $1 != --no-packages ) ]]; then
    echo "Usage: $0 [--no-packages]" >&2
    exit 1
fi

PROFILE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
DKMS_SRC="$PROFILE_DIR/dkms/ipu4p"
CAM_DIR="$PROFILE_DIR/camera"

if [[ ! -f "$DKMS_SRC/dkms.conf" ]]; then
    echo "Missing DKMS source tree at $DKMS_SRC" >&2
    exit 1
fi

REQUIRED_PKGS=(dkms libcamera libcamera-ipa libcamera-tools pipewire-libcamera)
if [[ ${1:-} != --no-packages ]]; then
    echo "--> Ensuring camera & DKMS packages are installed..."
    pacman -S --needed "${REQUIRED_PKGS[@]}"
fi
pacman -Q "${REQUIRED_PKGS[@]}" >/dev/null

# 1. Install signed Intel IPU4P CSE firmware (SHA-256 verified) + license
FW_SHA256="ff2c36cc81a5c726508b22970c2e2538ff06107dc5a72c93401403c227e5157f"
FW_DEST="/usr/lib/firmware/intel/ipu/ipu4p_fw.bin"
FW_URL="https://raw.githubusercontent.com/ulfendk/sb3-ipu4-camera/main/kernel/ipu4-20191030.bin"

verify_fw_sha256() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    [[ "$(sha256sum "$file" | awk '{print $1}')" == "$FW_SHA256" ]]
}

if verify_fw_sha256 "$FW_DEST"; then
    echo "--> Verified existing $FW_DEST (SHA-256 OK)"
else
    INVOKER_HOME=""
    if [[ -n "${SUDO_USER:-}" ]]; then
        INVOKER_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6 || true)"
    fi
    CANDIDATES=(
        "${IPU4P_FW_SRC:-}"
        "$CAM_DIR/firmware/ipu4p_fw.bin"
        "${INVOKER_HOME:+$INVOKER_HOME/work/surface-ipu4p/windows-drivers/sb3-camera-drivers/SurfaceUpdate/camera/cpd_component_signed.bin}"
        "${INVOKER_HOME:+$INVOKER_HOME/work/surface-ipu4p/sb3-ipu4-camera/kernel/ipu4-20191030.bin}"
    )
    FOUND_FW=""
    for cand in "${CANDIDATES[@]}"; do
        if [[ -n "$cand" ]] && verify_fw_sha256 "$cand"; then
            FOUND_FW="$cand"
            break
        fi
    done

    TMP_FW=""
    trap '[[ -n "${TMP_FW:-}" && -f "$TMP_FW" ]] && rm -f "$TMP_FW"' EXIT
    if [[ -z "$FOUND_FW" ]]; then
        echo "--> Fetching signed Intel IPU4P firmware from $FW_URL..."
        TMP_FW="$(mktemp)"
        curl -fsSL "$FW_URL" -o "$TMP_FW"
        if ! verify_fw_sha256 "$TMP_FW"; then
            echo "Firmware SHA-256 verification failed for $FW_URL" >&2
            exit 1
        fi
        FOUND_FW="$TMP_FW"
    fi

    echo "--> Installing verified firmware to $FW_DEST..."
    install -Dm644 -- "$FOUND_FW" "$FW_DEST"
fi

install -Dm644 -- "$CAM_DIR/firmware/LICENSE.ipu4-firmware" \
    /usr/share/licenses/surface-ipu4p/LICENSE.ipu4-firmware

# 2. Deploy libcamera simple IPA tuning & WirePlumber rule
echo "--> Deploying libcamera simple IPA tuning files to /etc/libcamera/ipa/simple/..."
for yaml in ov5693.yaml ov8865.yaml ov7251.yaml; do
    install -Dm644 -- "$CAM_DIR/ipa/simple/$yaml" "/etc/libcamera/ipa/simple/$yaml"
done

echo "--> Deploying WirePlumber camera rule to /etc/wireplumber/wireplumber.conf.d/52-surface-ipu4p.conf..."
install -Dm644 -- "$CAM_DIR/wireplumber/52-surface-ipu4p.conf" \
    /etc/wireplumber/wireplumber.conf.d/52-surface-ipu4p.conf

# 3. Deploy & build surface-ipu4p DKMS modules
PKG_NAME="$(sed -n 's/^PACKAGE_NAME="\(.*\)"/\1/p' "$DKMS_SRC/dkms.conf")"
PKG_VER="$(sed -n 's/^PACKAGE_VERSION="\(.*\)"/\1/p' "$DKMS_SRC/dkms.conf")"
echo "--> Deploying DKMS $PKG_NAME/$PKG_VER..."

while IFS= read -r old_ver; do
    [[ -n "$old_ver" && "$old_ver" != "$PKG_VER" ]] || continue
    dkms remove -m "$PKG_NAME" -v "$old_ver" --all 2>/dev/null || true
    rm -rf "/usr/src/${PKG_NAME}-${old_ver}"
done < <(dkms status -m "$PKG_NAME" 2>/dev/null | awk -F'[,/ ]+' '{print $2}' | sort -u)

if dkms status -m "$PKG_NAME" -v "$PKG_VER" 2>/dev/null | grep -q .; then
    dkms remove -m "$PKG_NAME" -v "$PKG_VER" --all 2>/dev/null || true
fi
rm -rf "/usr/src/${PKG_NAME}-${PKG_VER}"
cp -r "$DKMS_SRC" "/usr/src/${PKG_NAME}-${PKG_VER}"

dkms add -m "$PKG_NAME" -v "$PKG_VER"
KVER="$(uname -r)"
if [[ "$KVER" == *-cachyos* ]]; then
    dkms build -m "$PKG_NAME" -v "$PKG_VER" -k "$KVER"
    dkms install --force -m "$PKG_NAME" -v "$PKG_VER" -k "$KVER"
else
    dkms autoinstall || true
fi
depmod -a "$KVER"

# 4. Live hot-load on running CachyOS kernel (no reboot required)
if [[ "$KVER" == *-cachyos* && -d /sys/bus/pci/devices/0000:00:05.0 ]]; then
    echo "--> Reloading IPU4P & sensor kernel modules on live kernel ($KVER)..."
    # libcamera inside the user's WirePlumber keeps the camera subdevs open,
    # which pins the modules; stop it for the reload and restart it afterwards.
    USER_CTL=()
    if [[ -n "${SUDO_USER:-}" ]] && id "$SUDO_USER" &>/dev/null; then
        USER_CTL=(sudo -u "$SUDO_USER" env "XDG_RUNTIME_DIR=/run/user/$(id -u "$SUDO_USER")" systemctl --user)
        "${USER_CTL[@]}" stop wireplumber.service 2>/dev/null || true
    fi
    modprobe -r intel_ipu6_isys intel_ipu6 2>/dev/null || true
    modprobe -r ov7251 ov5693 ov8865 dw9719 2>/dev/null || true

    modprobe intel_ipu6
    modprobe intel_ipu6_isys
    modprobe ov5693 || true
    modprobe ov8865 || true
    modprobe dw9719 || true
    modprobe ov7251 || true
    if [[ ${#USER_CTL[@]} -gt 0 ]]; then
        "${USER_CTL[@]}" start wireplumber.service 2>/dev/null || true
    fi
fi

echo "==> Surface IPU4P native camera stack installed successfully."
