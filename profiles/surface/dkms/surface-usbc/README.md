# surface-usbc-dkms — USB-C UCSI-over-HID & SSAM Adapter Rating (`Artg`) for Microsoft Surface

Out-of-tree DKMS kernel module package for CachyOS / Arch Linux `7.1+` kernels (`LLVM=1` Clang and GCC) on Microsoft Surface Book 3 (and Surface Pro X):

1. **`ucsi_surface_hid.ko`:**
   - Bridges Microsoft's SSAM HID UCSI Platform Policy Manager (`HID\VID_045E&UP:FF00_U:F900`, Feature/Input Report `0x32` + Feature Report `0x33`) to the Linux `typec_ucsi` subsystem.
   - Exposes `/sys/class/typec/port0` (Type-C 1.3, USB PD 3.0, data/power roles) and `/sys/class/power_supply/ucsi-source-psy-*` while leaving sibling HID collections (`045E:09A6` Base CFU `0xFF0B:0x0101`, `09AE` keyboard, `09AF` touchpad) intact.
2. **`surface_charger.ko`:**
   - Extends `drivers/power/supply/surface_charger.c` with SSAM `TC=0x02, CID=0x0f` (`Artg`, connected AC / USB-C PD adapter wattage rating in `mW`), exposed via `/sys/class/power_supply/ADP1/input_power_limit` (in `uW`), and fixes `spwr_ac_get_property()`'s positive return value on state transitions.

## Upstream Pull Requests

- [`linux-surface/kernel#184`](https://github.com/linux-surface/kernel/pull/184)
- [`linux-surface/linux-surface#2354`](https://github.com/linux-surface/linux-surface/pull/2354)
