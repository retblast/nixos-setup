import QtQuick
import Quickshell
import Quickshell.Hyprland

Text {
    text: Hyprland.activeToplevel && Hyprland.activeToplevel.title
        ? Hyprland.activeToplevel.title
        : qsTr("Desktop")
    color: Theme.fg
    font.family: Theme.sans
    font.pointSize: 9
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter
    width: parent ? Math.min(parent.width / 2, implicitWidth) : implicitWidth
}
