import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Row {
    id: root

    spacing: 6

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem

            required property var modelData

            width: 20
            height: 20

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
