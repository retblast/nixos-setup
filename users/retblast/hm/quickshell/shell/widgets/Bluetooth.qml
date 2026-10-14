import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

// Native bluetooth status, backed by BlueZ via Quickshell.Bluetooth.
// Replaces the blueman tray icon. Icon follows the adapter state:
// disabled / on with a connected device / on and idle. Hidden when the
// machine has no adapter. Left-click toggles the adapter power,
// right-click opens blueman-manager (temporary handler until a native
// panel exists).
Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    // Global device list covers every adapter; the count only matters for
    // the icon state.
    readonly property int connectedCount: {
        const devs = Bluetooth.devices.values;
        let n = 0;
        for (let i = 0; i < devs.length; i++)
            if (devs[i].connected)
                n++;
        return n;
    }

    readonly property string iconName: {
        if (!adapter || !adapter.enabled)
            return "bluetooth-disabled-symbolic";
        if (connectedCount > 0)
            return "bluetooth-active-symbolic";
        return "bluetooth-disconnected-symbolic";
    }

    visible: adapter !== null
    width: 20
    height: Theme.barHeight

    IconImage {
        id: icon
        anchors.centerIn: parent
        source: Theme.adwaitaIcon(root.iconName)
        implicitWidth: 16
        implicitHeight: 16
        opacity: root.adapter && root.adapter.enabled ? 1.0 : 0.55
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        // Left: toggle adapter power. Right: device manager GUI.
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["blueman-manager"]);
                return;
            }
            if (root.adapter)
                root.adapter.enabled = !root.adapter.enabled;
        }
    }
}
