import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

// Keyboard layout indicator + toggle (es <-> us). Shows ES/EN; a click
// flips input:kb_layout through a runtime hl.config eval - the option
// carries the REFRESH_INPUT_DEVICES bit, so the keyboards reconfigure
// live (verified in the 0.56.2 source). The activelayout event keeps
// the state synced after flips from the SUPER+K bind or an external
// hyprctl; the getoption probe covers the shell's own startup.
Item {
    id: root

    property string layout: "es"

    width: label.implicitWidth
    height: Theme.barHeight

    Text {
        id: label

        anchors.verticalCenter: parent.verticalCenter
        text: root.layout === "us" ? "EN" : "ES"
        color: Theme.fgDim
        font.family: Theme.sans
        font.pointSize: 9
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.layout = root.layout === "es" ? "us" : "es";
            Quickshell.execDetached([
                "hyprctl",
                "eval",
                'hl.config({ input = { kb_layout = "' + root.layout + '" } })'
            ]);
            // The external keyboard has a layout of its own, so it
            // follows the toggle: the two layouts swap places.
            Quickshell.execDetached([
                "hyprctl",
                "eval",
                'hl.device({ name = "DaKai-Keyboard", kb_layout = "' + (root.layout === "us" ? "es" : "us") + '" })'
            ]);
        }
    }

    // setKeyboardLayout posts activelayout as "<keyboard>,<layout
    // display name>" on every reconfigure. Matched loosely so layout
    // variants ("Spanish (...)") still map.
    //
    // The event carries the keyboard it belongs to. The label follows
    // the internal keyboard (the keyd virtual keyboard, or the
    // internal device itself when keyd is not running); the external
    // keyboard has a layout of its own.
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "activelayout")
                return;
            const data = String(event.data);
            const keyboard = data.split(",")[0];
            if (keyboard !== "keyd-virtual-keyboard" && keyboard !== "at-translated-set-2-keyboard")
                return;
            const layout = data;
            if (layout.indexOf("Spanish") !== -1)
                root.layout = "es";
            else if (layout.indexOf("English") !== -1)
                root.layout = "us";
        }
    }

    // Startup probe: the compositor may already carry a runtime flip
    // from before the shell restarted. Fails harmlessly without a
    // compositor (GNOME sessions, the load-test rig).
    Process {
        id: probeProc

        command: ["hyprctl", "getoption", "-j", "input:kb_layout"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(this.text);
                    if (parsed && typeof parsed.str === "string" && parsed.str.length > 0)
                        root.layout = parsed.str;
                } catch (e) {
                    // No compositor or unexpected shape: keep the default.
                }
            }
        }
    }

    Component.onCompleted: probeProc.running = true
}
