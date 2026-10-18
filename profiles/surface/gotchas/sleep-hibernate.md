# Surface Modern Standby & Hibernation Failure Gotchas

Detailed troubleshooting for hibernation failures, ACPI S4 platform power-down rejections, intermediate battery estimation wakeups, 19-hour frozen sleep limbo, and measured S0ix entry on Microsoft Surface Book 3.

---

## 1. Hibernation Never Powers Off / 19-Hour Sleep Limbo (`HibernateMode=platform`)

- **Symptom**:
  - The laptop is closed on battery with `suspend-then-hibernate` configured (e.g. `HibernateDelaySec=90min`).
  - After 90 minutes, the machine is expected to enter zero-watt hibernation. Instead:
    - **Scenario A (Instant Wakeup Abort)**: The system starts hibernation, but wakes back up after ~12 seconds.
    - **Scenario B (Frozen Limbo Hang)**: The system enters hibernation freeze, but **never powers off**. It remains trapped in an intermediate frozen sleep state with the lid closed for hours (e.g., 19 continuous hours from Sep 19 10:22 to Sep 20 05:20), draining battery continuously until the lid is physically opened.
- **Root Cause**:
  - The Microsoft Surface Book 3 is designed around Intel Ice Lake **Modern Standby** (S0ix / `s2idle`). Its UEFI firmware does not support traditional **ACPI S4** platform sleep states.
  - By default, `systemd` uses `HibernateMode=platform shutdown`. When entering hibernation, it attempts ACPI S4 (`platform` mode).
  - In `platform` mode:
    1. The kernel prepares ACPI S4 (`ACPI: PM: Preparing to enter system sleep state S4`).
    2. Communication with the Surface Aggregator Module (SAM) EC may time out during device freeze (`surface_dtx: failed to get base state: -19`, `WARNING: ssam_request_do_sync_with_buffer`), causing an immediate freeze abort and wakeup.
    3. If the freeze succeeds, the firmware rejects or hangs on the S4 platform power-down call, leaving the device frozen without shutting down power to SoC and RAM.
- **Fix (`HibernateMode=shutdown`)**:
  - Force systemd to use standard **ACPI S5** kernel power-off rather than ACPI S4 platform sleep.
  - In `/etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf`:
    ```ini
    [Sleep]
    AllowSuspendThenHibernate=yes
    HibernateMode=shutdown
    HibernateDelaySec=90min
    SuspendEstimationSec=90min
    HibernateOnACPower=no
    ```
  - Reload systemd daemon:
    ```bash
    sudo systemctl daemon-reload
    ```
  - In `shutdown` mode, the kernel writes the snapshot image to the designated NVMe swap partition (`/dev/nvme0n1p3`), frees memory bitmaps, and executes `kernel_power_off()`, cleanly cutting power.

---

## 2. Unnecessary Intermediate RTC Wakeup at 60 Minutes

- **Symptom**:
  - Even with `HibernateDelaySec=90min`, the system wakes up at exactly 60 minutes, accesses storage/battery, and then suspends again until 90 minutes.
- **Root Cause**:
  - `systemd` enables periodic battery discharge sampling by default (`SuspendEstimationSec=60min`).
  - At the 60-minute mark, systemd's RTC alarm fires to measure battery drain rate, causing an unnecessary hardware wake cycle before the true 90-minute hibernation threshold.
- **Fix**:
  - Align `SuspendEstimationSec=90min` in `/etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf`.

---

## 3. Spurious ACPI Lid Wake Abort & 30s Wake Loop (`button.lid_init_state=open`)

- **Symptom**:
  - **Scenario A (Sleep Abort overnight with `method`)**: After 90 minutes of sleep, the system wakes to hibernate (`Performing sleep operation 'hibernate'`), but aborts after ~12–14 seconds. The laptop is stranded awake with the lid closed for the rest of the night.
  - **Scenario B (30s Suspend Loop on Wake with `ignore`)**: The system successfully hibernates to disk. However, upon powering back on, the laptop suspends again every ~30 seconds. The user has to repeatedly press the power button to keep it awake.
- **Root Cause**:
  1. **Spurious `Lid opened.` ACPI Event (`method`)**:
     - When the RTC alarm wakes the machine from `s2idle`, `acpi_button_resume()` queries `_LID`.
     - Because communication with the Surface Aggregator Module (SAM) EC is asynchronous or unready during initial wake milliseconds, ACPI returns `1` (`open`).
     - In `acpi_lid_update_state()`, the driver executes `acpi_pm_wakeup_event(button->dev)`, registering a wakeup event in the PM subsystem.
     - When the kernel reaches the secondary CPU offline checkpoint during snapshot generation, `pm_wakeup_pending()` evaluates to `true` and immediately aborts the snapshot.
  2. **The 30-Second Suspend Loop with `ignore`**:
     - Setting `button.lid_init_state=ignore` instructs the ACPI button driver to emit **no** initial lid state events on resume.
     - When the user closed the lid at sleep time, `systemd-logind` registered `LidClosed = true`.
     - When resuming from hibernation, because of `ignore`, the kernel sent no event to update logind that the lid was opened.
     - `systemd-logind` enforces `HoldoffTimeoutSec=30s` on resume. Exactly 30 seconds after waking up, the holdoff timer expires, logind sees `LidClosed == true`, and triggers `HandleLidSwitch=suspend-then-hibernate` again.
  3. **The Solution (`button.lid_init_state=open`)**:
     - Setting `button.lid_init_state=open` causes `acpi_lid_initialize_state()` to execute `acpi_lid_notify_state(button, true)` directly.
     - Crucially, it **does not** call `acpi_pm_wakeup_event()` (unlike `method`), so it never trips `pm_wakeup_pending()`.
     - At the same time, it reports `SW_LID = 0` (open) to userspace upon every resume, ensuring `systemd-logind` clears `LidClosed` and never triggers the 30-second suspend loop.
  4. **IPTS Disconnect Hang**:
     - Concurrently, IPTS touchscreen hardware power-cycles upon wake from `s2idle`, dropping `/dev/hidraw0`.
     - `iptsd` hangs in an ioctl read (`IOCTL 3221374982 failed: No such device`) and ignores `SIGTERM`.
     - `systemd` stalls for its default 14-second stop timeout before terminating `iptsd` with `SIGKILL`.
- **Fix**:
  1. **Kernel Command Line Quirk (`button.lid_init_state=open`)**:
     - Add `button.lid_init_state=open` to `KERNEL_CMDLINE[default]` in `/etc/default/limine`:
       ```bash
       sudo sed -i 's/button.lid_init_state=ignore/button.lid_init_state=open/' /etc/default/limine
       sudo limine-entry-tool
       ```
     - Apply immediately at runtime:
       ```bash
       echo "open" | sudo tee /sys/module/button/parameters/lid_init_state
       ```
  2. **IPTS Wake Re-enumeration Hook**:
     - Deploy `/etc/systemd/system-sleep/21-surface-ipts-resume.sh` (tracked in `profiles/surface/systemd/`) to trigger `udevadm trigger -s hidraw` after a 1-second delay upon wake.
  3. **IPTS Service Timeout Guard**:
     - Create `/etc/systemd/system/iptsd@.service.d/timeout.conf` with `TimeoutStopSec=3s` so an unseated touch device cannot stall system transitions.

---

## 4. AC Disconnect Clamshell Battery Drain & 30-Minute Hibernation (`HandleLidSwitchExternalPower`)

- **Symptom**:
  - The laptop is closed while plugged into AC power (enters low-power suspend).
  - Later, the charger is unplugged while the lid remains closed (e.g., packing it into a backpack).
  - The laptop **never transitions into hibernation**, draining the battery completely in `s2idle` Modern Standby or running hot in a bag.
