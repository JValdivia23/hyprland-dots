-- Apple MacBook Pro 15,1 Retina Display Configuration
-- Primary internal screen: 2880x1800@60Hz with 1.6 fractional scaling
-- eDP-1 is used on AMD discrete GPU; eDP-2 is used on Intel integrated GPU.
-- External displays: fallback to preferred mode and auto position

hl.monitor({
    output    = "eDP-1",
    mode      = "preferred",
    position  = "auto",
    scale     = 1.6,
})

hl.monitor({
    output    = "eDP-2",
    mode      = "preferred",
    position  = "auto",
    scale     = 1.6,
})

hl.monitor({
    output    = "",
    mode      = "preferred",
    position  = "auto",
    scale     = 1,
})
