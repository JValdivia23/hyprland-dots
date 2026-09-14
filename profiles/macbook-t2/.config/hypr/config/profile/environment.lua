-- AMD Radeon Pro 560X (Baffin / Polaris 11) Hardware Acceleration & Compute
hl.env("LIBVA_DRIVER_NAME", "radeonsi")
hl.env("VDPAU_DRIVER", "radeonsi")
hl.env("RUSTICL_ENABLE", "radeonsi")
