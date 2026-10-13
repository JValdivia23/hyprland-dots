-- Microsoft Surface Profile Autostart
local homeDir = os.getenv("HOME") or "/home/user"

-- Start lisgd touchscreen gesture daemon
hl.on("hyprland.start", function ()
    hl.exec_cmd(homeDir .. "/.local/bin/hypr-lisgd")
end)
