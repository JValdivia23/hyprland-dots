# Apple T2 Subsystem & Hardware Gotchas

Curated hardware quirks, services, and diagnostic procedures for Apple MacBook Pro (MacBookPro15,1 with T2 Security Chip) running CachyOS Linux.

---

## 1. Touch Bar Display & Operating Modes (`kait2en-touchbar` & `tiny-dfr`)

- **Architecture & Operational Mode**:
  - **Userspace DRM Mode (`appletbdrm` + `kait2en-touchbar`, Configuration 2 - Default & Canonical)**: The standard and reliable Touch Bar architecture for Intel T2 MacBooks (`MacBookPro15,1`).
    - The Touch Bar USB device (`05ac:8302`) exposes two interfaces:
      - `7-6:2.0`: Multitouch digitizer managed by `hid-multitouch`.
      - `7-6:2.1`: DRM display framebuffer managed by `appletbdrm` -> `/dev/dri/card0`.
    - **Daemon (`kait2en-touchbar.service`)**: Modern Rust Touch Bar daemon replacing `tiny-dfr`.
      - **Features**: Dark-first OLED power saving (bar stays off until touched or `Fn` pressed), 2-finger volume swipe on dark bar, 3-finger brightness swipe on dark bar, 2-finger carousel swipe across 3 layers (Media keys, F1–F12, and extended Mac navigation keys like Home/End/PgUp/PgDn/Ins/Del).
      - **Arch Linux Font Path Gotcha**: Source hardcodes Fedora font paths (`/usr/share/fonts/adwaita-sans-fonts/`). On Arch Linux, Adwaita fonts reside in `/usr/share/fonts/Adwaita/AdwaitaSans-Regular.ttf`. `renderer.rs` MUST be patched with Arch paths before compiling.
      - **Device Group & Permissions (`99-zz-kait2en-touchbar.rules`)**: Fedora upstream assigns dedicated group `kait2en-touchbar`. To avoid requiring session re-logins or broken group states in systemd user sessions, map udev rules to `GROUP="video"` and `MODE="0660"` (`java1127` is a member of `video`).
    - **Legacy Fallback Daemon (`tiny-dfr.service`)**: Static SVG key renderer (`/etc/tiny-dfr/*.svg`), disabled by default in favor of `kait2en-touchbar`.
  - **Hardware Keyboard Mode (`hid-appletb-kbd`, Configuration 1 - Unsupported on 15,1)**: On the MacBookPro15,1 (Intel Core i9 + discrete AMD Radeon 560X), attempting to run Configuration 1 results in BridgeOS transfer queue failures (`URB failed: 3`) and continuous endpoint drops (`bce_vhci_drop_endpoint 6:11`). `hid_appletb_kbd` MUST be blacklisted in `/etc/modprobe.d/blacklist-touchbar.conf` (`blacklist hid_appletb_kbd`) to prevent the kernel from auto-claiming `05ac:8302` during sleep/resume cycles.
- **Sleep, Boot & Resume Lifecycle (`t2-sleep-helper`, `t2-touchbar-setup.service` & `99-zz-kait2en-touchbar.rules`)**:
  - **T2 Readiness Window Gotcha**: When the Touch Bar re-enumerates after boot or sleep, setting `bConfigurationValue` directly to 2 causes `appletbdrm` probe timeout (`-110` / `ETIMEDOUT: Failed to send message`). The USB device MUST cycle from `bConfigurationValue = 0` (unconfigured) to `bConfigurationValue = 2` (DRM mode) to open BridgeOS's hardware readiness window.
  - **Pre-suspend**: Saves brightness to `/run/tb_brightness` and gracefully stops `kait2en-touchbar` / `tiny-dfr` via `pkill -TERM kait2en-touchbar` to avoid sudden DRM disconnect panics.
  - **Post-resume / Boot Setup**: `t2-sleep-helper post` cycles `05ac:8302` `0 -> 2`, loads `appletbdrm` to register `/dev/dri/card0`, restores saved brightness, and restarts `systemctl --user restart kait2en-touchbar.service`. Also refreshes GPU/CPU power policy via `amdgpu-power-switch.sh auto`.
