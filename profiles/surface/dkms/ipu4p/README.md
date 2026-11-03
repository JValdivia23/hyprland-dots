# surface-ipu4p-dkms — Native Linux Camera Stack for Microsoft Surface Book 3 & Surface Pro 7

Out-of-tree DKMS kernel module stack + `libcamera` SoftISP/GPU-ISP tuning + WirePlumber configuration bringing **all 3 internal cameras** (Front RGB `OV5693`, Rear RGB `OV8865` + `DW9719` VCM, and Front IR `OV7251`) to stock Arch / CachyOS Linux `7.3+` / `7.4+` kernels (`LLVM=1` Clang and GCC) on Intel Ice Lake IPU4P (`8086:8a19`).

Built on top of [`ruslanbay/ipu4-drivers`](https://github.com/ruslanbay/ipu4-drivers) RFC v2 (`[RFC PATCH v2 00/12] media: intel/ipu6: add Intel IPU4P ISYS support`), [`linux-surface/linux-surface#2289`](https://github.com/linux-surface/linux-surface/pull/2289) (`@popos123` & `@loafecho`), and clean-room hardware reverse engineering of Surface Book 3's Windows 11 driver package (`iacamera64.sys` & `OV8865_MSHW0201_ICL.aiqb`) via [Craft Anything](https://getartcraft.com/apps/craft-anything).

---

## Hardware Discoveries Added Beyond RFC v2

1. **Missing CSI-2 D-PHY Building Block 8 (`ipu4p-isys-csi-phy.c`):**
   - `iacamera64.sys` (`sub_14004df80` / `sub_14004e034`, table at `0x140111020`) maps `fw_port 6` (Linux CSI-2 Port 1, Front IR `OV7251`, `i2c-INT347E:00`) to **Building Block 8** (`{ 8, 13, 32, 0x15 }`), alongside `fw_port 3` -> BB 6 (Rear `OV8865`) and `fw_port 7` -> BB 10 (Front `OV5693`).
2. **16-ticks/ns IPU4P CSI-2 D-PHY Counter (`IPU4P_CSI2_ACCINV = 16`, `ipu6-isys-csi2.c`):**
   - `iacamera64.sys` (`sub_14004e290` / `sub_14004e313`) computes `csettle = 0x5f0 - 128000 / rate_mhz` (`16 * 95 ns`) and `dsettle = 0x550 - 32000 / rate_mhz` (`16 * 85 ns`), proving IPU4P's D-PHY timer runs at `0.0625 ns` resolution (`ACCINV = 16`), double IPU6's `CSI2_ACCINV = 8`.
3. **Architectural 2-Lane vs 4-Lane CSI-2 RX `DLY_CNT` Register Map (`ipu4p-isys-csi-phy.c`):**
   - Replaces the Surface Pro 7 DMI quirk from RFC v2 `11/12` with the true hardware register split from `sub_14004e313`:
     - **2-lane CSI-2 RX blocks** (`fw_port 0, 1, 6, 7` -> Linux CSI-2 ports `1` and `2`): shifted `DLY_CNT` offsets (`+0x30` `TERMEN_CLANE`, `+0x34` `SETTLE_CLANE`, `+0x38 + 8*i` `TERMEN_DLANE`, `+0x3c + 8*i` `SETTLE_DLANE`).
     - **4-lane CSI-2 RX blocks** (`fw_port 2, 3, 8, 9` -> Linux CSI-2 port `0` and ports `3..4`): unshifted `DLY_CNT` offsets (`+0x2c`, `+0x30`, `+0x34 + 8*i`, `+0x38 + 8*i`).
4. **Ice Lake Package C-State PM QoS Clamp (`IPU4P_ISYS_PM_QOS_VALUE = 100`, `ipu6-isys.c`):**
   - Holds CPU DMA latency `<= 100 us` only while ISYS is actively streaming (`@loafecho`), preventing Ice Lake deep C-state CSI-2 FIFO stalls while allowing full runtime PM suspend when idle.
5. **Surface `INT3472` Discrete `"avdd"` Regulator Support in `ov7251.c`:**
   - Acquires optional `"avdd"` gpio-regulator (`INT3472:02-avdd`) and optional `"enable"` / `"reset"` / `"powerdown"` GPIOs so `i2c-INT347E:00` powers up cleanly on Surface Book 3 & Surface Pro 7.
6. **Genuine Surface Book 3 `OV8865` 7-Illuminant CCM (`configs/ipa/simple/ov8865.yaml`):**
   - Extracted 7 calibrated `traditional_matrix` 3x3 CCMs (`2864K`–`6227K`) directly from `OV8865_MSHW0201_ICL.aiqb` (`CPFF/AIQB`), replacing the uncalibrated identity matrix stub.
