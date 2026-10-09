# OpenCode Install Method Gotchas

Upstream self-update only works with supported installers on `surface`.

---

## 1. `opencode upgrade: installation method not found` on CachyOS repo / AUR build

- **Symptom**: `opencode upgrade` / `update` fails with `installation method not found`. Log shows `automatic update skipped: installation method not found`.
- **Root Cause**: `opencode upgrade` auto-detects only `curl, npm, pnpm, bun, yarn` (see `opencode upgrade --help`). V2 docs list `Homebrew, AUR, Windows package managers, standalone binaries` as not supported. `cachyos-extra-v4` `opencode` (`/usr/bin/opencode`) and AUR builds leave no detection marker.
- **Fix (switch to upstream, fluent `upgrade`)**:
  ```bash
  # 1. Remove repo build via interactive Kitty prompt (Rule 8)
  HYPR_SIG=$(ls -1 /run/user/$(id -u)/hypr/ 2>/dev/null | head -n1)
  export HYPRLAND_INSTANCE_SIGNATURE="$HYPR_SIG"
  hyprctl eval 'hl.exec_cmd("kitty --title OpencodeRemove -e bash -c \"sudo pacman -Rns opencode; echo Done!; read -p PressEnter\"")'

  # 2. Install upstream to ~/.opencode/bin (no sudo)
  curl -fsSL https://opencode.ai/v2/install | bash

  # 3. Fish PATH (installer appends; stowed file: core/.config/fish/config.fish)
  # fish_add_path /home/jmvp/.opencode/bin
  ```
- **Verification**:
  ```bash
  fish -c 'which -a opencode; opencode --version'
  opencode upgrade
  # expected: Using method: curl / already installed (not installation method not found)
  ```
- **Keep-out**: Do not add `opencode` to `core/packages.txt` or `profiles/surface/packages.txt`; `install.sh` would reinstall `/usr/bin/opencode` and shadow `~/.opencode/bin/opencode` in `$PATH`.
- **Shell fluency**: Fish gets `~/.opencode/bin` via `fish_add_path`; bash/non-fish shells use `~/.local/bin` — keep symlink `~/.local/bin/opencode -> ~/.opencode/bin/opencode` so `opencode upgrade` works everywhere.
- **Alternative (keep repo build)**: Update only via `sudo pacman -Syu opencode`, set `"autoupdate": false` in `opencode.jsonc` to silence self-update. `opencode upgrade` will never work in this mode.

---

## 2. Line Navigation (`SUPER + Left / Right` & `Home / End`) in Input vs. Message Scrolling

- **Symptom**: Pressing `SUPER + Left` or `SUPER + Right` while typing in OpenCode does not jump to the beginning or end of the current line; instead, it jumps to the first or last message in the session history or does nothing.
- **Root Cause**:
  1. Hyprland maps `SUPER + Left` / `SUPER + Right` to simulated `Home` / `End` keys via `hl.dsp.send_shortcut({ mods = "", key = "Home"|"End", window = "activewindow" })` in `core/.config/hypr/config/binds.lua`.
  2. OpenCode's TUI keymap binds `Home` (and `ctrl+g`, `alt+home`) to `messages_first` ("Navigate to first message") and `End` (and `ctrl+alt+g`) to `messages_last` ("Navigate to last message").
  3. Cursor movement in OpenCode's input prompt defaults strictly to Emacs/Readline bindings: `Ctrl + A` (`input_line_home`) and `Ctrl + E` (`input_line_end`).
- **Fix**: Override OpenCode keybindings in universal dotfiles configuration `core/.config/opencode/cli.json`:
  ```json
  {
    "$schema": "https://opencode.ai/v2/cli.json",
    "theme": {
      "name": "system"
    },
    "keybinds": {
      "messages_first": "ctrl+g,alt+home",
      "messages_last": "ctrl+alt+g",
      "input_line_home": "home,ctrl+a",
      "input_line_end": "end,ctrl+e",
      "input_select_line_home": "shift+home,ctrl+shift+a",
      "input_select_line_end": "shift+end,ctrl+shift+e"
    }
  }
  ```
  - Removes `home` from `messages_first` (keeps `ctrl+g,alt+home`).
  - Removes `end` from `messages_last` (keeps `ctrl+alt+g`).
  - Maps `home` to `input_line_home` and `end` to `input_line_end`.
  - Maps `shift+home` and `shift+end` to `input_select_line_home` and `input_select_line_end`.
- **Verification**: Run `opencode reload` and test `SUPER + Left` / `SUPER + Right` in an active OpenCode session. Cursor moves instantly to beginning/end of line.