- **Diagnostic / Status**:
  ```bash
  systemctl --user status kait2en-touchbar.service
  ls -la /dev/dri/card0
  cat /sys/class/backlight/appletb_backlight/brightness
  ```

---

## 2. Suspend / Sleep Wakeup Fix (`suspend-fix-t2.service` & `t2-sleep-helper`)

- **Quirk**: T2 MacBooks can experience spontaneous wakeups or fail to enter deep sleep if PCIe devices (NVMe, Wi-Fi, T2 bridge) remain in active D0 power states, or leave Touch Bar drivers in unconfigured states.
- **Service & Helper**: Handled automatically via `suspend-fix-t2.service` executing `/usr/local/bin/t2-sleep-helper {pre|post}`.
- **Diagnostic**:
  ```bash
  systemctl status suspend-fix-t2.service
  journalctl -u suspend-fix-t2.service -b
  ```

---

## 3. Apple Audio Subsystem (`aaudio` / `apple_bce`)

- **Architecture**: Audio input/output is routed through the Apple T2 co-processor (`0000:02:00.3`) using the `aaudio` driver compiled directly into the `apple_bce` kernel module, managed by PipeWire with WirePlumber.
- **Sleep & Suspend Gotcha**: Never unbind `0000:02:00.3` or unload `apple_bce` during pre-suspend. Unbinding before sleep corrupts the BridgeOS Submission Queue handshake upon resume (`apple-bce: SQ registration failed (34/74)` / `EBADMSG`), causing PipeWire to fall back to `Dummy Output`.
- **Troubleshooting & Driver Reload**:
  ```bash
  # Inspect PipeWire sinks/sources
  wpctl status

  # If Apple Audio Device is missing or shows SQ registration error:
  kitty -e bash -c "sudo modprobe -r apple_bce && sudo modprobe apple_bce; systemctl --user restart pipewire wireplumber"
  ```

---

## 4. Fan Daemon & Thermal Throttling (`t2fanrd`)

- **Quirk**: Default Apple SMC thermal curve waits until 90–98°C before ramping fans, causing aggressive throttling on the Intel Core i9.
- **Config Gotcha**: `/etc/t2fand.conf` requires capitalized `[Fan1]` and `[Fan2]` section headers (e.g. `[fan_left]` is rejected with `Missing Fan1 in config file`).
- **Configuration**:
  ```ini
  [Fan1]
  low_temp=50
  high_temp=78
  speed_curve=exponential
  always_full_speed=false

  [Fan2]
  low_temp=50
  high_temp=78
  speed_curve=exponential
  always_full_speed=false
  ```
- **Service**: `sudo systemctl restart t2fanrd.service`

---

## 4.1 AMDGPU Power-Saving DPM Profile (`POWER_SAVING` Mode 2)

