import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Pipewire

// GNOME-style OSD for volume and brightness: a centered pill near the bottom
// with an icon and a progress bar, auto-hiding after ~2s.
//
// Triggers are state-based, not keybind-based, so the OSD reacts to every
// source: the XF86 keybinds, the bar mute button, media players, sensors.
// - volume: Pipewire default sink signals
// - brightness: a stream of `brightnessctl get` readings (1/s); a change
//   against the previous value shows the OSD.
PanelWindow {
    id: osd

    anchors {
        bottom: true
        left: true
        right: true
    }

    // Overlay: do not reserve screen space for a transient indicator.
    exclusionMode: ExclusionMode.Ignore
    implicitHeight: 100
    color: "transparent"
    focusable: false

    // A mapped layer window swallows pointer input even when fully
    // transparent - that killed the dock. Map the window only while the
    // pill shows; the fade runs on the pill, so the window unmaps just
    // after the fade-out finishes.
    visible: pill.opacity > 0

    property string kind: "volume"
    property real level: 0
    property bool muted: false

    // PanelWindow itself has no opacity; the fade lives on the pill.
    function show(kind, level, muted) {
        osd.kind = kind;
        osd.level = level;
        osd.muted = muted ?? false;
        pill.opacity = 1;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1800
        onTriggered: pill.opacity = 0
    }

    // ---- volume ----

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink ? sink.audio : null

    // Nodes stay unbound until tracked; without this the audio iface reports
    // empty volumes (and the mute write fails). Re-arms on device switches.
    PwObjectTracker {
        objects: [osd.sink]
    }

    onAudioChanged: {
        // Re-arm the change handlers after a device switch.
        Qt.callLater(() => {
            if (osd.audio)
                volumeWiring.target = osd.audio;
        });
    }

    Connections {
        id: volumeWiring
        target: osd.audio

        // NOTE: the notify signal for PwNodeAudioIface.volume is plural:
        // "volumesChanged" (verified in the 0.3.1 qmltypes).
        function onVolumesChanged() {
            osd.show("volume", osd.audio.volume, osd.audio.muted);
        }

        function onMutedChanged() {
            osd.show("volume", osd.audio.muted ? 0 : osd.audio.volume, osd.audio.muted);
        }
    }

    // ---- brightness ----

    property int maxBright: 0

    Component.onCompleted: maxProbe.running = true

    Process {
        id: maxProbe
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            // Machine format: device,class,type,cur,max,%
            onStreamFinished: {
                const parts = this.text.trim().split(",");
                if (parts.length >= 5 && !isNaN(parseInt(parts[4])))
                    osd.maxBright = parseInt(parts[4]);
            }
        }
    }

    Process {
        id: brightStream
        command: ["fish", "-c", "while true; brightnessctl get; sleep 1; end"]
        running: true
        stdout: SplitParser {
            property int last: -1

            onRead: data => {
                const v = parseInt(data);
                if (isNaN(v) || osd.maxBright <= 0)
                    return;
                if (last === -1) {
                    // First reading is the baseline, not a change.
                    last = v;
                    return;
                }
                if (v !== last) {
                    last = v;
                    osd.show("brightness", v / osd.maxBright, false);
                }
            }
        }
    }

    // ---- visuals ----

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        width: 260
        height: 56
        radius: 28
        color: Theme.bg
        opacity: 0
        border.color: Theme.border

        Behavior on opacity {
            NumberAnimation {
                duration: 180
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 12

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                source: {
                    if (osd.kind === "brightness")
                        return Theme.adwaitaIcon("display-brightness-symbolic");
                    if (osd.muted)
                        return Theme.adwaitaIcon("audio-volume-muted-symbolic");
                    return Theme.adwaitaIcon("audio-volume-high-symbolic");
                }
                implicitWidth: 24
                implicitHeight: 24
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 140
                height: 8
                radius: 4
                color: Theme.bgAlt
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(0, Math.min(1, osd.level)) * parent.width
                    radius: 4
                    color: osd.muted ? Theme.fgDim : Theme.accent
                    Behavior on width {
                        NumberAnimation {
                            duration: 90
                        }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Math.max(0, Math.min(1, osd.level)) * 100) + "%"
                color: Theme.fg
                font.family: Theme.sans
                font.pointSize: 9
            }
        }
    }
}
