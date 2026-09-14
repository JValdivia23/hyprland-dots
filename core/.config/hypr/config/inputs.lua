-- Input configuration (Universal Core)
-- Hardware-specific gestures and touchpad tuning are loaded via config.profile.inputs

hl.config({
    input = {
        accel_profile = "adaptive",
        kb_options = "",
        repeat_rate = 40,
        repeat_delay = 600,
    },
    cursor = {
        inactive_timeout = 3,
        hide_on_key_press = true,
    },
})
