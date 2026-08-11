local mainMod = "SUPER"
local noctCall = "noctalia msg "
local launchPrefix = "uwsm app -- " -- if you are not using UWSM, make this empty (e.g. "")
local homeDir = os.getenv("HOME") or "/home/user"
local macHelper = homeDir .. "/.local/bin/mac-key-helper "
local winPop = homeDir .. "/.local/bin/hypr-window-pop"
local kbdBrightness = homeDir .. "/.local/bin/hypr-kbd-brightness"

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Window manipulation
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd(noctCall .. "panel-toggle session"))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + W",      hl.dsp.window.close())
hl.bind(mainMod .. " + T",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D",      hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + J",      hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + P",         hl.dsp.exec_raw("pseudo", ""))
hl.bind(mainMod .. " + O",         hl.dsp.exec_cmd(winPop))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd(winPop .. " pip"))

-- Change focus (CTRL + Arrows)
hl.bind("CONTROL + Left",  hl.dsp.focus({ direction = "left" }))
hl.bind("CONTROL + Right", hl.dsp.focus({ direction = "right" }))
hl.bind("CONTROL + Up",    hl.dsp.focus({ direction = "up" }))
hl.bind("CONTROL + Down",  hl.dsp.focus({ direction = "down" }))
hl.bind("ALT + Tab",       hl.dsp.window.cycle_next())

-- Workspace switching
hl.bind(mainMod .. " + Tab",       hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "e-1" }))

-- Swap windows position (SUPER + ALT + Arrows)
hl.bind(mainMod .. " + ALT + Left",  hl.dsp.exec_cmd("hyprctl dispatch swapwindow l"))
hl.bind(mainMod .. " + ALT + Right", hl.dsp.exec_cmd("hyprctl dispatch swapwindow r"))
hl.bind(mainMod .. " + ALT + Up",    hl.dsp.exec_cmd("hyprctl dispatch swapwindow u"))
hl.bind(mainMod .. " + ALT + Down",  hl.dsp.exec_cmd("hyprctl dispatch swapwindow d"))

-- Move active window around workspaces & monitors
hl.bind(mainMod .. " + SHIFT + 1",                    hl.dsp.window.move({ monitor = MONITOR1 }))
hl.bind(mainMod .. " + SHIFT + 2",                    hl.dsp.window.move({ monitor = MONITOR2 }))
hl.bind(mainMod .. " + SHIFT + 3",                    hl.dsp.window.move({ monitor = MONITOR3 }))
hl.bind(mainMod .. " + SHIFT + mouse_up",             hl.dsp.window.move({ monitor   = "+1" }))
hl.bind(mainMod .. " + SHIFT + mouse_down",           hl.dsp.window.move({ monitor   = "-1" }))
hl.bind(mainMod .. " + CONTROL + Right",              hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mainMod .. " + CONTROL + Left",               hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + Right",      hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + Left",       hl.dsp.window.move({ workspace = "r-1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_up",   hl.dsp.window.move({ workspace = "r+1" }))
hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "r-1" }))
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + CONTROL + " .. key, hl.dsp.window.move({ workspace = "m~" .. i }))
end

-- Move & Resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-------------------------------
---- macOS TEXT & EDITING ----
-------------------------------

local targetWin = "activewindow"

-- Navigation (Line Home / End)
hl.bind(mainMod .. " + Left",  hl.dsp.send_shortcut({ mods = "", key = "Home", window = targetWin }), { repeating = true })
hl.bind(mainMod .. " + Right", hl.dsp.send_shortcut({ mods = "", key = "End", window = targetWin }),  { repeating = true })

-- Document Navigation (Doc Home / End)
hl.bind(mainMod .. " + Up",   hl.dsp.send_shortcut({ mods = "CTRL", key = "Home", window = targetWin }), { repeating = true })
hl.bind(mainMod .. " + Down", hl.dsp.send_shortcut({ mods = "CTRL", key = "End", window = targetWin }),  { repeating = true })

-- Word Navigation & Selection
hl.bind("ALT + Left",          hl.dsp.send_shortcut({ mods = "CTRL", key = "Left", window = targetWin }),  { repeating = true })
hl.bind("ALT + Right",         hl.dsp.send_shortcut({ mods = "CTRL", key = "Right", window = targetWin }), { repeating = true })
hl.bind("ALT + SHIFT + Left",  hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "Left", window = targetWin }),  { repeating = true })
hl.bind("ALT + SHIFT + Right", hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "Right", window = targetWin }), { repeating = true })

