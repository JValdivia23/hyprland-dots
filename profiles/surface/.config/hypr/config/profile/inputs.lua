-- Microsoft Surface Touchscreen, Stylus & Touchpad Configuration
hl.config({
    input = {
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            clickfinger_behavior = true,
        },
        touchdevice = {
            output = "eDP-1",
        },
        tablet = {
            output = "eDP-1",
        },
    },
})

-- Touchpad Gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "down",       action = "close" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
