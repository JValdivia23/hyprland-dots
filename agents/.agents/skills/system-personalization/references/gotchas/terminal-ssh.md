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

## 2. Elevated Sudo Prompts in Background / Agent Processes (`kitty -e`)

- **Symptom**: Running administrative commands (such as `sudo pacman -S <pkg>`) directly from non-interactive background agent processes hangs indefinitely or fails with `sudo: a password is required`.
- **Root Cause**: Background subprocesses do not possess an attached TTY terminal device to securely ask for user password input.
- **Fix**: Launch an interactive Kitty terminal window to prompt the user securely:
  ```bash
  kitty -e bash -c "sudo pacman -S --needed package_name; echo 'Done! Press Enter to close...'; read"
  ```
