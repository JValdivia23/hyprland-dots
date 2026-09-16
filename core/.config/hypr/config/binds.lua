local helpers = require("helpers")

local mainMod = "SUPER"
local noctCall = "noctalia msg "
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")
local homeDir = os.getenv("HOME") or "/home/user"
local macHelper = homeDir .. "/.local/bin/mac-key-helper "
local winPop = homeDir .. "/.local/bin/hypr-window-pop"
local kbdBrightness = homeDir .. "/.local/bin/hypr-kbd-brightness "
local screenBrightness = homeDir .. "/.local/bin/hypr-screen-brightness "
local lidHandler = homeDir .. "/.local/bin/hypr-lid-handler "
local keybindsMenu = homeDir .. "/.local/bin/hypr-keybinds-menu"

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Window manipulation
helpers.bind(mainMod .. " + Escape", "Toggle session menu", hl.dsp.exec_cmd(noctCall .. "panel-toggle session"))
helpers.bind(mainMod .. " + Q",      "Close active window", hl.dsp.window.close())
helpers.bind(mainMod .. " + W",      "Close active window", hl.dsp.window.close())
helpers.bind(mainMod .. " + T",      "Toggle window floating", hl.dsp.window.float({ action = "toggle" }))
helpers.bind(mainMod .. " + D",      "Toggle monocle fullscreen", hl.dsp.window.fullscreen({ mode = 1 }))
helpers.bind(mainMod .. " + F",      "Toggle fullscreen", hl.dsp.window.fullscreen())
helpers.bind(mainMod .. " + J",      "Toggle split layout", hl.dsp.layout("togglesplit"))
helpers.bind(mainMod .. " + P",      "Toggle pseudo tiling", hl.dsp.exec_raw("pseudo", ""))
helpers.bind(mainMod .. " + O",      "Pop window to center float", hl.dsp.exec_cmd(winPop))
helpers.bind(mainMod .. " + SHIFT + O", "Pop window to Picture-in-Picture", hl.dsp.exec_cmd(winPop .. " pip"))

-- Window grouping / stacking
helpers.bind(mainMod .. " + G",                 "Toggle window grouping / stacking", hl.dsp.group.toggle())
helpers.bind(mainMod .. " + ALT + G",           "Move window out of group",          hl.dsp.exec_raw("moveoutofgroup", ""))
helpers.bind(mainMod .. " + ALT + Tab",         "Cycle next window in group",        hl.dsp.group.next())
helpers.bind(mainMod .. " + ALT + SHIFT + Tab", "Cycle previous window in group",   hl.dsp.group.prev())
helpers.bind(mainMod .. " + CONTROL + G",       "Toggle group lock",                 hl.dsp.group.lock_active())

-- Change focus (CTRL + Arrows)
helpers.bind("CONTROL + Left",  "Focus window left",  hl.dsp.focus({ direction = "left" }))
helpers.bind("CONTROL + Right", "Focus window right", hl.dsp.focus({ direction = "right" }))
helpers.bind("CONTROL + Up",    "Focus window up",    hl.dsp.focus({ direction = "up" }))
helpers.bind("CONTROL + Down",  "Focus window down",  hl.dsp.focus({ direction = "down" }))
helpers.bind("ALT + Tab",       "Cycle next window",  hl.dsp.window.cycle_next())

-- Workspace switching
helpers.bind(mainMod .. " + Tab",       "Switch to next workspace", hl.dsp.focus({ workspace = "e+1" }))
helpers.bind(mainMod .. " + SHIFT + Tab", "Switch to previous workspace", hl.dsp.focus({ workspace = "e-1" }))

