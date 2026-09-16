# Apple T2 Subsystem & Hardware Gotchas

Curated hardware quirks, services, and diagnostic procedures for Apple MacBook Pro (MacBookPro15,1 with T2 Security Chip) running CachyOS Linux.

---

## 1. Touch Bar Display & Operating Modes (`hid-appletb-kbd` & `tiny-dfr`)

- **Architecture & Operational Mode**:
  - **Userspace DRM Mode (`appletbdrm` + `tiny-dfr`, Configuration 2 - Default & Canonical)**: The standard and reliable Touch Bar architecture for Intel T2 MacBooks (`MacBookPro15,1`).
    - The Touch Bar USB device (`05ac:8302`) exposes two interfaces:
      - `7-6:2.0`: Multitouch digitizer managed by `hid-multitouch`.
      - `7-6:2.1`: DRM display framebuffer managed by `appletbdrm` -> `/dev/tiny_dfr_display`.
    - **Daemon (`tiny-dfr.service`)**: Renders custom vector SVG keys (`/etc/tiny-dfr/*.svg`), handles `Fn` layer switching (F-keys ⬌ Media controls), smooth touch input emission via `uinput`, and OLED burn-in pixel shift (`EnablePixelShift = true`).
  - **Hardware Keyboard Mode (`hid-appletb-kbd`, Configuration 1 - Unsupported on 15,1)**: On the MacBookPro15,1 (Intel Core i9 + discrete AMD Radeon 560X), attempting to run Configuration 1 results in BridgeOS transfer queue failures (`URB failed: 3`) and continuous endpoint drops (`bce_vhci_drop_endpoint 6:11`). `hid_appletb_kbd` MUST be blacklisted in `/etc/modprobe.d/blacklist-touchbar.conf` (`blacklist hid_appletb_kbd`) to prevent the kernel from auto-claiming `05ac:8302` during sleep/resume cycles.
- **Sleep, Boot & Resume Lifecycle (`t2-sleep-helper`, `t2-touchbar-setup.service` & `99-touchbar-tiny-dfr.rules`)**:
  - **T2 Readiness Window Gotcha**: When the Touch Bar re-enumerates after boot or sleep, setting `bConfigurationValue` directly to 2 causes `appletbdrm` probe timeout (`-110` / `ETIMEDOUT: Failed to send message`). The USB device MUST cycle from `bConfigurationValue = 0` (unconfigured) to `bConfigurationValue = 2` (DRM mode) to open BridgeOS's hardware readiness window.
  - **Pre-suspend**: Saves brightness to `/run/tb_brightness` and gracefully stops `tiny-dfr.service` to avoid sudden DRM disconnect panics.
  - **Post-resume / Boot Setup**: `t2-sleep-helper post` cycles `05ac:8302` `0 -> 2`, loads `appletbdrm` to register `/dev/dri/card0`, restores saved brightness, and restarts `tiny-dfr.service`. Enabled on boot via `t2-touchbar-setup.service`.
- **Systemd Binding**: `/etc/systemd/system/tiny-dfr.service` uses `BindsTo=dev-tiny_dfr_display.device` so `tiny-dfr` never attempts to open the primary AMD GPU DRM card `/dev/dri/card1` if the Touch Bar DRM node is temporarily absent.
- **Service Cleanup**: Disabled and masked obsolete `supergfxd.service` (an ASUS ROG GPU daemon left over from dual-GPU configs) which was triggering spurious PCIe bus rescans and resetting T2 VHCI endpoints.
- **Diagnostic / Status**:
  ```bash
  systemctl status tiny-dfr.service
  ls -la /dev/dri/
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





