# Apple T2 Subsystem & Hardware Gotchas

Curated hardware quirks, services, and diagnostic procedures for Apple MacBook Pro (MacBookPro15,1 with T2 Security Chip) running CachyOS Linux.

---

## 1. Touch Bar Display & Operating Modes (`hid-appletb-kbd` & `tiny-dfr`)

- **Architecture & Dual Modes**: The Touch Bar (`05ac:8302`) supports two operational modes:
  - **Hardware Keyboard Mode (`hid-appletb-kbd`, Configuration 1)**: Native Apple T2 hardware mode. Renders physical-like buttons directly via T2 firmware with instant responsiveness, automatic dimming, and zero DRM overhead.
    - **Configuration (`/etc/modprobe.d/touchbar.conf`)**:
      ```ini
      options hid_appletb_kbd mode=1 fntoggle=1 double_press_switch_time=500
      ```
    - **Controls**:
      - Default (`mode=1`): Direct `Esc` and standard `F1`–`F12` Function Keys row.
      - `Fn` hold (`fntoggle=1`): Dynamically switches to Special Media controls (Brightness, Illumination, Media Playback, Volume, Mute).
      - Double-tap `Fn` (`double_press_switch_time=500`): Locks/toggles the layer between F-keys and Media keys.
  - **Userspace DRM Mode (`appletbdrm` + `tiny-dfr`, Configuration 2)**: Userspace SVG rendering daemon. Note that on Linux kernel 7.1.x (`7.1.8-1-cachyos`), the upstream `appletbdrm` DRM driver has a known probe timeout regression (`error -110 / ETIMEDOUT`) during USB bus probe.
- **Service Cleanup**: Disabled and masked obsolete `supergfxd.service` (an ASUS ROG GPU daemon left over from dual-GPU configs) which was triggering spurious PCIe bus rescans and resetting T2 VHCI endpoints.
- **Diagnostic / Status**:
  ```bash
  cat /sys/module/hid_appletb_kbd/parameters/mode
  cat /sys/class/backlight/appletb_backlight/brightness
  ```

---

## 2. Suspend / Sleep Wakeup Fix (`suspend-fix-t2.service`)

- **Quirk**: T2 MacBooks can experience spontaneous wakeups or fail to enter deep sleep if PCIe devices (NVMe, Wi-Fi, T2 bridge) remain in active D0 power states.
- **Service**: Handled automatically via `suspend-fix-t2.service`.
- **Diagnostic**:
  ```bash
  systemctl status suspend-fix-t2.service
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

