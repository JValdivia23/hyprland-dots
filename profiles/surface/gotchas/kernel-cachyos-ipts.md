# Surface Touch/Pen (IPTS) on linux-cachyos 7.x (no linux-surface kernel)

How the Surface Book 3 keeps a working touchscreen/stylus while booting the stock
CachyOS kernel (7.2+), which linux-surface had not released yet (last: 6.19.8).

---

## 1. Symptom
- Booting `linux-cachyos`: battery, charger, clipboard detach (`surface_dtx`), keyboard/touchpad
  (`surface_hid`), platform profile and dGPU hotplug all work (mainline drivers).
- Touchscreen + pen are dead: no `ipts` module, `iptsd@*` never starts,
  PCI `00:16.4` (`8086:34e4`) has **no driver**.

## 2. Root Cause
Two linux-surface-only pieces are missing from mainline:
1. **`ipts` driver** (Intel Precise Touch & Stylus) — never upstreamed.
2. **`mei_me` device ID `8086:34e4`** (Ice Lake iTouch MEI function) — linux-surface patch
   `mei: me: Add Icelake device ID for iTouch`. Without it the IPTS MEI client never appears.

The second upstream patch (IOMMU passthrough for IPTS) is **not needed**: Intel IOMMU is off by
default on CachyOS (`CONFIG_INTEL_IOMMU_DEFAULT_ON` unset, `/sys/class/iommu/` empty).

## 3. Fix (deployed by `profiles/surface/setup.sh` step 10)
| Piece | Location |
|---|---|
| Vendored driver source (upstream `intel-precise-touch` @ `3b88a45`) | `profiles/surface/dkms/ipts/` → `/usr/src/ipts-2024.04.16/` |
| DKMS (auto-rebuild on every kernel update, `BUILD_EXCLUSIVE_KERNEL="-cachyos"`) | `dkms.conf` |
| Runtime ID binder (writes `8086 34e4 ffffffff ffffffff 0 0 9` to `mei_me/new_id`) | `/usr/local/bin/surface-ipts-mei-bind` |
| udev triggers (PCI add of 34e4 + `mei_me` module add) | `/etc/udev/rules.d/72-surface-ipts-mei-bind.rules` |
| Boot order `linux-cachyos, linux-surface*, …` | `/etc/default/limine` (`BOOT_ORDER`) |

Chain: `mei_me` binds 34e4 → MEI client `3e8d0870-…` appears → udev autoloads DKMS `ipts` →
`hidraw` IPTS device → `50-iptsd.rules` starts `iptsd@dev-hidrawN.service`.

On **linux-surface** everything is a no-op: DKMS skips it and the binder exits because the
kernel's `modules.alias` already contains `34E4`.

## 4. Gotchas
- **Build with clang.** CachyOS kernels are clang-built; gcc dies on `-mllvm`, `-fms-anonymous-structs`.
  The DKMS `Makefile` auto-adds `LLVM=1` when `CONFIG_CC_IS_CLANG=y`.
- **`driver_data 9` = `MEI_ME_PCH12_CFG`** in `enum mei_cfg_idx` (`drivers/misc/mei/hw-me.h`, verified 7.2.9).
  If a future kernel reorders the enum, `mei_me` may fail to probe `00:16.4` → re-check the index.
- **Harmless:** ~10× `ipts …: Failed to process buffer: -16` right after load (before iptsd attaches),
  and the kernel "taint" message for an unsigned out-of-tree module.
- **Local patches applied over upstream `3b88a45` (`profiles/surface/dkms/ipts/src/`)**:
  1. `eds2.c`: `GET_FEATURES_TIMEOUT` reduced from `30 * MSEC_PER_SEC` to `5 * MSEC_PER_SEC` (matching `linux-surface`) and `ipts_eds2_get_feature()` switched to `mutex_lock_interruptible()` + `wait_for_completion_interruptible_timeout()`. Without this, `udev`'s `iptsd-check-device` probe during a lid-closed 30-minute `s2idle` $\rightarrow$ `hibernate` RTC wake blocks in `TASK_UNINTERRUPTIBLE` (`state:D`) for 30s, exceeding the kernel's 20s `pm_freeze_timeout` and aborting hibernation.
  2. `control.c`: Fixed upstream typo in `ipts_control_set_mem_window()` where `cmd.tail_offset_addr_lower = upper_32_bits(wq_addr);` overwrote `_lower` instead of setting `cmd.tail_offset_addr_upper`.
- **Pen** detected (`IPTS 045E:09B2 Stylus`, `IPTSD Virtual Stylus`) but untested (no pen yet).

## 5. Verification
```bash
uname -r                                              # *-cachyos
readlink -f /sys/bus/pci/devices/0000:00:16.4/driver  # .../mei_me
dkms status -m ipts                                   # installed for each cachyos kernel
lsmod | grep '^ipts'; systemctl list-units 'iptsd*'
journalctl -t surface-ipts-mei-bind -b
```

## 6. Rollback
Pick `linux-surface` in Limine (always kept). To remove entirely:
`sudo dkms remove ipts/2024.04.16 --all; sudo rm -r /usr/src/ipts-2024.04.16 /usr/local/bin/surface-ipts-mei-bind /etc/udev/rules.d/72-surface-ipts-mei-bind.rules`
and restore `/etc/default/limine.bak-ipts`.
