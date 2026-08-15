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
