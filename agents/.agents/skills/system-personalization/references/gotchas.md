# Known Gotchas & Troubleshooting Index

A curated index of modular troubleshooting topics, pitfalls, and verified fixes for `cachyos-cu` (Apple MacBook Pro 15,1).

---

## Modular Topics

| Topic | File | Scope |
| :--- | :--- | :--- |
| **Hyprland & Lua Configs** | [`gotchas/hyprland.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/hyprland.md) | `hyprctl configerrors`, `send_shortcut` syntax, `window = "activewindow"`, `repeating = true`, `CTRL+SHIFT+C` terminal copy, Alt/Super layout toggle, absolute PATHs. |
| **Wayland & Noctalia** | [`gotchas/wayland-noctalia.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/wayland-noctalia.md) | `noctalia msg reload` vs `restart`, Satty piped screenshot integration, Quick Look overlay. |
| **Apple T2 Hardware** | [`gotchas/apple-t2.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/apple-t2.md) | Touch Bar `tiny-dfr` daemon, `suspend-fix-t2.service`, `aaudio` PipeWire routing, Broadcom Wi-Fi. |
| **Networking & Firewall** | [`gotchas/networking.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/networking.md) | LocalSend discovery on port 53317 (TCP/UDP) through UFW firewall. |
| **Terminal & SSH** | [`gotchas/terminal-ssh.md`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/terminal-ssh.md) | Remote host `xterm-kitty` terminfo fixes, interactive `kitty -e` sudo prompts for background tasks. |

---

> [!TIP]
> When adding new gotchas, create or append to the appropriate modular file in [`references/gotchas/`](file:///home/java1127/dotfiles/agents/.agents/skills/system-personalization/references/gotchas/).
