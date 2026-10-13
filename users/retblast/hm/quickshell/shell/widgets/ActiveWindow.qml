import QtQuick
import Quickshell
import Quickshell.Hyprland
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

// Width comes from the anchors in Bar.qml (between workspaces and clock);
// do not bind width here — the old parent-derived width let long titles
// overlap the clock.
Text {
    text: Hyprland.activeToplevel && Hyprland.activeToplevel.title
        ? Hyprland.activeToplevel.title
        : qsTr("Desktop")
    color: Theme.fg
    font.family: Theme.sans
    font.pointSize: 9
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignHCenter
}
