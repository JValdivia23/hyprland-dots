#!/bin/sh
# Bind the stock mei_me driver to the Ice Lake iTouch MEI function (8086:34e4)
# on kernels that lack linux-surface's "mei: me: Add Icelake device ID for iTouch"
# patch (e.g. linux-cachyos). Once bound, the IPTS MEI client appears and udev
# autoloads the DKMS ipts module, which in turn starts iptsd.
#
# driver_data 9 = MEI_ME_PCH12_CFG in enum mei_cfg_idx (drivers/misc/mei/hw-me.h),
# the same config the linux-surface patch uses. Verified on 7.2.9. Re-check if a
# future kernel reorders that enum (symptom: mei_me probe error on 00:16.4).
set -u
CFG_IDX=9
dev=""
for d in /sys/bus/pci/devices/*; do
    if [ "$(cat "$d/vendor" 2>/dev/null)" = "0x8086" ] && [ "$(cat "$d/device" 2>/dev/null)" = "0x34e4" ]; then
        dev="$d"
        break
    fi
done
[ -n "$dev" ] || exit 0
[ -e "$dev/driver" ] && exit 0

# The kernel already knows the ID (linux-surface) -> nothing to do.
grep -qi 'pci:v00008086d000034E4' "/lib/modules/$(uname -r)/modules.alias" 2>/dev/null && exit 0

[ -d /sys/bus/pci/drivers/mei_me ] || modprobe mei_me || exit 1
[ -e "$dev/driver" ] && exit 0

if echo "8086 34e4 ffffffff ffffffff 0 0 $CFG_IDX" > /sys/bus/pci/drivers/mei_me/new_id 2>/dev/null; then
    logger -t surface-ipts-mei-bind "bound mei_me to ${dev##*/} (cfg $CFG_IDX)"
else
    logger -t surface-ipts-mei-bind "failed to add 8086:34e4 to mei_me"
fi
