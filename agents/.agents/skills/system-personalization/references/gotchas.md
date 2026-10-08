# Known Gotchas & Troubleshooting Index

A curated index of modular troubleshooting topics, pitfalls, and verified fixes for `surface` (Surface Book 3).

---

## Universal Gotchas (`core`)

| Topic | File | Scope |
| :--- | :--- | :--- |
| **Hyprland & Lua Configs** | [`gotchas/hyprland.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/hyprland.md) | `hyprctl configerrors`, `send_shortcut` syntax, `window = "activewindow"`, `repeating = true`, `CTRL+SHIFT+C` terminal copy, Alt/Super layout toggle, clamshell lid handling. |
| **Wayland & Noctalia** | [`gotchas/wayland-noctalia.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/wayland-noctalia.md) | `noctalia msg reload` vs `restart`, Satty piped screenshot integration, Quick Look overlay, Waypaper progressive caching, WebApp icon formats. |
| **Networking & Firewall** | [`gotchas/networking.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/networking.md) | LocalSend discovery on port 53317 (TCP/UDP) through UFW firewall. |
| **Terminal & SSH** | [`gotchas/terminal-ssh.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/terminal-ssh.md) | Remote host `xterm-kitty` terminfo fixes, interactive `kitty -e` sudo prompts for background tasks. |
| **Zen Browser** | [`gotchas/zen-browser.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/zen-browser.md) | Zen Browser keybindings, Linux modifier mappings & in-memory overwrite gotchas. |
| **OpenCode CLI** | [`gotchas/opencode.md`](file:///home/jmvp/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/opencode.md) | TUI line navigation (`Home`/`End`), TLS certificate clock-drift gotcha, `packages.txt` keep-out. |

---

## Hardware Profile Gotchas: Surface Book 3 (`profiles/surface/gotchas/`)

Per Rule 9, hardware-specific pitfalls and troubleshooting procedures are kept out of `core/` and maintained under `profiles/surface/gotchas/` (symlinked into `references/gotchas/` on this machine):

| Topic | File | Scope |
| :--- | :--- | :--- |
| **Surface Dual-Battery** | [`gotchas/battery-upower.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/battery-upower.md) | Surface Book dual-battery calculation desync (~200%), UPower bug #336, and automated watchdog timer. |
| **Surface Sleep & Hibernate** | [`gotchas/sleep-hibernate.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/sleep-hibernate.md) | Surface Modern Standby hibernation failure, ACPI S4 rejection, `HibernateMode=shutdown`, `button.lid_init_state=open`, AC disconnect clamshell handler. |
| **Surface Touchscreen & Stylus** | [`gotchas/touchscreen-iptsd.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/touchscreen-iptsd.md) | Surface Book touchscreen & stylus wake race condition (`iptsd` EAGAIN -11), udev re-trigger recovery. |
| **Surface On-Screen Keyboard** | [`gotchas/virtual-keyboard.md`](file:///home/jmvp/dotfiles/profiles/surface/gotchas/virtual-keyboard.md) | On-screen touch keyboard (`wvkbd-mobintl`) vs desktop IME (`fcitx5`), compositor execution path. |

---

> [!TIP]
> When adding new gotchas, identify whether the issue is universal or hardware-specific per Rule 9. Universal gotchas go into `agents/.agents/skills/system-personalization/references/gotchas/`, while profile gotchas belong in `profiles/<profile>/gotchas/`.

