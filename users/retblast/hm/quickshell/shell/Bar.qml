import QtQuick
import Quickshell
import "widgets" as Widgets

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        opacity: 0.92
    }

    // Left: workspaces + focused window
    Widgets.Workspaces {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
    }

    Widgets.ActiveWindow {
        anchors.left: parent.left
        anchors.leftMargin: 180
        anchors.right: parent.right
        anchors.rightMargin: 380
        anchors.verticalCenter: parent.verticalCenter
    }

    // Center: clock
    Widgets.Clock {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }

    // Right: volume, battery, tray
    Row {
        id: rightSide
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Widgets.Volume {
        }

        Widgets.Battery {
        }

        Widgets.Tray {
        }
    }
}
