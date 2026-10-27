import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

// Media control: title of the current MPRIS player - the first playing
// one wins, else the first registered player. Click toggles play/pause.
// Hidden when no player exists. The players model is an
// UntypedObjectModel: .values gives the object list (0.3.2 qmltypes).
Item {
    id: root

    readonly property var players: Mpris.players.values

    readonly property var player: {
        let first = null;
        for (let i = 0; i < root.players.length; i++) {
            const p = root.players[i];
            if (!first)
                first = p;
            if (p.isPlaying)
                return p;
        }
        return first;
    }

    readonly property bool hasPlayer: root.player !== null && root.player !== undefined

    visible: root.hasPlayer
    width: root.hasPlayer ? icon.width + title.width + 8 : 0
    height: Theme.barHeight

    IconImage {
        id: icon

        anchors.verticalCenter: parent.verticalCenter
        source: Theme.adwaitaIcon(root.player && root.player.isPlaying
            ? "media-playback-pause-symbolic"
            : "media-playback-start-symbolic")
        implicitWidth: 16
        implicitHeight: 16
        opacity: 0.85
    }

    Text {
        id: title

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: icon.right
        anchors.leftMargin: 6
        // Cap the title so long names cannot push the right cluster.
        width: Math.min(implicitWidth, 160)
        text: root.player ? (root.player.trackTitle || "") : ""
        color: Theme.fgDim
        font.family: Theme.sans
        font.pointSize: 9
        elide: Text.ElideRight
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: root.hasPlayer
        onClicked: if (root.player && root.player.canTogglePlaying)
            root.player.togglePlaying()
    }
}