- **Root Cause**:
  1. Setting `HandleLidSwitchExternalPower=suspend` in `/etc/systemd/logind.conf.d/10-lid-sleep.conf` caused `systemd-logind` to invoke plain `systemd-suspend.service` upon lid closure on external power.
  2. Plain suspend has no countdown timer or battery threshold monitoring.
  3. Disconnecting the charger triggers an ACPI power supply interrupt (`ADP1 online=0`), briefly waking the SoC. However, `systemd-logind` **only** evaluates lid switch policies when the lid switch physically moves (`open` $\leftrightarrow$ `closed`), not on power supply events.
  4. Because the session was initiated under `suspend.service`, the machine remained trapped in indefinite `s2idle`.
  5. Furthermore, upon wake from the unplug event, `button.lid_init_state=open` in the kernel command line signaled `open` to userspace, leaving the laptop awake with the screen off for 15 minutes until `hypridle` timed out.
- **Fix**:
  1. **Align External Power Lid Action (`suspend-then-hibernate`)**:
     - Set `HandleLidSwitchExternalPower=suspend-then-hibernate` in `/etc/systemd/logind.conf.d/10-lid-sleep.conf` (tracked in `profiles/surface/systemd/10-lid-sleep.conf`).
     - Configured `HibernateOnACPower=yes` in `/etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf` so the machine consistently hibernates after 30 minutes whether on AC power or on battery.
  2. **Tune Hibernate Delay to 30 Minutes**:
     - Align `HibernateDelaySec=30min` and `SuspendEstimationSec=30min` in `/etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf` (tracked in `profiles/surface/systemd/10-suspend-then-hibernate.conf`).
  3. **AC Disconnect Clamshell Guard (Udev + Oneshot Service)**:
     - Deployed `/usr/local/bin/surface-unplug-lid-handler` (tracked in `profiles/surface/scripts/surface-unplug-lid-handler.sh`), triggered by `/etc/udev/rules.d/98-surface-unplug-lid.rules` via `/etc/systemd/system/surface-unplug-lid.service`.
      - When `ADP1` switches to `online=0`, the handler verifies if the lid is physically closed (`/proc/acpi/button/lid/*/state`), debounces 1.5s, and triggers `systemctl suspend-then-hibernate` to initiate the 30-minute battery countdown immediately.

---

## 5. Verify Real S0ix Entry Before Assuming `s2idle` Is Broken

- **Verified on 2026-10-08**: Surface Book 3 i5-1035G7, kernel `6.19.8-arch1-3-surface`, keyboard base attached, `ADP1 online=0` at both snapshots. Existing 30-minute suspend-then-hibernate policy was retained; no sleep configuration was changed for the test.
- **Method**: Read `/sys/kernel/debug/pmc_core/slp_s0_residency_usec` through an interactive sudo terminal immediately before and after a user-operated lid-close test. Compare the counter delta with the kernel's actual suspend entry/exit timestamps, not merely the time between battery snapshots.
- **Result**:
  - Kernel `s2idle` interval: `12:29:13.982109` to `12:34:36.548501` MDT, **322.566392 seconds**.
  - PMC S0ix counter: `0` to `321987600` microseconds, **321.9876 seconds / 99.82%** of that interval.
  - One clean suspend/resume cycle; lid opening coincided with resume and no intermediate full resumes were logged. The system returned before the hibernation threshold.
  - CPU-idle residency counters also became nonzero after this test. A zero reading on a fresh boot before any sleep is not proof of a blocked low-power state: compare before/after values.
- **Battery measurement limitation**: `BAT1` fell from 8.32 to 8.18 Wh and `BAT2` from 8.69 to 8.64 Wh, a combined **0.19 Wh**. The snapshots were 369.696133 seconds apart and included **47.129741 seconds outside suspend**. The resulting 1.85 W whole-interval average is **not isolated standby power**; do not extrapolate it as overnight sleep drain. High S0ix residency alone does not establish minimum whole-device power draw.
- **Longer repeat completed the same day**:
  - Kernel `s2idle` interval: `12:44:45.611526` to `13:05:17.547980` MDT, **1231.936454 seconds / approximately 20 minutes 32 seconds**, with one clean suspend/resume cycle and no intermediate full resumes logged.
  - PMC counter increased from `321987600` to `1554680200` microseconds, a **1232.6926-second delta / approximately 100% residency**. The raw ratio is 100.061% because counter boundaries and clock differences do not align exactly with the journal interval; do not report this as literal residency above 100%.
  - `BAT1` fell from 5.92 to 5.67 Wh and `BAT2` from 8.55 to 8.40 Wh, a combined **0.40 Wh**. The boottime snapshot interval was 1262.148080 seconds; the **1.14 W whole-capture average includes roughly half a minute awake**, not only standby. Both snapshots reported `ADP1 online=0`; hibernation was not reached.
  - Used one privileged, read-only counter-reader process across the test, with two fixed `cat` calls and a manual Enter prompt between them. Unprivileged snapshot collection saved the battery readings; no second sudo authentication after waking was needed and no sleep command or configuration change was made.
- **Read-only PMC/device follow-up completed**: See section 6. No definite standby-power culprit was identified. S0ix entry has now succeeded in two consecutive short battery-only cycles; minimum whole-device standby power, overnight reliability, and Windows/macOS parity remain unverified. Retain the 30-minute hibernation safeguard.
- **Persistent evidence**: `~/.cache/opencode/surface-standby-tests/test-pz4boori/` contains `preflight.json`, `before.json`, `after.json`, raw PMC readings, and `analysis.json` with the kernel transition timestamps and interpretation limits.
- **Longer-test evidence**: `~/.cache/opencode/surface-standby-tests/20min-fv705gun/` contains both snapshots, raw PMC readings, and `analysis.json` with the timing/energy calculations and their limitations.

---

## 6. Awake PMC/Runtime-PM Diagnostics Do Not Identify Standby Power Draw

- **Capture on 2026-10-08**: Kernel `6.19.8-arch1-3-surface`, awake with `ADP1 online=1` at both the device and PMC snapshots. No settings changed or packages installed.
- **Confirmed capabilities/settings**:
  - Cumulative PMC S0ix counter: `1554680200` microseconds; cumulative package C10 counter: `1557296412` microseconds. Nonzero C10 confirms that the CPU package has reached this state since boot, not that a specific sleep interval spent its entire time there or that the whole Surface reached minimum power draw.
  - All captured USB devices, including Bluetooth, hubs, and root hubs, were runtime-suspended with `power/control=auto` even while awake. The Thunderbolt USB controller was also in D3cold.
  - `iw dev wlan0 get power_save` reported `on`. The `iwlwifi power_save=N` module default alone does not establish the live network interface setting.
  - `power-profiles-daemon` was active with profile `power-saver`; TLP, tuned, and auto-cpufreq services were not found. Existing `intel_pmc_core ltr_ignore_all_suspend=Y` was recorded, not modified.
- **Important interpretation limits**:
  - This Ice Lake PMC exposes total S0ix and package C-state counters, but **no separate S0ix substate residency/status/requirements files**. The upstream Ice Lake register map likewise lacks the newer LPM substate map; this check cannot rank deeper S0ix substates.
  - `pch_ip_power_gating_status` and PCI `D0`, `runtime_status=active`, or `power/control=on` describe the **awake** system. They are not evidence that a component stays powered during system suspend. Similarly, audio `power_save=0` is an awake-idle tuning lead, not a confirmed standby blocker.
  - `wakeup_sources` contains cumulative statistics since boot. Without matching before/after samples, counts cannot be attributed to the earlier 20-minute test.
  - No sleep-block inhibitor was listed. Noctalia's Caffeine entry blocked `idle`, not lid-triggered sleep; the other sleep inhibitors used delay mode.
