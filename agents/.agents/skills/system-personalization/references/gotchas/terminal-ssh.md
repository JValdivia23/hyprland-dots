# Terminal & SSH Gotchas

Curated terminal emulator behaviors, SSH quirks, and administrative prompt practices on `cachyos-cu`.

---

## 1. Missing `xterm-kitty` Terminfo on Remote SSH Hosts

- **Symptom**: When connecting to remote Linux/macOS servers (`ssh <host>`) from Kitty, typing in ZSH, Bash, or line editors causes duplicated characters (e.g. `cd folder` becomes `ccd foldercdcdd d`), broken arrow keys, or unrendered escape codes.
- **Root Cause**: Kitty sets `TERM=xterm-kitty`. Remote systems lack this terminfo entry, breaking Line Editor (ZLE/Readline) cursor movement sequences (`cub1`, `cuf1`, `kbs`).
- **Fix (Method 1 — Export Terminfo)**:
  ```bash
  infocmp -a xterm-kitty | ssh <host> "tic -x -"
  ```
- **Fix (Method 2 — Kitty SSH Kitten)**:
  ```bash
  kitty +kitten ssh <host>
  ```

---

## 2. Elevated Sudo Prompts in Background / Agent Processes (`kitty -e` & `hl.exec_cmd`)

- **Symptom**: Running administrative commands (such as `sudo pacman -S <pkg>`) directly from non-interactive background agent processes hangs indefinitely or fails with `sudo: a password is required`. Furthermore, attempting to launch `kitty -e ... &` directly from detached background subshells fails to attach to the active Wayland workspace because `HYPRLAND_INSTANCE_SIGNATURE` is not exported.
- **Root Cause**: Background subprocesses do not possess an attached TTY terminal device, and detached subshells lack compositor IPC socket registration.
- **Fix**: Export the Hyprland socket and dispatch through Hyprland's native Lua IPC engine:
  ```bash
  HYPR_SIG=$(ls -1 /run/user/$(id -u)/hypr/ 2>/dev/null | head -n1)
  export HYPRLAND_INSTANCE_SIGNATURE="$HYPR_SIG"
  hyprctl eval 'hl.exec_cmd("kitty --title Prompt -e bash -c \"sudo pacman -S --needed package_name; echo; echo Done! Press Enter to close...; read\"")'
  ```

---

## 3. Dynamic Background Opacity & Remote Control Sockets in Kitty

- **Symptom**: Editing `kitty.conf` to add `dynamic_background_opacity yes` and `listen_on` does not enable remote control in currently running Kitty instances even after triggering config reload (`Ctrl+Shift+F5`).
- **Root Cause**: Kitty explicitly disables initializing dynamic background buffers and remote control UNIX domain sockets on live config reload (`Changing this option by reloading the config is not supported`). Existing processes ignore the directive; only newly spawned Kitty instances create the socket.
- **Socket Protocol Performance**: Spawning `kitten @ --to=... set-background-opacity` incurs Python startup and CLI wrapper overhead (~100 ms). For real-time window focus synchronization (< 1 ms latency), send the DCS Device Control String directly over the UNIX socket:
  ```python
  b"\x1bP@kitty-cmd" + json.dumps({"cmd": "set-background-opacity", "version": [0, 26, 0], "payload": {"opacity": 0.75, "all": True}}).encode() + b"\x1b\\"
  ```

