# Networking & Firewall Gotchas

Curated networking and firewall rules for `cachyos-cu`.

---

## 1. LocalSend Discovery & File Transfer via UFW

- **Symptom**: LocalSend is running on this machine, but mobile phones or other PCs on the same Wi-Fi/LAN cannot discover or send files to it.
- **Root Cause**: CachyOS enables UFW (`ufw.service`) by default. Inbound broadcast packets and HTTP transfers on LocalSend's default port (`53317`) are blocked.
- **Fix**: Open port `53317` for both TCP and UDP:
  ```bash
  sudo ufw allow 53317/tcp comment 'LocalSend TCP'
  sudo ufw allow 53317/udp comment 'LocalSend UDP'
  sudo ufw reload
  ```
- **Verification**:
  ```bash
  sudo ufw status verbose
  ```

---

## 2. Clock Desync After S4 Hibernation / Sleep (`chrony` Migration)

- **Symptom**: System clock falls several hours out of sync (e.g. ~5.5–7 hours behind) after waking up from deep sleep or S4 hibernation (`suspend-then-hibernate`), despite `timedatectl` stating `System clock synchronized: yes`. Causes TLS/SSL certificate verification failures (`certificate is not yet valid`) across CLI tools and browsers.
- **Root Cause**:
  1. Surface Book 3 hardware RTC crystal drifts or restores an out-of-sync timestamp upon S4 hibernation resume.
  2. `systemd-timesyncd` is an ultra-minimal SNTP client with an exponential poll backoff up to 34 minutes (`2048s`). When running continuously, it treats large multi-hour offsets as network "spikes" and ignores them, or attempts to slew at ~500 ppm (which takes weeks to correct hours).
  3. Workaround hooks failed because `system-sleep post` fires at the millisecond of kernel wake before Wi-Fi associates (DNS/NTP unreachable), and NetworkManager emits `connectivity-change` / `dhcp4-change` rather than device `up`.
- **Permanent Fix (Migrated to `chrony`)**:
  1. Disabled `systemd-timesyncd`:
     ```bash
     sudo timedatectl set-ntp false
     sudo systemctl disable --now systemd-timesyncd.service
     ```
  2. Installed `chrony` package (`core/packages.txt`):
     ```bash
     sudo pacman -S --needed chrony
     ```
  3. Configured `/etc/chrony.conf`:
     - `makestep 1 -1`: Unconditionally steps the clock on any offset > 1 second (permanently prevents multi-hour sleep drifts).
     - `rtcsync`: Enables kernel 11-minute RTC synchronization.
     - *(Note: `rtcsync` and `rtcfile` directives are mutually exclusive in chrony).*
  4. Deployed official NetworkManager dispatcher script:
     ```bash
     sudo cp /usr/share/doc/chrony/examples/chrony.nm-dispatcher.onoffline /etc/NetworkManager/dispatcher.d/20-chrony-onoffline.sh
     sudo chmod 755 /etc/NetworkManager/dispatcher.d/20-chrony-onoffline.sh
     ```
  5. Enabled and started `chronyd.service`:
     ```bash
     sudo systemctl enable --now chronyd.service
     ```
- **Verification**:
  ```bash
  chronyc tracking
  chronyc sources -v
  timedatectl status
  ```