- **Strict read-only debugfs caution**: Deliberately skipped `slp_s0_debug_status`. In upstream `core.c`, its show callback invokes `pmc_core_slps0_dbg_latch(..., true)`, which writes the debug register to clear the latch even when the latch flag was initially false. Do not assume every debugfs read has no hardware side effects. No latch, ignore mask, runtime-PM control, or module parameter was written by this capture.
- **Outcome / next step**: No definite standby-power culprit or evidence-backed tuning fix was identified. Do not blanket-enable runtime PM, force ASPM, disable wake sources, or add a second power manager based on this snapshot. Retain the current 30-minute safeguard; its automatic hibernation transition subsequently passed the supervised test in section 7. Precise sleep-boundary energy samples or a controlled A/B test would be needed to attribute remaining standby power draw.
- **Evidence**: `~/.cache/opencode/surface-standby-tests/pmc-devices-m_7wd6iw/` contains `devices.json`, `pmc.json`, and `analysis.json`. Source semantics cross-checked against upstream Linux v6.19 [`core.c`](https://github.com/torvalds/linux/blob/v6.19/drivers/platform/x86/intel/pmc/core.c) and [`icl.c`](https://github.com/torvalds/linux/blob/v6.19/drivers/platform/x86/intel/pmc/icl.c); these references explain the interface, not a new local sleep test.

---

## 7. Automatic 30-Minute Hibernation Passed; Clock and PMC Counters Reset

- **Supervised test on 2026-10-08**: User-operated 35-minute lid-close test, battery only (`ADP1 online=0` before/after), kernel `6.19.8-arch1-3-surface`. Existing `HibernateDelaySec=30min`, `SuspendEstimationSec=30min`, and `HibernateMode=shutdown` were preserved; the capture itself did not issue a sleep command or change settings.
- **Automatic transition and restoration confirmed**:
  - Lid closed at `14:17:25.396274` MDT; kernel entered `s2idle` at `14:17:25.676281`.
  - Kernel left suspend at `14:47:30.248109` and entered hibernation at `14:47:30.389102`: approximately **30 minutes 5 seconds after lid closure**.
  - After restoration, `systemd-suspend-then-hibernate.service` reported `Result=success`, `ExecMainStatus=0`; the same boot ID and collector process (PID `32115`) survived. `/sys/power/disk` showed `[shutdown]`, as selected by systemd for this operation; its pre-test `[platform]` default did not override the configured hibernation mode.
  - **User observation**: Opening the lid alone restored the existing desktop; no power-button press was needed. Reported time to the lock screen/desktop was **10–30 seconds**. This is one successful automatic cycle, not proof of overnight reliability or an exact benchmark.
- **Clock/journal gotcha**:
  - BEFORE→AFTER wall time was **2229.201584 seconds / 37 minutes 9 seconds**, but `CLOCK_BOOTTIME` advanced only **1859.108933 seconds**.
  - `chronyd` explicitly reported `System clock wrong by 370.092634 seconds` and stepped the clock forward by that amount after restoration. The raw journal hibernation entry/exit timestamps appear only about 8.4 seconds apart, but **do not measure the physical powered-off interval** and must not be interpreted as an instant hibernation abort. Exact powered-off duration and the clock-handling root cause were not independently measured/investigated.
- **PMC counter gotcha**: S0ix counter changed from `1554680200` microseconds before to `0` after hibernation/power loss. This reset prevents a valid residency delta for this test; it is **not evidence of broken S0ix**. The separate short tests in section 5 remain the evidence for S0ix entry.
- **Energy limitation**: Tablet fell from 10.76 to 10.35 Wh and base from 11.67 to 11.43 Wh: **0.65 Wh combined** across the full capture. This includes awake time, roughly 30 minutes suspended, hibernation write/restore work, and the hibernated interval. It does not isolate standby or hibernated power and must not be extrapolated as a constant overnight drain rate.
- **Other logs**: MEI/IPTS/USB warnings occurred during transitions; no fatal hibernation error was logged. Peripheral functionality was not separately tested, so successful desktop restoration is not blanket validation of every device. A subsequent read-only follow-up found no running IPTS daemon despite the touch HID device being present; see section 9.
- **Outcome**: Keep the current 30-minute policy: measured S0ix entry for short breaks, with the automatic hibernation/restore path now verified in this supervised cycle. No system configuration changes or package installs were made.
- **Evidence**: `~/.cache/opencode/surface-standby-tests/hibernate-35min-dvh4l4ii/` contains preflight and both snapshots, raw PMC readings, bounded sleep/kernel journals, structured transition/clock events, and `analysis.json` with the user's wake observations and measurement limits.

---

## 8. Hidden 1-Second Limine Menu Reduces Hibernation Restore Delay

- **User request / scope (2026-10-08)**: After the successful hibernation test, the user reported seeing the Surface/regular-kernel boot menu with a **5-second** autoboot delay. Hibernation restoration still traverses firmware, bootloader, and the kernel's resume path. This is a **Surface-only boot preference**, not a universal desktop/theme change.
- **Inspected actual bootloader**: EFI `LoaderInfo` reported **Limine 12.9.0** and `LoaderEntrySelected=CachyOS.linux-surface`. The active ESP config was `/boot/limine.conf`, with no higher-priority config candidate shadowing it. Both the active and fallback Limine EFI images had zero/unset enrolled config hashes, so a config-only edit did not require re-enrollment or bootloader reinstallation.
- **User-approved live change** (hidden 1-second option rather than instant/zero-second boot):
  ```ini
  quiet: yes
  timeout: 1
  ```
  - Changed `timeout: 5` to `timeout: 1` and added the global `quiet: yes`. These global options belong in `/boot/limine.conf`, not the shell-style `/etc/default/limine` kernel-entry-tool configuration.
  - Preserved `default_entry: 2` (the first bootable child, `linux-surface`), `remember_last_entry: yes`, all Surface/regular/LTS kernels, all snapshot entries, file hashes, kernel arguments, and theme settings byte-for-byte. Existing remember-last behavior remains: a deliberate alternate-kernel selection can override the configured default on subsequent boots.
  - Installed the reviewed, narrowly patched staged file under the boot-partition lock after verifying that the original config and EFI binaries had not changed. A verified backup was created first; the installed config was read back and matched the staged file exactly. No EFI binary, firmware boot order, initramfs, sleep policy, or universal `core/` configuration was changed.
- **Expected behavior / recovery access**:
   - On subsequent normal boots and hibernation restores, the menu is hidden and the one-second wait still occurs. Expected countdown saving is **approximately 4 seconds**; firmware startup and loading/restoring the saved session are not bypassed. The user confirmed the menu was hidden during the subsequent direct-hibernation test (`ipts-recovery-z4wvl2hs/direct-hibernate-x9pc08ys/`); exact wake time and the expected countdown saving were **not measured**.
  - Press a key such as **Space during that one second** to reveal the kernel/recovery menu and cancel autoboot. Do not claim that `timeout: 0` has this same recovery window; the user explicitly chose the nonzero hidden timeout.
  - From running Linux, a planned `systemctl reboot --boot-loader-menu=10s` can request a one-time menu through Limine's Boot Loader Interface. **This command initiates a reboot** and was not run here. When a valid hibernation image is pending, let the matching Surface entry restore it rather than casually selecting another kernel or snapshot.
- **Backup / rollback**: `/var/backups/limine-fast-resume-20261008-153612-33670/limine.conf`. To undo only this preference, restore `timeout: 5` and remove the added global `quiet: yes`. Do not overwrite newer kernel/snapshot entries by blindly restoring the entire dated backup after subsequent boot-config updates. Verify these global options if a future installer/tool replaces the config header.
- **Evidence**: `~/.cache/opencode/surface-standby-tests/limine-fast-resume-booaiyec/` contains inspection/application records, original/staged/installed config copies, and `analysis.json`. Original SHA-256: `eba26760d7f1fe900257d3dcb85c171410b7b1a520aec7b4fcf866981236e84a`; installed SHA-256: `a42875434b50cb7995e054bba9bd611c684b8753be0c7720e512f3b2100d21e1`. Option semantics checked against installed `/usr/share/doc/limine/CONFIG.md`. No package installs or automatic reboot/hibernation performed.

---

## 9. Further Hibernation Optimization: Fix Peripheral Recovery Before Blind Tuning

- **Read-only follow-up on 2026-10-08**: User asked about further improvements after the boot-menu change. No additional settings, modules, kernel arguments, or packages were changed.
- **Concrete reliability issue: IPTS daemon missing after the automatic cycle**:
  - `iptsd@dev-hidraw0.service` reported `Result=timeout`, `ExecMainStatus=9` (SIGKILL). Journal messages show I/O errors, a stop request during the suspend-to-hibernate transition, then a stop timeout during restoration.
  - The replacement `iptsd@dev-hidraw6.service` connected to `045E:09B2` and started, but was stopped again shortly afterward with exit status 0. At follow-up it was inactive, `pgrep -x iptsd` found **no daemon**, and the actual `hidraw6` IPTS device (`HID_ID=0000:0000045E:000009B2`) remained present.
  - Before the repair, the existing unit stop-timeout guard was **3 seconds**, and the hook waited 1 second before triggering hidraw udev events. Both guards are retained, with the hardware delay now in an asynchronous worker. The underlying IPTS/MEI reset and daemon-stop sequence, physical pen behavior, and any contribution to measured restore latency are not fully established.
  - **Recovery gaps confirmed and replacement deployed**: The old hook sent the default `change` event while packaged `50-iptsd.rules` matches only `add`. The device already had the systemd tag/Wants and was active, but systemd only acts on device Wants at initial activation. Deployed a Surface-only asynchronous, bounded worker to retrigger the actual IPTS device with `add` and explicitly start its inactive matching daemon without restarting healthy instances. Live manual inactive-daemon recovery succeeded; both virtual inputs appeared in Hyprland and **the user confirmed touchscreen input works**. Actual hook dispatch subsequently passed the registered-hook cycle below; pen remains untested. See `touchscreen-iptsd.md`, option 2; evidence under `~/.cache/opencode/surface-standby-tests/ipts-recovery-z4wvl2hs/`.
  - **First direct-cycle result / additional registration gap**: A subsequent direct hibernation on AC restored the original session; normal udev started `iptsd@dev-hidraw0.service` and the user confirmed touch works and the boot menu is hidden. However, no recovery-worker execution was logged: both old and replacement dispatchers were only under `/etc/systemd/system-sleep`, while the installed `systemd-sleep` binary/manual scan **only `/usr/lib/systemd/system-sleep`**. Added/read-back verified the guarded IPTS-only registration symlink and corrected profile deployment. One retest prompt was cancelled before sleep, then the confirmed retry below passed. This first unregistered test alone is **not** proof of automatic fallback execution. `chronyd` again stepped the clock `+230.951801s`; no exact wake benchmark or battery-drain result was obtained. Evidence: `ipts-recovery-z4wvl2hs/direct-hibernate-x9pc08ys/` and `registered-hook-retest-gt6ybkeh/`.
  - **Registered-hook restore verified**: In `registered-hook-retry-pinr1140/`, the journal records automatic worker startup and successful completion, reporting the replacement `iptsd@dev-hidraw6.service` already healthy and leaving it running (PID `37942`). Original boot/collector survived; user confirmed full power-off, **lid-only restoration and working touchscreen**. Worker ran ~2.14s and finished ~2.13s after `user.slice` thaw, confirming asynchronous dispatch rather than blocking the session for its waits. Both virtual inputs remained present; no failed units or Hyprland config errors were found. This does not establish an exact wake-speed saving, overnight reliability, physical pen, or an induced-race recovery; the inactive-daemon branch was separately recovered manually. `chronyd` later stepped `+88.570899s`; power-off/wake duration must not be inferred from raw journal intervals. LZO, image-size target, hidden-menu configuration, and the 30-minute policy were unchanged.
- **Performance candidate: LZ4 hibernation-image compression**:
   - At the initial read-only follow-up, `/sys/module/hibernate/parameters/compressor` was **`lzo`**; its sysfs control is writable by root. `CONFIG_CRYPTO_LZ4=m` and the installed module `/lib/modules/6.19.8-arch1-3-surface/kernel/crypto/lz4.ko.zst` provided an LZ4 candidate without rebuilding the kernel. The later approved persistent LZ4 selection is verified in section 10.
  - **Kconfig pitfall**: `CONFIG_HIBERNATION_COMP_LZ4` being unset here selects LZO as the **default**, not a lack of all LZ4 support. Upstream `hibernate.c` builds the allowed compressor list using `IS_ENABLED(CONFIG_CRYPTO_LZ4)` and reads the saved image's compression flag during resume.
   - Both installed mkinitcpio `systemd` and `resume` build hooks request `crypto-lzo` and `crypto-lz4`. The actual generated Surface initramfs was subsequently inspected and contains `crypto/lz4.ko.zst`, `lib/lz4/lz4_compress.ko.zst`, module alias/dependency databases, kmod/modprobe, and `systemd-hibernate-resume`. Selected Surface entry and kernel/initramfs BLAKE2b hashes were verified. Active image: `/boot/5fc77b86d2ec467b971039d4de8f4efa/linux-surface/initramfs`, SHA-256 `7afeeae49dcec0a3953c9877639cf1230d2bb11e1202deebefe0489c26f5f515`; no rebuild was necessary.
   - LZ4 may reduce compression/decompression CPU time at the cost of a potentially larger stored image. The supervised pair below confirmed a working LZ4 restore and a **reported 3-second lower lid-to-lock time in one pair**, not a repeatable or codec-only speedup. No actual compressed-image size was measured; preserve the existing automatic sleep policy.
   - **User-approved LZO baseline (2026-10-08)**: Actual-image checks and a direct LZO baseline passed. The same boot/collector survived; iptsd re-enumerated to `hidraw0` and remained active, and the automatic recovery worker completed its healthy-instance check. User reported **14 seconds to hibernate** and **18 seconds from lid opening to the first lock screen**; the former's exact start/stop boundaries were not further specified. The terminal observation form was not saved; timing and lid wake came from chat, while logs verify daemon/virtual inputs, not physical touch. Evidence: `~/.cache/opencode/surface-standby-tests/lz4-ab-75k6c24s/lzo-baseline/`.
   - **Temporary LZ4 restore passed (2026-10-08)**: The first launch stopped at the sudo password prompt while the user was AFK, before any privileged trial action; this was not a codec failure. On the requested relaunch, exact `HIBERNATE` confirmation preceded `modprobe crypto-lz4`; `/proc/crypto` showed `lz4-scomp` with self-test passed, and the selector read back `lz4` before and after restoration. User's external-stopwatch observation form recorded **12 seconds from confirmation to full power-off** and **15 seconds lid-open to first lock screen**, plus full power-off, lid wake, and **working touch**. Original session/boot/collector survived; the automatic worker completed and preserved healthy `iptsd@dev-hidraw6.service` (PID `41636` at follow-up). Both virtual inputs were present; no failed system units or Hyprland config errors remained.
   - **Trial rollback verified**: The harness waited for the journal's actual `Finished System Hibernate.` event, not the possibly queued `systemctl hibernate` command's return, then restored/read-back **LZO** before collecting observations. At that point the LZ4 provider remained loaded but was not selected; no module unload or persistent configuration was requested by the trial. Kernel, active initramfs/hash, resume device, boot/sleep/recovery-file hashes, `3109138432`-byte image-size target, hidden one-second menu, and 30-minute sleep policy were unchanged. No packages installed or boot images rebuilt. The separately approved persistent selection followed later (section 10).
   - **Comparison limits / evidence**: Reported lid-to-lock time fell **18s → 15s (3s / approximately 17%)**; hibernation reports fell **14s → 12s**, with less precise baseline boundaries. Only one pair was measured; apps were requested to stay the same, but memory was not identical (snapshot allocation `756340` → `746321` pages; normal pages needed `648624` → `627734`, excluding the extra 1024 pages). These are allocation figures, not stored-image sizes. Both tests were on AC, so there is no battery-drain result. `chronyd` later stepped the LZ4 cycle's clock **+41.468226s**; raw journal intervals remain unsuitable as physical timing. Pen, overnight reliability, repeatability, and automatic 30-minute transition with LZ4 remain untested. Successful trial: `lz4-ab-75k6c24s/lz4-trial-retry-8mlx_s1d/`; consolidated evidence: `lz4-ab-75k6c24s/comparison-analysis.json`. The trial restored LZO as promised; subsequent explicit approval for a persistent default is recorded in section 10. Another comparison pair is still recommended before treating the timing difference as reliable.
   - **Benchmark / compressor distinction**: mkinitcpio's archive `COMPRESSION` is separate from the hibernation RAM-image compressor. This experiment must not change archive compression, the image-size target, or boot arguments. Upstream resume chooses the saved image's compression flag, so an available codec in the matching initramfs is essential. Time lid-open to **first lock screen** with an external phone/watch, using the same apps, charger, base, and wake method for both trials. Do not count unlocking; do not use raw journal/boottime intervals as wake benchmarks given the observed clock resets. A single LZO/LZ4 pair is preliminary, not proof of a repeatable improvement; missing stopwatch measurements must be reported as unmeasured rather than estimated.
   - **Controlled non-hibernating codec test requested and completed (2026-10-08)**: Native userspace LZO 2.10/LZ4 1.10.0 compared identical fixed 8 MiB fixtures in **128 KiB blocks** (upstream `UNC_PAGES=32`). Three warm-ups, calibrated ~80 ms batches, **12 paired rounds per operation**, balanced alternating algorithm/operation order, and one native thread pinned to CPU 3 yielded **192 timed samples**. Monotonic-raw wall and thread CPU times, sizes, context switches/page faults, sampled clocks/temperature, and exact byte restoration were recorded; verification/file IO stayed outside timing. No hibernation/suspend, sudo, package/module/swap/configuration operation was performed. AC/base, LZO, existing power-saver/powersave settings, readable sleep/recovery hashes, image-size target, kernel/boot ID and module names were unchanged. Temperature stayed **53–57°C**; clocks were not fixed and other/sibling activity was not disabled. Boot config was unreadable unprivileged and untouched.

     | Fixture (synthetic/public, not a RAM snapshot) | Median paired LZ4/LZO compression throughput | Decompression throughput | LZ4 compressed payload versus LZO |
     |---|---:|---:|---:|
     | Mixed: equal zero/text/binary/random page shares | 1.10× | 3.71× | 0.22% smaller |
     | Installed system binaries | 1.32× | 5.87× | 3.58% larger |
     | Seeded incompressible control | 0.75× | 1.00× | Essentially equal |
     | All-zero best-case control | 1.01× | 7.93× | 11.64% smaller payload; identical emulated page-padded size |

     Mixed-page decompression interquartile range **3.62–3.80×**, full range **3.57–3.93×**, across 12 paired observations. Five incompressible samples exceeded 2% off-CPU time and were flagged **without discarding any samples**; CPU-time comparisons agreed with wall-time direction. All measured roundtrips passed, with no timed page faults. Sanitizer roundtrips, 48 timing-loop smoke samples, seven invalid-input cases and paired-statistics/order/noise checks passed first. This supports LZ4's codec-level decompression advantage on compressible data, **not a prediction of real wake seconds or a universally faster encoder**. Userspace implementations differ from kernel code; this single-thread warm-cache test excludes the real multiworker/checksum/copy/IO/firmware/device path and uses no actual application RAM. Emulated padded sizes are not real image sizes. Evidence/repeat instructions: `~/.cache/opencode/surface-standby-tests/codec-lab-eyxw8afi/README.md`; successful run `run-xyu17qq1/report.json`. The lab left LZO selected; a later, separate approval for persistence is recorded below.
- **Avoid premature image-size tuning**: `/sys/power/image_size` is `3109138432` bytes, a target rather than the measured on-disk image size. Requesting a smaller image may increase reclamation/swapping or leave applications with cold caches after restore, particularly on this 8 GB machine. Keep the existing target until a measured bottleneck justifies an experiment.
- **Measurement limits / other follow-ups**: `systemd-analyze time` describes the original startup, not a new hibernation benchmark or post-menu-change result. Firmware startup is not bypassed by Linux resume tuning. The clock correction observed in section 7 is another potential offline-resume reliability investigation, not a root-caused or fixed problem.
- **Evidence**: `~/.cache/opencode/surface-standby-tests/hibernate-35min-dvh4l4ii/optimization-followup.json` records current controls, running-kernel compression config, module availability, live touch-device identity, IPTS service/process state, and mkinitcpio hook codec requests. Existing test journals preserve the failure sequence. Source semantics checked against upstream Linux v6.19 [`hibernate.c`](https://github.com/torvalds/linux/blob/v6.19/kernel/power/hibernate.c) and [`Kconfig`](https://github.com/torvalds/linux/blob/v6.19/kernel/power/Kconfig).

---

## 10. Persistent Surface-Only LZ4 Default Applied and Verified

- **Separate approval and application (2026-10-08)**: After the successful real trial and controlled codec test, the user explicitly approved making LZ4 persistent. The interactive sudo installer succeeded; **live selection is now `lz4`**, and the Surface-kernel-only boot service is **enabled / active (exited), `Result=success`, `ExecMainStatus=0`**. This approval did not authorize another hibernation or reboot, and none was requested.
- **Method / scope**: New `profiles/surface/scripts/surface-hibernate-compressor.sh` and `systemd/surface-hibernate-compressor.service` are installed at `/usr/local/bin/surface-hibernate-compressor` (root-owned `0755`) and `/etc/systemd/system/surface-hibernate-compressor.service` (root-owned `0644`). The `multi-user.target.wants` symlink was verified to point to this unit. The oneshot is ordered after module loading and before user sessions / hibernation units. It runs only on a `*-surface` kernel with the compressor control present; the helper also requires Surface DMI identity. Other hardware/non-Surface kernels are left at their own defaults.
- **Safety**: Load `crypto-lz4`, require a registered `lz4` provider with passed self-test, preserve unexpected/concurrently changed compressor values, write/read-back `lz4`. The kernel rejects a write during a power transition with `EBUSY`; the installer also refuses active/queued sleep. Only two new files and their boot-enablement link are created; unexpected existing files/units/symlinks are not replaced. A root-only manifest/payload backup is created first; failed deployment has scoped cleanup and LZO rollback without reverting another actor's changed files/settings.
- **No boot-image changes**: Persistence uses a boot service, not a new Limine argument, archive compression setting, initramfs rebuild or new sleep hook. The guarded installer rechecks the actual matching Surface image, its embedded LZ4 provider/dependency/loader/resume helper, and protected boot/kernel/sleep/IPTS/mkinitcpio/battery-hook hashes. Hidden one-second menu, fallback/recovery entries, image-size target and 30-minute policy remain untouched. Resume still chooses the saved image's codec flag before the normal boot service runs. Reverify codec inclusion after future kernel/initramfs changes; a cold-boot run of this new service has not yet been tested.
- **Validation**: Bash syntax and staged unit verification passed; current `ConditionKernelVersion=*-surface` matches. Eleven mocked helper cases cover success/idempotence/hardware and kernel skips/provider failures/unwritable control/concurrent state. Four mocked installer workflows and exclusive-file/symlink/queued-sleep/scoped-rollback guards passed without real module/sysfs/service actions. `profiles/surface/setup.sh` now deploys only absent or identical owned files and refuses to shadow an unexpected unit; **do not run the full setup script just to apply this preference**, since it also configures unrelated boot/sleep components.
- **Live verification**: Actual selected Surface initramfs codec/dependency/loader/resume-helper checks passed again and its SHA-256 remains `7afeeae49dcec0a3953c9877639cf1230d2bb11e1202deebefe0489c26f5f515`. Before/after protected boot/sleep/IPTS/mkinitcpio/battery-file hashes, kernel/boot ID, image-size target and resume device matched. New installed-file hashes/modes/owner, enablement link, service success and runtime selector were independently read back. Journal records helper startup, `Surface hibernation RAM-image compressor verified: lz4.`, and successful completion. `iptsd@dev-hidraw6.service` PID `41636` remained healthy with both virtual inputs; no failed system units or Hyprland errors. Physical touch was not newly retested by this no-sleep deployment. No packages, image rebuild, reboot or sleep test performed; next cold boot and automatic delayed hibernation with this persistent policy remain untested.
- **Rollback after successful installation** (enter sudo passwords interactively):
  ```sh
  sudo systemctl disable --now surface-hibernate-compressor.service
  printf 'lzo\n' | sudo tee /sys/module/hibernate/parameters/compressor
  cat /sys/module/hibernate/parameters/compressor
  ```
  Disabling/stopping the oneshot alone does **not** undo its previous sysfs write. No boot/initramfs rebuild or codec-library unload is needed. Future `profiles/surface/setup.sh` runs re-enable this profile preference unless its new compressor block is intentionally removed/skipped. Keep the matching kernel when an image is pending; never discard a pending image merely to change defaults.
- **Historical harness caution**: The earlier LZO baseline, temporary LZ4 rollback collector and codec lab have LZO-specific guards/cleanup. They are historical evidence, not persistence verification tools; do not blindly rerun them after applying the new default or let their old rollback overwrite it.
- **Backup / evidence**: Root-only manifest and reviewed payload copies: `/var/backups/surface-hibernate-lz4-20261008-191458-43170/`; the helper, unit and enablement link were originally absent, so no old configuration was overwritten. `~/.cache/opencode/surface-standby-tests/lz4-persistent-eq_82i4s/` contains plan, guarded `install.py`, mock validation, actual image inspection, before/after protected hashes, `completed.json`, command records and independent `followup.json`. Cold boot and another restore remain untested until separately requested.

---

## 11. CachyOS 7.x DKMS `ipts` 30s `state:D` Freezer Abort & Sleep Consistency Hardening (2026-10-15)

- **Symptom**:
  - After switching the default kernel from `linux-surface` (`6.19.8-arch1-3-surface`) to `linux-cachyos` (`7.2.9-2-cachyos`) with out-of-tree DKMS `ipts`, closing the lid triggered `systemd-suspend-then-hibernate.service`, but at the 30-minute mark the machine **failed to hibernate** and fell back into indefinite `s2idle` (staying suspended for 19–21 hours).
  - Concurrently, `surface-hibernate-compressor.service` was `inactive (dead)` (`ConditionVersion=*-surface was not met`, reverting `/sys/module/hibernate/parameters/compressor` to `lzo`), and `surface-unplug-lid.service` entered `failed (Result: exit-code)` during the 30-minute RTC wake.
- **Root Cause**:
  1. **DKMS `ipts` 30-Second Uninterruptible `GET_FEATURES_TIMEOUT` Exceeding Kernel Freezer (20s)**:
     - At the 30-minute RTC wake (`PM: suspend exit` $\rightarrow$ `PM: hibernation: hibernation entry`), the lid remains physically closed (touch panel unpowered).
     - During the ~150ms transition window, `ipts` re-enumerates `/dev/hidraw0`, triggering `/usr/lib/udev/rules.d/50-iptsd.rules` $\rightarrow$ `/usr/bin/iptsd-check-device --quiet /dev/hidraw0`, which issues `ioctl(HIDIOCGFEATURE)` $\rightarrow$ `ipts_eds2_get_feature()`.
     - Because the lid is closed, the touch sensor does not reply to `GET_FEATURES`.
     - While `linux-surface` (`6.19.8-arch1-3-surface`) uses a **5-second** timeout (`5000` ms), the vendored `intel-precise-touch` (`commit 3b88a45`) in `profiles/surface/dkms/ipts/src/eds2.c` used `#define GET_FEATURES_TIMEOUT 30 * MSEC_PER_SEC` (30 seconds) with uninterruptible `wait_for_completion_timeout()` (`TASK_UNINTERRUPTIBLE` / `state:D`).
     - Because `30s > 20s` (`pm_freeze_timeout`), `Freezing user space processes` failed after `20.002 seconds` (`task:iptsd-check-dev state:D`), aborting hibernation with `-EBUSY`. `systemd-sleep` then fell back to plain `suspend` (`s2idle` with no RTC timer), where the remaining `9.948s` of the 30s timeout expired (`20.002s + 9.948s = 29.950s`).
  2. **Kernel-Name Gate on `surface-hibernate-compressor.service`**:
     - `ConditionKernelVersion=*-surface` in the unit and `[[ "$kernel" != *-surface ]]` in `/usr/local/bin/surface-hibernate-compressor` prevented the service from running on `7.2.9-2-cachyos` (which has `CONFIG_CRYPTO_LZ4=y` built-in).
  3. **`surface-unplug-lid.service` Colliding with Active `suspend-then-hibernate`**:
     - During the 30-minute RTC wake on battery, the kernel emitted a `change` uevent on `ADP1` (`online=0`), triggering `surface-unplug-lid.service`, which called `systemctl suspend-then-hibernate` while `systemd-suspend-then-hibernate.service` was already running.
  4. **Unregistered Battery Sleep Hook & Spurious Clamshell IPTS Recovery**:
     - `20-surface-battery-resume.sh` was only in `/etc/systemd/system-sleep/` without a symlink in `/usr/lib/systemd/system-sleep/`.
     - `21-surface-ipts-resume.sh` started `surface-ipts-resume.service` on `post/*` during the 30-minute clamshell RTC wake, only for `pre/*` to kill it 140ms later with `SIGTERM` (`Failed with result 'signal'`).
- **Fixes Applied**:
  1. **DKMS `ipts` (`profiles/surface/dkms/ipts/src/eds2.c` & `control.c`)**:
     - Reduced `GET_FEATURES_TIMEOUT` to `5 * MSEC_PER_SEC` and switched `ipts_eds2_get_feature()` to `mutex_lock_interruptible()` + `wait_for_completion_interruptible_timeout()` (`TASK_INTERRUPTIBLE` / `state:S`), allowing the kernel freezer (`freeze_processes()`) and `timeout` signals to interrupt an in-flight `GET_FEATURES` request in `<1ms`.
     - Fixed upstream typo in `control.c` line 111 (`cmd.tail_offset_addr_upper = upper_32_bits(wq_addr);`).
     - Rebuilt and reloaded `ipts/2024.04.16` via DKMS for `7.2.9-2-cachyos` and `6.18.55-2-cachyos-lts`.
  2. **Kernel-Agnostic Surface LZ4 Compressor (`surface-hibernate-compressor.service` & `.sh`)**:
     - Removed `*-surface` kernel-name restrictions while preserving the `Surface*` DMI hardware check and `/proc/crypto` `lz4` self-test verification. Verified `lz4` active on `7.2.9-2-cachyos`.
  3. **Active-Sleep Guard in `surface-unplug-lid-handler.sh`**:
     - Added `is_sleep_in_progress()` check against `sleep.target`, `suspend-then-hibernate.target`, `hibernate.target`, `suspend.target`, and their `systemd-*.service` units before and after the 1.5s debounce.
  4. **Sleep Hook Registration & Clamshell Guard**:
     - Symlinked `/usr/lib/systemd/system-sleep/20-surface-battery-resume.sh` $\rightarrow$ `/etc/systemd/system-sleep/20-surface-battery-resume.sh`.
     - Updated `21-surface-ipts-resume.sh` to skip starting `surface-ipts-resume.service` on `post/*` when the lid is physically closed, and added `SuccessExitStatus=143 SIGTERM` to `surface-ipts-resume.service`.

---

## 12. Hibernation Clock Freeze (`<7h`) / `-7h` Wake Offset (`>7h`) — Surface SAM EC UEFI POST `rtc0` Epoch Mismatch (2026-10-18)

- **7-Cycle `suspend-then-hibernate` Verification (Oct 15–18, 2026)**:
  - Following the `[2.55.0]` DKMS `ipts` interruptible timeout hardening on `7.2.9-2-cachyos`, all **7 consecutive `suspend-then-hibernate` cycles** (`Oct 15 22:04`, `Oct 16 00:38`, `Oct 16 16:25`, `Oct 16 23:32`, `Oct 17 09:09`, `Oct 17 15:44`, and `Oct 17 19:24` $\rightarrow$ `Oct 18 11:58`) transitioned cleanly at the 30-minute mark into zero-watt `HibernateMode=shutdown` with zero freezer aborts, preserving the same `Oct 13` boot session across 5 days.
- **Symptom**:
  - Upon every resume from S5 hibernation (`HibernateMode=shutdown`):
    - **Short hibernations (`< 7 hours`)**: Both `CLOCK_REALTIME` and `CLOCK_BOOTTIME` **froze completely** at the pre-hibernate timestamp (e.g., on `Oct 17 16:14` $\rightarrow$ `18:45`, the system woke with its clock still at `16:14:52`, and `chronyd` logged `System clock wrong by 9016.298188 seconds` ~10s later once Wi-Fi reconnected).
    - **Long overnight hibernations (`> 7 hours`)**: The system clock advanced by $T_{\text{hibernated}} - 25,179\text{s}$ (`-7 hours`), waking **7 hours behind** true time (e.g., on `Oct 17 19:54` $\rightarrow$ `Oct 18 11:58`, `16h 04m` hibernated, the kernel injected `9h 04m` so the system woke at `04:58:23` MDT instead of `11:58:02` MDT, and `chronyd` logged `System clock wrong by 25178.998475 seconds`).
- **Root Cause (Proved via `vmlinux` Disassembly & Hardware Inspection)**:
  1. **x86 Persistent Clock Path (`read_persistent_clock64` $\rightarrow$ `mach_get_cmos_time`)**:
     - On `7.2.9-2-cachyos`, `x86_platform.get_wallclock` points to `mach_get_cmos_time`, reading CMOS `rtc0` (`rtc_cmos PNP0B00:00`, ports `0x70`/`0x71`). Because `read_persistent_clock64()` returns nonzero seconds, `persistent_clock_exists = 1`, which causes `rtc_suspend()` / `rtc_resume()` in `drivers/rtc/class.c` to return early and delegates sleep-time injection exclusively to `timekeeping_suspend()` / `timekeeping_resume()` in `kernel/time/timekeeping.c`.
     - Note also that `rtc1` (`acpi-tad ACPI000E:00`) fails with `-EIO` (`5`) on `_GRT`/`_SRT` (`__acpi_tad_get_real_time`), and `rtc_resume()` resets `rtc_hctosys_ret = -ENODEV` before checking `strcmp(dev_name(dev), "rtc0")`, which causes `/sys/class/rtc/rtc0/hctosys` to read `0` after any resume because `rtc1` resumes after `rtc0`.
  2. **Kernel `sync_hw_clock` (UTC) vs. Surface UEFI POST SAM EC Clock (`UTC - 25,179s`)**:
     - While Linux is awake with `chronyd` (`rtcsync`) synchronized, the kernel's 11-minute `sync_hw_clock` hrtimer writes **UTC** to CMOS `rtc0` (`0x70`/`0x71`).
     - Across S5 power-off (`HibernateMode=shutdown`), however, Surface UEFI POST re-initializes CMOS `rtc0` from the Surface Aggregator Module (SAM) EC real-time clock, which runs at **`UTC - 25,179s` (`~-7 hours`)** (matching EFI variable `/sys/firmware/efi/efivars/RTC-378d7b65-8da9-4773-b6e4-a47826a833e1` = `07 00 00 00 a4 01 03 00`, where `0x01a4 = 420 minutes = 7 hours`).
     - Across 5 days of logs, this UEFI POST offset measured `-25,180.96s` (Oct 13 cold boot), `-25,179.77s` (Oct 17 hibernate wake), and `-25,179.00s` (Oct 18 hibernate wake).
  3. **Epoch Mismatch in `timekeeping_resume()`**:
     - At hibernation snapshot creation (`syscore_suspend()` $\rightarrow$ `timekeeping_suspend()`), `timekeeping_suspend_time` was read from `rtc0` in **UTC** ($t_{\text{sleep}}$).
     - At hibernation wake (`syscore_resume()` $\rightarrow$ `timekeeping_resume()`), `ts_new` was read from POST-reinitialized `rtc0` ($t_{\text{wake}} - 25,179\text{s}$).
     - `timekeeping_resume()` computed $\Delta = \text{ts\_new} - \text{timekeeping\_suspend\_time} = T_{\text{hibernated}} - 25,179\text{s}$:
       - When $T_{\text{hibernated}} < 25,179\text{s}$ (`7h`), $\Delta < 0$, so `timekeeping_resume()` (`jl` guard) rejected the negative delta and injected **`0 seconds`**, freezing both `CLOCK_REALTIME` and `CLOCK_BOOTTIME`.
       - When $T_{\text{hibernated}} > 25,179\text{s}$ (`7h`), `timekeeping_resume()` injected $T_{\text{hibernated}} - 25,179\text{s}$, leaving the system **7 hours behind** until `chronyd` stepped `CLOCK_REALTIME` (and leaving `CLOCK_BOOTTIME` permanently short by 7 hours per overnight hibernation).
- **Fix (Option B — Pre-Hibernate `rtc0` Epoch Alignment Hook)**:
  1. **Helper `/usr/local/bin/surface-hibernate-rtc-sync` (`profiles/surface/scripts/surface-hibernate-rtc-sync.sh`) & Sleep Hook `/etc/systemd/system-sleep/19-surface-rtc-hibernate.sh` (symlinked in `/usr/lib/systemd/system-sleep/`)**:
     - **Hibernate-Only Filter**: Checks `${SYSTEMD_SLEEP_ACTION:-$2}` so it is a complete no-op during `s2idle` (`SYSTEMD_SLEEP_ACTION=suspend`, where UEFI POST does not run and `rtc0` remains in UTC) and executes only on `hibernate` / `hybrid-sleep` phases.
     - **`pre` (`pre/hibernate`)**:
       - Latches `STA_UNSYNC` (`0x0040`) via `adjtimex()` so the kernel's `sync_hw_clock` hrtimer (which retries every 2s when aligning to its CMOS sub-second window) cannot overwrite `rtc0` back to UTC during the ~7–12s snapshot memory preallocation window before `timekeeping_suspend()`.
       - Shifts CMOS `rtc0` to `CLOCK_REALTIME + offset_sec` (`-25,179s` default, stored in `/var/lib/surface-hibernate-rtc/offset_sec`) via direct `ioctl(fd, RTC_SET_TIME)` (`<1ms`, without touching `/etc/adjtime`).
       - `timekeeping_suspend()` then records `timekeeping_suspend_time = t_sleep + offset_sec` in the hibernation image.
     - **`post` (`post/hibernate`)**:
       - During `syscore_resume()`, `timekeeping_resume()` reads POST-initialized `rtc0` (`t_wake + offset_sec`) and subtracts `timekeeping_suspend_time` (`t_sleep + offset_sec`). The offsets cancel out ($\Delta = t_{\text{wake}} - t_{\text{sleep}} = T_{\text{hibernated}} > 0$), so the kernel natively injects the exact hibernated duration into **both `CLOCK_REALTIME` and `CLOCK_BOOTTIME`** before userspace thaws.
       - Immediately restores CMOS `rtc0` back to UTC (`CLOCK_REALTIME`) via `ioctl(RTC_SET_TIME)`, clears `STA_UNSYNC` via `adjtimex()`, and records the raw POST sample in `/var/lib/surface-hibernate-rtc/last_wake_sample.json` so the next `pre/hibernate` (while NTP-synchronized) automatically tracks slow SAM EC crystal drift (~0.4s/day) within a bounded `[-25500, -24900]` guard window.
       - Includes an automatic safety-net fallback (`clock_settime`) if `CLOCK_REALTIME` is ever `>30s` behind `rtc_post - offset_sec`, and handles aborted hibernations cleanly without false clock steps.
  2. **Snapshot Memory Preallocation Tuning (`/sys/power/image_size = 4800000000`)**:
     - Disassembly of `hibernate_preallocate_memory()` in `vmlinux` (`0xffffffff8128d877`–`0xffffffff8128d927`) confirmed that with the default `/sys/power/image_size = 3105640448` (`758,213` pages $\approx 3.06\text{ GB}$), whenever saveable RAM (`%r14`) was between `758,213` pages and `max_size` ($\approx 960,000$ pages $\approx 3.93\text{ GB}$), the kernel missed the `jae` fast path (`size >= saveable`) and invoked `shrink_all_memory(saveable - size)`, spending 6.80–12.60 seconds swapping anonymous pages into `zram0`.
     - Updated `/usr/local/bin/surface-hibernate-compressor` (`profiles/surface/scripts/surface-hibernate-compressor.sh`) to set and verify `/sys/power/image_size = 4800000000` alongside `lz4` at boot, clamping `size` to `max_size` so `hibernate_preallocate_memory()` bypasses `shrink_all_memory()` whenever `saveable <= max_size` and avoids ~827 MB of pre-snapshot `zram0` reclaim thrashing.
  3. **Pre-Sleep `iptsd` Clean Stop & Stale `hidraw` Failure Elimination (`21-surface-ipts-resume.sh`)**:
     - Updated `pre/*` in `/etc/systemd/system-sleep/21-surface-ipts-resume.sh` to run `systemctl stop 'iptsd@*.service'` and `systemctl reset-failed 'iptsd@*.service'`, preventing both the 3s `stop-sigterm` `SIGKILL` timeout on `iptsd@dev-hidraw0.service` during `s2idle` $\rightarrow$ `hibernate` transitions and the stale queued `iptsd@dev-hidraw6.service` `No such file or directory` failure upon hibernation restore.
  4. **Sub-Second Fast Path in `surface-ipts-resume-recover`**:
     - Added `is_device_healthy()` after an initial `0.5s` settle in `/usr/local/bin/surface-ipts-resume-recover` (`profiles/surface/scripts/surface-ipts-resume-recover.sh`) before the `1.5s` + `6 × 2s` active-probe loop, reducing healthy resume verification from `3.10s` to `1.09s` when normal udev has already started `iptsd@dev-hidraw0.service`.
- **Live Full-Cycle Verification (`Oct 18 12:52:29` $\rightarrow$ `14:34:12` MDT)**:
  - ** Phase 1 (`s2idle`, `12:52:31` $\rightarrow$ `13:22:36`)**: `21-surface-ipts-resume.sh` cleanly stopped `iptsd@dev-hidraw0.service` at `12:52:31.777` before `s2idle` entry; `19-surface-rtc-hibernate.sh` (`SYSTEMD_SLEEP_ACTION=suspend`) left `rtc0` untouched in UTC.
  - **Phase 2 (`30m` RTC Wake $\rightarrow$ `HibernateMode=shutdown`, `13:22:36`)**:
    - `19-surface-rtc-hibernate.sh` (`SYSTEMD_SLEEP_ACTION=hibernate`) logged `Surface hibernate RTC pre-sync: shifted rtc0 1792351356 -> 1792326178 (sys=1792351357, offset=-25179s, ntp_synced=True).`
    - With `/sys/power/image_size = 4800000000`, `hibernate_preallocate_memory()` allocated **`979,012` pages (`3,916,048` kbytes, +27% more preserved RAM) in `5.56 seconds` (`704.32 MB/s`)** — more than **2× faster** than the previous `11.64–12.60s` (`243–263 MB/s`) `zram0` reclaim bottleneck.
  - **Phase 3 (Hibernation Wake after `1h 11m 36s` `<7h` S5 Power-Off, `14:34:12`)**:
    - Whereas `<7h` hibernations previously injected `0s` (freezing `CLOCK_REALTIME` and `CLOCK_BOOTTIME` at the pre-hibernate timestamp), `timekeeping_resume()` natively injected **`+4,295.8s`** into both `CLOCK_REALTIME` and `CLOCK_BOOTTIME` before userspace thawed (`wake boot_delta=+4295.8s, rtc_post=1792330474, sys_post=1792355652, restored rtc0 -> 1792355652 UTC`).
    - When Wi-Fi reconnected 8s later, `chronyd` saw only `1.181535s` of sub-second/crystal rounding (down from `4,296s` / `25,179s`), and `/var/lib/surface-hibernate-rtc/last_wake_sample.json` recorded the wake sample to auto-calibrate `offset_sec` to `-25180s` on the next cycle.
    - Zero `iptsd` `stop-sigterm` `SIGKILL` timeouts, zero failed systemd units (`systemctl --failed` = `0`), and `surface-ipts-resume.service` verified `iptsd@dev-hidraw6.service` active and exited in **`0.89s`** after `user.slice` thaw.

