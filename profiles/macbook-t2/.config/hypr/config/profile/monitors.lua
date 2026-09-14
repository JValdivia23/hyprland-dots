-- Apple MacBook Pro 15,1 Retina Display Configuration
-- Primary internal screen: 2880x1800@60Hz with 1.33 fractional scaling
-- External displays: fallback to preferred mode and auto position

hl.monitor({
    output    = "eDP-1",
    mode      = "preferred",
    position  = "auto",
    scale     = 1.33,
})

hl.monitor({
    output    = "",
    mode      = "preferred",
    position  = "auto",
    scale     = 1,
})
