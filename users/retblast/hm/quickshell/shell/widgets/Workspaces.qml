import QtQuick
import Quickshell
import Quickshell.Hyprland
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

Row {
    id: root

    spacing: 4

    // One pill per existing workspace, ordered by id. No numbers: the
    // compositor keeps the numbering packed (see hyprland.lua numeric
    // binds) and destroys empty unfocused workspaces, so the pill
    // count and order follow the real layout. A click focuses by id
    // through the Lua-form dispatch (Lua config mode wraps raw IPC
    // dispatch arguments as Lua code, so legacy dispatcher strings
    // are syntax errors).
    readonly property var workspaces: {
        const list = Hyprland.workspaces.values.filter(w => w.id > 0);
        list.sort((a, b) => a.id - b.id);
        return list;
    }

    Repeater {
        model: root.workspaces

        delegate: Rectangle {
            id: wsItem

            required property var modelData
            readonly property bool focused: modelData.focused

            width: focused ? 18 : 8
            height: 8
            radius: 4
            color: focused ? Theme.accent : Theme.bgAlt
            Behavior on width {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${modelData.id} })`)
            }
        }
    }
}
