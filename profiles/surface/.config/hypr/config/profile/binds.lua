local helpers = require("helpers")
local homeDir = os.getenv("HOME")

-- Microsoft Surface Hardware & Tablet Keybindings
-- Detach Surface Book clipboard / tablet base
helpers.bind("SUPER + ALT + D", "Detach Surface Book base", "sh -c 'surface dtx request 2>/dev/null && notify-send \"Surface Detach\" \"Latch opening — pull the tablet.\" || notify-send -u critical \"Surface Detach\" \"Hold hardware detach key or verify dGPU is unmounted.\"'")

-- Toggle On-Screen Virtual Keyboard (wvkbd)
helpers.bind("SUPER + ALT + V", "Toggle on-screen virtual keyboard", hl.dsp.exec_cmd(homeDir .. "/.local/bin/hypr-virtual-keyboard"))
