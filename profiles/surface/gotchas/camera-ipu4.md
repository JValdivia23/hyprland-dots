# Surface Book 3 Internal Cameras (Intel IPU4P) — Native support via DKMS + libcamera

**Scope:** device-specific (`profiles/surface`). Deployed 2026-11-01 on `7.3.0-2-cachyos`.

## 1. Working state
- All 3 sensors stream through libcamera (SoftISP/GPU-ISP): Front RGB `OV5693` (~28.7 fps), Rear RGB `OV8865` (~15 fps), Front IR `OV7251` (30 fps, `R10`). `cam --list` shows all three; WirePlumber shows `Surface Front Camera`, `Surface Rear Camera`, `Surface Front IR Camera`.
- Stack: DKMS `surface-ipu4p` (`dkms/ipu4p/`: `intel-ipu6`, `intel-ipu6-isys`, `ov7251`, `ov5693`) on stock kernel + stock `ipu-bridge`/`ov8865`/`dw9719`; signed firmware `/usr/lib/firmware/intel/ipu/ipu4p_fw.bin` (SHA-256 `ff2c36cc…e5157f`, license in `camera/firmware/`); IPA tuning in `/etc/libcamera/ipa/simple/`; WirePlumber `/etc/wireplumber/wireplumber.conf.d/52-surface-ipu4p.conf`.
- Deploy: `sudo bash profiles/surface/scripts/install-cameras.sh [--no-packages]` (also Step 13 of `setup.sh`).
- Upstream-able source: `~/work/surface-ipu4p/surface-ipu4p-dkms` (git), RE report `~/work/surface-ipu4p/CRAFT-ANYTHING-RE-REPORT.md`.

## 2. Gotchas
- **Never install popos123's `99-surface-ipu6-video.rules`** (`0600`, no `uaccess`) — it blocks user-session libcamera.
- Do not copy `media-ref/include/media/ipu-bridge.h` into the DKMS tree (struct ABI vs stock `ipu-bridge.ko`).
- libcamera requires `V4L2_CID_ANALOGUE_GAIN`; stock `ov7251` only had `V4L2_CID_GAIN` (fixed in DKMS copy).
- V4L2 driver name is `isys`, card `ipu4p` (not `intel-ipu6`); WirePlumber rule matches `device.name ~ v4l2_device.pci-0000_00_05.0.*`.
- Kernel >= 7.4 adds a `v4l2_subdev_client_info *ci` pad-op arg; DKMS sources guard with `LINUX_VERSION_CODE`.
- DKMS rebuilds automatically per kernel (`BUILD_EXCLUSIVE_KERNEL=-cachyos`); on linux-surface kernel no DKMS needed? Not tested.

## 3. Known issues / TODO
- `dw9719` VCM: `Error writing reg 0x0003: -121` at probe; libcamera `cam` logs "Lens initialisation failed" -> no rear autofocus.
- While WirePlumber runs, libcamera keeps the rear lens subdev open, so `ov8865`/VCM and `INT3472:01-avdd` stay powered (stopping WirePlumber suspends everything). Idle-power cost unmeasured.
- IR (`ov7251`) has no libcamera sensor helper (works with defaults).
