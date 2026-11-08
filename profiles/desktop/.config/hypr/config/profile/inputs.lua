-- Desktop Mouse & Keyboard Input Configuration
-- Peripherals: Attack Shark X85 (SONiX USB mechanical keyboard) + Logitech G903 LIGHTSPEED wireless mouse

hl.config({
    input = {
        -- Bilingual US + Latin American Spanish layouts
        kb_layout = "us,latam",
        -- Attack Shark X85 runs in Windows hardware mode; toggleable to Mac alt/win swap via Super+Shift+K
        kb_options = "",
        repeat_rate = 40,
        repeat_delay = 600,
        follow_mouse = 1,
        -- Flat profile for precision desktop mouse tracking
        accel_profile = "flat",
        sensitivity = 0.0,
        -- Force discrete scroll wheel click emulation globally for XWayland games (fixes G903 hi-res scroll in Dota 2)
        emulate_discrete_scroll = 2,
    },
    general = {
        -- Allow screen tearing for low-latency competitive gaming
        allow_tearing = true,
    },
    misc = {
        -- Focus window behind fullscreen apps on Alt+Tab without collapsing fullscreen games into dwindle tiles
        on_focus_under_fullscreen = 1,
    },
    cursor = {
        no_warps = false,
        inactive_timeout = 5,
    },
})

-- Logitech G903 LIGHTSPEED per-device rule
hl.device({
    name = "logitech-g903-ls-1",
    scroll_factor = 1.0,
    natural_scroll = false,
})
