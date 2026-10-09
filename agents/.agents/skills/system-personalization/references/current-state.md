# Current System State

Base system snapshot automatically generated on Wed Sep 16 12:16:18 AM MDT 2026; dated package additions reflect subsequent verified changes.

## Operating System & Kernel
- **OS**: CachyOS
- **Kernel**: `6.19.8-arch1-3-surface`
- **Shell**: `/bin/fish`
- **Compositor**: Hyprland 0.56.2 built from branch v0.56.2 at commit efb50993780079460b0cbed1363e2166a2de1d9f clean ([gha] Nix: update inputs).
- **Active Profiles**: surface

## Boot & Sleep (`surface`)
- **Bootloader**: Active Limine 12.9.0; ESP mounted at `/boot`, configuration `/boot/limine.conf` (verified 2026-10-08).
- **Boot menu**: Hidden one-second countdown (`quiet: yes`, `timeout: 1`), replacing the visible five-second wait on 2026-10-08. User confirmed the menu was hidden during a later direct hibernation restore; exact timing/speedup was not measured. Press Space during that second to reveal the menu.
- **Kernel selection**: `default_entry: 2` selects `linux-surface`; existing `remember_last_entry: yes` remains enabled. Regular CachyOS, LTS, and snapshot recovery entries are preserved.
- **Lid policy**: Suspend-then-hibernate, with 30-minute hibernation delay and `HibernateMode=shutdown`. A supervised battery-only automatic transition/restore passed on 2026-10-08; user reported lid-only restoration in 10–30 seconds before the menu reduction.
- **Hibernation compression**: **LZ4 selected**, read-back verified after separately approved persistence on 2026-10-08. Actual Surface initramfs contains the codec/dependency/loader/resume helper and matches Limine. Earlier temporary pair restored the original session/touch: LZO **14s to hibernate / 18s lid-to-lock**, LZ4 **12s / 15s**; that trial rolled back to LZO before the later permanent change. The 3s wake improvement remains preliminary, with differing memory and untested repeatability. Boot/initramfs, image-size target and sleep policy were unchanged. Trial evidence: `~/.cache/opencode/surface-standby-tests/lz4-ab-75k6c24s/comparison-analysis.json`.
- **Persistent LZ4 service verified (2026-10-08)**: Root-owned `/usr/local/bin/surface-hibernate-compressor` and `/etc/systemd/system/surface-hibernate-compressor.service` installed; unit enabled for `multi-user.target`, active (exited), result success, exit 0. Provider/self-test/selector guards apply only to Surface hardware / `*-surface`; other kernels retain defaults. Installed hashes/modes/owner, boot link and LZ4 were independently verified; protected boot/kernel/sleep/IPTS/mkinitcpio/battery files unchanged, no failed units or compositor errors. Eleven helper/four installer mock workflows passed first. No package/rebuild/reboot/sleep test; cold-boot behavior and delayed hibernation with the persistent policy untested. Backup: `/var/backups/surface-hibernate-lz4-20261008-191458-43170/`; evidence `~/.cache/opencode/surface-standby-tests/lz4-persistent-eq_82i4s/completed.json` and `followup.json`. See sleep gotcha section 10 for rollback.
- **Controlled codec-only lab (2026-10-08)**: User requested a more controlled test without hibernation. Identical fixed data, 128 KiB blocks, one pinned native thread and 12 balanced paired rounds per operation yielded 192 samples. Userspace LZ4/LZO median decompression throughput: **3.71× mixed pages / 5.87× system binaries**; compression **1.10× / 1.32×**, respectively. Incompressible compression was slower with LZ4 (0.75×). Exact roundtrips passed; 53–57°C, all noisy samples retained. Userspace/warm-cache/single-thread results do not predict real wake time or image size. The lab did not change selection or configuration. Evidence: `~/.cache/opencode/surface-standby-tests/codec-lab-eyxw8afi/run-xyu17qq1/report.json`; method/limits in its parent `README.md`.
- **IPTS recovery (2026-10-08)**: Surface-only asynchronous worker and `/usr/lib/systemd/system-sleep` registration symlink deployed. Manual inactive-daemon recovery passed; direct hibernation verified real automatic hook execution and healthy-daemon preservation, including both compression trials. Latest LZ4 follow-up: user confirmed full power-off, lid-only original-session restoration and working touch; both virtual inputs present, `iptsd@dev-hidraw6.service` PID `41636` active. Pen, an induced resume-race test, speed improvement attributable to the hook, and overnight reliability remain unverified. See sleep gotcha section 9 and `touchscreen-iptsd.md`, option 2.
- **Separate resume follow-ups**: Post-hibernation clock corrections still occur (`+230.951801s` after the initial direct cycle; `+88.570899s` after the registered-hook cycle; **+41.468226s** after the LZ4 trial). The battery-refresh hook under `/etc/systemd/system-sleep` remains unregistered in the scanned `/usr/lib` directory and was left untouched during IPTS/compression work; neither issue was fixed by these changes.
- **Details / rollback**: `profiles/surface/gotchas/sleep-hibernate.md`, sections 5–10; boot-config backup at `/var/backups/limine-fast-resume-20261008-153612-33670/limine.conf`.

