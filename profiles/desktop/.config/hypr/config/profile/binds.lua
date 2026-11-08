local helpers = require("helpers")
local homeDir = os.getenv("HOME") or "/home/user"

-- NOTE: core workspaces.lua / windowrules.lua / binds.lua load BEFORE profile modules,
-- so they captured MONITOR1/PRIMARY_MONITOR = "eDP-1". Re-apply monitor-dependent rules here.
helpers.bind("SUPER + ALT + 1", "Focus monitor 1 (DP-1)",     hl.dsp.focus({ monitor = "DP-1" }))
helpers.bind("SUPER + ALT + 2", "Focus monitor 2 (HDMI-A-1)", hl.dsp.focus({ monitor = "HDMI-A-1" }))
hl.window_rule({ match = { class = "^(.*\\.exe)$", float = true }, monitor = "DP-1", center = true, fullscreen_state = 0 })
hl.window_rule({ match = { class = "^(.*[Ll]auncher.*)$" }, float = true, monitor = "DP-1" })
hl.window_rule({ match = { class = "^(vesktop|discord)$" }, monitor = "DP-1" })

-- Desktop Workstation & Voice Dictation Keybindings
-- Switch keyboard layout (US <-> LATAM) across Attack Shark X85 and wireless dongles
helpers.bind("SUPER + ALT + L", "Switch keyboard layout (US / LATAM)", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-switch-layout"))

-- Voice Dictation (whisper.cpp EN/ES auto-detect with Dota 2 F9 passthrough)
helpers.bind("SUPER + CONTROL + X", "Toggle voice dictation (whisper.cpp)", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-dictate toggle"))
helpers.bind("F9", "Push-to-talk voice dictation (hold)", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-dictate start"))
helpers.bind("F9", "Stop push-to-talk dictation (release)", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-dictate stop"), { release = true })
