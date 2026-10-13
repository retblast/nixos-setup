import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Owns org.freedesktop.Notifications. No other daemon (mako etc.) may run.
NotificationServer {
    id: server

    bodySupported: true
    bodyMarkupSupported: true
    actionsSupported: true
    imageSupported: true
    keepOnReload: false

    // Mutable: onNotification reassigns this list. It was readonly once and
    // notifications silently never rendered ("Cannot assign to read-only
    // property toasts").
    property var toasts: []

    onNotification: toast => {
        server.toasts = server.toasts.concat([toast]);
    }

    // NotificationServer has no default property, so the window must be a
    // property value (quickshell instantiates it like a Variants delegate).
    property PanelWindow window: PanelWindow {
        id: window

        anchors {
            top: true
            right: true
        }

        implicitWidth: 340
        implicitHeight: Math.max(0, list.contentHeight + 12)
        color: "transparent"
        margins {
            top: Theme.barHeight + 8
            right: 8
        }

        Column {
            id: list
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6

            Repeater {
                model: server.toasts

                delegate: Rectangle {
                    id: toastCard

                    required property int index
                    readonly property var toast: server.toasts[index]

                    width: parent ? parent.width : 320
                    height: cardCol.implicitHeight + 16
                    radius: 10
                    color: Theme.bgAlt
                    // urgency: 2 = Critical (org.freedesktop.Notifications spec)
                    border.color: toastCard.toast && toastCard.toast.urgency === 2
                        ? Theme.urgent
                        : Theme.border

                    function remove() {
                        const next = server.toasts.slice();
                        next.splice(toastCard.index, 1);
                        server.toasts = next;
                    }

                    Timer {
                        // Auto-expire only when the app asked for it
                        running: toastCard.toast && toastCard.toast.expireTimeout > 0
                        interval: toastCard.toast
                            ? Math.max(toastCard.toast.expireTimeout, 100)
                            : 5000
                        onTriggered: if (toastCard.toast)
                            toastCard.toast.expire()
                    }

                    Connections {
                        target: toastCard.toast

                        function onClosed(reason) {
                            toastCard.remove();
                        }
                    }

                    Column {
                        id: cardCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2

                        Text {
                            width: parent.width
                            text: toastCard.toast ? toastCard.toast.summary : ""
                            color: Theme.fg
                            font.family: Theme.sans
                            font.pointSize: 10
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: toastCard.toast && toastCard.toast.body.length > 0
                            text: toastCard.toast ? toastCard.toast.body : ""
                            color: Theme.fgDim
                            font.family: Theme.sans
                            font.pointSize: 9
                            wrapMode: Text.Wrap
                            textFormat: Text.MarkdownText
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            // Invoke the default action if present, then dismiss
                            const actions = toastCard.toast ? toastCard.toast.actions : [];
                            if (actions.length > 0)
                                actions[0].invoke();
                            toastCard.toast.dismiss();
                        }
                    }
                }
            }
        }
    }
}
