import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Networking
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

// Native network status, backed by NetworkManager via Quickshell.Networking.
// Replaces the nm-applet tray icon, whose fallback pixmaps look wrong on the
// dark bar.
Item {
    id: root

    readonly property var wifiDev: {
        const devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wifi)
                return devs[i];
        return null;
    }

    readonly property var wiredDev: {
        const devs = Networking.devices.values;
        for (let i = 0; i < devs.length; i++)
            if (devs[i].type === DeviceType.Wired)
                return devs[i];
        return null;
    }

    // The connected network in the wifi scan list. Without a scan hit, fall
    // back to the device's own connected state and assume a decent signal.
    readonly property var activeNet: {
        if (!wifiDev)
            return null;
        const nets = wifiDev.networks.values;
        for (let i = 0; i < nets.length; i++)
            if (nets[i].connected)
                return nets[i];
        return null;
    }

    readonly property bool online: (wifiDev && wifiDev.connected)
        || (wiredDev && wiredDev.connected)

    width: icon.width + (ssid.visible ? ssid.width + 5 : 0)
    height: Theme.barHeight

    IconImage {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        source: Theme.adwaitaIcon(root.iconName)
        implicitWidth: 16
        implicitHeight: 16
        visible: root.online || Networking.wifiEnabled
    }

    Text {
        id: ssid
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        anchors.left: icon.right
        anchors.leftMargin: 5
        visible: root.activeNet !== null
        text: root.activeNet ? root.activeNet.name : ""
        color: Theme.fgDim
        font.family: Theme.sans
        font.pointSize: 8
        elide: Text.ElideRight
        // Keep a long SSID from pushing into the caffeine toggle.
        width: Math.min(implicitWidth, 90)
    }

    readonly property string iconName: {
        if (wiredDev && wiredDev.connected)
            return "network-wired-symbolic";
        if (!Networking.wifiEnabled || !wifiDev)
            return "network-wireless-offline-symbolic";
        if (!root.activeNet)
            return "network-wireless-signal-good-symbolic";
        const s = root.activeNet.signalStrength;
        if (s >= 0.75)
            return "network-wireless-signal-excellent-symbolic";
        if (s >= 0.5)
            return "network-wireless-signal-good-symbolic";
        if (s >= 0.25)
            return "network-wireless-signal-ok-symbolic";
        if (s > 0.05)
            return "network-wireless-signal-weak-symbolic";
        return "network-wireless-signal-none-symbolic";
    }
}
