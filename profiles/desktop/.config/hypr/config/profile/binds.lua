local helpers = require("helpers")
local homeDir = os.getenv("HOME") or "/home/user"

-- Desktop Workstation & Voice Dictation Keybindings
-- Switch keyboard layout (US <-> LATAM) across Attack Shark X85 and wireless dongles
helpers.bind("SUPER + ALT + L", "Switch keyboard layout (US / LATAM)", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-switch-layout"))

-- Voice Dictation (whisper.cpp EN/ES auto-detect with Dota 2 F9 passthrough)
helpers.bind("SUPER + CONTROL + X", "Toggle voice dictation (whisper.cpp)", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-dictate toggle"))
helpers.bind("F9", "Push-to-talk voice dictation (hold)", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-dictate start"))
helpers.bind("F9", "Stop push-to-talk dictation (release)", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-dictate stop"), { release = true })

-- Move all windows on active workspace to target workspace (SUPER + CTRL + [1-8])
for i = 1, 8 do
    helpers.bind("SUPER + CONTROL + " .. i, "Move all windows to workspace " .. i, hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-move-all-to-ws " .. i))
end
