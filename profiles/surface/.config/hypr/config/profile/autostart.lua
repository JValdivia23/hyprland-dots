-- Microsoft Surface Profile Autostart
-- Note: Touch gestures (hypr-lisgd) and interactive resizer (hypr-touch-resizer)
-- are supervised by systemd --user bound to graphical-session.target.

hl.on("hyprland.start", function ()
    hl.exec_cmd("systemctl --user start hypr-lisgd hypr-touch-resizer")
    hl.exec_cmd("easyeffects --service-mode")
end)
