# Surface Dual-Battery, UPower & USB-C Charging Gotchas

Detailed troubleshooting for dual-battery aggregation bugs, Surface EC communication timeouts, impossible percentage readings (e.g. 200%–300%), and USB-C charging failures on Surface Book devices.

---

## 1. Impossible Battery Percentage (e.g. ~300%) on Surface Book

- **Symptom**: Noctalia status bar or `upower -i /org/freedesktop/UPower/devices/DisplayDevice` reports impossible battery percentages such as 200%–300% (e.g. `299.032%`), even though both batteries are discharging normally.
- **Root Cause**:
  - The Surface Book 3 features two physical batteries:
    - **`BAT1`**: Tablet / Clipboard battery (~14.5 Wh capacity), directly connected on motherboard.
    - **`BAT2`**: Base / Keyboard battery (~45.3 Wh capacity), communicating via the Surface Aggregator Module (SAM) EC serial bus (`00:00:01:11:00`).
  - During suspend/resume or transient EC latency, the kernel driver may log:
    ```text
    power_supply BAT2: driver failed to report `present' property: -110
    ```
    (`-110 = ETIMEDOUT`).
  - When this occurs, UPower's `up_device_battery_update_info()` resets exported D-Bus properties to `energy-full = 0.0 Wh`, but **fails to reset its internal cache comparison variables** (`priv->energy_full_reported`).
  - When `BAT2` recovers and reports its true full capacity (45.32 Wh), UPower compares incoming capacity against its stale cache (`45.32 == 45.32`), assumes no changes occurred, and skips republishing `energy-full` to D-Bus.
  - UPower's composite `DisplayDevice` then calculates:
    $$\text{Percentage} = 100 \times \frac{\text{BAT1.energy} + \text{BAT2.energy}}{\text{BAT1.energy\_full} + 0} = 100 \times \frac{43.27\text{ Wh}}{14.47\text{ Wh}} \approx 300\%$$
- **Fix (Automated Watchdog & Service Recovery)**:
  An automated, multi-tiered recovery system is deployed in `profiles/surface/` to eliminate manual intervention:
  1. **Watchdog Script**: `/usr/local/bin/surface-battery-watchdog` (tracked in `profiles/surface/scripts/surface-battery-watchdog.sh`):
     - Inspects `/sys/class/power_supply/BAT2/energy_full` and compares against UPower D-Bus properties (`battery_BAT2.EnergyFull` and `DisplayDevice.Percentage`).
     - Detects when sysfs reports healthy full energy but UPower reports `0 Wh` or `DisplayDevice > 100%`.
     - Rate-limits restarts to at most once per 30 seconds via `/run/surface-battery-watchdog.last-restart` to prevent restart loops.
     - Restarts `upower.service` and refreshes active Noctalia Wayland bars via `noctalia msg config-reload`.
  2. **Systemd Service & Timer**:
     - Service: `/etc/systemd/system/surface-battery-watchdog.service` (`Type=oneshot`).
     - Timer: `/etc/systemd/system/surface-battery-watchdog.timer` (`OnUnitActiveSec=2min`, `AccuracySec=30s`).
  3. **Udev Event Trigger**:
     - Rule: `/etc/udev/rules.d/99-surface-battery.rules` (`ACTION=="change", SUBSYSTEM=="power_supply", KERNEL=="BAT2", TAG+="systemd", ENV{SYSTEMD_WANTS}+="surface-battery-watchdog.service"`).
     - Automatically invokes the watchdog when `BAT2` status changes or recovers from EC timeout.
  4. **Sleep/Resume Hook**:
     - Hook: `/etc/systemd/system-sleep/20-surface-battery-resume.sh` triggers the watchdog on wake (`post/*`).
  - **Manual Recovery (if needed)**:
    ```bash
    sudo systemctl restart upower
    noctalia msg config-reload
    ```
- **Upstream Reference**: Tracked in freedesktop UPower issue #336 (*DisplayDevice shows 204% battery on dual-battery laptops when one battery reports energy_full=0*).

## 2. USB-C Charging Failure After Connecting a Monitor (Investigation, 2026-09-16–17)

- **User report**: USB-C charging stopped after connecting a monitor and persisted through reboot/OS reinstall. Three chargers were tried (two Apple, one described as a 60 W portable charger); other devices charge normally. User subsequently confirmed different known-good USB-C cables, working magnetic Surface Connect charging, and working USB-C external video. After the proposed recovery test, USB-C charging still failed. The detached keyboard base's own battery also failed to gain charge through USB-C. Only CachyOS is installed.
- **Read-only findings** on Surface Book 3 13.5-inch i5, kernel `6.19.8-arch1-3-surface`:
  - Raw `/sys/class/power_supply/ADP1/online` was `0`; `BAT1` reported `Not charging`, `BAT2` reported `Discharging`, and its energy decreased between samples. UPower agreed with the kernel; its combined full capacity was a plausible `59.79 Wh`.
  - Follow-up with the user-confirmed 60 W portable charger on September 16 at 18:15:52–18:16:31 MDT: a 40-second observation sampled adapter/battery statuses every 0.5 seconds and captured **30 `ADP1 online` transitions between 0 and 1**. `BAT2` remained `Discharging` and its energy fell from `23.84 Wh` to `23.68 Wh`; `BAT1` remained `Not charging`. This confirms unstable reported external power with net battery discharge, not a complete failure to recognize a power source. It is consistent with PD/power cycling, but does not decode the PD protocol or identify the failing component.
  - `surface_charger` and `surface_battery` were loaded. `/sys/class/typec` was absent and ACPI `USBC000:00/status` was `0`. These observations do **not** prove the USB-C port is physically disabled, damaged, or permanently assigned to video; generic Linux Type-C role controls were not exposed in this boot.
  - DMI UEFI version `23.101.140` (build date `2024-10-10`) matches Microsoft's latest published UEFI entry, `23.101.140.0`, released January 23, 2025. Kernel-reported SAM firmware `10.600.139` matches the latest System Aggregator entry, `10.600.139.0`, released June 20, 2024. Comparison checked September 16, 2026. The separate base/CFU firmware was inventoried September 17 via a direct HID version report matched to Microsoft's official package (see reverse-engineering findings below); all three records match the latest offered versions.
  - Initially `fwupdmgr` was unavailable; EFI firmware-resource attributes required elevated access and were not read directly. The user approved installing `fwupd` for inventory on September 17; results are recorded below. No firmware flash has been performed.
- **Interpretation**: Reinstalling Linux generally does not replace device firmware. Display output and USB-C power roles are negotiated separately; connecting a monitor should not permanently make the port display-only. The confirmed cable/charger tests and detached-base failure increase suspicion of the base's USB-C power circuitry or firmware, but do not prove a defective controller IC. Detaching the tablet leaves the base battery connected and is not a full removal of power from the base.
- **Diagnostic procedure, with user agreement before restarting/changing the system**:
  1. Verify a direct USB-C PD charger and a separately tested USB-C-to-USB-C cable, without the monitor/dock or Surface Connect attached. Microsoft lists 60 W for this non-Nvidia Book 3 model; verify the charger's actual per-port PD output, not just its total rating. Try both plug orientations.
  2. Microsoft's USB-C recovery sequence: save work, unplug the USB-C device, shut down fully, wait 10 seconds, then hold **Power only** for about 20 seconds until the Surface/Windows logo appears, disappears, and appears again. Release and reconnect the direct charger. Treat this as a recovery test, not a guaranteed firmware reset or fix.
  3. Recheck `ADP1/online`, both battery statuses, and energy over time. Test Surface Connect separately: it takes charging priority if both inputs are connected.
  4. If direct charging still fails, compare charging while fully shut down (battery energy before/after) and USB-C data/display behavior. Persistent failure with verified charger/cable combinations while powered off increases suspicion of the device-side controller or charging circuitry; it does not by itself prove which component failed.
- **Status**: Unresolved after user-reported recovery and detached-base tests. Stock `fwupd` inventory did not identify a dedicated base/USB-C update target. A subsequent direct HID CFU-version request **did return data from the base**, and matching those records to Microsoft's official base package is now complete: every live record matches the latest offered version, so there is no stale/missing base firmware to explain the charging fault (see reverse-engineering findings below). Electrical diagnosis remains relevant. Do not record this as the UPower percentage bug or a confirmed firmware defect. The `surface-uefi-firmware` repacker handles UEFI capsules; that does not establish support for the separate base updater or justify reflashing already-current UEFI/SAM firmware.
- **Sources**:
  - [Microsoft USB-C troubleshooting and recovery sequence](https://support.microsoft.com/en-us/surface/surface-dock/troubleshoot-problems-with-usb-c-on-surface)
  - [Surface Book 3 update history](https://support.microsoft.com/en-us/surface/updates/surface-book-3-update-history)
  - [Surface Book charging requirements](https://support.microsoft.com/en-us/surface/battery/surface-charging-requirements-and-power-supplies-surface-book)
  - [USB-C charging and Surface Connect priority](https://support.microsoft.com/en-us/surface/battery/usb-c-and-fast-charging-for-surface)

### Linux firmware inventory — 2026-09-17

- Installed with user approval through an interactive Kitty/Hyprland password prompt: `sudo pacman -S --needed fwupd`. Verified packages: `fwupd 2.1.7-1.1`, dependencies `fwupd-efi 1.8-2` and `passim 0.1.12-1.1` (19.75 MiB installed). Pacman created Snapper pre/post snapshots 19 and 20. Installation log: `/tmp/opencode/surface-fwupd-install-xx8_if3e/install.log` (temporary).
- `fwupdmgr get-devices --show-all-devices --json` succeeded via the D-Bus-activated daemon. It exposed six UEFI capsule resources, plus the SSD, TPM, Intel ME, CPU, SPI regions, and other platform entries; no dedicated base/USB-C power-delivery target was identified.
- Preserve raw capsule versions: `fwupd` reports these as decimal numbers without Microsoft-specific version formatting. Do not compare a naive byte-wise/triplet decoding with Microsoft's published version strings.

  | Capsule GUID | Raw version | Identification / evidence |
  |---|---:|---|
  | `e6396636-6eee-429e-b0ee-3dcb64dd8d59` | `385901964` | UEFI; DMI confirms `23.101.140`. |
  | `480d12ba-2a5b-40e2-8b1f-9f32d06a8fb2` | `167925899` | System Aggregator; kernel confirms `10.600.139`. |
  | `5e2a82e7-6995-414b-8968-76838f7d9596` | `67163019` | Touch firmware; public driver hardware ID and published `4.0.211.139` match. |
  | `50b3bfce-40f7-4662-afc1-8419426898b5` | `117572096` | TPM; separately detected runtime TPM version `7.2.2.0`. |
  | `46bc7190-c1b5-4a52-ac71-7ae532bd225b` | `654311687` | Likely 13.5-inch SMF: bytes decode to published `39.0.1.7`; exact GUID-to-INF mapping remains unverified. |
  | `87d5ff4f-a1e1-4d90-98af-faebb757cad7` | `3490284546` | ME; separate runtime ME version is `13.0.70.2436`, not the Windows package version. |

- The `cfu` plugin was ready, but `/usr/share/fwupd/quirks.d/builtin.quirk.gz` had no matching base profile for observed Surface Aggregator HID devices `045E:09A6`, `045E:09AE`, or `045E:09AF`. Its Microsoft CFU entry was for the USB-C Travel Hub (`045E:09BC`), a different device. Generic CFU support does not establish support for this base's update transport.
- `fwupdmgr refresh --no-authenticate` successfully refreshed LVFS metadata: **0 detected devices supported in enabled remotes** (no published matching update). `fwupdmgr get-updates --json --no-authenticate` returned an empty `Devices` array. This does not establish that every Surface component is current, especially the unexposed base updater.
- `firmware-locked` on SPI regions describes firmware write protection; it is not evidence that USB-C charging is disabled. `require-ac-power` was reported while `ADP1` was offline; the working Surface Connect charger would be needed for any later approved firmware update.
- The daemon was active and its unit static; `fwupd-refresh.timer` remained disabled. No firmware was installed/staged, no remotes were newly enabled, and `hyprctl configerrors` was clean after package installation.
- Further references: [Microsoft Book 3 driver/firmware package](https://www.microsoft.com/en-us/download/details.aspx?id=101315), [linux-surface UEFI capsule repacker](https://github.com/linux-surface/surface-uefi-firmware), [fwupd CFU protocol documentation](https://fwupd.github.io/libfwupdplugin/cfu-README.html). GUID cross-check for UEFI/SAM/TPM/ME: [public Windows PnP inventory](https://chirpmyradio.com/attachments/12543/win_system_info.txt); this is corroborating inventory, not a firmware download source.

### Reverse engineering: direct base CFU read — 2026-09-17

- **Interface discovered**: Surface Aggregator HID instance `01:15:02:05:00`, bus `BUS_HOST` (`0x19`), VID/PID `045E:09A6`, currently `/dev/hidraw2`. The adjacent instance `01:15:02:06:00` has the same VID/PID but a different descriptor, so select by physical identity and descriptor, not VID/PID or a fixed `hidrawN` alone.
- The cached 378-byte report descriptor contains vendor usage page `0xFF0B`, top-level usage `0x0101`, and feature report ID `0x20`, usage `0x62`, with a 60-byte payload. This matches the default CFU firmware-version report mapping in fwupd. Descriptor SHA-256: `b6ddc6bfff7832a1b0ad6f04e0d74c1cb22f79c109da44e0eb6a191f45e952f7`.
- **Stock tooling limitation explained**: fwupd 2.1.7's CFU device derives from `FuHidDevice`, which derives from `FuUsbDevice`. This base's HID is carried through Surface Aggregator serial transport, not USB. A matching USB quirk alone does not bridge those transports. The Linux Surface HID driver already supports HID feature reads through `hidraw`.
- **Successful read**: An identity-checked Python probe opened the device read-only and issued `HIDIOCGFEATURE(61)` for report `0x20`, through an interactive sudo terminal. It returned **61 bytes**, including the report ID. Probe: `/tmp/opencode/surface-cfu-version-f4f9bd09effe.py`; log: `/tmp/opencode/surface-cfu-version-xu6e6zp1/version-read.log` (temporary artifacts).
  ```text
  20 03 00 00 04 00 00 00 00 00 fe 25 00 01 06 00 03 20 12 25 00 8b 5a 02 0a 21 10 25 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
  ```
- Header bytes are `03 00 00 04`: component count `3`, protocol revision `4` (low nibble of the flags byte), extension flag clear. Microsoft's public CFU specification describes revision `2`, while fwupd 2.1.7 parses the same header layout without rejecting revision 4. The initial probe intentionally exited `2` at its protocol-version guard after preserving the successful raw read; this was **not an I/O failure**.
- **Confirmed decoding** using fwupd 2.1.7's `FuStructCfuGetVersionRsp` / `FuStructCfuGetVersionRspComponent` layout (`fw_version u32le`, `flags u8`, `component_id u8`, `vendor/product u16le`) and Microsoft's official `SurfaceBook3_Win11_22621_25.013.34389.0.msi` offer blobs (hash-verified against the MSI `MsiFileHash` table; full 1.67 GB MSI never downloaded, only bounded range reads totaling ~116 MB):

  | Live component | Live version | Official offer file | Offer component/version | Meaning |
  |---|---|---|---|---|
  | `0x12` (flags `0x20`) | `0x03000601` = `3.6.1` | `SurfaceBookBaseV3_PD.offer.bin` (16 B, MD5 `70c0ee7cc2d8811b120b04d0e9e10808`) | `0x12` / `3.6.1` | USB-C PD controller firmware; **already current**. |
  | `0x10` (flags `0x21`) | `0x0A025A8B` = `10.602.139` | `SurfaceBookBaseV3_KIP_APP1.offer.bin` and `SurfaceBookBaseV3_KIP_APP2.offer.bin` (16 B each) | `0x10` / `10.602.139` (both) | Base KIP firmware (two images/banks); **already current**. |
  | `0xFE` (flags `0x00`) | `0x00000000` = `0.0.0` | — (no offer; `0xFE`/`0xFF` are CFU offer-information pseudo-components) | — | Expected sentinel, **not failed firmware**. |

- All offers share product ID `0x0025`, matching the live records' vendor/product field `0x0025`. The PD payload `SurfaceBookBaseV3_PD.cfu` (20,471 B, MD5 `1079ab2e21ec41408bffec0b6c2f3c4c`, SHA-256 `70bd8fa2…`) was also extracted and hash-verified for inspection; its body is a signed/DER-structured image, not plaintext configuration.
- **Conclusion for charging**: the base CFU interface responds normally and reports the latest versions for every component, so the USB-C charging failure is not explained by stale or missing base firmware. This does not clear downstream power hardware (connector, PD power path, charging circuitry).

- The read demonstrates a responding base firmware interface, not that the downstream USB-C controller or charging hardware is healthy. Component identities are now confirmed via the official PD/KIP offer mapping above; all live versions match the latest offers. A USB-PD protocol analyzer may be needed to distinguish negotiation failures from loss of power; normal USB data captures do not capture the PD conversation on the CC wires.
- **Operations performed**: cached descriptor reads, one firmware-version GET request, and read-only range-based extraction of five small official files (`SurfaceBookBaseV3_PD.cfu`, `SurfaceBookBaseV3_PD.offer.bin`, both KIP offer blobs, two `.cat` files) with MSI-hash verification. No CFU offers were sent to the device, and no SET/Output reports, firmware writes, or kernel changes were performed. User-approved `cabextract 1.11-3.1` was installed for LZX CAB handling (Snapper snapshots 21/22); `bsdtar` could list but not decompress Microsoft's LZX-21 folders.
- Sources: [Microsoft CFU specification, GET_FIRMWARE_VERSION](https://learn.microsoft.com/en-us/windows-hardware/drivers/cfu/cfu-specification#51-get_firmware_version), [fwupd 2.1.7 CFU implementation](https://github.com/fwupd/fwupd/blob/2.1.7/plugins/cfu/fu-cfu-device.c), [fwupd 2.1.7 CFU wire structs](https://github.com/fwupd/fwupd/blob/2.1.7/libfwupdplugin/fu-cfu.rs), [fwupd 2.1.7 CFU offer layout](https://github.com/fwupd/fwupd/blob/2.1.7/libfwupdplugin/fu-cfu-firmware.rs), [fwupd 2.1.7 USB HID transport](https://github.com/fwupd/fwupd/blob/2.1.7/libfwupdplugin/fu-hid-device.c), [Linux Surface HID transport](https://github.com/torvalds/linux/blob/master/drivers/hid/surface-hid/surface_hid.c).

## 3. Portable Windows USB: Failed Initial Deployment and Native Rebuild (2026-09-18)

- The initial Lexar preparation was **not a successful Windows boot test**. EFI loader hashes matched, but the user reached the OOBE recovery page ("Why did your PC restart?") with nonfunctional built-in input. This is not a charging-test result.
- Two preparation defects were found:
  1. `wimlib-imagex apply ... /mnt/surface-win` used Unix directory-extraction mode through an NTFS-3G mount. `apply-image2.log` explicitly reports discarded Windows security descriptors for 122,776 files, extended attributes for 13,762 files, DOS names, and Windows file flags. File hashes do not verify these metadata. For Windows deployment, use native DISM or the documented **unmounted NTFS block-device mode**, never a Unix mountpoint. Direct libntfs-3g mode still lacks EA support, so the rebuild uses native `DISM /Apply-Image /EA /CheckIntegrity /Verify`.
  2. The 41 Surface runtime driver packages were only copied to `C:\SurfaceDrivers`; the abandoned custom-media script contained `/Add-Driver`, but the replacement deployment never executed it. `First-Logon.cmd` contained no `pnputil` command, and `DevicePath` remained `%SystemRoot%\inf`. Drivers need actual offline driver-store installation before first boot.
- Read-only logs preserved under `~/.cache/opencode/surface-windows-usb/failure-20260918-084331/`: specialize and system OOBE reported success, then CloudExperienceHost resealed to recovery OOBE. `RecoveryOOBEEnabled=1`; `setupapi.dev.log` reports `0xE0000223` (Plug and Play service unavailable). This establishes a broken setup, but does not isolate which missing metadata triggered that service failure. The original `SanPolicy=4` persisted; `PortableOperatingSystem` had reverted to `0` during setup.
- User approved repair. Native rebuild in progress: original, unmodified Microsoft ISO boots WinPE; a separate **data-only** ISO carries scripts and the hash-verified 41 runtime driver packages. QEMU exposes only the identity-checked Lexar as a physical disk. Rebuilds partition 3, installs drivers with DISM, applies portable settings, and regenerates boot files. VM startup configurations were preflighted using disposable sparse files before opening the USB.
- Required completion checks: native DISM success and 41 installed OEM INFs; a real UEFI USB boot to the Windows desktop; running Plug and Play; SAN policy 4; installed-driver manifest check. A VM cannot establish that Surface hardware input or charging works: those still require a native Surface boot.
- Keep repair tooling in the persistent cache (`repair-tools/`), since `/tmp/opencode` is cleared on reboot. QEMU 11 uses `-run-with user=jmvp`; q35 SATA ports accept one device per `ide.N` bus. Use explicit QMP `qcode` values, validating a whole string before typing it.
- **Repair result (same day)**: native `DISM /Apply-Image /EA /CheckIntegrity /Verify` plus offline `/Add-Driver` of all 41 packages succeeded; the first native attempt still wrote no PnP-ready Windows because the fresh ESP format failed when WinPE's diskpart rejected `gpt attributes`, and the second attempt was interrupted. After fixing the diskpart script, the third run deployed and the read-back from Linux confirmed both ESP boot-file hashes and a valid BCD hive.
- **Verified boot**: the rebuilt stick booted to the Windows desktop in the isolated VM (SATA attachment; the VM's `usb-storage` attachment is rejected by OVMF with `0xc0000428` or `Boot0002 Not Found` inconsistently — a VM transport/OVMF artifact, since the same disk boots via SATA and the real Surface already accepted this stick's USB boot manager). In-Windows verification reported Plug and Play running, SAN policy 4, `PortableOperatingSystem=1`, all 41 expected driver packages present, zero missing, and the expected disk offline. `WINDOWS-READY.json` is stored in `native-boot-verification/`. Setuperr from the good boot read only `System disks found` (an informational line, not a failure).
- **Driver package check**: the 41 staged packages contain no firmware/CFU payloads. `SurfaceHIDFriendlyNames.inf` only names the "Surface Component Firmware Update" HID collections; it does not update firmware. A real Surface boot with the built-in keyboard/touchpad and USB-C charger is still required for the actual charging diagnosis.
- References: [wimapply extraction modes and limitations](https://wimlib.net/man1/wimapply.html), [native DISM image application and EA](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-image-management-command-line-options-s14), [offline driver servicing](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/add-and-remove-drivers-to-an-offline-windows-image).
