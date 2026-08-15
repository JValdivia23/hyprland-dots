# Hardware Specifications

Documentation of physical machine specs and active hardware subsystems for `cachyos-cu`.

## Machine & Architecture
- **System**: Apple MacBook Pro 15,1 (`MacBookPro15,1`, Chassis: Laptop)
- **Processor**: Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz (8 Cores, 16 Threads)
  - Architecture: x86_64 (Coffee Lake)
  - Base / Max Clock: 800 MHz / 4800 MHz
  - Cache: L1 512 KiB, L2 2 MiB, L3 16 MiB

## Graphics Processing Unit (GPU)
- **Discrete GPU**: AMD Radeon Pro 560X (Baffin / Polaris 11, GCN 4, 4 GB GDDR5)
  - Driver: `amdgpu` (open-source kernel module)
  - Bus ID: `01:00.0` (PCIe 8 GT/s x8)
  - Display Engine: Wayland / Hyprland direct rendering on `eDP-1`

## Memory & Storage
- **System Memory (RAM)**: 16 GiB (15.5 GiB available)
- **Swap**: 15.5 GiB zram (`/dev/zram0`, priority 100)
- **Internal Storage**: Apple NVMe SSD 512 GB (`AP0512M`)
  - Linux Root / Home: `/dev/nvme0n1p4` (229 GB Btrfs, subvolumes `@`, `@home`, `@var_log`, etc.)
  - Boot: `/dev/nvme0n1p3` (4.0 GB vfat, mounted on `/boot`)
  - macOS Dual Boot: `/dev/nvme0n1p2` (APFS container)
  - EFI: `/dev/nvme0n1p1` (vfat FAT32)

## Display Panel
- **Panel**: Internal Retina Display (`eDP-1`)
  - Model: Apple Computer Inc Color LCD
  - Physical Size: 330mm x 210mm (~15.4 inches)
  - Native Resolution: 2880 x 1800 @ 60.00 Hz (DPI: 221)
  - Hyprland Scale Factor: `1.3333334`

## Apple T2 Security Chip & Subsystems
- **T2 Bridge Controller**: Apple Inc. T2 Bridge Controller (`apple-bce` driver)
- **Touch Bar Display**: USB HID display (`appletbdrm` DRM driver, `tiny-dfr.service` for dynamic function keys)
- **Audio Device**: Apple Audio (`aaudio` kernel driver, managed via PipeWire + WirePlumber)
- **Wireless Network**: Broadcom BCM4364 802.11ac Wireless Network Adapter (`brcmfmac` driver)
- **Camera**: Apple FaceTime HD Camera Built-in (`uvcvideo` driver)
- **Power & Suspend**: Managed via `suspend-fix-t2.service`

