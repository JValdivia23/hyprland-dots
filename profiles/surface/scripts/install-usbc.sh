#!/usr/bin/env bash
# Deploy Microsoft Surface UCSI-over-HID (ucsi_surface_hid) and SSAM charger
# Artg power rating (surface_charger) DKMS modules on CachyOS 7.1+ kernels.
set -euo pipefail

if (( EUID != 0 )); then
    echo "ERROR: install-usbc.sh must be run as root (via sudo)." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DKMS_SRC="${PROFILE_DIR}/dkms/surface-usbc"

if [[ ! -f "${DKMS_SRC}/dkms.conf" ]]; then
    echo "ERROR: Missing DKMS source at ${DKMS_SRC}" >&2
    exit 1
fi

PKG_NAME="$(sed -n 's/^PACKAGE_NAME="\(.*\)"/\1/p' "${DKMS_SRC}/dkms.conf")"
PKG_VER="$(sed -n 's/^PACKAGE_VERSION="\(.*\)"/\1/p' "${DKMS_SRC}/dkms.conf")"

echo "--> Installing DKMS ${PKG_NAME}/${PKG_VER}..."

while IFS= read -r old_ver; do
    [[ -n "${old_ver}" && "${old_ver}" != "${PKG_VER}" ]] || continue
    dkms remove -m "${PKG_NAME}" -v "${old_ver}" --all 2>/dev/null || true
    rm -rf "/usr/src/${PKG_NAME}-${old_ver}"
done < <(dkms status -m "${PKG_NAME}" 2>/dev/null | awk -F'[,/ ]+' '{print $2}' | sort -u)

if dkms status -m "${PKG_NAME}" -v "${PKG_VER}" 2>/dev/null | grep -q .; then
    dkms remove -m "${PKG_NAME}" -v "${PKG_VER}" --all 2>/dev/null || true
fi

rm -rf "/usr/src/${PKG_NAME}-${PKG_VER}"
cp -r "${DKMS_SRC}" "/usr/src/${PKG_NAME}-${PKG_VER}"
make -C "/usr/src/${PKG_NAME}-${PKG_VER}" clean >/dev/null 2>&1 || true

dkms add -m "${PKG_NAME}" -v "${PKG_VER}"
KVER="$(uname -r)"
if [[ "${KVER}" == 7.*-cachyos* || "${KVER}" == 8.*-cachyos* || "${KVER}" == 9.*-cachyos* ]]; then
    dkms build -m "${PKG_NAME}" -v "${PKG_VER}" -k "${KVER}"
    dkms install --force -m "${PKG_NAME}" -v "${PKG_VER}" -k "${KVER}"
else
    dkms autoinstall || true
fi
depmod -a "${KVER}"

# Live hot-reload on running CachyOS kernel (no reboot required)
if [[ "${KVER}" == 7.*-cachyos* || "${KVER}" == 8.*-cachyos* || "${KVER}" == 9.*-cachyos* ]]; then
    echo "--> Hot-loading ucsi_surface_hid and patched surface_charger on live kernel (${KVER})..."
    if [[ -d /sys/module/ucsi_surface_hid ]]; then
        rmmod ucsi_surface_hid
    fi
    if [[ -d /sys/module/surface_charger ]]; then
        rmmod surface_charger
    fi
    modprobe typec_ucsi
    modprobe typec_displayport 2>/dev/null || true
    modprobe ucsi_surface_hid
    modprobe surface_charger
    sleep 2

    echo "--> Live verification:"
    dkms status -m "${PKG_NAME}"
    ls -ld /sys/class/typec/port* 2>/dev/null || true
    cat /sys/class/power_supply/ADP1/uevent 2>/dev/null || true
fi

echo "==> ${PKG_NAME}/${PKG_VER} DKMS installation complete."
