import QtQuick
import Quickshell
import Quickshell.Io
import "Data.js" as Data

// Background switcher. Probes ~/.config/omarchy/current/theme/backgrounds
// for wallpaper files, and marks the one currently pointed to by
// ~/.config/omarchy/current/background (resolved via readlink) as active.
//
// Selection drives the wallpaper preview in the preview pane;
// Enter updates the symlink and relaunches swaybg.
Item {
    id: backgrounds

    required property bool active

    property var items: []
    property bool loaded: false
    readonly property bool running: probeProc.running

    function clear() {
        backgrounds.items = [];
        backgrounds.loaded = false;
    }

    function refresh() {
        probeProc.command = ["sh", "-c",
              "cur=$(readlink -f \"$HOME/.config/omarchy/current/background\" 2>/dev/null); "
            + "for f in \"$HOME/.config/omarchy/current/theme/backgrounds\"/*; do "
            + "  [ -f \"$f\" ] || continue; "
            + "  name=$(basename \"$f\"); "
            + "  real_f=$(readlink -f \"$f\"); "
            + "  marker=' '; [ \"$real_f\" = \"$cur\" ] && marker='*'; "
            + "  printf '===%s\\t%s\\t%s\\n' \"$name\" \"$marker\" \"$f\"; "
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
            if (parts.length < 3) continue;
            const name = parts[0] || "";
            const marker = parts[1] || " ";
            const path = parts[2] || "";
            if (!name || !path) continue;

            const active = marker === "*";
            // Clean up name for display title: strip extension and replace underscores/hyphens with spaces
            let title = name.replace(/\.[^/.]+$/, "");
            title = title.replace(/[_-]/g, " ");

            const kw = title + " background wallpaper image desktop backdrop bg" + (active ? " active current" : "");
            const entry = {
                title: title,
                category: active ? "ACTIVE_BG" : "BACKGROUND",
                keywords: kw,
                icon: "󰸉",
                exec: "",
                backgroundPath: path,
                isBackground: true,
                isActive: active,
                previewImage: path,
                rawCategory: false,
                _t: title.toLowerCase(),
                _k: kw.toLowerCase(),
                _c: "background"
            };
            out.push(entry);
        }
        // Active background floats to the top, otherwise alphabetical.
        out.sort((a, b) => {
            if (a.isActive !== b.isActive) return a.isActive ? -1 : 1;
            return a.title.localeCompare(b.title);
        });
        backgrounds.items = out;
        backgrounds.loaded = true;
    }

    // Refresh on entering the mode so the active marker stays honest.
    onActiveChanged: { if (backgrounds.active) backgrounds.refresh(); }

    // Preload once at startup so background rows are present in root search.
    Component.onCompleted: backgrounds.refresh()

    Process {
        id: probeProc
        running: false
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: { backgrounds.ingest(this.text || ""); }
        }
    }
}
