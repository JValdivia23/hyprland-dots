#!/usr/bin/env bash
# Recover the Surface IPTS touchscreen/stylus daemon after device re-enumeration.
set -u

find_ipts_devices() {
    local directory="${1:-/sys/class/hidraw}" sys
    for sys in "$directory"/hidraw*; do
        [[ -r "$sys/device/uevent" ]] || continue
        grep -q '^HID_NAME=IPTS ' "$sys/device/uevent" || continue
        printf '%s\n' "$sys"
    done
}

recover_device() {
    local sys="$1" device escaped unit properties wants
    device="/dev/${sys##*/}"
    escaped="$(systemd-escape --path "$device")" || return 1
    unit="iptsd@${escaped}.service"

    # Never restart a healthy instance or probe a device it is already using.
    if systemctl is-active --quiet "$unit"; then
        sleep 1
        if systemctl is-active --quiet "$unit"; then
            printf 'IPTS instance already active: %s\n' "$unit"
            return 0
        fi
    fi

    timeout --kill-after=2s 6s iptsd-check-device --quiet --type touchscreen "$device" || return 1
    # The packaged iptsd rule matches ACTION==add, not the default change event.
    timeout --kill-after=1s 2s udevadm trigger --action=add "$sys" || return 1
    udevadm settle --timeout=2 || true

    # Re-enumeration can invalidate the node while the add event is processed.
    [[ -r "$sys/device/uevent" ]] || return 1
    grep -q '^HID_NAME=IPTS ' "$sys/device/uevent" || return 1
    timeout --kill-after=2s 6s iptsd-check-device --quiet --type touchscreen "$device" || return 1
    properties="$(udevadm info --query=property --path="$sys")" || return 1
    wants="$(sed -n 's/^SYSTEMD_WANTS=//p' <<< "$properties")"
    [[ " $wants " == *" $unit "* ]] || return 1
    systemctl is-active --quiet "${escaped}.device" || return 1

    if systemctl is-failed --quiet "$unit"; then
        systemctl reset-failed "$unit" || return 1
    fi
    # SYSTEMD_WANTS is only acted on when a device first becomes active.
    # Explicit start also recovers a stopped daemon on an already-active device.
    systemctl --no-block start "$unit" || return 1
    sleep 1
    systemctl is-active --quiet "$unit" || return 1
    printf 'Recovered IPTS instance: %s\n' "$unit"
    pkill -x lisgd 2>/dev/null || true
}

reset_obsolete_failures() {
    local unit rest
    while read -r unit rest; do
        case "$unit" in
            iptsd@dev-hidraw*.service)
                # Only clear a stale failure whose old device node is gone.
                local node="${unit#iptsd@dev-}"
                node="${node%.service}"
                [[ -e "/dev/$node" ]] && continue
                systemctl reset-failed "$unit" || true
                ;;
        esac
    done < <(systemctl list-units --state=failed --type=service --no-legend --plain 'iptsd@*.service')
}

main() {
    local attempt sys found=0
    # Retain the hardware handshake guard, but not in the blocking sleep hook.
    sleep 2
    for attempt in 1 2 3 4 5 6; do
        while IFS= read -r sys; do
            found=1
            if recover_device "$sys"; then
                reset_obsolete_failures
                return 0
            fi
        done < <(find_ipts_devices)
        printf 'IPTS recovery not ready (attempt %s/6).\n' "$attempt"
        [[ "$attempt" == 6 ]] || sleep 2
    done
    if [[ "$found" == 0 && ! -d /sys/module/ipts ]]; then
        printf 'No IPTS driver/device present; recovery skipped.\n'
        return 0
    fi
    printf 'IPTS recovery exhausted retries; inspect the device and iptsd journal.\n' >&2
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main
fi
