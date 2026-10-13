-- Microsoft Surface Profile Autostart
local homeDir = os.getenv("HOME") or "/home/user"

-- Start lisgd touchscreen gesture daemon & touch resizer daemon
hl.on("hyprland.start", function ()
    hl.exec_cmd(homeDir .. "/.local/bin/hypr-lisgd")
    hl.exec_cmd(homeDir .. "/.local/bin/hypr-touch-resizer")
    hl.exec_cmd("easyeffects --service-mode")
end)
