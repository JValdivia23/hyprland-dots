# Keyboard Shortcuts (Keybindings)

A reference sheet of keyboard bindings on `cachy-asus`. All bindings are defined in `~/.config/hypr/config/binds.lua`.

The modifier key `SUPER` (Windows/Command key) is denoted as **`SUPER`**.

## Window Management & System Controls

| Shortcut | Action | Description |
|----------|--------|-------------|
| `SUPER` + `Escape` | `hyprctl kill` | Force close window (interactive cursor click) |
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
| `CTRL` + `Left` / `Right` / `Up` / `Down` | Focus Direction | Change focus to adjacent window |
| `ALT` + `Tab` | Cycle Next | Cycle focus through windows |
| `SUPER` + `ALT` + `Left` / `Right` / `Up` / `Down` | Swap Window | Swap positions with adjacent window |
| `SUPER` + `Tab` / `SUPER` + `SHIFT` + `Tab` | Workspace Switch | Switch to next / previous workspace |
| `SUPER` + `CONTROL` + `Left` / `Right` | Move WS (Relative) | Move active window to next/prev workspace |
| `SUPER` + Left Click Drag | Drag Move | Move floating window |
| `SUPER` + Right Click Drag | Drag Resize | Resize floating window |

## Application Launchers (`SUPER + SHIFT + <key>`)

| Shortcut | Launch Command | Target App |
|----------|----------------|------------|
| `SUPER` + `Return` | `kitty` | Default Terminal |
| `SUPER` + `SHIFT` + `Return` | `ghostty` | Ghostty Terminal |
| `SUPER` + `SHIFT` + `B` | `zen-browser` | Zen Web Browser |
| `SUPER` + `SHIFT` + `F` | `dolphin` | Dolphin File Manager |
| `SUPER` + `SHIFT` + `A` | `kitty -e lazygit` | LazyGit CLI |
| `SUPER` + `SHIFT` + `D` | `kitty -e lazydocker` | LazyDocker CLI |
| `SUPER` + `SHIFT` + `N` | `kitty -e nvim ~/Documents/Notes` | Neovim Notes |
| `SUPER` + `SHIFT` + `Y` | `gtk-launch YouTube.desktop` | YouTube Web App |
| `SUPER` + `SHIFT` + `U` | `kitty -e yazi` | Yazi CLI File Manager |

## System Panels & Utilities (`SUPER + <key>`)

| Shortcut | Action | Description |
|----------|--------|-------------|
| `SUPER` + `Space` | Launcher | Toggle Noctalia Application Launcher |
| `SUPER` + `A` | Notifications | Toggle Notifications panel |
| `SUPER` + `L` | Lock Screen | Lock screen session |
| `SUPER` + `E` | Control Center | Toggle Noctalia Control Center |
| `SUPER` + `,` | Noctalia Settings | Toggle Noctalia Settings menu |
| `SUPER` + `CONTROL` + `V` | Clipboard | Toggle Clipboard history panel |
| `SUPER` + `ALT` + `K` / `SUPER` + `SHIFT` + `K` | Layout Toggle | Toggle Super/Alt position swap (Mac vs PC layout) |
| `SUPER` + `K` | Dynamic Cheat Sheet | Open searchable, floating keybindings cheat sheet |
| `SUPER` + `Escape` | Session Menu | Open Noctalia shutdown, reboot, logout, suspend menu |
| `SUPER` + `ALT` + `C` | Force-Kill Window | Turn cursor into crosshair to click & kill any window |
| `SUPER` + `L` | Lock Session | Lock screen session |
| `SUPER` + `SHIFT` + `L` / `XF86Sleep` | Lock & Suspend | Lock screen and put system to sleep / suspend |
| `SUPER` + `SHIFT` + `P` | Color Picker | Launch `hyprpicker -a` (click to copy hex) |
| `Print` / `SUPER` + `SHIFT` + `S` | Region Screenshot | Select region screenshot with annotation editor (Satty) |
| `SHIFT` + `Print` | Window / Pick Screenshot | Interactive monitor / window pick screenshot |
| `CTRL` + `Print` / `SUPER` + `Print` | Fullscreen Screenshot | Fullscreen screenshot with annotation editor (Satty) |
| `SUPER` + `SHIFT` + `W` | Wallpaper Panel | Toggle Noctalia wallpaper panel |
| `ALT` + `Space` | Waypaper GUI | Open Waypaper GUI (folder/subfolder browsing, rotation timer, random wallpaper) |
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
| `XF86MonBrightnessUp` | `noctalia msg brightness-up` | Increase screen brightness (5%) |
| `XF86MonBrightnessDown` | `noctalia msg brightness-down` | Decrease screen brightness (5%) |
| `SHIFT` + `XF86MonBrightnessUp` / `Down` | Fine Brightness | Fine-tune screen brightness in 1% steps |
| `CONTROL` + `XF86MonBrightnessUp` / `Down` | Coarse Brightness | Coarse-tune screen brightness in 10% steps |
| `XF86KbdBrightnessUp` / `Down` (`Fn` + `Up` / `Down`) | Keyboard Brightness | Adjust keyboard backlight brightness (0-3) with OSD |

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
