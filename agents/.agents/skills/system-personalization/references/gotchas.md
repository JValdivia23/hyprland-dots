# Known Gotchas & Troubleshooting

A curated list of pitfalls, quirks, and configurations specific to this machine (`cachy-asus`).

---

## Networking & Firewalls

### LocalSend not visible on local network (devices cannot discover or send files)
- **Symptom**: LocalSend is installed and running, but other devices on the same Wi-Fi/LAN cannot discover this machine or send files to it.
- **Root Cause**: CachyOS enables UFW (`ufw.service`) by default, which blocks uninvited incoming network traffic including LocalSend's discovery broadcast and transfer requests.
- **Fix**: Allow LocalSend's port `53317` (TCP and UDP) through UFW:
  ```bash
  sudo ufw allow 53317/tcp comment 'LocalSend TCP'
  sudo ufw allow 53317/udp comment 'LocalSend UDP'
  sudo ufw reload
  ```

---

## Graphics & Dual GPU

### Launching games or heavy applications on the dedicated GPU (PRIME)
- **Quirk**: This laptop features dual GPUs: AMD Renoir (Vega) for low-power display and an NVIDIA RTX 2060 Max-Q for high-performance rendering. By default, applications run on the integrated AMD graphics to save power.
- **Symptom**: 3D games or GPU-heavy apps run at very low framerates.
- **Fix**: Launch the application using the `prime-run` command wrapper (e.g. `prime-run steam`), or prepend environment variables:
  ```bash
  __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia <command>
  ```

---

## Wayland & Noctalia

### Noctalia configuration changes do not apply automatically
- **Symptom**: Modifying `~/.config/noctalia/config.toml` does not update the visual bar or widget states immediately.
- **Fix**: Send a reload message directly to the running Noctalia daemon:
  ```bash
  noctalia msg reload
  ```
  If changes require a full restart of the shell panel, run:
  ```bash
  noctalia msg restart
  ```

### Clipboard screenshots do not launch Satty
- **Symptom**: Pressing the PrintScreen key launches slurp/grim, but the screenshot is not saved or opened.
- **Root Cause**: The Noctalia configuration `clipboard_image_action_command = "satty -f -"` pipes screenshot data to Satty, which expects standard input. If Satty fails to run, verify that `satty` is installed and that the user's environment has the correct Wayland socket variables.
- **Fix**: Run `pacman -Q satty` to ensure it is installed.

---

## Hyprland Lua Configurations & Keybindings

### Lua config changes crash Hyprland or display errors
- **Symptom**: After editing a `.lua` configuration file, Hyprland displays a red error bar on screen or user reports "there's a system error". Standard system logs (`journalctl`) do NOT capture config validation errors.
- **Root Cause**: Hyprland parses config files dynamically and renders config errors to an on-screen red overlay banner without printing validation failures to systemd journald.
- **Fix**: ALWAYS run Hyprland's built-in error checker first when diagnosing Hyprland desktop issues:
  ```bash
  hyprctl configerrors
  ```
  This immediately prints the file path, line number, and exact invalid key or syntax error.

### Hyprland 0.55+ Window Resizing API (`hl.dsp.window.resize`)
- **Symptom**: Calling `exec_raw("resizeactive", "exact 560 315")` or legacy `resizeactive` from bash scripts fails to resize floating windows.
- **Root Cause**: In Hyprland 0.55+, `resizeactive` has been replaced by the native Lua API `hl.dsp.window.resize()`.
- **Fix**: Update scripts to invoke `hl.dsp.window.resize({ x = width, y = height, exact = true })`:
  ```bash
  hyprctl dispatch 'hl.dsp.window.resize({ x = 560, y = 315, exact = true })'
  ```

### Hyprland Lua `hl.bind` expects native dispatcher objects (not function closures or immediate return values)
- **Symptom**: Keybindings registered with `hl.bind("SUPER + Left", function() ... end)` or `hl.bind("SUPER + Left", hl.dsp.exec_raw(...))` fail to execute when the physical key is pressed, returning no errors on load.
- **Root Cause**: In Hyprland 0.55+ Lua mode, `hl.bind` expects a native Hyprland C++ dispatcher object returned by `hl.dsp...`. Passing an anonymous Lua function closure or an immediate function invocation returns `nil` to `hl.bind`, silently failing to register a valid keybinding callback.
- **Fix**: Pass native `hl.dsp...` dispatcher objects directly:
  ```lua
  local targetWin = "activewindow"
  hl.bind("SUPER + Left", hl.dsp.send_shortcut({ mods = "", key = "Home", window = targetWin }), { repeating = true })
  hl.bind("ALT + Left",   hl.dsp.send_shortcut({ mods = "CTRL", key = "Left", window = targetWin }), { repeating = true })
  ```

