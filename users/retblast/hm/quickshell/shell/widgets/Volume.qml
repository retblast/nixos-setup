import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property int percent: audio ? Math.round(audio.volume * 100) : 0

    width: label.implicitWidth
    height: Theme.barHeight

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: root.audio && root.audio.muted
            ? "muted"
            : root.percent + "%"
        color: root.audio && root.audio.muted ? Theme.urgent : Theme.fg
        font.family: Theme.sans
        font.pointSize: 9
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if (root.audio)
                root.audio.muted = !root.audio.muted;
        }
    }
}