## System Specs & Display
- **Product**: Surface Book 3 (`surface`)
- **CPU**: Intel(R) Core(TM) i5-1035G7 CPU @ 1.20GHz
- **GPU**: Intel Corporation Iris Plus Graphics G7
- **RAM**: 7.4Gi RAM, 16Gi swap
- **Primary Display**: eDP-1 (3000x2000@60Hz, scale 2)

## Key Installed Packages & Utilities

| Package | Version | Purpose |
|---------|---------|---------|
| hyprland | 0.56.2-4.1 | Core / Profile Utility; updated 2026-10-08 |
| noctalia | 5.2.1-1.1 | Core / Profile Utility (Wayland shell); updated 2026-10-08 |
| kitty | 0.49.2-1.1 | Core / Profile Utility (primary terminal) |
| alacritty | 0.17.0-1.2 | Core / Profile Utility |
| fish | 4.9.3-1 | Core / Profile Utility |
| btop | 1.4.7-1.1 | Core / Profile Utility |
| swayimg | 5.6-2.1 | Core / Profile Utility |
| dolphin | 26.08.2-1.1 | Core / Profile Utility; updated 2026-10-08 |
| easyeffects | 8.3.0-1.1 | Core / Profile Utility |
| localsend | 1.17.0-4 | Core / Profile Utility |
| chrony | 4.9-1.1 | Robust NTP daemon with immediate stepping (makestep 1 -1) and NM dispatcher; installed 2026-09-22 |
| opencode | 2.0.25 | AI coding assistant CLI (upstream in ~/.opencode/bin); updated 2026-10-08 |
| upower | 1.91.5-1.1 | Dual-battery power daemon; updated 2026-10-08 |
| fwupd | 2.1.8-1.1 | Firmware inventory; updated 2026-10-01 |
| fwupd-efi | 1.8-2 | fwupd UEFI capsule helper dependency; installed 2026-09-17 |
| passim | 0.1.12-1.1 | fwupd local-cache dependency; installed 2026-09-17 |
| cabextract | 1.11-3.1 | LZX CAB extraction for official MSI range-fetch forensics; installed 2026-09-17 |
| wvkbd | 0.20-1 | Minimal on-screen touch virtual keyboard for Wayland/Hyprland; installed 2026-09-17 |
| scdoc | 1.11.5-1.1 | Make dependency for wvkbd manual generation; installed 2026-09-17 |
| qemu-system-x86 | 11.1.2-1 | Isolated Windows VM for portable USB preparation and boot verification; updated 2026-10-08 |
| edk2-ovmf | 202608-1 | UEFI firmware (4m build, `OVMF_CODE.4m.fd`) for preparation/boot VMs; installed 2026-09-17 |
| wimlib | 1.14.5-4.1 | Windows image inspection and split-WIM creation; updated 2026-10-01 |
| msitools | 0.106-3.1 | Extract official Surface driver MSI; installed 2026-09-17 |
| libisoburn | 1.5.8.2-1.1 | Provides xorriso for UEFI preparation media; installed 2026-09-17 |
| ntfsprogs | 2026.9.28-1.1 | `ntfscat`/`ntfsls`/`mtype` read-only USB inspection and verification; updated 2026-10-01 |
| hivex | 1.3.24-8.1 | Offline registry edits and SYSTEM/SOFTWARE verification; installed 2026-09-18 |
| fuse2 | 2.9.9-6 | hivex/ntfs-3g dependency; installed 2026-09-18 |
| ntfs-3g | 2026.9.28-1.1 | Lexar NTFS read/write when a mount is required; updated 2026-10-01 |
| cdrtools | 3.02a09-6.1 | `mkisofs` for the small data-only repair ISO; installed 2026-09-18 |

## Compositor Health
- **Hyprland Errors**: None (clean)
