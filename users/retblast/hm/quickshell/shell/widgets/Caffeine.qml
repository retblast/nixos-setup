import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

// Caffeine toggle: keeps the screen on by stopping hypridle, which also
// disables its lock and dpms listeners. Sun = idle blocked, moon = normal.
Item {
    id: root

    // true while hypridle is stopped (screen stays on).
    property bool active: false

    readonly property string unit: "hypridle.service"

    width: 20
    height: Theme.barHeight

    IconImage {
        id: icon
        anchors.centerIn: parent
        source: Theme.adwaitaIcon(root.active
            ? "weather-clear-symbolic"
            : "weather-clear-night-symbolic")
        implicitWidth: 16
        implicitHeight: 16
        opacity: root.active ? 1.0 : 0.8
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.active = !root.active;
            if (root.active)
                stopProc.running = true;
            else
                startProc.running = true;
        }
    }

    Process {
        id: stopProc
        command: ["systemctl", "--user", "stop", "hypridle.service"]
    }

    Process {
        id: startProc
        command: ["systemctl", "--user", "start", "hypridle.service"]
    }

    // Sync the icon with the real unit state at startup (and after any
    // external restart of the service), instead of trusting local state.
    Process {
        id: stateProc
        command: ["systemctl", "--user", "is-active", root.unit]
        stdout: StdioCollector {
            onStreamFinished: root.active = this.text.trim() !== "active"
        }
    }

    Process {
        id: reProbeProc
        command: ["systemctl", "--user", "is-active", root.unit]
        stdout: StdioCollector {
            onStreamFinished: root.active = this.text.trim() !== "active"
        }
    }

    Component.onCompleted: stateProc.running = true

    // Re-probe once a minute; a rebuild restarts quickshell anyway, but a
    // manual systemctl outside the shell would otherwise stale the icon.
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: reProbeProc.running = true
    }
}