-- Swap windows position (CTRL + SHIFT + Arrows & SUPER + ALT + Arrows)
helpers.bind("CONTROL + SHIFT + Left",  "Swap window left",  hl.dsp.window.swap({ direction = "left" }))
helpers.bind("CONTROL + SHIFT + Right", "Swap window right", hl.dsp.window.swap({ direction = "right" }))
helpers.bind("CONTROL + SHIFT + Up",    "Swap window up",    hl.dsp.window.swap({ direction = "up" }))
helpers.bind("CONTROL + SHIFT + Down",  "Swap window down",  hl.dsp.window.swap({ direction = "down" }))
helpers.bind(mainMod .. " + ALT + Left",  "Swap window left",  hl.dsp.window.swap({ direction = "left" }))
helpers.bind(mainMod .. " + ALT + Right", "Swap window right", hl.dsp.window.swap({ direction = "right" }))
helpers.bind(mainMod .. " + ALT + Up",    "Swap window up",    hl.dsp.window.swap({ direction = "up" }))
helpers.bind(mainMod .. " + ALT + Down",  "Swap window down",  hl.dsp.window.swap({ direction = "down" }))

-- Move active window around workspaces & monitors
helpers.bind(mainMod .. " + SHIFT + mouse_up",             "Move window to next monitor", hl.dsp.window.move({ monitor   = "+1" }))
helpers.bind(mainMod .. " + SHIFT + mouse_down",           "Move window to previous monitor", hl.dsp.window.move({ monitor   = "-1" }))
helpers.bind(mainMod .. " + CONTROL + Right",              "Move window to relative workspace next", hl.dsp.window.move({ workspace = "r+1" }))
helpers.bind(mainMod .. " + CONTROL + Left",               "Move window to relative workspace prev", hl.dsp.window.move({ workspace = "r-1" }))
helpers.bind(mainMod .. " + CONTROL + SHIFT + Right",      "Move window to relative workspace next", hl.dsp.window.move({ workspace = "r+1" }))
helpers.bind(mainMod .. " + CONTROL + SHIFT + Left",       "Move window to relative workspace prev", hl.dsp.window.move({ workspace = "r-1" }))
helpers.bind(mainMod .. " + CONTROL + SHIFT + mouse_up",   "Move window to relative workspace next", hl.dsp.window.move({ workspace = "r+1" }))
helpers.bind(mainMod .. " + CONTROL + SHIFT + mouse_down", "Move window to relative workspace prev", hl.dsp.window.move({ workspace = "r-1" }))
for i = 1, NUM_WPM do
    local key = i % 10
    helpers.bind(mainMod .. " + SHIFT + CONTROL + " .. key, "Move window to workspace m~" .. i, hl.dsp.window.move({ workspace = "m~" .. i }))
end

-- Move & Resize with mouse
helpers.bind(mainMod .. " + mouse:272", "Move window with mouse", hl.dsp.window.drag())
helpers.bind(mainMod .. " + mouse:273", "Resize window with mouse", hl.dsp.window.resize())

-------------------------------
---- macOS TEXT & EDITING ----
-------------------------------

local targetWin = "activewindow"

-- Navigation (Line Home / End)
helpers.bind(mainMod .. " + Left",  "Move to start of line", hl.dsp.send_shortcut({ mods = "", key = "Home", window = targetWin }), { repeating = true })
helpers.bind(mainMod .. " + Right", "Move to end of line",   hl.dsp.send_shortcut({ mods = "", key = "End", window = targetWin }),  { repeating = true })

-- Document Navigation (Doc Home / End)
helpers.bind(mainMod .. " + Up",   "Move to top of document",    hl.dsp.send_shortcut({ mods = "CTRL", key = "Home", window = targetWin }), { repeating = true })
helpers.bind(mainMod .. " + Down", "Move to bottom of document", hl.dsp.send_shortcut({ mods = "CTRL", key = "End", window = targetWin }),  { repeating = true })

-- Word Navigation & Selection
helpers.bind("ALT + Left",          "Move backward one word", hl.dsp.send_shortcut({ mods = "CTRL", key = "Left", window = targetWin }),  { repeating = true })
helpers.bind("ALT + Right",         "Move forward one word",  hl.dsp.send_shortcut({ mods = "CTRL", key = "Right", window = targetWin }), { repeating = true })
helpers.bind("ALT + SHIFT + Left",  "Select word backward",   hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "Left", window = targetWin }),  { repeating = true })
helpers.bind("ALT + SHIFT + Right", "Select word forward",    hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "Right", window = targetWin }), { repeating = true })

