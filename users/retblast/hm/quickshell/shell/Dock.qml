import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland
import Quickshell.Wayland

// Dock: favorites + running apps, GNOME dash-to-dock style (centered,
// 48px icons). Shown only on workspaces in float mode (see float-workspace
// script): tiling workspace = no dock, floating workspace = dock.
//
// quickshell 0.3.1's DesktopEntries returns an empty index on this system
// (verified by probe: applications count 0 even with a correct
// XDG_DATA_DIRS), so favorites carry their own launch argv and theme icon
// names. IconImage resolves theme names through the Qt icon engine, which
// reads XDG_DATA_DIRS. Bottles is not listed: it ships no .desktop here.
PanelWindow {
    id: root

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: Theme.dockHeight
    color: "transparent"

    // Float mode per workspace id. The float-workspace script holds the
    // truth (marker files in the runtime dir) and pokes the running shell
    // over IPC; this map mirrors it. Rebuilt from the marker dir on start,
    // so a shell restart re-syncs without a toggle.
    property var floatStates: ({})

    // Active workspace id. Hyprland.focusedWorkspace looked right but is
    // stale in quickshell 0.3.1: it never updates after startup, so the dock
    // always read workspace 1. Probe hyprctl once at start, then follow the
    // event socket (workspace>>ID), which is reliable.
    property int wsId: 1

    // An unmapped window reserves no exclusive zone, so tiled windows use
    // the full height while the dock is hidden.
    visible: root.floatStates[root.wsId] === true

    Component.onCompleted: {
        floatSyncProbe.running = true;
        wsProbe.running = true;
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            // Event data is the part after ">>": "workspace>>77" -> "77".
            // Named workspaces parse as NaN and keep the current id.
            if (event.name === "workspace") {
                const id = parseInt(event.data);
                if (id)
                    root.wsId = id;
            }
        }
    }

    Process {
        id: floatSyncProbe
        command: ["fish", "-c", "ls $XDG_RUNTIME_DIR/hypr-float-ws 2>/dev/null; or true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const line of this.text.split("\n")) {
                    const id = line.trim();
                    if (id)
                        map[id] = true;
                }
                root.floatStates = map;
            }
        }
    }

    Process {
        id: wsProbe
        command: [
            "fish", "-c",
            "hyprctl -j activeworkspace | tr -d ' \\n\\t' | string replace -rf '.*\"id\":([0-9]+).*' '$1'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const id = parseInt(this.text.trim());
                if (id)
                    root.wsId = id;
            }
        }
    }

    IpcHandler {
        target: "floatws"

        function set(ws: string, state: string): void {
            const map = Object.assign({}, root.floatStates);
            map[ws] = state === "on";
            root.floatStates = map;
        }
    }

    readonly property var favorites: [
        {
            match: "google-chrome",
            name: "Chrome",
            command: ["google-chrome-stable"],
            icon: "google-chrome"
        },
        {
            match: "firefox",
            name: "Firefox",
            command: ["firefox", "--name", "firefox"],
            icon: "firefox"
        },
        {
            match: "ptyxis",
            name: "Ptyxis",
            command: ["ptyxis"],
            icon: "org.gnome.Ptyxis"
        },
        {
            match: "nautilus",
            name: "Nautilus",
            command: ["nautilus", "--new-window"],
            icon: "org.gnome.Nautilus"
        },
        {
            match: "zed",
            name: "Zed",
            command: ["zeditor"],
            icon: "zed"
        }
    ]

    // Running detection via the wlr-foreign toplevel list
    // (ToplevelManager): quickshell 0.3.1's Hyprland.toplevels model is
    // unreliable (same family as the stale focusedWorkspace), while
    // ToplevelManager works (the overview uses it). appId carries the
    // window class on Hyprland.
    function runningFor(match) {
        return ToplevelManager.toplevels.values.filter(t => {
            const id = (t.appId || "").toLowerCase();
            return id.includes(match);
        });
    }

    Rectangle {
        id: dockBg
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: row.implicitWidth + 20
        height: 52
        radius: 14
        color: Theme.bg
        opacity: 0.92

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: root.favorites

                delegate: Rectangle {
                    id: appBtn

                    required property var modelData
                    readonly property var running: root.runningFor(modelData.match)
                    readonly property bool focused: running.some(t => t.activated)

                    width: 48
                    height: 48
                    radius: 12
                    color: mouseArea.containsMouse
                        ? Theme.bgAlt
                        : (appBtn.focused ? Theme.bgAlt : "transparent")

                    IconImage {
                        anchors.centerIn: parent
                        // Bare names resolve as relative URLs in IconImage;
                        // iconPath goes through the freedesktop theme lookup.
                        source: Quickshell.iconPath(appBtn.modelData.icon)
                        implicitWidth: 40
                        implicitHeight: 40
                    }

                    // Running indicator (GNOME dock dot)
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 4
                        height: 4
                        radius: 2
                        color: Theme.accent
                        visible: appBtn.running.length > 0
                    }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (appBtn.running.length > 0) {
                                    if (appBtn.focused) {
                                        // 0.56 has no minimize dispatcher; the
                                        // wlr-foreign toplevel takes the request.
                                        appBtn.running.forEach(t => {
                                            if (t.activated)
                                                t.minimized = true;
                                        });
                                    } else {
                                        // Unminimize first: plain activate() may
                                        // not restore a minimized window.
                                        appBtn.running.forEach(t => {
                                            t.minimized = false;
                                        });
                                        appBtn.running[0].activate();
                                    }
                                } else {
								Quickshell.execDetached(appBtn.modelData.command);
							}
						}
					}
                }
            }
        }
    }
}
