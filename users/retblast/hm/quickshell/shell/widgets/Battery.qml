import QtQuick
import Quickshell
import Quickshell.Services.UPower

Item {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev ? (dev.isPresent ?? false) : false

    width: present ? label.implicitWidth : 0
    height: Theme.barHeight

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        visible: root.present
        text: root.dev
            ? Math.round(root.dev.percentage * 100) + "%" + (UPower.onBattery ? "" : " charging")
            : ""
        color: root.dev && root.dev.percentage < 0.15 && UPower.onBattery
            ? Theme.urgent
            : Theme.fg
        font.family: Theme.sans
        font.pointSize: 9
    }
}
