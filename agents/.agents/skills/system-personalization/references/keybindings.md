# Keyboard Shortcuts (Keybindings)

A reference sheet of keyboard bindings on `cachyos-cu`. All bindings are defined in `~/.config/hypr/config/binds.lua`.

The modifier key `SUPER` (Windows/Command key) is denoted as **`SUPER`**.

## Window Management & System Controls

| Shortcut | Action | Description |
|----------|--------|-------------|
| `SUPER` + `Escape` | Session Menu | Open Noctalia shutdown, reboot, logout, suspend menu |
| `SUPER` + `Q` / `W` | Close Window | Close the focused window |
| `SUPER` + `T` | Toggle Floating | Toggle floating/tiling state of active window |
| `SUPER` + `D` | Fullscreen Mode 1 | Fullscreen window keeping workspace bar |
| `SUPER` + `C` | macOS Copy | `CTRL` + `C` in GUI apps / `CTRL` + `SHIFT` + `C` in terminals |
| `SUPER` + `V` | macOS Paste | `CTRL` + `V` in GUI apps / `CTRL` + `SHIFT` + `V` in terminals |
| `SUPER` + `F` | Fullscreen | Fullscreen window |
| `SUPER` + `J` | Toggle Split | Toggle split direction (dwindle layout) |
| `SUPER` + `P` | Pseudo Split | Toggle pseudo dwindle layout |
| `SUPER` + `O` | Pop-out & Pin | Float, resize (1100x700), center, & pin window across workspaces |
| `SUPER` + `SHIFT` + `O` | Video PiP & Pin | Small video PiP (560x315) in bottom-right corner & pin across workspaces |
| `SUPER` + `G` | Toggle Group / Stacking | Collapse window into / out of tabbed group slot (`hl.dsp.group.toggle`) |
| `SUPER` + `ALT` + `G` | Move Out of Group | Remove active window from grouped stack (`hl.dsp.exec_raw("moveoutofgroup")`) |
| `SUPER` + `ALT` + `Tab` | Cycle Next in Group | Switch to next window tab within active group (`hl.dsp.group.next`) |
| `SUPER` + `ALT` + `SHIFT` + `Tab` | Cycle Prev in Group | Switch to previous window tab within active group (`hl.dsp.group.prev`) |
| `SUPER` + `CONTROL` + `G` | Toggle Group Lock | Lock/unlock active group (`hl.dsp.group.lock_active`) |
| `CTRL` + `Left` / `Right` / `Up` / `Down` | Focus Direction | Change focus to adjacent window |
| `ALT` + `Tab` | Cycle Next | Cycle focus through windows |
| `CTRL` + `SHIFT` + Arrows / `SUPER` + `ALT` + Arrows | Swap Window | Swap positions with adjacent window (`hl.dsp.window.swap`) |
| `SUPER` + `SHIFT` + `ALT` + Arrows | Move Window to Monitor | Move focused window to Left / Right / Top / Bottom monitor (`hl.dsp.window.move`) |
| `SUPER` + `CONTROL` + `ALT` + Arrows | Move Workspace to Monitor | Move entire workspace to Left / Right / Top / Bottom monitor (`hl.dsp.workspace.move`) |
| `SUPER` + `grave` (`~`) / `SHIFT` + `grave` / `CONTROL` + `grave` | Cycle Monitor Controls | Focus next monitor / Move window to next monitor / Move workspace to next monitor |
| `SUPER` + `Tab` / `SUPER` + `SHIFT` + `Tab` | Workspace Switch | Switch to next / previous workspace |
| `SUPER` + `CONTROL` + `Left` / `Right` | Move WS (Relative) | Move active window to next/prev workspace |
| `SUPER` + Left Click Drag | Drag Move | Move floating window |
| `SUPER` + Right Click Drag | Drag Resize | Resize floating window |

## Application Launchers (`SUPER + SHIFT + <key>`)

> [!NOTE]
> All application launchers use **native focus-or-launch** (`helpers.launch_or_focus`). If the target application is already running on any workspace, Hyprland immediately switches to and focuses the window (or cycles between multiple instances). If not running, it launches cleanly managed by systemd cgroups via `uwsm-app`.

