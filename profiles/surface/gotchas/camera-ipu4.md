# Surface Book 3 Internal Cameras (Intel IPU4) — Unsupported

**Scope:** device-specific (`profiles/surface`).

## 1. Symptom
- No `/dev/video*` or `/dev/media*` nodes; `v4l2-ctl --list-devices` is empty; apps/browsers see no camera.
- `lsmod` shows sensor drivers (`ov8865`, `ov5693`, `ov7251`) and `videodev`/`v4l2_async`, and `dmesg` only logs `ov8865 i2c-INT347A:00: supply dvdd/dovdd not found, using dummy regulator`.
- `lspci -k -s 00:05.0` shows `Intel Image Signal Processor [8086:8a19]` with **no "Kernel driver in use"**.

## 2. Root Cause
- Surface Book 3 (Ice Lake) uses the Intel **IPU4** ISP (`8086:8a19`), not IPU3 or IPU6.
- `ipu3_cio2` only matches `8086:9d32` (IPU3); `intel-ipu6` only covers newer Tiger Lake+ IDs. Nothing in mainline or `linux-surface` binds IPU4, and Intel never released upstream drivers/firmware for it.
- The OmniVision sensor modules loading is cosmetic: with no ISP/CSI bridge driver, no video pipeline is created.

## 3. Verdict
- **No software fix exists** (checked 2026-10-18 on kernel `7.2.9-2-cachyos`). Do not waste time on `libcamera`, `pipewire-libcamera`, `linux-surface` kernel swaps, or `ipu3-*` modules.
- Only workaround: an external USB UVC webcam, which works out of the box (`uvcvideo`).
- Re-check only if `linux-surface`/mainline announces IPU4 support.
