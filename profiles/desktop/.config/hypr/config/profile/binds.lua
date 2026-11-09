-- Desktop Workstation Keybindings
-- Restores and standardizes 100% of the desktop bindings:
-- Terminal (Alacritty/Ghostty), Browser (Zen), Files (Nautilus), Notes, Yazi, Lazygit, Lazydocker,
-- Quickshell OmniMenu/Quick Tiles, Omarchy System Controls, SwayOSD, Whisper dictation, and multi-monitor.

local helpers = require("helpers")
local homeDir = os.getenv("HOME") or "/home/user"
local mainMod = "SUPER"
local osdClient = "swayosd-client --monitor \"$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')\" "

-- 1. Unbind core defaults that conflict with desktop conventions
helpers.unbind(mainMod .. " + Return")
helpers.unbind(mainMod .. " + SHIFT + Return")
helpers.unbind(mainMod .. " + L")
helpers.unbind(mainMod .. " + SHIFT + M")
helpers.unbind(mainMod .. " + SHIFT + F")
helpers.unbind(mainMod .. " + SHIFT + B")
helpers.unbind(mainMod .. " + SHIFT + D")
helpers.unbind(mainMod .. " + SHIFT + Y")
helpers.unbind(mainMod .. " + O")
helpers.unbind(mainMod .. " + D")

-- 2. Core Application Launchers (Desktop Standard)
helpers.bind(mainMod .. " + Return",         "Launch Alacritty Terminal", "alacritty")
helpers.bind(mainMod .. " + SHIFT + Return", "Launch Ghostty Terminal",   "ghostty")
helpers.bind(mainMod .. " + SHIFT + B",      "Launch Zen Browser",        "zen-browser")
helpers.bind(mainMod .. " + SHIFT + F",      "Launch Nautilus",           "nautilus --new-window")
helpers.bind(mainMod .. " + SHIFT + M",      "Launch Spotify",            "spotify-launcher")
helpers.bind(mainMod .. " + SHIFT + Y",      "Launch YouTube App",        "brave-origin --new-window --ozone-platform=wayland --app=\"https://youtube.com\" --name=\"YouTube\" --class=\"YouTube\"")

-- Fast TUI Launchers (Direct in Alacritty)
helpers.bind(mainMod .. " + N",              "Launch Notes (Neovim)",     "alacritty -e nvim " .. homeDir .. "/Documents/Notes")
helpers.bind(mainMod .. " + Y",              "Launch Yazi File Manager",  "alacritty -e yazi")
helpers.bind(mainMod .. " + L",              "Launch Lazygit",            "alacritty -e lazygit")
helpers.bind(mainMod .. " + SHIFT + D",      "Launch Lazydocker",         "alacritty -e lazydocker")
helpers.bind(mainMod .. " + D",              "Launch Wofi App Launcher",  "wofi --show drun -p 'Search...'")

-- 3. Quickshell OmniMenu & Quick Tiles (only if active shell is quickshell)
if SHELL_BACKEND == "quickshell" then
    helpers.bind(mainMod .. " + Space",          "Toggle OmniMenu Palette",   hl.dsp.global("quickshell:palette-toggle"))
    helpers.bind("ALT + Space",                  "Toggle Quick Panel",        hl.dsp.global("quickshell:palette-quick"))
    helpers.bind(mainMod .. " + SHIFT + Space",  "Toggle Quick Tiles Grid",   hl.dsp.global("quickshell:palette-quick"))
end