| Shortcut | Launch / Focus Target | Focus-or-Launch Behavior |
|----------|----------------------|--------------------------|
| `SUPER` + `Return` | `kitty` | **Multi-instance**: Always spawns a new terminal |
| `SUPER` + `SHIFT` + `Return` | `ghostty` | Focuses active Ghostty or launches |
| `SUPER` + `SHIFT` + `B` | `zen-browser` | Focuses active Zen Browser or launches |
| `SUPER` + `SHIFT` + `F` | `dolphin` | Focuses active Dolphin File Manager or launches |
| `SUPER` + `SHIFT` + `A` | `lazygit` | Focuses active LazyGit TUI or launches |
| `SUPER` + `SHIFT` + `D` | `lazydocker` | Focuses active LazyDocker TUI or launches |
| `SUPER` + `SHIFT` + `N` | `nvim ~/Documents/Notes` | Focuses active Notes session or launches |
| `SUPER` + `SHIFT` + `Y` | YouTube Webapp | Focuses active YouTube window or launches |
| `SUPER` + `SHIFT` + `U` | `yazi` | Focuses active Yazi TUI or launches |

## System Panels & Utilities (`SUPER + <key>`)

| Shortcut | Action | Description |
|----------|--------|-------------|
| `SUPER` + `Space` | Launcher | Toggle Noctalia Application Launcher |
| `SUPER` + `A` | Notifications | Toggle Notifications panel |
| `SUPER` + `L` | Lock Session | Lock screen session |
| `SUPER` + `E` | Control Center | Toggle Noctalia Control Center |
| `SUPER` + `,` | Noctalia Settings | Toggle Noctalia Settings menu |
| `SUPER` + `CONTROL` + `V` | Clipboard | Toggle Clipboard history panel |
| `SUPER` + `ALT` + `K` / `SUPER` + `SHIFT` + `K` | Layout Toggle | Toggle Super/Alt position swap (Mac vs PC layout) |
| `SUPER` + `K` | Live IPC Cheatsheet | Open instant floating `fzf` cheatsheet querying compositor runtime (`hyprctl binds -j`) |
| `SUPER` + `Escape` | Session Menu | Open Noctalia shutdown, reboot, logout, suspend menu |
| `SUPER` + `ALT` + `C` | Force-Kill Window | Turn cursor into crosshair to click & kill any window |
| `SUPER` + `SHIFT` + `L` / `XF86Sleep` | Lock & Suspend | Lock screen and put system to sleep / suspend |
| `SUPER` + `SHIFT` + `P` | Color Picker | Launch `hyprpicker -a` (click to copy hex) |
| `Print` / `SUPER` + `SHIFT` + `S` | Region Screenshot | Select region screenshot with annotation editor (Satty) |
| `SHIFT` + `Print` | Window / Pick Screenshot | Interactive monitor / window pick screenshot |
| `CTRL` + `Print` / `SUPER` + `Print` | Fullscreen Screenshot | Fullscreen screenshot with annotation editor (Satty) |
| `SUPER` + `SHIFT` + `W` | Wallpaper Panel | Toggle Noctalia wallpaper panel |
| `ALT` + `Space` | Wallpaper Panel | Toggle Noctalia wallpaper panel (instant, shuffled, pre-cached) |
| `ALT` + `Return` | Quick Look Preview | Open macOS-style floating Quick Look overlay (`swayimg`) over highlighted file |
| `SUPER` + `ALT` + `N` | Night Light Toggle | Toggle night light / warm temperature color filter |
| `SUPER` + `ALT` + `T` | Dark/Light Toggle | Toggle desktop theme between dark and light mode |
| `SUPER` + `CONTROL` + `I` | Caffeine Toggle | Toggle Caffeine (idle inhibitor) to prevent automatic sleep/idle |

## macOS Text Editing & Selection

