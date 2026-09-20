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
