-- Microsoft Surface Touchscreen, Stylus & Precision Touchpad Configuration
hl.config({
    input = {
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

-- Touchpad Gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "down",       action = "close" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

-- Virtual Keyboard (wvkbd-mobintl): render above ext-session-lock-v1 lock screen
-- and allow touch interaction (above_lock = 2) when base is detached
hl.layer_rule({
    name = "surface-wvkbd-above-lock",
    match = { namespace = "^(wvkbd)$" },
    above_lock = 2,
})

