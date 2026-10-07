# Surface Modern Standby & Hibernation Failure Gotchas

Detailed troubleshooting for hibernation failures, ACPI S4 platform power-down rejections, intermediate battery estimation wakeups, and 19-hour frozen sleep limbo on Microsoft Surface Book 3.

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
     - Because `/etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf` defines `HibernateOnACPower=no`, the machine **never hibernates while plugged into AC power** (stays in fast suspend at the desk).
  2. **Tune Hibernate Delay to 30 Minutes**:
     - Align `HibernateDelaySec=30min` and `SuspendEstimationSec=30min` in `/etc/systemd/sleep.conf.d/10-suspend-then-hibernate.conf` (tracked in `profiles/surface/systemd/10-suspend-then-hibernate.conf`).
  3. **AC Disconnect Clamshell Guard (Udev + Oneshot Service)**:
     - Deployed `/usr/local/bin/surface-unplug-lid-handler` (tracked in `profiles/surface/scripts/surface-unplug-lid-handler.sh`), triggered by `/etc/udev/rules.d/98-surface-unplug-lid.rules` via `/etc/systemd/system/surface-unplug-lid.service`.
     - When `ADP1` switches to `online=0`, the handler verifies if the lid is physically closed (`/proc/acpi/button/lid/*/state`), debounces 1.5s, and triggers `systemctl suspend-then-hibernate` to initiate the 30-minute battery countdown immediately.