-- Word & Line Deletion (Smart Context-Aware Routing)
helpers.bind(mainMod .. " + Backspace", "Delete line backward (Smart Terminal/GUI)", function()
    if helpers.is_terminal() then
        hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "U", window = targetWin }))
    else
        hl.dispatch(hl.dsp.send_shortcut({ mods = "SHIFT", key = "Home", window = targetWin }))
        hl.dispatch(hl.dsp.send_shortcut({ mods = "", key = "BackSpace", window = targetWin }))
    end
end, { repeating = true })
helpers.bind("ALT + Backspace", "Delete word backward", hl.dsp.send_shortcut({ mods = "ALT", key = "BackSpace", window = targetWin }), { repeating = true })

-- Selection (Line Left / Right)
helpers.bind(mainMod .. " + SHIFT + Left",  "Select to start of line",      hl.dsp.send_shortcut({ mods = "SHIFT", key = "Home", window = targetWin }), { repeating = true })
helpers.bind(mainMod .. " + SHIFT + Right", "Select to end of line",        hl.dsp.send_shortcut({ mods = "SHIFT", key = "End", window = targetWin }),  { repeating = true })
helpers.bind(mainMod .. " + SHIFT + Up",    "Select to top of document",    hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "Home", window = targetWin }), { repeating = true })
helpers.bind(mainMod .. " + SHIFT + Down",  "Select to bottom of document", hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "End", window = targetWin }),  { repeating = true })

-- Global Clipboard Overrides & Text Actions (Smart Context-Aware Routing)
helpers.bind(mainMod .. " + C", "Copy selection (Smart Terminal/GUI)", function()
    if helpers.is_terminal() then
        hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "C", window = targetWin }))
    else
        hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "C", window = targetWin }))
    end
end)
helpers.bind(mainMod .. " + V", "Paste from clipboard (Smart Terminal/GUI)", function()
    if helpers.is_terminal() then
        hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "V", window = targetWin }))
    else
        hl.dispatch(hl.dsp.send_shortcut({ mods = "CTRL", key = "V", window = targetWin }))
    end
end)
helpers.bind(mainMod .. " + X",         "Cut selection",  hl.dsp.send_shortcut({ mods = "CTRL", key = "X", window = targetWin }))
helpers.bind(mainMod .. " + Z",         "Undo",           hl.dsp.send_shortcut({ mods = "CTRL", key = "Z", window = targetWin }))
helpers.bind(mainMod .. " + SHIFT + Z", "Redo",           hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "Z", window = targetWin }))


------------------
---- LAUNCHER ----
------------------

-- Application Launchers (SUPER + SHIFT + <key>)
helpers.bind(mainMod .. " + Return",         "Launch Kitty Terminal (New Window)", launchPrefix .. TERMINAL)
helpers.bind(mainMod .. " + SHIFT + Return", "Launch or focus Ghostty Terminal",    helpers.launch_or_focus("ghostty", launchPrefix .. "ghostty"))
helpers.bind(mainMod .. " + SHIFT + B",      "Launch or focus Zen Browser",         helpers.launch_or_focus("zen", launchPrefix .. "zen-browser"))
helpers.bind(mainMod .. " + SHIFT + F",      "Launch or focus File Manager",        helpers.launch_or_focus("dolphin", launchPrefix .. FILE_MANAGER))
helpers.bind(mainMod .. " + SHIFT + A",      "Launch or focus LazyGit",             helpers.launch_or_focus("lazygit", launchPrefix .. TERMINAL .. " --class lazygit -e lazygit"))
helpers.bind(mainMod .. " + SHIFT + D",      "Launch or focus LazyDocker",          helpers.launch_or_focus("lazydocker", launchPrefix .. TERMINAL .. " --class lazydocker -e lazydocker"))
helpers.bind(mainMod .. " + SHIFT + N",      "Launch or focus Notes (Neovim)",      helpers.launch_or_focus("notes", launchPrefix .. TERMINAL .. " --class notes -e nvim ~/Documents/Notes"))
helpers.bind(mainMod .. " + SHIFT + Y",      "Launch or focus YouTube Webapp",      helpers.launch_or_focus("YouTube", launchPrefix .. "gtk-launch YouTube.desktop"))
helpers.bind(mainMod .. " + SHIFT + U",      "Launch or focus Yazi",                helpers.launch_or_focus("yazi", launchPrefix .. TERMINAL .. " --class yazi -e yazi"))

