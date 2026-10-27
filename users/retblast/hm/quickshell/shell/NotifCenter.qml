import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Notification center: the history panel behind the clock. While open,
// one fullscreen window maps with the card at the top right; the rest
// of the surface is a dimmed click-catcher (a mapped layer window
// swallows pointer input, which here is the wanted behavior - a click
// outside closes).
//
// Toggle: click the clock, SUPER+N, or
//   quickshell -c shell ipc call notifcenter toggle
// Panel visibility binds to NotifStore.openPanel, so the center and the
// quick settings panel can never be open at the same time.
PanelWindow {
	id: root

	// Overlay above everything; exclusive keyboard so Esc lands here.
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

	anchors {
		top: true
		bottom: true
		left: true
		right: true
	}
	color: "transparent"
	visible: NotifStore.openPanel === "notifcenter"

	IpcHandler {
		target: "notifcenter"

		function toggle(): void {
			NotifStore.openPanel = NotifStore.openPanel === "notifcenter"
				? ""
				: "notifcenter";
		}

		function close(): void {
			NotifStore.openPanel = "";
		}
	}

	onVisibleChanged: if (visible)
		NotifStore.seen()

	// Dim backdrop; click-through closes.
	Rectangle {
		anchors.fill: parent
		color: Theme.bg
		opacity: root.visible ? 0.5 : 0
		visible: opacity > 0

		MouseArea {
			anchors.fill: parent
			onClicked: NotifStore.openPanel = ""
		}
	}

	// The panel card. Esc handling hangs on the focus item inside.
	Rectangle {
		id: card

		anchors {
			top: parent.top
			right: parent.right
		}
		anchors.topMargin: Theme.barHeight + 8
		anchors.rightMargin: 8

		width: 380
		height: Math.min(notifList.contentHeight + 64, parent.height - Theme.barHeight - 24)
		radius: 10
		color: Theme.bgAlt
		border.color: Theme.border
		border.width: 1

		Item {
			id: focusItem

			anchors.fill: parent
			focus: true

			Keys.onEscapePressed: NotifStore.openPanel = ""
		}

		// Header
		Item {
			id: header

			anchors {
				top: parent.top
				left: parent.left
				right: parent.right
			}
			anchors.margins: 12
			height: 28

			Text {
				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
				text: "Notifications"
				color: Theme.fg
				font.family: Theme.sans
				font.pointSize: 11
				font.bold: true
			}

			Rectangle {
				id: clearButton

				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				width: 56
				height: 24
				radius: 6
				color: clearMouse.containsMouse ? Theme.accent : Theme.bg
				border.color: Theme.border
				border.width: 1
				visible: NotifStore.count > 0

				Text {
					anchors.centerIn: parent
					text: "Clear"
					color: clearMouse.containsMouse ? Theme.fg : Theme.fgDim
					font.family: Theme.sans
					font.pointSize: 9
				}

				MouseArea {
					id: clearMouse
					anchors.fill: parent
					hoverEnabled: true
					cursorShape: Qt.PointingHandCursor
					onClicked: NotifStore.clearAll()
				}
			}
		}

		// Empty state
		Text {
			anchors.centerIn: parent
			visible: NotifStore.count === 0
			text: "No notifications"
			color: Theme.fgDim
			font.family: Theme.sans
			font.pointSize: 11
		}

		// History list. ListModel is a real QAbstractListModel (see
		// NotifStore.qml): assigning it once here is stable.
		ListView {
			id: notifList

			anchors {
				top: header.bottom
				left: parent.left
				right: parent.right
				bottom: parent.bottom
			}
			anchors.margins: 10
			visible: NotifStore.count > 0
			clip: true
			spacing: 6
			model: NotifStore

			delegate: Rectangle {
				id: notifCard

				width: notifList.width
				height: 64
				radius: 8
				color: Theme.bg
				// urgent border matches the toast cards
				border.color: urgent ? Theme.urgent : Theme.border
				border.width: 1

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					// Click a history entry to drop it.
					onClicked: NotifStore.remove(index)
				}

				Column {
					anchors.fill: parent
					anchors.margins: 8
					spacing: 1

					Item {
						width: parent.width
						height: summaryText.height

						Text {
							id: summaryText

							anchors.left: parent.left
							width: parent.width - timeText.width - 8
							text: summary || ""
							color: Theme.fg
							font.family: Theme.sans
							font.pointSize: 10
							font.bold: true
							elide: Text.ElideRight
						}

						Text {
							id: timeText

							anchors.right: parent.right
							text: time || ""
							color: Theme.fgDim
							font.family: Theme.sans
							font.pointSize: 8
						}
					}

					Text {
						width: parent.width
						visible: (body || "").length > 0
						text: body || ""
						color: Theme.fgDim
						font.family: Theme.sans
						font.pointSize: 9
						wrapMode: Text.WrapAnywhere
						maximumLineCount: 2
						elide: Text.ElideRight
					}

					Text {
						width: parent.width
						visible: (appName || "").length > 0
						text: appName || ""
						color: Theme.fgDim
						font.family: Theme.sans
						font.pointSize: 8
						opacity: 0.7
						elide: Text.ElideRight
					}
				}
			}
		}
	}
}
