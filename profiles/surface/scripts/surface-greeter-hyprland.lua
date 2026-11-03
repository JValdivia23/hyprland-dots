-- Microsoft Surface Pre-Login Greeter Hyprland Configuration
-- Minimal compositor config for noctalia-greeter + wvkbd-mobintl + lisgd touch gestures

hl.env("GDK_SCALE", "2")
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 2 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 0,
        layout = "dwindle",
    },
    decoration = {
        rounding = 0,
        shadow = { enabled = false },
        blur = { enabled = false },
    },
    animations = {
        enabled = false,
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true,
    },
    input = {
        kb_layout = "us",
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            clickfinger_behavior = true,
            scroll_factor = 0.4,
            disable_while_typing = false,
        },
        touchdevice = {
            output = "eDP-1",
        },
        tablet = {
            output = "eDP-1",
        },
    },
})

-- Ensure Noctalia Greeter spans the full output without borders or resizing
hl.window_rule({
    name = "surface-greeter-fullscreen",
    match = { class = "^(dev\\.noctalia\\.Greeter)$" },
    fullscreen = true,
})

-- Ensure wvkbd-mobintl renders on overlay layer and accepts touch input
hl.layer_rule({
    name = "surface-greeter-wvkbd",
    match = { namespace = "^(wvkbd)$" },
    above_lock = 2,
})

hl.on("hyprland.start", function ()
    hl.exec_cmd("/usr/local/bin/surface-greeter-client")
end)