-- 4. Window Floating, Fullscreen & Pop
helpers.bind(mainMod .. " + O",              "Pop window (Float + Pin)",  hl.dsp.exec_cmd(homeDir .. "/.local/bin/omarchy-hyprland-window-pop"))
helpers.bind(mainMod .. " + A",              "Toggle Window Floating",    hl.dsp.window.float({ action = "toggle" }))
helpers.bind(mainMod .. " + minus",          "Resize active window -100px", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
helpers.bind(mainMod .. " + equal",          "Resize active window +100px", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
helpers.bind(mainMod .. " + SHIFT + minus",  "Resize active window height -100px", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
helpers.bind(mainMod .. " + SHIFT + equal",  "Resize active window height +100px", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

-- 5. Multi-Monitor Toggle & Window Movement
helpers.bind(mainMod .. " + grave",           "Toggle focus between monitors",       hl.dsp.focus({ monitor = "+1" }))
helpers.bind(mainMod .. " + SHIFT + grave",   "Move active window to other monitor", hl.dsp.window.move({ monitor = "+1" }))
helpers.bind(mainMod .. " + CONTROL + grave", "Move active workspace to other monitor", hl.dsp.workspace.move({ monitor = "+1" }))
helpers.bind("CONTROL + SUPER + Left",        "Move window to previous workspace",   hl.dsp.window.move({ workspace = "-1" }))
helpers.bind("CONTROL + SUPER + Right",       "Move window to next workspace",       hl.dsp.window.move({ workspace = "+1" }))

-- 6. Workspaces 1-8 (Supports both number keys and code:10..17 for US/LATAM layouts)
local keycodes = { 10, 11, 12, 13, 14, 15, 16, 17 }
for i = 1, 8 do
    -- Switch workspace
    helpers.bind(mainMod .. " + " .. i, "Switch to workspace " .. i, hl.dsp.focus({ workspace = i }))
    helpers.bind(mainMod .. " + code:" .. keycodes[i], "Switch to workspace " .. i, hl.dsp.focus({ workspace = i }))

    -- Move window to workspace
    helpers.bind(mainMod .. " + SHIFT + " .. i, "Move window to workspace " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
    helpers.bind(mainMod .. " + SHIFT + code:" .. keycodes[i], "Move window to workspace " .. i, hl.dsp.window.move({ workspace = tostring(i) }))

    -- Move ALL windows from active workspace to workspace i
    helpers.bind(mainMod .. " + CONTROL + " .. i, "Move all windows to workspace " .. i, hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-move-all-to-ws " .. i))
    helpers.bind(mainMod .. " + CONTROL + code:" .. keycodes[i], "Move all windows to workspace " .. i, hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-move-all-to-ws " .. i))
end

-- 7. Voice Dictation (whisper.cpp) & Hermes Voice
helpers.bind(mainMod .. " + CONTROL + X", "Toggle voice dictation", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-dictate toggle"))
helpers.bind("F9", "Push-to-talk dictation start", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-dictate start"))
helpers.bind("F9", "Push-to-talk dictation stop",  hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-dictate stop"), { release = true })

helpers.bind(mainMod .. " + CONTROL + G", "Start Hermes Voice", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hermes-voice start"))
helpers.bind("code:74", "Hermes voice push-to-talk", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hermes-voice start"))
helpers.bind("code:74", "Hermes voice push-to-talk stop", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hermes-voice stop"), { release = true })

-- 8. Layouts, Modifiers & OCR
helpers.bind(mainMod .. " + CONTROL + Home", "Extract OCR text", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-ocr"))
helpers.bind(mainMod .. " + SHIFT + L", "Switch XKB keyboard layout (Sonix X85)", hl.dsp.exec_cmd("hyprctl switchxkblayout sonix-x85 next"))
helpers.bind(mainMod .. " + ALT + L",   "Switch keyboard layout (US / LATAM)", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-switch-layout"))
helpers.bind(mainMod .. " + SHIFT + K", "Toggle Alt/Win keyboard mode", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-toggle-altwin"))
helpers.bind(mainMod .. " + ALT + K",   "Toggle Alt/Win keyboard mode", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-toggle-altwin"))

-- 9. Omarchy System Controls (Desktop standard)
helpers.bind(mainMod .. " + CONTROL + A", "Audio Mixer (Wiremix)", "alacritty --class Wiremix -e wiremix")
helpers.bind(mainMod .. " + CONTROL + B", "Bluetooth Controls (bluetui)", "bluetui")
helpers.bind(mainMod .. " + CONTROL + W", "WiFi Network Manager (nmtui)", "alacritty --class Impala -e nmtui")
helpers.bind(mainMod .. " + CONTROL + S", "LocalSend File Sharing", "localsend")
helpers.bind(mainMod .. " + CONTROL + T", "Activity Monitor (Btop)", "alacritty --class Btop -e btop")
helpers.bind(mainMod .. " + CONTROL + C", "Omarchy Capture Menu", hl.dsp.exec_cmd(homeDir .. "/.local/bin/omarchy-menu capture"))
helpers.bind(mainMod .. " + CONTROL + O", "Omarchy Toggle Menu", hl.dsp.exec_cmd(homeDir .. "/.local/bin/omarchy-menu toggle"))
helpers.bind(mainMod .. " + CONTROL + H", "Hardware Info (Fastfetch)", "alacritty --class Fastfetch -e bash -c 'fastfetch; read -p \"Presiona Enter para cerrar...\"'")
helpers.bind(mainMod .. " + CONTROL + V", "Clipboard Manager (Walker)", "walker -k clipboard")
helpers.bind(mainMod .. " + CONTROL + L", "Lock System (hyprlock)", hl.dsp.exec_cmd("hyprlock"))
helpers.bind(mainMod .. " + CONTROL + I", "Toggle Idle Inhibit", hl.dsp.exec_cmd(homeDir .. "/.local/bin/omarchy-toggle-idle"))
helpers.bind(mainMod .. " + CONTROL + N", "Toggle Nightlight", hl.dsp.exec_cmd(homeDir .. "/.local/bin/omarchy-toggle-nightlight"))
helpers.bind(mainMod .. " + CONTROL + Space", "Cycle Next Wallpaper", hl.dsp.exec_cmd(homeDir .. "/.local/bin/omarchy-theme-bg-next"))
helpers.bind(mainMod .. " + SHIFT + CONTROL + Space", "Theme Selection Menu", hl.dsp.exec_cmd(homeDir .. "/.local/bin/omarchy-menu theme"))
helpers.bind(mainMod .. " + Escape", "Omarchy System Menu", hl.dsp.exec_cmd(homeDir .. "/.local/bin/omarchy-menu system"))
helpers.bind(mainMod .. " + K", "Omarchy Keybindings Cheatsheet", hl.dsp.exec_cmd(homeDir .. "/.local/bin/omarchy-menu-keybindings"))

-- Notifications
helpers.bind(mainMod .. " + comma", "Dismiss notification", hl.dsp.exec_cmd("makoctl dismiss"))
helpers.bind(mainMod .. " + SHIFT + comma", "Dismiss all notifications", hl.dsp.exec_cmd("makoctl dismiss --all"))
helpers.bind(mainMod .. " + CONTROL + comma", "Toggle Do Not Disturb", hl.dsp.exec_cmd("makoctl mode -t do-not-disturb && makoctl mode | grep -q 'do-not-disturb' && notify-send 'Silenced notifications' || notify-send 'Enabled notifications'"))

-- Screenshots & Recordings
helpers.bind("PRINT", "Screenshot region", hl.dsp.exec_cmd("omarchy-cmd-screenshot"))
helpers.bind(mainMod .. " + SHIFT + S", "Screenshot region", hl.dsp.exec_cmd("omarchy-cmd-screenshot"))
helpers.bind("SHIFT + PRINT", "Screenshot active window", hl.dsp.exec_cmd("omarchy-cmd-screenshot window"))
helpers.bind("CONTROL + PRINT", "Screenshot full display", hl.dsp.exec_cmd("omarchy-cmd-screenshot output"))
helpers.bind("ALT + PRINT", "Screenrecord region", hl.dsp.exec_cmd("omarchy-cmd-screenrecord"))
helpers.bind("CONTROL + ALT + PRINT", "Screenrecord full display", hl.dsp.exec_cmd("omarchy-cmd-screenrecord output"))
helpers.bind(mainMod .. " + PRINT", "Color Picker (Hyprpicker)", hl.dsp.exec_cmd("pkill hyprpicker || hyprpicker -a"))

-- 10. Hardware Keys via SwayOSD (fallback for quickshell backend; noctalia handles hardware keys in core)
if SHELL_BACKEND == "quickshell" then
    helpers.bind("XF86AudioRaiseVolume", "Raise volume", hl.dsp.exec_cmd(osdClient .. "--output-volume raise"), { locked = true, repeating = true })
    helpers.bind("XF86AudioLowerVolume", "Lower volume", hl.dsp.exec_cmd(osdClient .. "--output-volume lower"), { locked = true, repeating = true })
    helpers.bind("SHIFT + XF86AudioRaiseVolume", "Raise volume 1%", hl.dsp.exec_cmd(osdClient .. "--output-volume +1"), { locked = true, repeating = true })
    helpers.bind("SHIFT + XF86AudioLowerVolume", "Lower volume 1%", hl.dsp.exec_cmd(osdClient .. "--output-volume -1"), { locked = true, repeating = true })
    helpers.bind("XF86AudioMute", "Toggle mute", hl.dsp.exec_cmd(osdClient .. "--output-volume mute-toggle"), { locked = true })
    helpers.bind("XF86AudioMicMute", "Toggle mic mute", hl.dsp.exec_cmd(osdClient .. "--input-volume mute-toggle"), { locked = true })
    helpers.bind("XF86MonBrightnessUp", "Raise brightness", hl.dsp.exec_cmd(osdClient .. "--brightness raise"), { locked = true, repeating = true })
    helpers.bind("XF86MonBrightnessDown", "Lower brightness", hl.dsp.exec_cmd(osdClient .. "--brightness lower"), { locked = true, repeating = true })
    helpers.bind("SHIFT + XF86MonBrightnessUp", "Raise brightness 1%", hl.dsp.exec_cmd(osdClient .. "--brightness +1"), { locked = true, repeating = true })
    helpers.bind("SHIFT + XF86MonBrightnessDown", "Lower brightness 1%", hl.dsp.exec_cmd(osdClient .. "--brightness -1"), { locked = true, repeating = true })
    helpers.bind("XF86AudioNext", "Next media track", hl.dsp.exec_cmd(osdClient .. "--playerctl next"), { locked = true })
    helpers.bind("XF86AudioPrev", "Previous media track", hl.dsp.exec_cmd(osdClient .. "--playerctl previous"), { locked = true })
    helpers.bind("XF86AudioPlay", "Toggle media playback", hl.dsp.exec_cmd(osdClient .. "--playerctl play-pause"), { locked = true })
    helpers.bind("XF86AudioPause", "Toggle media playback", hl.dsp.exec_cmd(osdClient .. "--playerctl play-pause"), { locked = true })
end
