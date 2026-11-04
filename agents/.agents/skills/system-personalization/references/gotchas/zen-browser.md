# Zen Browser Configuration & Keybinding Gotchas

Gotchas and procedures for managing Zen Browser (`zen-browser-bin`) on `surface`.

---

## 1. Modifying Keybindings from Terminal

- **Config Path**: `~/.config/zen/<profile>/zen-keyboard-shortcuts.json`
  (Resolved from `~/.config/zen/profiles.ini`, e.g. `~/.config/zen/1q66wgda.Default (release)/zen-keyboard-shortcuts.json`).
- **Schema & Linux Modifiers**:
  - Shortcuts are stored in a top-level `"shortcuts"` list.
  - On Linux, Zen Browser internally normalizes the Primary Accelerator to `accel: true` (representing <kbd>Ctrl</kbd>).
  - Modifier mapping:
    - `accel: true` -> <kbd>Ctrl</kbd>
    - `alt: true` -> <kbd>Alt</kbd>
    - `shift: true` -> <kbd>Shift</kbd>
    - `meta: true` -> <kbd>Super</kbd> / <kbd>Win</kbd>
  - Single characters use `"key"` (e.g. `"1"`, `"t"`), while special keys use `"keycode"` (e.g. `"VK_F3"`, `"VK_LEFT"`, `"VK_ESCAPE"`).

### Gotcha: In-Memory Overwrite on Exit
- **Symptom**: Editing `zen-keyboard-shortcuts.json` while Zen Browser is running has no effect, and edits are overwritten with the previous state when Zen exits.
- **Root Cause**: Zen Browser reads `zen-keyboard-shortcuts.json` into memory (`_currentShortcutList`) at startup. It does not monitor the file on disk via inotify. On settings adjustments or shutdown, it dumps its in-memory list back to disk.
- **Fix**: **Always ensure Zen Browser is completely closed** (`pgrep -a zen` -> exit code 1) before modifying `zen-keyboard-shortcuts.json`.

---

## 2. Default Workspace vs. Tab Switching Conflict (<kbd>Ctrl</kbd> + <kbd>1..9</kbd>)

- **Symptom**: Pressing <kbd>Ctrl</kbd> + <kbd>1..9</kbd> in Zen Browser on Linux causes conflicts between switching browser tabs (`key_selectTab1..8`, `key_selectLastTab`) and switching Zen workspaces (`zen-workspace-switch-1..10`).
- **Root Cause**: On macOS, Zen defaults to `Cmd + 1..9` (`accel`) for tabs and `Ctrl + 1..9` (`control`) for workspaces. On Linux and Windows, `control` and `accel` both collapse to <kbd>Ctrl</kbd>, causing identical key definitions.
- **Fix (remap tabs to <kbd>Alt</kbd> + <kbd>1..9</kbd>)**:
  Set `modifiers.alt = true` and `modifiers.accel = false` on `key_selectTab1` through `key_selectTab8` and `key_selectLastTab`. Keep `zen-workspace-switch-1` through `10` on `modifiers.accel = true` (<kbd>Ctrl</kbd> + <kbd>1..9, 0</kbd>).

---

## 3. Passphrase-Encrypted Profile Clone (`~/zen-sync` / `JValdivia23/zen-sync`)

- **Repository**: `~/zen-sync` (`https://github.com/JValdivia23/zen-sync.git`, Private)
- **CLI Entrypoint**: `~/.local/bin/zen-sync` -> `~/zen-sync/zen-sync.sh`
- **Encryption**: GnuPG Symmetric AES-256 (`--cipher-algo AES256 --s2k-digest-algo SHA512 --s2k-mode 3 --s2k-count 65011712`) over a `zstd -T0 -9` tarball (`zen-profile.tar.zst.gpg`).
- **Why Raw `~/.config/zen` Is 1.4+ GB**:
  - Websites like WhatsApp Web (`storage/default/https+++web.whatsapp.com` = 1.1 GB: 785 MB `cache/` + 305 MB `idb/` chat/search DBs) and SharePoint (`148 MB`) store huge offline Service Worker caches and IndexedDB blobs.
  - `zen-sync.sh backup` excludes `*/storage/default/*/cache`, `*/gmp-widevinecdm`, `*/gmp-gmpopenh264`, and the heavy WhatsApp/SharePoint `idb` blobs while preserving all workspaces, pinned/open tabs (`zen-sessions.jsonlz4`, `sessionstore.jsonlz4`), saved passwords + master decryption key (`logins.json`, `logins.db`, `key4.db`, `cert9.db`), active cookies & site `localStorage` (`cookies.sqlite`, `storage/default/*/ls`), extensions, and shortcuts (`~7 MB` encrypted).
- **Cross-Machine Path Normalization on Restore**:
  - `profiles.ini` and `<profile>/extensions.json` store absolute `/home/<user>/.config/zen/...` paths. `zen-sync.sh restore` automatically rewrites those paths to match `$ZEN_DIR` on the target laptop.
- **Gotcha**: Always ensure Zen Browser is closed before `zen-sync backup` or `zen-sync restore` (`zen-sync` checks `pgrep -x zen` / `zen-bin` and offers to close it gracefully) so in-memory shortcuts/sessions and SQLite `.sqlite-wal` locks flush cleanly.