-- System Panels & Controls (SUPER + <key>)
helpers.bind("CONTROL + SHIFT + Escape", "Launch Btop system monitor", launchPrefix .. TERMINAL .. " -e btop")
helpers.bind(mainMod .. " + comma",      "Toggle Noctalia settings",   hl.dsp.exec_cmd(noctCall .. "settings-toggle"))
helpers.bind(mainMod .. " + E",          "Toggle Noctalia control center", hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center"))
helpers.bind(mainMod .. " + Space",      "Toggle Noctalia app launcher",   hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher"))
helpers.bind("ALT + Space",              "Toggle Noctalia wallpaper panel", hl.dsp.exec_cmd(noctCall .. "panel-toggle wallpaper"))
helpers.bind(mainMod .. " + period",     "Open Noctalia emoji picker",     hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher /emo"))
helpers.bind(mainMod .. " + L",          "Lock desktop session",           hl.dsp.exec_cmd(noctCall .. "session lock"))
helpers.bind(mainMod .. " + ALT + C",    "Kill window mode",               hl.dsp.exec_cmd("hyprctl kill"))
helpers.bind(mainMod .. " + A",          "Toggle notification center",     hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center notifications"))
helpers.bind(mainMod .. " + CONTROL + V","Toggle clipboard history",       hl.dsp.exec_cmd(noctCall .. "panel-toggle clipboard"))
helpers.bind(mainMod .. " + ALT + K",    "Toggle Command/Alt modifier layout", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-toggle-altwin"))
helpers.bind(mainMod .. " + SHIFT + K",  "Toggle Command/Alt modifier layout", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-toggle-altwin"))
helpers.bind(mainMod .. " + K",          "Interactive Keybindings Cheatsheet (Live IPC)", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " --class Keybindings -T 'Hyprland Keybindings' -e " .. keybindsMenu))
helpers.bind("ALT + Return",            "Quick Look preview",             hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-quicklook"))

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio
helpers.bind("XF86AudioRaiseVolume", "Raise audio volume",   hl.dsp.exec_cmd(noctCall .. "volume-up"),   { locked = true, repeating = true })
helpers.bind("XF86AudioLowerVolume", "Lower audio volume",   hl.dsp.exec_cmd(noctCall .. "volume-down"), { locked = true, repeating = true })
helpers.bind("XF86AudioMute",        "Toggle audio mute",    hl.dsp.exec_cmd(noctCall .. "volume-mute"), { locked = true })
helpers.bind("XF86AudioMicMute",     "Toggle mic mute",      hl.dsp.exec_cmd(noctCall .. "mic-mute"),    { locked = true })

-- Media
helpers.bind("XF86AudioPlay",  "Toggle media play/pause", hl.dsp.exec_cmd(noctCall .. "media toggle"),   { locked = true })
helpers.bind("XF86AudioPause", "Toggle media play/pause", hl.dsp.exec_cmd(noctCall .. "media toggle"),   { locked = true })
helpers.bind("XF86AudioNext",  "Next media track",        hl.dsp.exec_cmd(noctCall .. "media next"),     { locked = true })
helpers.bind("XF86AudioPrev",  "Previous media track",    hl.dsp.exec_cmd(noctCall .. "media previous"), { locked = true })

-- Brightness (Display / Screen Backlight)
helpers.bind("XF86MonBrightnessUp",         "Increase screen brightness (5%)",        hl.dsp.exec_cmd(screenBrightness .. "+5%"),   { locked = true, repeating = true })
helpers.bind("XF86MonBrightnessDown",       "Decrease screen brightness (5%)",        hl.dsp.exec_cmd(screenBrightness .. "5%-"),   { locked = true, repeating = true })
helpers.bind("SHIFT + XF86MonBrightnessUp",   "Increase screen brightness fine (1%)",   hl.dsp.exec_cmd(screenBrightness .. "+1%"), { locked = true, repeating = true })
helpers.bind("SHIFT + XF86MonBrightnessDown", "Decrease screen brightness fine (1%)",   hl.dsp.exec_cmd(screenBrightness .. "1%-"), { locked = true, repeating = true })
helpers.bind("CONTROL + XF86MonBrightnessUp",   "Increase screen brightness coarse (10%)", hl.dsp.exec_cmd(screenBrightness .. "+10%"), { locked = true, repeating = true })
helpers.bind("CONTROL + XF86MonBrightnessDown", "Decrease screen brightness coarse (10%)", hl.dsp.exec_cmd(screenBrightness .. "10%-"),{ locked = true, repeating = true })

-- Keyboard Backlight
helpers.bind("XF86KbdBrightnessUp",   "Increase keyboard backlight", hl.dsp.exec_cmd(kbdBrightness .. "up"),   { locked = true, repeating = true })
helpers.bind("XF86KbdBrightnessDown", "Decrease keyboard backlight", hl.dsp.exec_cmd(kbdBrightness .. "down"), { locked = true, repeating = true })


-------------------
---- UTILITIES ----
-------------------

-- Screen Capture
helpers.bind(mainMod .. " + SHIFT + P", "Pick screen color (hyprpicker)",   hl.dsp.exec_cmd("hyprpicker -a"))
helpers.bind("Print",                   "Screenshot region",               hl.dsp.exec_cmd(noctCall .. "screenshot-region"))
helpers.bind("SHIFT + Print",           "Screenshot fullscreen interactive", hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen pick"))
helpers.bind("CONTROL + Print",         "Screenshot fullscreen",           hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen"))
helpers.bind(mainMod .. " + Print",     "Screenshot fullscreen",           hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen"))

-- Lock & Suspend
helpers.bind(mainMod .. " + SHIFT + L",  "Lock session and suspend", hl.dsp.exec_cmd(noctCall .. "session lock-and-suspend"))
helpers.bind("XF86Sleep",                "System sleep",             hl.dsp.exec_cmd(noctCall .. "session lock-and-suspend"), { locked = true })

-- Laptop Lid Switch (Clamshell & Ultra-Low Power Mode)
helpers.bind("switch:on:Lid Switch",     "Clamshell lid closed handler", hl.dsp.exec_cmd(lidHandler .. "close"), { locked = true })
helpers.bind("switch:off:Lid Switch",    "Clamshell lid opened handler", hl.dsp.exec_cmd(lidHandler .. "open"),  { locked = true })

-- Theming, Wallpaper & Night Light
helpers.bind(mainMod .. " + SHIFT + W", "Toggle Noctalia wallpaper panel", hl.dsp.exec_cmd(noctCall .. "panel-toggle wallpaper"))
helpers.bind(mainMod .. " + ALT + N",   "Toggle night light",             hl.dsp.exec_cmd(noctCall .. "nightlight-toggle"))
helpers.bind(mainMod .. " + ALT + T",   "Toggle dark/light theme mode",   hl.dsp.exec_cmd(noctCall .. "theme-mode-toggle"))
helpers.bind(mainMod .. " + CONTROL + I", "Toggle caffeine mode",         hl.dsp.exec_cmd(noctCall .. "caffeine-toggle"))

-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- Switch to workspace with SUPER + [1-9, 0]
for i = 1, 10 do
    local key = i % 10
    helpers.bind(mainMod .. " + " .. key, "Switch to workspace " .. i, hl.dsp.focus({ workspace = i }))
end

-- Move active window to workspace with SUPER + SHIFT + [1-9, 0]
for i = 1, 10 do
    local key = i % 10
    helpers.bind(mainMod .. " + SHIFT + " .. key, "Move window to workspace " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- Focus monitors with SUPER + ALT + [1-3]
helpers.bind(mainMod .. " + ALT + 1", "Focus monitor 1", hl.dsp.focus({ monitor = MONITOR1 }))
helpers.bind(mainMod .. " + ALT + 2", "Focus monitor 2", hl.dsp.focus({ monitor = MONITOR2 }))
helpers.bind(mainMod .. " + ALT + 3", "Focus monitor 3", hl.dsp.focus({ monitor = MONITOR3 }))

-- Single-Key Multi-Monitor Controls (SUPER + grave / ~)
helpers.bind(mainMod .. " + grave",           "Focus next monitor",                 hl.dsp.focus({ monitor = "+1" }))
helpers.bind(mainMod .. " + SHIFT + grave",   "Move active window to next monitor", hl.dsp.window.move({ monitor = "+1" }))
helpers.bind(mainMod .. " + CONTROL + grave", "Move workspace to next monitor",     hl.dsp.workspace.move({ monitor = "+1" }))

-- Directional Window to Monitor (SUPER + SHIFT + ALT + Arrows)
helpers.bind(mainMod .. " + SHIFT + ALT + Left",  "Move window to left monitor",   hl.dsp.window.move({ monitor = "l" }))
helpers.bind(mainMod .. " + SHIFT + ALT + Right", "Move window to right monitor",  hl.dsp.window.move({ monitor = "r" }))
helpers.bind(mainMod .. " + SHIFT + ALT + Up",    "Move window to top monitor",    hl.dsp.window.move({ monitor = "u" }))
helpers.bind(mainMod .. " + SHIFT + ALT + Down",  "Move window to bottom monitor", hl.dsp.window.move({ monitor = "d" }))

-- Directional Workspace to Monitor (SUPER + CONTROL + ALT + Arrows)
helpers.bind(mainMod .. " + CONTROL + ALT + Left",  "Move workspace to left monitor",   hl.dsp.workspace.move({ monitor = "l" }))
helpers.bind(mainMod .. " + CONTROL + ALT + Right", "Move workspace to right monitor",  hl.dsp.workspace.move({ monitor = "r" }))
helpers.bind(mainMod .. " + CONTROL + ALT + Up",    "Move workspace to top monitor",    hl.dsp.workspace.move({ monitor = "u" }))
helpers.bind(mainMod .. " + CONTROL + ALT + Down",  "Move workspace to bottom monitor", hl.dsp.workspace.move({ monitor = "d" }))

-- Move to adjacent workspaces and next empty on a given monitor
helpers.bind(mainMod .. " + CONTROL + Down",  "Focus next empty workspace", hl.dsp.focus({ workspace = "emptym" }))

-- Scroll through existing workspaces & monitors
helpers.bind(mainMod .. " + mouse_down",           "Scroll to next workspace",     hl.dsp.focus({ workspace = "m+1" }))
helpers.bind(mainMod .. " + mouse_up",             "Scroll to previous workspace", hl.dsp.focus({ workspace = "m-1" }))
helpers.bind(mainMod .. " + CONTROL + mouse_up",   "Scroll to next workspace",     hl.dsp.focus({ workspace = "m+1" }))
helpers.bind(mainMod .. " + CONTROL + mouse_down", "Scroll to previous workspace", hl.dsp.focus({ workspace = "m-1" }))

-- Special workspace (scratchpad)
helpers.bind(mainMod .. " + S",       "Toggle scratchpad workspace",     hl.dsp.workspace.toggle_special())
helpers.bind(mainMod .. " + ALT + S", "Move window to scratchpad silently", hl.dsp.exec_raw("movetoworkspacesilent", "special:scratchpad"))
helpers.bind(mainMod .. " + SHIFT + S", "Screenshot region",             hl.dsp.exec_cmd(noctCall .. "screenshot-region"))
