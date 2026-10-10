-- Apple MacBook Pro 15,1 Hardware Video Acceleration & Graphics Compute
-- Dynamically adapts to active GPU: Intel UHD 630 (iHD) vs AMD Radeon Pro 560X (radeonsi)
local pciFile = io.popen("lspci -d ::0300 -nn 2>/dev/null")
local pciInfo = pciFile and pciFile:read("*a") or ""
if pciFile then pciFile:close() end

if string.find(pciInfo, "8086:") then
    -- Intel UHD Graphics 630 (Integrated GPU mode)
    hl.env("LIBVA_DRIVER_NAME", "iHD")
    hl.env("VDPAU_DRIVER", "va_gl")
else
    -- AMD Radeon Pro 560X (Discrete GPU mode)
    hl.env("LIBVA_DRIVER_NAME", "radeonsi")
    hl.env("VDPAU_DRIVER", "radeonsi")
    hl.env("RUSTICL_ENABLE", "radeonsi")
end
