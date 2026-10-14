import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.UPower
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

Item {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev ? (dev.isPresent ?? false) : false
    readonly property int percent: dev ? Math.round((dev.percentage ?? 0) * 100) : 0
    readonly property bool charging: !UPower.onBattery

    width: present ? icon.width + pct.width + 5 : 0
    height: Theme.barHeight

    IconImage {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        visible: root.present
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
        visible: root.present
        text: root.percent + "%"
        color: root.percent < 15 && !root.charging ? Theme.urgent : Theme.fgDim
        font.family: Theme.sans
        font.pointSize: 8
    }

    // adwaita battery-level-N(-charging)-symbolic, N in steps of 10.
    // adwaita 50: levels 0-90 have -charging; level 100 uses -charged instead.
    readonly property string iconName: {
        const level = Math.min(100, Math.round(root.percent / 10) * 10);
        const base = "battery-level-" + level;
        if (!root.charging)
            return base + "-symbolic";
        return level >= 100 ? base + "-charged-symbolic" : base + "-charging-symbolic";
    }
}
