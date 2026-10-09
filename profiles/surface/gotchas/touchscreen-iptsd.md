# Surface Touchscreen & Stylus (`iptsd`) Wake Race Condition

Detailed troubleshooting and recovery for touchscreen and stylus unresponsiveness after sleep/suspend on Microsoft Surface devices (Surface Book 3, Surface Pro, Surface Laptop) running the `linux-surface` kernel and `iptsd`.

---

## 1. Symptom

- After waking the laptop from suspend or hibernation (`systemd-suspend`, `suspend-then-hibernate`), the touchscreen and Surface Pen are completely unresponsive.
- Tapping or dragging across the display produces no cursor movements, clicks, or gestures in Wayland/Hyprland.
- Checking `hyprctl devices` shows the raw kernel driver node (`ipts-045e:09b2-touchscreen`), but **`iptsd-virtual-touchscreen-045e:09b2`** and **`iptsd-virtual-stylus-045e:09b2`** are completely missing from the device list.
- Checking `systemctl status 'iptsd*'` reports 0 loaded or active services (daemon is dead).

---

## 2. Architecture & Root Cause

### A. Subsystem Architecture
1. **Kernel Driver (`ipts`)**: The Microsoft Surface IPTS (Intel Precise Touch & Stylus) hardware communicates over the Intel MEI (Management Engine Interface) bus. The kernel driver `ipts` does not directly emit calibrated Wayland touch events; instead, it outputs raw sensor heatmap data frames to `/dev/hidraw*`.
2. **Userspace Daemon (`iptsd`)**: `iptsd` connects to the raw `/dev/hidraw*` interface, processes touch matrices, computes blob detection, performs palm rejection and stylus arbitration, and emits standardized multi-touch events through a virtual device (`uinput`) recognized by libinput and Hyprland.
3. **Systemd & Udev Integration**:
   - Modern `iptsd` (3.x+) uses an instantiated template service: `/usr/lib/systemd/system/iptsd@.service`, which enforces `StopWhenUnneeded=yes` and `BindsTo=%i.device`.
   - Service instantiation is driven by udev rule `/usr/lib/udev/rules.d/50-iptsd.rules`:
     ```udev
     SUBSYSTEM=="hidraw", ACTION=="add", TAG+="systemd", \
         PROGRAM="/usr/bin/iptsd-check-device --quiet $env{DEVNAME}", \
         PROGRAM="/bin/systemd-escape --path $env{DEVNAME}", \
         ENV{SYSTEMD_WANTS}+="iptsd@$result.service"
     ```

### B. The Wake-from-Sleep Timing Race
When the Surface wakes from sleep:
1. **Device Re-enumeration**: The IPTS controller power-cycles and re-enumerates. The kernel assigns a new `hidraw` node number (e.g. from `/dev/hidraw0` to `/dev/hidraw6`).
2. **Transient EAGAIN (-11)**: During the first ~1 second of wake, the MEI/IPTS interface is still completing its power-state handshake, logging:
   ```text
   ipts 0000:00:16.4-...: FEEDBACK: recv failed: -11
   ipts 0000:00:16.4-...: Failed to send hid2me feedback: -11
   ```
   (`-11` = `-EAGAIN`, Resource temporarily unavailable).
3. **Udev Rule Abortion**:
   - Udev immediately fires `ACTION=="add"` the instant `/dev/hidraw6` appears.
   - It runs the gatekeeper command `PROGRAM="/usr/bin/iptsd-check-device --quiet /dev/hidraw6"`.
   - Because the hardware controller is still busy handling the wake handshake, `iptsd-check-device` fails to read or query the device and exits with a non-zero code.
   - When a `PROGRAM` key fails in udev, rule execution aborts: **udev drops `TAG+="systemd"` and discards `ENV{SYSTEMD_WANTS}`**.
