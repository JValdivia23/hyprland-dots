# Hardware Specifications

Documentation of the physical machine specs and active peripherals.

## CPU & System Architecture
- **Processor**: AMD Ryzen 9 4900HS (8 Cores, 16 Threads)
- **Architecture**: x86_64
- **Base/Boost Clock**: 3.0 GHz / 4.3 GHz

## Graphics Processing Units (GPUs)
- **Dedicated GPU**: NVIDIA GeForce RTX 2060 Max-Q (6 GB GDDR6)
  - Driver: proprietary NVIDIA driver (recommended) or open-source nouveau depending on setup
  - Role: High-performance rendering & external displays
- **Integrated GPU**: AMD Renoir (Radeon Vega Mobile Series)
  - Driver: `amdgpu` (open-source kernel module)
  - Role: Low-power display rendering (eDP-1) and energy saving

## Memory & Storage
- **System Memory (RAM)**: 22 GiB
- **Primary Disk**: NVMe SSD (Partition `/dev/nvme0n1p7` mounted on `/` and `/home` with 232 GB total size)

## Monitors & Display Panel
- **Panel**: Internal Laptop Display (`eDP-1`)
  - Make/Model: AU Optronics 0xE68C
  - Physical Size: 310mm x 170mm (~14 inches)
  - Native Resolution: 2560 x 1440
  - Refresh Rate: 60.01 Hz
  - Scale Factor: 1.33 (fractional scaling)

## Peripherals (Input/Output)
- **Keyboard**: Built-in laptop keyboard
- **Pointing Device**: Built-in touchpad
- **Audio Device**: AMD Renoir Audio Controller / NVIDIA TU106 HDMI Audio Controller (managed via Wireplumber/Pipewire)
