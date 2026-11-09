-- Desktop Workstation Keybindings
-- Tier 2 profile overrides: Only defines hardware-specific and workstation-specific binds.
-- Universal bindings (Noctalia shell, window tiling, terminal, browsers, macOS navigation) are inherited from core.

local helpers = require("helpers")
local homeDir = os.getenv("HOME") or "/home/user"
local mainMod = "SUPER"

----------------------------------------
---- DESKTOP HARDWARE & SHORTCUTS   ----
----------------------------------------

-- 1. Spotify Launcher (Desktop standard)
helpers.bind(mainMod .. " + SHIFT + M", "Launch Spotify", "spotify-launcher")

-- 2. Whisper Push-to-Talk (F9) & Toggle
helpers.bind("F9", "Whisper Dictation (Start)", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-dictate start"))
helpers.bind("F9", "Whisper Dictation (Stop)", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-dictate stop"), { release = true })
helpers.bind(mainMod .. " + CONTROL + X", "Toggle Whisper Dictation", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-dictate toggle"))

-- 3. Hermes Voice Push-to-Talk (F8 / code:74) & Toggle
helpers.bind("code:74", "Hermes Voice (Start)", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hermes-voice start"))
helpers.bind("code:74", "Hermes Voice (Stop)", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hermes-voice stop"), { release = true })
helpers.bind(mainMod .. " + CONTROL + G", "Hermes Voice Toggle", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hermes-voice start"))

-- 4. Attack Shark X85 Keyboard Layout Switch (US <-> ES)
helpers.bind(mainMod .. " + SHIFT + L", "Switch X85 Keyboard Layout", hl.dsp.exec_cmd("hyprctl switchxkblayout sonix-x85 next"))

-- 5. Relative Workspace Movement (CTRL + SUPER + Left / Right)
helpers.bind("CONTROL + SUPER + Left",  "Move window to previous workspace", hl.dsp.window.move({ workspace = "-1" }))
helpers.bind("CONTROL + SUPER + Right", "Move window to next workspace",     hl.dsp.window.move({ workspace = "+1" }))

-- 6. Move all windows from current workspace to target workspace (SUPER + CONTROL + 1..8)
for i = 1, 8 do
    helpers.bind(mainMod .. " + CONTROL + " .. i, "Move all windows to workspace " .. i, hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-move-all-to-ws " .. i))
end

-- 7. Quickshell Fallback Bindings (Active only if SHELL_BACKEND == "quickshell")
if SHELL_BACKEND == "quickshell" then
    helpers.bind(mainMod .. " + Space",         "Toggle OmniMenu Palette", hl.dsp.global("quickshell:palette-toggle"))
    helpers.bind("ALT + Space",                 "Toggle Quick Panel",      hl.dsp.global("quickshell:palette-quick"))
    helpers.bind(mainMod .. " + SHIFT + Space", "Toggle Quick Tiles Grid",  hl.dsp.global("quickshell:palette-quick"))
end
