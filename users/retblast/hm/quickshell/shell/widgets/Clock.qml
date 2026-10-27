import QtQuick
import Quickshell
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

// Clock; click opens the notification center. The dot marks unread
// notifications (hidden while the center itself is open).
Item {
    id: root

    property date now: new Date()

    width: timeText.width + (unreadDot.visible ? unreadDot.width + 6 : 0)
    height: Theme.barHeight

    Text {
        id: timeText

        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.now, "ddd d MMM  HH:mm")
        color: Theme.fg
        font.family: Theme.sans
        font.pointSize: 10
    }

    Rectangle {
        id: unreadDot

        anchors.left: timeText.right
        anchors.leftMargin: 6
        anchors.verticalCenter: timeText.verticalCenter
        width: 7
        height: 7
        radius: width / 2
        color: Theme.accent
        visible: NotifStore.unread > 0 && NotifStore.openPanel !== "notifcenter"
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // Same-process IPC roundtrip (the clock cannot reach the
        // panel's window by id; the handler lives on the panel root).
        onClicked: Quickshell.execDetached([
            "quickshell",
            "-c",
            "shell",
            "ipc",
            "call",
            "notifcenter",
            "toggle"
        ])
    }

    Timer {
        interval: 30 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
}
