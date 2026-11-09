-- Desktop Workstation Profile Autostart (Personalized Quickshell Bar + Omarchy + Gaming)
local homeDir = os.getenv("HOME") or "/home/user"

hl.on("hyprland.start", function ()
    -- Quickshell suite (only if active shell backend is quickshell)
    if SHELL_BACKEND == "quickshell" then
        hl.exec_cmd("qs -n -d -c desktop")
        hl.exec_cmd("mako")
        hl.exec_cmd("swayosd-server")
        hl.exec_cmd("swaybg -i " .. homeDir .. "/.config/omarchy/current/background -m fill")
        hl.exec_cmd(homeDir .. "/.local/bin/omarchy-gsettings-bg-sync")
        hl.exec_cmd(homeDir .. "/.local/bin/omarchy-portal-backend")
    end

    -- Polkit authentication, clipboard persistence & session restore
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("wl-clip-persist --clipboard regular --all-mime-type-regex '^(?!x-kde-passwordManagerHint).+'")
    hl.exec_cmd(homeDir .. "/.local/bin/hyprresume")
    hl.exec_cmd("ydotoold")

    -- Load XWayland HiDPI DPI resources (144 DPI for 1.67x fractional scaling)
    hl.exec_cmd("sh -c '[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources || true'")

    -- Start EasyEffects background service (Realtek ALC4080/4082 USB audio mic boost & RNNoise)
    hl.exec_cmd("easyeffects --gapplication-service")

    -- Route Dota 2 / gamescope windows automatically to secondary monitor (Workspace 8 on HDMI-A-1)
    hl.exec_cmd(homeDir .. "/.local/bin/dota2-workspace")
end)
