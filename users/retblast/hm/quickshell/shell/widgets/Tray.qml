import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

Row {
    id: root

    spacing: 6

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem

            required property var modelData

            // Full bar height: the Row positioner top-aligns children, so a
            // 20px delegate sat 8px above the centered widgets next to it.
            width: 20
            height: Theme.barHeight

            IconImage {
                anchors.centerIn: parent
                source: trayItem.modelData.icon
                implicitWidth: 18
                implicitHeight: 18
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        trayItem.modelData.activate();
                    else
                        trayItem.modelData.secondaryActivate();
                }
            }
        }
    }
}
