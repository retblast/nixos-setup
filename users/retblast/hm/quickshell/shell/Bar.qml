import QtQuick
import Quickshell
import "widgets" as Widgets

// Layout contract: the title is anchored BETWEEN the workspace row and the
// clock, so a long title can never overlap either (the old fixed 180/380px
// margins let it run into the clock).
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

    // Left: workspaces
    Widgets.Workspaces {
        id: wsRow
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
    }

    // Title fills the space between the workspaces and the clock
    Widgets.ActiveWindow {
        id: titleItem
        anchors.left: wsRow.right
        anchors.leftMargin: 12
        anchors.right: clockItem.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
    }

    // Center: clock
    Widgets.Clock {
        id: clockItem
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }

        // Right: weather, volume, battery, network, caffeine, bluetooth, tray
        Row {
        id: rightSide
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Widgets.Weather {
        }

        Widgets.Volume {
        }

        Widgets.Battery {
        }

        Widgets.Network {
        }

        Widgets.Caffeine {
        }

        Widgets.Bluetooth {
        }

        Widgets.Tray {
        }
    }
}
