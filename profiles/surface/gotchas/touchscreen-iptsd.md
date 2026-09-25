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

### Option 2: Automated Sleep/Resume Hook (Permanent Prevention)

To prevent this timing race after every sleep cycle, automate the re-triggering of udev after a 1-second delay upon waking.

Create `/etc/systemd/system-sleep/21-surface-ipts-resume.sh` (tracked in `profiles/surface/systemd/`):
```bash
#!/usr/bin/env bash
# Microsoft Surface post-resume hook for IPTS touchscreen re-enumeration
case "$1/$2" in
    post/*)
        # Give IPTS / MEI controller 1s to finish power-state handshake
        sleep 1
        udevadm trigger -s hidraw
        ;;
esac
```
Ensure permissions are set to `755`:
```bash
sudo chmod 755 /etc/systemd/system-sleep/21-surface-ipts-resume.sh
```
