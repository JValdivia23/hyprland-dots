import QtQuick
import Quickshell
import Quickshell.Io
import "Data.js" as Data

// Waybar Theme switcher. Probes ~/.local/share/omarchy/waybar-themes/config
// for theme directories, parses each theme's available screenshot (PNG/JPG),
// and marks the one whose name matches ~/.config/waybar/.active_theme as active.
//
// Selection drives the screenshot preview in the preview pane;
// Enter triggers omarchy-waybar-theme-set via the parent's activate().
Item {
    id: waybarThemes

    required property bool active

    property var items: []
    property bool loaded: false
    readonly property bool running: probeProc.running

    function clear() {
        waybarThemes.items = [];
        waybarThemes.loaded = false;
    }

    function refresh() {
        probeProc.command = ["sh", "-c",
              "cur=$(cat \"$HOME/.config/waybar/.active_theme\" 2>/dev/null); "
            + "for d in \"$HOME/.local/share/omarchy/waybar-themes/config\"/*; do "
            + "  [ -d \"$d\" ] || continue; "
            + "  name=$(basename \"$d\"); "
            + "  marker=' '; [ -n \"$name\" ] && [ \"$name\" = \"$cur\" ] && marker='*'; "
            + "  prev=''; "
            + "  prev=$(find \"$d\" -maxdepth 1 -type f -size +0c \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) 2>/dev/null | sort | head -n1); "
            + "  printf '===%s\\t%s\\t%s\\n' \"$name\" \"$marker\" \"$prev\"; "
            + "done"];
        probeProc.running = false;
        probeProc.running = true;
    }

    function ingest(text) {
        const chunks = (text || "").split("===");
        const out = [];
        for (let i = 0; i < chunks.length; i++) {
            const chunk = chunks[i];
            if (!chunk) continue;
            const parts = chunk.trim().split("\t");
            if (parts.length < 2) continue;
            const name = parts[0] || "";
            const marker = parts[1] || " ";
            const previewImage = parts[2] || "";
            if (!name) continue;

            const active = marker === "*";
            const title = "Waybar " + name;

            const kw = title + " waybar theme layout bar hancore status panel switcher css config " + (active ? " active current" : "");
            const entry = {
                title: title,
                category: active ? "ACTIVE_WAYBAR_THEME" : "WAYBAR_THEME",
                keywords: kw,
                icon: active ? "󰸌" : "󰍜",
                exec: "",
                waybarThemeName: name,
                isWaybarTheme: true,
                isActive: active,
                previewImage: previewImage,
                rawCategory: false,
                _t: title.toLowerCase(),
                _k: kw.toLowerCase(),
                _c: "waybar theme"
            };
            out.push(entry);
        }
        // Active theme floats to the top, otherwise sorted version-logically.
        out.sort((a, b) => {
            if (a.isActive !== b.isActive) return a.isActive ? -1 : 1;
            return a.title.localeCompare(b.title, undefined, { numeric: true, sensitivity: 'base' });
        });
        waybarThemes.items = out;
        waybarThemes.loaded = true;
    }

    onActiveChanged: { if (waybarThemes.active) waybarThemes.refresh(); }

    Component.onCompleted: waybarThemes.refresh()

    Process {
        id: probeProc
        running: false
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: { waybarThemes.ingest(this.text || ""); }
        }
    }
}
