import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null
    readonly property bool muted: audio ? (audio.muted ?? false) : false
    readonly property int percent: audio ? Math.round((audio.volume ?? 0) * 100) : 0

    // Nodes stay unbound until tracked; without this the audio iface reports
    // empty volumes.
    PwObjectTracker {
        objects: [root.sink]
    }

    width: icon.width + (pct.visible ? pct.width + 4 : 0)
    height: Theme.barHeight

    IconImage {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        source: Theme.adwaitaIcon(root.iconName)
        // Adwaita symbolic art is a 16x16 viewBox; render 1:1 for crispness.
        implicitWidth: 16
        implicitHeight: 16
    }

    Text {
        id: pct
        anchors.verticalCenter: parent.verticalCenter
        // Digits have no descender; without the nudge they sit ~1px high
        // relative to the icon's optical center.
        anchors.verticalCenterOffset: 1
        anchors.left: icon.right
        anchors.leftMargin: 5
        visible: !root.muted
        text: root.percent + "%"
        color: Theme.fgDim
        font.family: Theme.sans
        font.pointSize: 8
    }

    readonly property string iconName: {
        if (root.muted)
            return "audio-volume-muted-symbolic";
        if (root.percent >= 100)
            return "audio-volume-overamplified-symbolic";
        if (root.percent >= 66)
            return "audio-volume-high-symbolic";
        if (root.percent >= 33)
            return "audio-volume-medium-symbolic";
        return "audio-volume-low-symbolic";
    }

    MouseArea {
        anchors.fill: parent
        // Guard: Pipewire nodes are unbound briefly during device switches;
        // writing mute to an unbound node logs a service error.
        enabled: Pipewire.ready && root.audio
        onClicked: {
            if (root.audio)
                root.audio.muted = !root.audio.muted;
        }
    }
}
