-- Hyprland default apps & shell backend (Universal Core Defaults)
-- Profile variables (config.profile.variables) override these.

SHELL_BACKEND = SHELL_BACKEND or "noctalia"

TERMINAL     = TERMINAL or "alacritty"
FILE_MANAGER = FILE_MANAGER or "nautilus"
BROWSER      = BROWSER or "zen-browser"
EDITOR       = EDITOR or "nvim"
CALCULATOR   = CALCULATOR or "gnome-calculator"

-- Monitors
MONITOR1 = MONITOR1 or "eDP-1"
MONITOR2 = MONITOR2 or ""
MONITOR3 = MONITOR3 or ""
PRIMARY_MONITOR = PRIMARY_MONITOR or MONITOR1

-- Workspaces
NUM_WPM = NUM_WPM or 3 -- Number of workspaces per monitor (Max 10)