### Hyprland `exec_cmd` fails on scripts in `~/.local/bin/` (missing PATH in compositor environment)
- **Symptom**: Custom helper scripts in `~/.local/bin/` (like `mac-key-helper` or `hypr-window-pop`) fail silently when triggered via `hl.dsp.exec_cmd("script-name")` with `command not found`.
- **Root Cause**: The running Hyprland compositor process environment PATH (`/proc/<pid>/environ`) is set at session startup and does not include `~/.local/bin/`.
- **Fix**: Always construct and pass the full absolute script path in `binds.lua`:
  ```lua
  local homeDir = os.getenv("HOME") or "/home/user"
  local winPop = homeDir .. "/.local/bin/hypr-window-pop"
  hl.bind("SUPER + O", hl.dsp.exec_cmd(winPop))
  ```

### Hyprland Lua `sendshortcut` IPC command execution from shell
- **Symptom**: Running `hyprctl dispatch sendshortcut "CTRL, U, activewindow"` from bash or scripts fails with `error: [string "return hl.dispatch(sendshortcut CTRL, U, acti..."]:1: ')' expected near 'CTRL'`.
- **Root Cause**: On Hyprland 0.55+ in Lua configuration mode (`hyprland.lua`), `hyprctl dispatch` wraps IPC arguments into `return hl.dispatch(...)`. Unquoted arguments with commas split the parameters and break Lua expression parsing.
- **Fix**: Wrap the dispatch call in quotes targeting the Lua `exec_raw` dispatcher:
  ```bash
  hyprctl dispatch 'hl.dsp.exec_raw("sendshortcut", "CTRL, U, activewindow")'
  ```

---

## SSH & Terminal Compatibility

### Missing `xterm-kitty` terminfo on remote SSH hosts causes ZSH/Bash key duplication
- **Symptom**: When SSHing (`ssh <host>`) from Kitty, typing in ZSH or line editors results in duplicated characters (e.g. `cd zigoku` becomes `ccd zigokucdcdd d zzziiggookku`), broken arrow keys, or raw escape codes.
- **Root Cause**: Kitty sets `TERM=xterm-kitty`. Remote SSH hosts lack the `xterm-kitty` terminfo entry, causing ZSH Line Editor (ZLE) cursor movement commands (`cub1`, `cuf1`, `kbs`) to fail silently. Redraw attempts print output side-by-side instead of overwriting in place.
- **Fix**: Transfer the local `xterm-kitty` terminfo database to the remote host using `infocmp`:
  ```bash
  infocmp -a xterm-kitty | ssh <host> "tic -x -"
  ```
  Alternatively, use Kitty's built-in SSH kitten: `kitty +kitten ssh <host>`.

---

### `hl.dsp.send_shortcut` fails to deliver keys if `window` selector is omitted
- **Symptom**: Calling `hl.dsp.send_shortcut({ mods = "CTRL", key = "Left" })` returns `ok` but fails to send key events to the active focused window.
- **Root Cause**: Hyprland's C++ IPC dispatcher requires an explicit target window selector parameter. If omitted, the key event is dropped or targeted to no window.
- **Fix**: Always specify `window = "activewindow"` in `hl.dsp.send_shortcut`:
  ```lua
  hl.dsp.send_shortcut({ mods = "CTRL", key = "Left", window = "activewindow" })
  ```

### Modifier key repetition on hold (`repeating = true`)
- **Symptom**: Holding down `SUPER + Left` or `ALT + Left` fires the action once on initial keydown and stops repeating across lines or words.
- **Root Cause**: Hyprland bindings default to single-trigger keydown events unless the `repeating = true` option flag is passed.
- **Fix**: Pass `{ repeating = true }` in the options table of `hl.bind`:
  ```lua
  hl.bind("ALT + Left", hl.dsp.send_shortcut({ mods = "CTRL", key = "Left", window = "activewindow" }), { repeating = true })
  ```

