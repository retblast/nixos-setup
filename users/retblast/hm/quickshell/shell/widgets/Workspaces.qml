import QtQuick
import Quickshell
import Quickshell.Hyprland
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

Row {
    id: root

    spacing: 4

    Repeater {
        model: 10

        delegate: Rectangle {
            id: wsItem

            required property int index
            readonly property int wsId: index + 1
            // Show all 10 slots (GNOME-like); a slot is filled once the
            // workspace exists in the compositor.
            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null

            width: 20
            height: 20
            radius: 5
            color: ws && ws.focused ? Theme.accent : (ws ? Theme.bgAlt : "transparent")

            Text {
                anchors.centerIn: parent
                text: wsItem.wsId
                color: wsItem.ws && wsItem.ws.focused ? "#ffffff" : Theme.fgDim
                font.family: Theme.sans
                font.pointSize: 8
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + wsItem.wsId)
            }
        }
    }
}
