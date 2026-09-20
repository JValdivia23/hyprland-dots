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

## 2. Clock Desync After S4 Hibernation / Sleep (`systemd-timesyncd`)

- **Symptom**: System clock falls several hours out of sync (e.g. ~7 hours behind) after waking up from deep sleep or S4 hibernation (`suspend-then-hibernate`), despite `timedatectl` stating `System clock synchronized: yes`.
- **Root Cause**: 
  1. Surface Book 3 hardware RTC can restore an unsynchronized or drifted timestamp upon S4 hibernation resume.
  2. `systemd-timesyncd` uses an exponential poll interval backoff up to ~34 minutes (`2048s`). Upon waking or Wi-Fi reconnecting, `systemd-timesyncd` remains idle and does not automatically fire an immediate NTP query.
  3. The kernel's `STA_UNSYNC` flag remained cleared from prior to sleep, masking the desync.
- **Fix**:
  1. Resync immediately:
     ```bash
     sudo systemctl restart systemd-timesyncd.service
     ```
  2. Install a systemd sleep hook in `/etc/systemd/system-sleep/10-timesyncd-resume.sh` (`chmod 755`):
     ```bash
     #!/bin/sh
     case "$1" in
         post)
             systemctl restart systemd-timesyncd.service
             ;;
     esac
     ```
  3. Install a NetworkManager dispatcher script in `/etc/NetworkManager/dispatcher.d/no-wait.d/10-timesyncd.sh` (`chmod 755`) so `systemd-timesyncd` restarts immediately whenever an interface connects:
     ```bash
     #!/bin/sh
     if [ "$2" = "up" ]; then
         systemctl restart systemd-timesyncd.service
     fi
     ```
- **Verification**:
  ```bash
  timedatectl status
  timedatectl timesync-status
  ```