### Alt / Super key position swap on PC laptops (`altwin:swap_lalt_lwin`)
- **Symptom**: Muscle memory for macOS keyboard shortcuts (`Command` next to Spacebar) feels wrong or triggers physical `Alt` instead of `Super`.
- **Root Cause**: PC laptop keyboards place physical `Alt` next to the Spacebar and physical `Windows (Super)` on the outer left. Mac keyboards place `Command (Super)` next to the Spacebar and `Option (Alt)` on the outer left.
- **Fix**: 
  - Set `input.kb_options = "altwin:swap_lalt_lwin"` in `~/.config/hypr/config/inputs.lua`.
  - Toggle dynamically on the fly via `SUPER + ALT + K`:
    ```bash
    hyprctl eval 'hl.config({ input = { kb_options = "altwin:swap_lalt_lwin" } })'
    ```

### Terminal `press ctrl+c again to exit` (SIGINT) vs. `CTRL+SHIFT+C` Copy
- **Symptom**: Pressing `SUPER+C` in terminal emulators or interactive CLI tools (Node.js, Python REPL, Fish shell, `agy`, `btop`) outputs `press ctrl+c again to exit.` or cancels the running process instead of copying text.
- **Root Cause**: In POSIX terminal emulators, sending a bare `CTRL+C` generates the `SIGINT` (Interrupt) signal. Interactive REPLs trap `SIGINT` and print exit prompts.
- **Fix**: 
  - In `binds.lua`, dispatch `CTRL, SHIFT, C` for `SUPER+C`:
    ```lua
    hl.bind(mainMod .. " + C", hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "C", window = targetWin }))
    ```
    `CTRL+SHIFT+C` is the universal terminal copy shortcut across Kitty, Ghostty, Alacritty, Foot, and WezTerm that copies selected text without sending interrupt signals (`SIGINT`). It also functions natively as Copy across modern Wayland GUI browsers and applications.

### Password authentication for background `sudo` commands (`kitty -e`)
- **Symptom**: Running `sudo pacman -S package` or administrative shell commands directly via non-interactive background agent processes blocks or fails with `sudo: a password is required`.
- **Root Cause**: Non-interactive background subprocesses do not possess a TTY device to prompt the user for password authentication.
- **Fix**: Launch an interactive Kitty terminal window to prompt the user for password input securely:
  ```bash
  kitty -e bash -c "sudo pacman -S --needed package_name; echo 'Done! Press Enter to close...'; read"
  ```

---

### SDDM / Xorg holds NVIDIA dGPU open on boot (preventing 0W D3cold sleep)
- **Symptom**: `supergfxctl` is set to `Hybrid` mode and `NVreg_DynamicPowerManagement=0x02` is enabled, but `nvidia-smi` shows `/usr/lib/Xorg` using 4MB of VRAM and `runtime_status` remains `active` (drawing 2-3W).
- **Root Cause**: SDDM display manager uses X11 by default, and Xorg auto-detects and opens DRM devices for all system GPUs on startup.
- **Fix**: Restrict Xorg to the AMD integrated GPU (`PCI:4:0:0`) by creating `/etc/X11/xorg.conf.d/10-primary-gpu.conf`:
  ```xorg
  Section "ServerFlags"
      Option "AutoAddGPU" "off"
  EndSection

  Section "Device"
      Identifier "AMD"
      Driver "amdgpu"
      BusID "PCI:4:0:0"
  EndSection
  ```

### Helper scripts calling `hyprctl dispatch sendshortcut` with legacy syntax
- **Symptom**: External bash helper scripts (like `mac-key-helper`) executing `hyprctl dispatch 'hl.dsp.exec_raw("sendshortcut", ...)'` return `ok` but fail to trigger keypresses in focused windows.
- **Root Cause**: In Hyprland Lua mode, `hyprctl dispatch` evaluates the argument as Lua code inside `hl.dispatch(...)`. Passing legacy string wrappers fails or gets ignored.
- **Fix**: Dispatch `hl.dsp.send_shortcut({ mods = "...", key = "...", window = "activewindow" })` directly in shell scripts:
  ```bash
  hyprctl dispatch 'hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "C", window = "activewindow" })'
  ```