| Shortcut | Context | Target Action |
|----------|---------|---------------|
| `SUPER` + `Left` / `Right` | Global | Jump to line HOME / END |
| `SUPER` + `Up` / `Down` | Terminal / GUI | Jump to document top / bottom |
| `SUPER` + `Backspace` | Terminal / GUI | Delete line (`CTRL+U` or `SHIFT+HOME -> BACKSPACE`) |
| `ALT` + `Backspace` | Terminal / GUI | Delete word (`ALT+BACKSPACE` or `CTRL+BACKSPACE`) |
| `ALT` + `Left` / `Right` | Terminal / GUI | Jump word left / right |
| `ALT` + `SHIFT` + `Left` / `Right` | Terminal / GUI | Select word left / right |
| `SUPER` + `SHIFT` + Arrows | Floating / Tiled | Fine window resize (20px) if floating, text selection if tiled |
| `SUPER` + `C` / `V` / `X` | Global | macOS-style Copy / Paste / Cut (`CTRL+SHIFT+C`, `CTRL+V`, `CTRL+X`) |
| `SUPER` + `Z` / `SUPER` + `SHIFT` + `Z` | Global | macOS-style Undo / Redo (`CTRL+Z`, `CTRL+SHIFT+Z`) |

## Hardware Controls

| Key | Action | Description |
|-----|--------|-------------|
| `XF86AudioRaiseVolume` | `noctalia msg volume-up` | Raise sound volume |
| `XF86AudioLowerVolume` | `noctalia msg volume-down` | Lower sound volume |
| `XF86AudioMute` | `noctalia msg volume-mute` | Mute sound volume |
| `XF86AudioMicMute` | `noctalia msg mic-mute` | Mute/unmute microphone |
| `XF86AudioPlay` / `Pause` | `noctalia msg media toggle` | Play/Pause audio playback |
| `XF86AudioNext` | `noctalia msg media next` | Next audio track |
| `XF86AudioPrev` | `noctalia msg media previous` | Previous audio track |
| `XF86MonBrightnessUp` | `hypr-screen-brightness +5%` | Increase screen brightness with Noctalia OSD (5%) |
| `XF86MonBrightnessDown` | `hypr-screen-brightness 5%-` | Decrease screen brightness with Noctalia OSD (5%) |
| `SHIFT` + `XF86MonBrightnessUp` / `Down` | `hypr-screen-brightness ±1%` | Fine-tune screen brightness with Noctalia OSD (1%) |
| `CONTROL` + `XF86MonBrightnessUp` / `Down` | `hypr-screen-brightness ±10%` | Coarse-tune screen brightness with Noctalia OSD (10%) |
| `XF86KbdBrightnessUp` / `Down` (`Fn` + `Up` / `Down`) | `hypr-kbd-brightness {up\|down}` | Adjust keyboard backlight brightness with Noctalia OSD |
| `switch:on:Lid Switch` | `hypr-lid-handler close` | Clamshell lid close: Lock session, DPMS off (`eDP-1`), save/cut keyboard light, power saving profile |
| `switch:off:Lid Switch` | `hypr-lid-handler open` | Clamshell lid open: DPMS on (`eDP-1`), restore keyboard brightness, restore active power profile |

## Workspaces & Monitor Control

| Shortcut | Action | Description |
|----------|--------|-------------|
| `SUPER` + `1` .. `9`, `0` | Switch Workspace | Switch active workspace to 1 through 10 |
| `SUPER` + `SHIFT` + `1` .. `9`, `0` | Move Window to WS | Move active window to workspace 1 through 10 |
| `SUPER` + `` ` `` (`grave` / `~`) | Focus Next Monitor | Cycle focus to the next monitor |
| `SUPER` + `SHIFT` + `` ` `` | Move Window Next Mon | Move active window to the next monitor |
| `SUPER` + `CONTROL` + `` ` `` | Move Workspace Next Mon | Move current workspace to the next monitor |
| `SUPER` + `ALT` + `1` / `2` / `3` | Focus Monitor | Focus monitor 1, 2, or 3 |
| `Fn` + `F6` / `SUPER` + `SHIFT` + `S` / `Print` | Region Screenshot | Select region screenshot with annotation editor (Satty) |
| `SUPER` + `S` | Toggle Scratchpad | Toggle visibility of hidden Scratchpad overlay |
| `SUPER` + `ALT` + `S` | Move to Scratchpad | Move focused window to Scratchpad silently |

## Surface Profile & Tablet Shortcuts

| Shortcut | Action | Description |
|----------|--------|-------------|
| `SUPER` + `ALT` + `D` | Detach Base | Request Surface Book tablet/base detachment (`surface dtx request`) |
| `SUPER` + `ALT` + `V` | Virtual Keyboard | Toggle on-screen virtual keyboard overlay (`hypr-virtual-keyboard` / `wvkbd`) |