-- Word & Line Deletion
hl.bind(mainMod .. " + Backspace", hl.dsp.send_shortcut({ mods = "CTRL", key = "U", window = targetWin }), { repeating = true })
hl.bind("ALT + Backspace",         hl.dsp.send_shortcut({ mods = "ALT", key = "BackSpace", window = targetWin }), { repeating = true })

-- Selection (Line Left / Right)
hl.bind(mainMod .. " + SHIFT + Left",  hl.dsp.send_shortcut({ mods = "SHIFT", key = "Home", window = targetWin }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.send_shortcut({ mods = "SHIFT", key = "End", window = targetWin }),  { repeating = true })
hl.bind(mainMod .. " + SHIFT + Up",    hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "Home", window = targetWin }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Down",  hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "End", window = targetWin }),  { repeating = true })

-- Global Clipboard Overrides & Text Actions (macOS style)
hl.bind(mainMod .. " + C",         hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "C", window = targetWin }))
hl.bind(mainMod .. " + V",         hl.dsp.send_shortcut({ mods = "CTRL", key = "V", window = targetWin }))
hl.bind(mainMod .. " + X",         hl.dsp.send_shortcut({ mods = "CTRL", key = "X", window = targetWin }))
hl.bind(mainMod .. " + Z",         hl.dsp.send_shortcut({ mods = "CTRL", key = "Z", window = targetWin }))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.send_shortcut({ mods = "CTRL, SHIFT", key = "Z", window = targetWin }))


------------------
---- LAUNCHER ----
------------------

