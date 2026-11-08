-- Desktop Workstation Profile Autostart
local homeDir = os.getenv("HOME") or "/home/user"

hl.on("hyprland.start", function ()
    -- Load XWayland HiDPI DPI resources (144 DPI for 1.67x fractional scaling)
    hl.exec_cmd("sh -c '[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources || true'")

    -- Start EasyEffects background service (Realtek ALC4080/4082 USB audio mic boost & RNNoise)
    hl.exec_cmd("easyeffects --gapplication-service")

    -- Route Dota 2 / gamescope windows automatically to secondary monitor (Workspace 8 on HDMI-A-1)
    hl.exec_cmd(homeDir .. "/.local/bin/dota2-workspace")
end)
