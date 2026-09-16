-- Microsoft Surface High-DPI 3:2 Display Configuration
-- Primary internal screen: 3000x2000@60Hz with 2.0 integer scaling (Omarchy-style 2x retina default)
-- External displays: fallback to preferred mode and auto scale

hl.env("GDK_SCALE", "2")
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 2 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Omarchy-style alternatives (uncomment to switch, then `hyprctl reload`):
-- Good compromise for 27" or 32" 4K externals (fractional): monitor 1.6, GDK 1.75.
-- hl.env("GDK_SCALE", "1.75")
-- hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", scale = 1.6 })
-- Straight 1x setup for low-resolution displays like 1080p, 1440p, or ultrawides: both 1.
-- hl.env("GDK_SCALE", "1")
-- hl.monitor({ output = "DP-1", mode = "preferred", position = "auto", scale = 1 })
