-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

local homeDir = os.getenv("HOME") or "/home/user"

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("noctalia -d")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("xhost +SI:localuser:root")
    hl.exec_cmd(homeDir .. "/.local/bin/kitty-focus-opacity")
end)

