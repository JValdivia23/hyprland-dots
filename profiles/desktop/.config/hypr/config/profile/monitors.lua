-- Desktop Dual-Monitor Workstation Configuration (cachyos-obsidian / MSI MS-7D75)
-- Primary 32" 4K Display (KTC A32Q8 on DP-1): 3840x2160@60Hz at 1.67 fractional scaling (~2304x1296 logical)
-- Secondary Left 24" 1440p Display (KTC Q24T09 on HDMI-A-1): 2560x1440@120Hz at 1.33333 fractional scaling (~1920x1080 logical)

MONITOR1 = "DP-1"
MONITOR2 = "HDMI-A-1"
PRIMARY_MONITOR = MONITOR1

-- Prevent GTK double-scaling under Wayland fractional scaling
hl.env("GDK_SCALE", "1")

-- Primary 32" 4K Monitor (KTC A32Q8)
hl.monitor({
    output   = "DP-1",
    mode     = "3840x2160@60",
    position = "0x0",
    scale    = 1.67,
})

-- Secondary 24" 1440p Monitor positioned to the left of DP-1 (KTC Q24T09)
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "2560x1440@120",
    position = "auto-left",
    scale    = 1.33333,
})

-- Global fallback for any additional newly connected monitors
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1,
})

-- Workspace assignments across monitors (Workspace 8 bound to secondary HDMI-A-1 for Dota 2 / gaming)
hl.workspace_rule({ workspace = "1", monitor = "DP-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "8", monitor = "HDMI-A-1", persistent = true })