4. **Daemon Deactivation**:
   - Because `TAG+="systemd"` was never assigned, systemd considers `dev-hidraw6.device` inactive.
   - The previous service `iptsd@dev-hidraw0.service` encounters `IOCTL ... failed: No such device` and terminates because `hidraw0` was removed.
   - `iptsd@dev-hidraw6.service` is never queued.
   - Result: No daemon runs, the virtual uinput touchscreen is destroyed, and the screen becomes dead to touch.

---

## 3. Verified Recovery Solutions

### Option 1: Immediate Manual Recovery (Verified)

Once the system has completed waking and the IPTS controller is responsive, manually trigger udev to re-evaluate the device node:

```bash
# Re-trigger udev on the active hidraw device (or all hidraw devices)
sudo udevadm trigger --action=add /dev/hidraw*
```

Alternatively, use `iptsd`'s built-in helper utility to restart the daemon:
```bash
sudo iptsd-systemd -t any restart
```

**Verification**:
1. Check that the service is running:
   ```bash
   systemctl status 'iptsd*'
   ```
   *(Should show `iptsd@dev-hidrawX.service` Active: active (running)).*
2. Verify Hyprland input devices:
   ```bash
   hyprctl devices | grep -i iptsd
   ```
   *(Both `iptsd-virtual-touchscreen-...` and `iptsd-virtual-stylus-...` will appear under Touch and Tablets).*
3. Touch the screen to confirm touch cursor response.

---

### Option 2: Asynchronous, Bounded Resume Recovery (Deployed and Dispatch Verified 2026-10-08)

The original one-second hook used `udevadm trigger -s hidraw`, whose default action is `change`. The packaged rule above requires `add`, so that hook did not reliably rerun the IPTS device check/start logic. A subsequent hibernation test also found an already-tagged, active device with a stopped daemon: re-adding `SYSTEMD_WANTS` alone does not start dependencies of a device that is already active.

The reviewed Surface-only replacement stores a short dispatcher at `/etc/systemd/system-sleep/21-surface-ipts-resume.sh` (tracked in `profiles/surface/systemd/`). **This location alone is not executed by systemd**: the installed `systemd-sleep` binary and manual specify `/usr/lib/systemd/system-sleep/`. Register the dispatcher there with a symlink, retaining the administrator-owned script under `/etc`:

```text
/usr/lib/systemd/system-sleep/21-surface-ipts-resume.sh
  -> /etc/systemd/system-sleep/21-surface-ipts-resume.sh
```

Dispatcher contents:
```bash
#!/usr/bin/env bash
case "${1:-}/${2:-}" in
    pre/*)
        systemctl --no-block stop surface-ipts-resume.service
        ;;
    post/*)
        systemctl --no-block restart surface-ipts-resume.service
        ;;
esac
```

