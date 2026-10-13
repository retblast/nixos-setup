import QtQuick
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

Text {
    id: root

    property date now: new Date()

    text: Qt.formatDateTime(root.now, "ddd d MMM  HH:mm")
    color: Theme.fg
    font.family: Theme.sans
    font.pointSize: 10

    Timer {
        interval: 30 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
}
