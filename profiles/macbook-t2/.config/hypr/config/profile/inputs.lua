-- Apple MacBook Pro Trackpad & Touchpad Gestures
hl.config({
    input = {
        accel_profile = "adaptive",
        kb_options = "",
        repeat_rate = 40,
        repeat_delay = 600,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            clickfinger_behavior = true,
            middle_button_emulation = true,
        },
    },
})

-- macOS-inspired Touchpad Gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "up",         action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "down",       action = "close" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