-- Application Launchers (SUPER + SHIFT + <key>)
hl.bind(mainMod .. " + Return",         hl.dsp.exec_cmd(launchPrefix .. TERMINAL))
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd(launchPrefix .. "ghostty"))
hl.bind(mainMod .. " + SHIFT + B",      hl.dsp.exec_cmd(launchPrefix .. "zen-browser"))
hl.bind(mainMod .. " + SHIFT + F",      hl.dsp.exec_cmd(launchPrefix .. FILE_MANAGER))
hl.bind(mainMod .. " + SHIFT + A",      hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e lazygit"))
hl.bind(mainMod .. " + SHIFT + D",      hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e lazydocker"))
hl.bind(mainMod .. " + SHIFT + N",      hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e nvim ~/Documents/Notes"))
hl.bind(mainMod .. " + SHIFT + Y",      hl.dsp.exec_cmd(launchPrefix .. "gtk-launch YouTube.desktop"))
hl.bind(mainMod .. " + SHIFT + U",      hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e yazi"))

-- System Panels & Controls (SUPER + <key>)
hl.bind("CONTROL + SHIFT + Escape", hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " -e btop"))
hl.bind(mainMod .. " + comma",      hl.dsp.exec_cmd(noctCall .. "settings-toggle"))
hl.bind(mainMod .. " + E",          hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center"))
hl.bind(mainMod .. " + Space",      hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher"))
hl.bind("ALT + Space",              hl.dsp.exec_cmd(homeDir .. "/.local/share/waypaper/venv/bin/waypaper"))
hl.bind(mainMod .. " + period",     hl.dsp.exec_cmd(noctCall .. "panel-toggle launcher /emo"))
hl.bind(mainMod .. " + L",          hl.dsp.exec_cmd(noctCall .. "session lock"))
hl.bind(mainMod .. " + ALT + C",    hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mainMod .. " + A",          hl.dsp.exec_cmd(noctCall .. "panel-toggle control-center notifications"))
hl.bind(mainMod .. " + CONTROL + V",hl.dsp.exec_cmd(noctCall .. "panel-toggle clipboard"))
hl.bind(mainMod .. " + ALT + K",    hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-toggle-altwin"))
hl.bind(mainMod .. " + SHIFT + K",  hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-toggle-altwin"))
hl.bind(mainMod .. " + K",          hl.dsp.exec_cmd(launchPrefix .. TERMINAL .. " --class Keybindings -e nvim " .. homeDir .. "/.agents/skills/system-personalization/references/keybindings.md"))
hl.bind("ALT + Return",            hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-quicklook"))

---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(noctCall .. "volume-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(noctCall .. "volume-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(noctCall .. "volume-mute"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(noctCall .. "mic-mute"),    { locked = true })

-- Media
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd(noctCall .. "media toggle"),   { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(noctCall .. "media toggle"),   { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd(noctCall .. "media next"),     { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd(noctCall .. "media previous"), { locked = true })

-- Brightness (Display / Screen Backlight)
hl.bind("XF86MonBrightnessUp",         hl.dsp.exec_cmd(noctCall .. "brightness-up"),            { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",       hl.dsp.exec_cmd(noctCall .. "brightness-down"),          { locked = true, repeating = true })
hl.bind("SHIFT + XF86MonBrightnessUp",   hl.dsp.exec_cmd(noctCall .. "brightness-up current 1"),  { locked = true, repeating = true })
hl.bind("SHIFT + XF86MonBrightnessDown", hl.dsp.exec_cmd(noctCall .. "brightness-down current 1"),{ locked = true, repeating = true })
hl.bind("CONTROL + XF86MonBrightnessUp",   hl.dsp.exec_cmd(noctCall .. "brightness-up current 10"), { locked = true, repeating = true })
hl.bind("CONTROL + XF86MonBrightnessDown", hl.dsp.exec_cmd(noctCall .. "brightness-down current 10"),{ locked = true, repeating = true })

-- Keyboard Backlight & ROG Key
hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd(kbdBrightness .. " up"),   { locked = true })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(kbdBrightness .. " down"), { locked = true })
hl.bind("XF86Launch1",           hl.dsp.exec_cmd("rog-control-center"))
hl.bind("XF86Launch4",           hl.dsp.exec_cmd("rog-control-center"))

-------------------
---- UTILITIES ----
-------------------

-- Screen Capture
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind("Print",                   hl.dsp.exec_cmd(noctCall .. "screenshot-region"))
hl.bind("SHIFT + Print",           hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen pick"))
hl.bind("CONTROL + Print",         hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen"))
hl.bind(mainMod .. " + Print",     hl.dsp.exec_cmd(noctCall .. "screenshot-fullscreen"))

-- Lock & Suspend
hl.bind(mainMod .. " + SHIFT + L",  hl.dsp.exec_cmd(noctCall .. "session lock-and-suspend"))
hl.bind("XF86Sleep",                hl.dsp.exec_cmd(noctCall .. "session lock-and-suspend"), { locked = true })

-- Theming, Wallpaper & Night Light
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(noctCall .. "panel-toggle wallpaper"))
hl.bind(mainMod .. " + ALT + N",   hl.dsp.exec_cmd(noctCall .. "nightlight-toggle"))
hl.bind(mainMod .. " + ALT + T",   hl.dsp.exec_cmd(noctCall .. "theme-mode-toggle"))
hl.bind(mainMod .. " + CONTROL + I", hl.dsp.exec_cmd(noctCall .. "caffeine-toggle"))

-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- Switch to workspace with SUPER + [1-9, 0]
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
end

-- Move active window to workspace with SUPER + SHIFT + [1-9, 0]
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- Focus monitors with SUPER + ALT + [1-3]
hl.bind(mainMod .. " + ALT + 1", hl.dsp.focus({ monitor = MONITOR1 }))
hl.bind(mainMod .. " + ALT + 2", hl.dsp.focus({ monitor = MONITOR2 }))
hl.bind(mainMod .. " + ALT + 3", hl.dsp.focus({ monitor = MONITOR3 }))

-- Single-Key Multi-Monitor Controls (SUPER + grave / ~)
hl.bind(mainMod .. " + grave",           hl.dsp.focus({ monitor = "+1" }))
hl.bind(mainMod .. " + SHIFT + grave",   hl.dsp.window.move({ monitor = "+1" }))
hl.bind(mainMod .. " + CONTROL + grave", hl.dsp.exec_raw("movecurrentworkspacetomonitor", "+1"))

-- Move to adjacent workspaces and next empty on a given monitor
hl.bind(mainMod .. " + CONTROL + Down",        hl.dsp.focus({ workspace = "emptym" }))

-- Scroll through existing workspaces & monitors
hl.bind(mainMod .. " + mouse_down",           hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + mouse_up",             hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + CONTROL + mouse_up",   hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + CONTROL + mouse_down", hl.dsp.focus({ workspace = "m-1" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",       hl.dsp.workspace.toggle_special())
hl.bind(mainMod .. " + ALT + S", hl.dsp.exec_raw("movetoworkspacesilent", "special:scratchpad"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(noctCall .. "screenshot-region"))

