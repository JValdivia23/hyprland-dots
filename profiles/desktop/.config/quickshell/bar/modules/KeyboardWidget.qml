import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: rootMod
    required property var root

    property string activeLayout: "US"

    readonly property string tooltipText: "Keyboard Layout · " + (activeLayout === "US" ? "English (US)" : (activeLayout === "LA" ? "Spanish (Latin American)" : "Spanish"))

    readonly property bool shown: true
    visible: implicitWidth > 0.5
    implicitWidth: shown ? row.implicitWidth + 18 : 0
    implicitHeight: 28

    Rectangle {
        x: 0; anchors.verticalCenter: parent.verticalCenter
        width: Math.round(row.width) + 18
        height: root.pillH
        radius: root.pillRadius
        color: root.pill
        border.color: root.pillBorder
        border.width: root.pillBorderW
        PillShadow { theme: root }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰌌"
            color: Qt.rgba(root.ink.r, root.ink.g, root.ink.b, 0.6)
            font.family: root.mono
            font.pixelSize: 14
        }

        UiText {
            anchors.verticalCenter: parent.verticalCenter
            text: rootMod.activeLayout
            color: root.seal
            font.family: root.mono
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    Process {
        id: layoutProc
        command: ["hyprctl", "devices", "-j"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const obj = JSON.parse(this.text);
                    const mainKbd = obj.keyboards.find(k => k.main === true) || obj.keyboards.find(k => k.name.indexOf("sonix-x85") !== -1) || obj.keyboards[0];
                    if (mainKbd) {
                        if (mainKbd.active_keymap.indexOf("Latin American") !== -1) {
                            rootMod.activeLayout = "LA";
                        } else if (mainKbd.active_keymap.indexOf("Spanish") !== -1) {
                            rootMod.activeLayout = "ES";
                        } else {
                            rootMod.activeLayout = "US";
                        }
                    }
                } catch (e) {
                }
            }
        }
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { layoutProc.running = false; layoutProc.running = true }
    }

    TooltipMixin { id: tip; root: rootMod.root; owner: rootMod; text: rootMod.tooltipText }

    Process {
        id: clickProc
        command: ["hyprctl", "switchxkblayout", "sonix-x85", "next"]
        running: false
        onExited: {
            layoutProc.running = false;
            layoutProc.running = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        onEntered: tip.show()
        onExited: { tip.hide() }
        onClicked: {
            tip.hide()
            clickProc.running = false
            clickProc.running = true
        }
    }
}
