import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Owns org.freedesktop.Notifications. No other daemon (mako etc.) may run.
//
// Toast cards are created imperatively (createObject) instead of a
// Repeater over a JS array: quickshell 0.3.1 + Qt 6.11.2 segfaults in
// VDMListDelegateDataType::createMissingProperties when a Repeater model
// is (re)assigned from a JS handler, even with a plain count model
// (crash reports under ~/.cache/quickshell/crashes). Direct object
// creation avoids the delegate-model machinery entirely.
NotificationServer {
    id: server

    bodySupported: true
    bodyMarkupSupported: true
    actionsSupported: true
    imageSupported: true
    keepOnReload: false

    onNotification: toast => {
        // Claim the notification: untracked ones are deleted by the server
        // right after this handler returns, which leaves every later
        // access (Timer's expire(), click handlers) hitting a dangling
        // QML wrapper ("Property 'expire' ... is not a function").
        toast.tracked = true;
        // Feed the shared history: plain copied fields only, never the
        // wrapper (same dangling-object rule).
        NotifStore.push(toast.appName, toast.summary, toast.body, toast.urgency === 2);
        toastCardComp.createObject(cardColumn, { toast: toast });
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
        implicitHeight: Math.max(0, cardColumn.implicitHeight + 12)
        color: "transparent"
        margins {
            top: Theme.barHeight + 8
            right: 8
        }

        Column {
            id: cardColumn
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6
        }
    }

    // Property value, not a bare child: NotificationServer has no default
    // property (same rule as the window below).
    property Component toastCardComp: Component {
        id: toastCardComp

        Rectangle {
            id: toastCard

            // Set at createObject() time; never null afterwards.
            property var toast

            width: parent ? parent.width : 320
            height: cardCol.implicitHeight + 16
            radius: 10
            color: Theme.bgAlt
            // urgency: 2 = Critical (org.freedesktop.Notifications spec)
            border.color: toast.toast && toast.toast.urgency === 2
                ? Theme.urgent
                : Theme.border

            Timer {
                // expireTimeout <= 0 means "server default" in the
                // spec; notify-send sends -1 when -t is absent. Use 5s
                // for normal urgency, keep critical notifications until
                // dismissed (GNOME behavior).
                readonly property int timeout: {
                    if (!toastCard.toast)
                        return 5000;
                    if (toastCard.toast.expireTimeout > 0)
                        return toastCard.toast.expireTimeout;
                    return toastCard.toast.urgency === 2 ? 0 : 5000;
                }
                running: toastCard.toast && timeout > 0
                interval: Math.max(timeout, 100)
                onTriggered: if (toastCard.toast)
                    toastCard.toast.expire()
            }

            Connections {
                target: toastCard.toast

                function onClosed(reason) {
                    toastCard.destroy();
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
                    visible: toastCard.toast && toastCard.toast.body
                        ? toastCard.toast.body.length > 0
                        : false
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
                    const actions = toastCard.toast && toastCard.toast.actions
                        ? toastCard.toast.actions
                        : [];
                    if (actions.length > 0)
                        actions[0].invoke();
                    toastCard.toast.dismiss();
                }
            }
        }
    }
}
