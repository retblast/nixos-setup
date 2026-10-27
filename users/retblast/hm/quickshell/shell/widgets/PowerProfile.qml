import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

// Power profile: shows the active power-profiles-daemon profile; click
// cycles balanced -> performance -> power-saver -> balanced. State is
// probed at startup, set optimistically on click and re-verified once
// a minute (powerprofilesctl can also be changed from the CLI).
Item {
    id: root

    property string profile: "balanced"

    readonly property var order: ["balanced", "performance", "power-saver"]

    readonly property var icons: ({
        "balanced": "power-profile-balanced-symbolic",
        "performance": "power-profile-performance-symbolic",
        "power-saver": "power-profile-power-saver-symbolic"
    })

    width: 20
    height: Theme.barHeight

    IconImage {
        anchors.centerIn: parent
        source: Theme.adwaitaIcon(root.icons[root.profile]
            || root.icons["balanced"])
        implicitWidth: 16
        implicitHeight: 16
        opacity: 0.85
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const idx = root.order.indexOf(root.profile);
            // Unknown probe results sit at "balanced" (index 0).
            root.profile = root.order[(idx + 1) % root.order.length];
            Quickshell.execDetached(["powerprofilesctl", "set", root.profile]);
        }
    }

    Process {
        id: probeProc

        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim();
                if (t.length > 0)
                    root.profile = t;
            }
        }
    }

    Process {
        id: reProbeProc

        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim();
                if (t.length > 0)
                    root.profile = t;
            }
        }
    }

    Component.onCompleted: probeProc.running = true

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: reProbeProc.running = true
    }
}
