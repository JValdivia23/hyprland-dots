-- Desktop Workstation Hardware Acceleration & Gaming Environment
-- Hardware: AMD Ryzen 5 7600X + AMD Radeon RX 7700 XT (Navi 32 / RDNA 3)

-- Wayland & Toolkit Backends
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")

-- AT-SPI2 Accessibility for Computer Use
hl.env("QT_ACCESSIBILITY", "1")

-- AMD RDNA 3 (RX 7000 / Navi 32) Hardware Video & Vulkan Optimizations
-- nggc = NGG culling (GFX11+), sam = Smart Access Memory VRAM optimizations, nircache = pipeline shader cache
hl.env("LIBVA_DRIVER_NAME", "radeonsi")
hl.env("VDPAU_DRIVER", "radeonsi")
hl.env("AMD_VULKAN_ICD", "RADV")
hl.env("RADV_PERFTEST", "nggc,sam,nircache")
hl.env("mesa_glthread", "true")

-- High-FPS Vulkan Presentation Workarounds (prevents 30 FPS lock in Dota 2 / Source 2)
hl.env("RADV_PRESENT_MODE", "mailbox")
hl.env("vblank_mode", "0")

-- ydotool socket location
hl.env("YDOTOOL_SOCKET", "/run/user/1000/.ydotool_socket")
