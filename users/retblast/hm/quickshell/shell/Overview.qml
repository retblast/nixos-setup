import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// GNOME-style app overview: a fullscreen overlay grid of all toplevels
// with live screencopy thumbnails. Toggle via IPC (SUPER+TAB or the
// 3-finger-up gesture): quickshell -c shell ipc call overview toggle.
// Click a card to focus the window; Esc or a backdrop click closes.
//
// PanelWindow already has a `visible` property that controls layer
// mapping. Never shadow it with a custom property: the window then maps
// at creation regardless and sits fullscreen over the desktop eating
// every click (found the hard way 2026-10-14).
PanelWindow {
	id: root

	// Overlay sits above everything; exclusive keyboard so Esc lands here.
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

	anchors {
		top: true
		bottom: true
		left: true
		right: true
	}
	color: "transparent"
	visible: false

	IpcHandler {
		target: "overview"

		function toggle(): void {
			root.visible = !root.visible;
		}
	}

	function close() {
		root.visible = false;
	}

	// Dim backdrop; click-through closes.
	Rectangle {
		anchors.fill: parent
		color: Theme.bg
		opacity: root.visible ? 0.88 : 0
		visible: opacity > 0

		MouseArea {
			anchors.fill: parent
			onClicked: root.close()
		}
	}

	Text {
		anchors.horizontalCenter: parent.horizontalCenter
		anchors.top: parent.top
		anchors.topMargin: 24
		visible: root.visible && grid.count === 0
		text: "No windows"
		color: Theme.fgDim
		font.family: Theme.sans
		font.pointSize: 16
	}

	GridView {
		id: grid

		anchors.fill: parent
		anchors.margins: 40
		anchors.topMargin: 70
		visible: root.visible
		focus: true
		// The toplevel model is a real QAbstractListModel assigned once —
		// the Repeater-crash gotcha does not apply (that one is about
		// models reassigned from JS handlers).
		model: ToplevelManager.toplevels
		cellWidth: Math.floor((width - 40) / Math.max(1, Math.floor(width / 380)))
		cellHeight: 240
		boundsBehavior: Flickable.StopAtBounds
		clip: true

		Keys.onEscapePressed: root.close()

		delegate: Item {
			id: card

			required property var modelData

			width: grid.cellWidth - 12
			height: grid.cellHeight - 12
			x: 6
			y: 6

			Rectangle {
				anchors.fill: parent
				radius: 10
				color: Theme.bgAlt
				border.color: card.modelData.activated ? Theme.accent : Theme.border
				border.width: card.modelData.activated ? 2 : 1

				MouseArea {
					anchors.fill: parent
					onClicked: {
						card.modelData.activate();
						root.close();
					}
				}
			}

			// Live thumbnail. Screencopy only runs while the overview is
			// open (live bound to visibility) to keep the GPU cost at rest
			// at zero. Placeholder when the compositor refuses per-window
			// capture or the window has no content yet.
			ScreencopyView {
				id: thumb

				anchors.fill: parent
				anchors.margins: 6
				anchors.bottomMargin: 40
				captureSource: card.modelData
				live: root.visible
				constraintSize: Qt.size(width, height)
				paintCursor: false
			}

			Rectangle {
				anchors.fill: thumb
				radius: 6
				color: Theme.bg
				visible: !thumb.hasContent

				Text {
					anchors.centerIn: parent
					text: (card.modelData.title || card.modelData.appId || "?")
						.charAt(0).toUpperCase()
					color: Theme.fgDim
					font.family: Theme.sans
					font.pointSize: 28
					font.bold: true
				}
			}

			Text {
				anchors.left: parent.left
				anchors.right: parent.right
				anchors.bottom: parent.bottom
				anchors.margins: 8
				text: card.modelData.title || card.modelData.appId || ""
				color: Theme.fg
				font.family: Theme.sans
				font.pointSize: 9
				elide: Text.ElideRight
			}

			// Close button: stops the click from reaching the focus
			// MouseArea underneath.
			MouseArea {
				anchors.right: parent.right
				anchors.top: parent.top
				anchors.margins: 6
				width: 22
				height: 22
				cursorShape: Qt.PointingHandCursor

				Rectangle {
					anchors.fill: parent
					radius: parent.width / 2
					color: Theme.bg
					border.color: Theme.border

					Text {
						anchors.centerIn: parent
						text: "×"
						color: Theme.fgDim
						font.pointSize: 12
					}
				}

				onClicked: {
					card.modelData.close();
					root.close();
				}
			}
		}
	}
}