- **Worker script**: `profiles/surface/scripts/surface-ipts-resume-recover.sh` → `/usr/local/bin/surface-ipts-resume-recover` (mode 755).
- **Static oneshot unit**: `profiles/surface/systemd/surface-ipts-resume.service` → `/etc/systemd/system/surface-ipts-resume.service` (mode 644). It is invoked by the hook, not enabled at boot; `TimeoutStartSec=45s`, `TimeoutStopSec=3s`.
- **Behavior**: Retain the initial 1-second hardware handshake delay in the asynchronous worker, rediscover the live IPTS node on each of up to four attempts, probe only touchscreen IPTS candidates with bounded `iptsd-check-device`, and trigger `--action=add` only on that device. Require its udev `SYSTEMD_WANTS` and active device unit, then explicitly start its matching daemon if inactive. Do not restart a healthy daemon. Confirm it remains active after a further second.
- **Lifecycle / safety**: Cancel an unfinished recovery before another sleep transition. Do not reset MEI, reload drivers, trigger every hidraw device, or change hibernation/compression/boot settings. Only clear historical failed IPTS units whose old device nodes are gone, after a current daemon has recovered. The vendor `BindsTo` / `StopWhenUnneeded` behavior and existing 3-second iptsd stop guard are retained.
- **Deployment**: `profiles/surface/setup.sh` deploys the helper and unit before the dispatcher, reloads systemd, and registers the `/usr/lib` hook symlink. Guarded interactive installation completed with source/target hash checks, installed-file read-back, clean `systemd-analyze verify`, and original-hook backup under `/var/backups/surface-ipts-resume-20261008-161227-34891/`. Initially only the three recovery files were deployed; the missing registration symlink was subsequently added. Compression, sleep policy, boot config, kernel drivers, and packages were unchanged.
- **Manual recovery / code validation**: Bash syntax checks and seven mocked recovery/dispatcher scenarios passed, covering already-active devices with inactive daemons, healthy-daemon preservation, rejected probes, missing udev Wants, inactive devices, node-number changes/retries, and nonblocking dispatch. The live manual worker completed successfully, restored the stopped `iptsd@dev-hidraw6.service` (PID `35009`), and both virtual inputs appeared in the kernel and Hyprland. User confirmed touch works; pen was not tested.
- **First direct hibernation validation**: Original boot/collector survived; the device changed from `hidraw6` to `hidraw0`, and normal packaged udev startup restored the daemon (PID `36795`) and both virtual inputs. User confirmed touch works and the boot menu is hidden; pen, wake method, and exact wake time were not reported. **No fallback-worker run was logged** because the scanned hook directory was empty. Thus this test validates touch/hidden-menu restoration, not the new automatic fallback. `chronyd` stepped the clock forward `230.951801` seconds, so raw hibernation journal timestamps are still not a physical duration benchmark.
- **Registration corrected**: Created and read-back verified the `/usr/lib` symlink to the reviewed `/etc` dispatcher. Updated profile deployment to create it only if absent, accept the same existing symlink idempotently, and refuse unexpected files/links; five setup and five guarded-registrar mock scenarios passed. Original helper/unit/dispatcher, boot config, sleep config, and battery hook hashes were unchanged. The first registered-hook prompt was cancelled before any hibernation request; the subsequent confirmed test below completed. No other hook was registered or modified. Rollback of registration means removing only this symlink after verifying its target, not restoring old boot/sleep configs.
- **Registered-hook direct restore passed**: The original boot and collector (PID `37771`) survived, IPTS changed `hidraw0` → `hidraw6`, and iptsd PID `37942` remained running in both post-resume snapshots and a later check. The journal records the worker starting and successfully finishing; it reported `IPTS instance already active: iptsd@dev-hidraw6.service`, preserving the daemon already started by normal udev. **User confirmed full power-off, lid-only restoration of the original desktop, and working touch; pen remains untested.** Both virtual inputs were present in Hyprland; no failed system units or compositor configuration errors were found.
- **Asynchronous behavior / evidence limits**: The worker ran for about **2.14 seconds** and finished **2.13 seconds after `user.slice` had already thawed**: its settle/health-check sleeps did not hold up user-session thaw. This is not an exact lock-screen benchmark or a measured speedup. Its `inactive/dead` state afterward is expected for a completed oneshot; unloaded-unit timestamps may reset to zero, so use the journal invocation rather than default `Result=success` as proof. This single direct AC cycle verifies real dispatch and healthy-daemon preservation; the inactive-daemon branch was verified manually, not by deliberately inducing a new resume failure. Overnight reliability, physical pen, exact wake time, and standby drain remain unmeasured. `chronyd` later stepped the clock `+88.570899s`, again precluding naive physical-duration claims from raw hibernation journal timestamps.
- **Evidence**: `~/.cache/opencode/surface-standby-tests/ipts-recovery-z4wvl2hs/` contains mock results and guarded deployment records; `direct-hibernate-x9pc08ys/` records the initial unregistered-hook cycle; `registered-hook-retest-gt6ybkeh/` records registration plus cancellation; `registered-hook-retry-pinr1140/` contains the completed registered-hook cycle, `analysis.json`, and `followup.json`. The preceding 30-minute automatic hibernation test is linked from `sleep-hibernate.md`, section 7.