- **Quirk**: On MacBookPro15,1 (AMD Radeon Pro 560X), the kernel `amdgpu` driver defaults to profile mode 1 (`3D_FULL_SCREEN`), pegging `sclk` and `mclk` at 1000 MHz and drawing ~15.26 W idle at 67°C even on minimal desktop loads.
- **Fix**: Apply `power_dpm_force_performance_level = manual` and `pp_power_profile_mode = 2` (`POWER_SAVING`).
  - Core clock drops to ~240–300 MHz, memory clock drops to 300 MHz, idle draw drops to ~9.5–12 W (~38% reduction).
  - Managed dynamically via [`profiles/macbook-t2/scripts/amdgpu-power-switch.sh`](file:///home/java1127/dotfiles/profiles/macbook-t2/scripts/amdgpu-power-switch.sh) and [`/usr/local/bin/amdgpu-power-switch.sh`](file:///usr/local/bin/amdgpu-power-switch.sh).
  - Reapplied on resume via [`t2-sleep-helper`](file:///usr/local/bin/t2-sleep-helper).

---

## 4.2 Intel Core i9 Thermal Throttling & RAPL Limits (`t2-cpu-control`)

- **Architecture**: Intel Core i9-9880H rapidly thermal-throttles (PROCHOT at 100°C) under sustained uncapped power spikes.
- **Utility**: Installed [`t2-cpu-control`](file:///usr/local/bin/t2-cpu-control) (GTK4 / libadwaita UI) backed by `msr-tools` and `/usr/local/libexec/t2-cpu-control-helper`.
- **Capabilities**: Visual and persistent control of Intel RAPL package constraints (sustained PL1 and burst PL2 wattage), MSR TCC offset, and governor/turbo profiles across boots via `t2-cpu-control.service`.

---

## 5. Built-in Speaker DSP Tuning & EasyEffects Gotcha

- **Quirk**: Raw `aaudio` drivers lack Apple's proprietary 4-channel crossover DSP. However, loading older community `mbp.json` presets in EasyEffects 8.2+ can trigger parameter range validation errors with the Calf Multiband Compressor (`setDry: value -100 is less than -80.01`), which causes EasyEffects to stall the stream pipeline and silence audio.
- **Recovery to Clean Baseline**:
  ```bash
  systemctl --user stop easyeffects.service
  systemctl --user restart pipewire wireplumber
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 60%
  ```


---

## 6. Broadcom BCM4364 Wi-Fi Adapter (`brcmfmac`)

- **Quirk**: 802.11ac Wi-Fi uses the Broadcom BCM4364 chip. Firmware is loaded from `/lib/firmware/brcm/` via the `brcmfmac` driver.
- **Diagnostic**:
  ```bash
  ip link show wlan0
  dmesg | grep -i brcmfmac
  ```

---

## 7. macOS & CachyOS Dual-Booting (`rEFInd` + `rEFInd-minimal-black`)

- **Architecture**: Modern Macs with T2 chips store macOS on an APFS container (`nvme0n1p2`) and Linux on separate ESP/root partitions (`nvme0n1p3`, `nvme0n1p4`). Linux bootloaders like Limine only scan their own partition and do not detect APFS containers.
- **Boot Manager**: `rEFInd` is installed to `/boot/EFI/refind/refind_x64.efi` and registered as `Boot0001` with highest UEFI boot priority (`BootOrder: 0001,0000,0080`).
- **Configuration (`/boot/EFI/refind/refind.conf`)**:
  - `timeout 3`: Displays the boot menu for 3 seconds before booting CachyOS automatically.
  - `default_selection "limine,vmlinuz,cachyos"`: Preselects CachyOS as the default boot target.
  - `scanfor internal,external,optical,manual`: Scans all internal partitions for macOS APFS and Linux kernels.
  - `include themes/rEFInd-minimal-black/theme.conf`: Ultra-minimalist dark theme with pitch black background (`#000000`) and monochrome gray logos (Arch Linux & Apple macOS).
- **Duplicate Arch Entry Gotcha & Resolution**:
  - T2 MacBooks partitioned for Linux retain Apple's factory 300MB EFI partition (`nvme0n1p1`, label `EFI`) in addition to CachyOS's 4GB `/boot` partition (`nvme0n1p3`). If early installers placed Limine on `nvme0n1p1`, rEFInd's internal scan discovers Limine on *both* partitions, displaying two identical Arch Linux icons.
  - Adding `dont_scan_volumes "EFI"` instructs rEFInd to ignore the factory ESP.
  - Adding `dont_scan_dirs "EFI/BOOT"` suppresses the redundant generic fallback loader (`BOOTX64.EFI`).
  - Result: A clean dual-boot picker with exactly 1 Arch Linux icon (Limine) and 1 Apple icon (macOS).
- **Manual Apple Boot Picker Fallback**: Holding the `Option` (`⌥`) key on startup bypasses all custom bootloaders and launches the Apple hardware Startup Manager.

---

## 8. Linux 7.2+ Modular `t2bce` Driver Transition & `mkinitcpio` Compatibility

- **Quirk / Error**: When upgrading from Linux 7.1 to 7.2+, `mkinitcpio` fails with `==> ERROR: module not found: 'apple_bce'` and skips generating the kernel initramfs image.
- **Root Cause**: In kernel 7.2+, the Apple T2 Bridge Controller driver was refactored from the monolithic `apple-bce.ko` module into upstream modular **`t2bce`** drivers (`t2bce_core`, `t2bce_vhci`, `t2bce_dma`, `t2bce_audio`, and `applesmc-t2`). Legacy auto-generated hardware configs (`/etc/mkinitcpio.conf.d/11-chwd.conf`) with hardcoded `MODULES+=(apple-bce)` throw missing module errors on 7.2+ kernels.
- **Fix**: Use `?` optional module tags in `/etc/mkinitcpio.conf.d/11-chwd.conf` so `mkinitcpio` succeeds across both LTS kernels (which use `apple-bce`) and modern 7.2+ kernels (which use `t2bce`):
  ```bash
  MODULES+=(apple-bce? t2bce_core? t2bce_vhci? t2bce_dma? applesmc-t2?)
  ```
  Then regenerate initramfs via `sudo mkinitcpio -P` and `sudo limine-mkinitcpio-install < /dev/null`.

---

## 9. Linux 7.2.5+ Upstream Regression: Missing T2 Drivers (`t2bce`) & Unresponsive Keyboard/Trackpad

- **Symptom**: After updating to `linux-cachyos 7.2.5-1`, the internal Apple keyboard, trackpad, Touch Bar, and audio stop working completely. No keyboard device appears in `/proc/bus/input/devices`, and PCI device `02:00.1` (`Apple Inc. T2 Bridge Controller [106b:1801]`) has no kernel driver bound (`lspci -k -s 02:00.1`).
- **Root Cause**: Upstream CachyOS removed the `7.2/t2` kernel patch branch in the `7.2.5-1` release. As a result, the `t2bce` modules (`t2bce_core`, `t2bce_vhci`, `t2bce_dma`, `t2bce_audio`) were not compiled into `linux-cachyos 7.2.5-1`. Without `t2bce_vhci`, USB Bus 7 (the virtual host controller for internal input devices) is never created.
- **Recovery Procedures**:
  1. **Option A: Boot into `linux-cachyos-lts` (6.18.50-3)**:
     - Retains the full `t2bce` driver stack in `/usr/lib/modules/<version>/kernel/drivers/staging/t2bce/` and initializes all internal T2 peripherals reliably.
     - Note: During bootloader display (Limine / rEFInd), the internal keyboard works via UEFI hardware emulation, allowing easy arrow-key navigation to select the LTS entry.
  2. **Option B: Downgrade to `linux-cachyos 7.2.3-1` (Preserves Linux 7.2 stack)**:
     - Reinstall from pacman cache: `linux-cachyos-7.2.3-1` and `linux-cachyos-headers-7.2.3-1`.
     - **Crucial Pacman Gotcha (`nvidia-utils` conflict)**: If `linux-cachyos-nvidia-open` was installed from a generic installer profile, downgrading will fail with `cannot resolve "nvidia-utils=610.57.04", a dependency of "linux-cachyos-nvidia-open"`. Because the MacBookPro15,1 uses AMD Radeon Pro 560X graphics, `linux-cachyos-nvidia-open` is completely unused and MUST be uninstalled prior to downgrading:
       ```bash
       sudo pacman -Rdd --noconfirm linux-cachyos-nvidia-open
       ```
     - **Pacman Upgrade Pinning (`/etc/pacman.conf`)**:
       Pin the kernel packages to prevent subsequent `pacman -Syu` upgrades from re-breaking the hardware before CachyOS fixes the T2 branch:
       ```ini
       IgnorePkg = linux-cachyos linux-cachyos-headers
       ```
- **Turnkey Automation Script**:
  Staged in [`profiles/macbook-t2/scripts/cachy-downgrade-kernel-723.sh`](file:///home/java1127/dotfiles/profiles/macbook-t2/scripts/cachy-downgrade-kernel-723.sh) and installed to [`~/.local/bin/cachy-downgrade-kernel-723`](file:///home/java1127/.local/bin/cachy-downgrade-kernel-723). Handles removal of obsolete nvidia modules, cached package reinstallation, pacman pinning, initramfs rebuild, and safe reboot.
- **Upstream Resolution (`linux-cachyos 7.2.9-1`)**:
  As of October 2026, upstream CachyOS re-integrated the staging `t2bce` patch tree (`t2bce_core`, `t2bce_vhci`, `t2bce_dma`, `t2bce_audio`) and Apple SMC / Touch Bar drivers into `linux-cachyos 7.2.9-1`. Unpinning `linux-cachyos` in `/etc/pacman.conf` and upgrading to `7.2.9-1` restores normal operation with full hardware support across internal keyboard, trackpad, Touch Bar, and audio.

---

## 10. Apple T2 Touch ID Integration (`t2-touchid`) & SEP Unlock Gate

- **Architecture**:
  - The T2 Touch ID sensor is managed by Apple's Secure Enclave Processor (SEP). Linux communicates with the SEP via Apple's BridgeXPC protocol routed over the internal virtual CDC-NCM Ethernet link (`t2_ncm`, MAC `ac:de:48:00:11:22`).
  - NetworkManager manages the link-local IPv6 interface profile in `/etc/NetworkManager/system-connections/t2-ncm.nmconnection`.
  - The [`t2-touchid`](file:///usr/local/bin/t2-touchid) daemon links with `fprintd` via a virtual socket at `/run/t2-touchid/fprint.sock` (drop-in at `/etc/systemd/system/fprintd.service.d/kait2en-t2-touchid.conf`).
  - When an authentication prompt occurs, `t2-touchid` broadcasts a D-Bus event on `org.kait2en.TouchId`, triggering an animated fingerprint unlock prompt directly on [`kait2en-touchbar`](file:///usr/local/bin/kait2en-touchbar). Pressing <kbd>Esc</kbd> aborts the biometric wait and immediately falls through to password entry.
- **The "Before-First-Unlock" SEP Gate Gotcha**:
  - **Symptom**: `t2-touchid` logs `no macOS user on this Mac has a finger enrolled, or the SEP is still locked because no password has unlocked it since the T2 last powered on; log into macOS once to fix that`.
  - **Root Cause**: Linux cannot enroll new raw biometrics into Apple's SEP. The SEP biometric keybag remains locked until a macOS user account password unlocks it once after a cold boot / power cut (the exact same security gate used in iOS/macOS).
  - **Resolution**: Boot into macOS once and log in with your user password. bridgeOS only sleeps during Linux reboots, so once unlocked in macOS, the SEP keybag stays unlocked across all subsequent Linux reboots.
- **PAM Integration**:
  - Configured in `/etc/pam.d/sudo`, `/etc/pam.d/hyprlock`, and `/etc/pam.d/greetd` via `auth sufficient pam_fprintd.so` placed at the top of the auth stack. Enables Touch ID for sudo privilege escalation, lock screen unlocking, and greeter session login. If no fingers are matched or the bridge is idle, PAM falls straight through to standard password authentication without freezing.
- **Verified Live Operation**:
  - On startup, `t2-touchid` detects the unlocked SEP on macOS UID 502 and automatically binds all enrolled fingers to Linux user `java1127` (`#0: right-thumb`, `#1: right-middle-finger`, `#2: right-index-finger`).
  - Tested live and confirmed working: `sudo -k && sudo whoami` prompts on the Touch Bar and authenticates immediately upon resting an enrolled finger on the sensor.

---

## 11. CPU & PCIe Power Tuning (`t2-power-tune` & `t2-power-explorer`)

- **Telemetry & ASPM Control**:
  - [`t2-power-tune`](file:///usr/local/bin/t2-power-tune) provides a GTK4 / Libadwaita interface displaying real-time 1-second interval Package C-state residencies (C2, C3, C6, C7, C8, C9, C10) sampled from `/sys/kernel/debug/pmc_core/package_cstate_show` via [`t2-power-tune-status`](file:///usr/local/libexec/t2-power-tune-status).
  - Granularly toggles PCIe ASPM (L0s, L1) across internal buses and enables runtime power management (`power/control -> auto`) on idle devices.
  - Safe application mode writes changes for the active session first; click "Create/Update systemd service" to generate `/etc/systemd/system/kait2en-power-tune.service` once verified.
- **Diagnostics**:
  - [`t2-power-explorer`](file:///usr/local/bin/t2-power-explorer) audits PCIe power management capabilities (D0–D3hot, D3cold) and display lanes across all buses on pure Wayland.

---

## 12. Dual-GPU Management & Integrated GPU Boot (`apple-gmux` & KAIT2EN `t2-dgpu-control`)

- **Architecture & Dual GPU Layout**:
  - The MacBookPro15,1 features an Intel UHD Graphics 630 (IGD) and an AMD Radeon Pro 560X (DIS).
  - Internal Retina display (`eDP-1`) is multiplexed by Apple's custom GMUX hardware chip.
  - If booted via standard third-party bootloaders (like Limine or GRUB without macOS spoofing), Apple EFI firmware cuts power to and hides the Intel UHD 630 (`00:02.0`) from the PCI bus completely.
- **The apple-set-os Firmware Unhide (`rEFInd` + `spoof_osx_version 10.9`)**:
  - In `/boot/EFI/refind/refind.conf`, `spoof_osx_version 10.9` invokes the `APPLE_SET_OS_PROTOCOL` (`Mac OS X 10.9` / `Apple Inc.`), signaling the firmware ROM to power up and expose `00:02.0` on PCI.
  - **Gotcha: Never put `apple_set_os.efi` in `drivers_x64/`**: `apple_set_os.efi` is a PE32+ application (`subsystem 10`), not an EFI driver (`subsystem 11`). Placing it in `drivers_x64/` causes rEFInd's driver loader to hang at the Apple logo. Use rEFInd's native `spoof_osx_version 10.9`.
- **The `gpu-power-prefs` NVRAM Hazard**:
  - **NEVER write `01 00 00 00` to `gpu-power-prefs` in NVRAM**: On a MacBookPro15,1, setting this EFI variable instructs firmware POST to route GMUX to the iGPU before rEFInd or GOP drivers initialize, resulting in a cold POST black screen requiring an NVRAM reset (<kbd>Option</kbd>+<kbd>Command</kbd>+<kbd>P</kbd>+<kbd>R</kbd>).
  - Leave NVRAM `gpu-power-prefs` as `00 00 00 00` (discrete POST). Dynamic switching to iGPU is handled cleanly in Linux via `apple-gmux`.
- **Dynamic Linux Switching & dGPU Sleep**:
  - **Modprobe Option**: `/etc/modprobe.d/apple-gmux.conf` (`options apple-gmux force_igd=y`) tells the kernel driver to switch the multiplexer to Intel once `00:02.0` is confirmed live.
  - **Kernel Parameter**: `i915.enable_guc=3` in `/etc/default/limine` enables GuC/HuC firmware loading to prevent sleep/resume wake freezes.
  - **Initramfs**: `MODULES+=(i915? ...)` in `/etc/mkinitcpio.conf.d/11-chwd.conf`.
  - **dGPU Sleep Service (`kait2en-dgpu-off.service`)**: Powers off the discrete AMD GPU via `vgaswitcheroo` (`DIS: :Off`), dropping idle draw from ~20W to ~8–9W and cooling thermals to ~52°C. Uses a 15-second loop on boot to wait for asynchronous `vgaswitcheroo` debugfs registration.
  - **dGPU Sleep Cycle (`kait2en-dgpu-suspend.service`)**: Temporarily restores power to dGPU during suspend and cuts it after resume to prevent AMD driver wake crashes.







