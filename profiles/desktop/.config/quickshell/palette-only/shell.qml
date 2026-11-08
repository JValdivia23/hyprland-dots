import QtQuick
import Quickshell

// Palette-only entry point: hosts the OmniMenu command palette without
// a visible bar. Waybar handles the top bar + tray; this process only
// serves the palette and quick-tiles.
//
// Launch with:
//   qs -n -d -c palette-only
//
// Toggle from Hyprland keybinds (same as before):
//   bind = SUPER, SPACE, global, quickshell:palette-toggle
//   bind = SUPER SHIFT, SPACE, global, quickshell:palette-quick
ShellRoot {
    id: root

    Theme { id: theme }

    Navbar {
        id: nav
        theme: theme
        showBar: false
        onPaletteToggleRequested: omni.toggle()
    }

    OmniMenu {
        id: omni
        theme: theme
        navbar: nav
    }
}
