import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

// Dock: favorites + running apps, GNOME dash-to-dock style (v1: always
// visible, centered, 48px icons). Autohide comes in a later batch.
PanelWindow {
    id: root

    anchors {
        bottom: true
        left: true
        right: true
    }

    implicitHeight: Theme.dockHeight
    color: "transparent"

    readonly property var favorites: [
        {
            id: "google-chrome.desktop",
            match: "google-chrome",
            name: "Chrome"
        },
        {
            id: "firefox.desktop",
            match: "firefox",
            name: "Firefox"
        },
        {
            id: "org.gnome.Ptyxis.desktop",
            match: "ptyxis",
            name: "Ptyxis"
        },
        {
            id: "org.gnome.Nautilus.desktop",
            match: "nautilus",
            name: "Nautilus"
        },
        {
            id: "dev.zed.Zed.desktop",
            match: "zed",
            name: "Zed"
        },
        {
            id: "com.usebottles.Bottles.desktop",
            match: "bottles",
            name: "Bottles"
        }
    ]

    function toplevelMatches(t, match) {
        const cls = t.lastIpcObject && t.lastIpcObject.class;
        return cls && cls.toLowerCase().includes(match);
    }

    function runningFor(match) {
        return Hyprland.toplevels.values.filter(t => root.toplevelMatches(t, match));
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
                    readonly property var entry: DesktopEntries.byId(modelData.id)
                        ?? DesktopEntries.byId(modelData.id.replace(".desktop", ""))
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
                        source: appBtn.entry ? appBtn.entry.icon : ""
                        implicitWidth: 40
                        implicitHeight: 40
                        visible: appBtn.entry
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
                                if (appBtn.focused)
                                    Hyprland.dispatch("minimize");
                                else
                                    Hyprland.dispatch("focuswindow class:" + appBtn.modelData.match);
                            } else if (appBtn.entry) {
                                appBtn.entry.execute();
                            }
                        }
                    }
                }
            }
        }
    }
}
