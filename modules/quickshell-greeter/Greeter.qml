import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import "."

// Full-screen login UI driven by greetd over its session socket. The PAM
// conversation (password, fingerprint prompts) arrives through Greetd's
// authMessage signal; the UI only routes responses back. No PamContext —
// greetd owns the PAM stack.
PanelWindow {
	id: root

	anchors {
		top: true
		bottom: true
		left: true
		right: true
	}
	color: Theme.bg

	// Fixed session user: single-user machine (tuigreet --remember served
	// the same role).
	readonly property string user: "retblast"

	property string prompt: ""
	property bool wantResponse: false
	property bool hideResponse: true
	property string status: Greetd.available
		? ""
		: "test mode: greetd socket not available"

	Component.onCompleted: if (Greetd.available)
		Greetd.createSession(root.user)

	Connections {
		target: Greetd

		function onAuthMessage(message, error, responseRequired, echoResponse) {
			if (error) {
				root.status = message;
				return;
			}
			if (responseRequired) {
				root.prompt = message.replace(/: *$/, "");
				root.wantResponse = true;
				root.hideResponse = !echoResponse;
				field.text = "";
				field.forceActiveFocus();
			} else {
				// No response expected: fingerprint prompts and PAM info
				// lines ("fingerprint scan succeeded" etc.).
				root.status = message;
			}
		}

		function onAuthFailure(message) {
			root.status = message.length > 0 ? message : "Authentication failed";
			root.wantResponse = false;
			root.prompt = "";
			field.text = "";
		}

		function onReadyToLaunch() {
			root.status = "Starting Hyprland...";
			// Same session command tuigreet used (--cmd start-hyprland).
			Greetd.launch(["start-hyprland"]);
		}

		function onError(error) {
			root.status = "greetd error: " + error;
		}
	}

	Rectangle {
		anchors.fill: parent
		color: Theme.bg
	}

	Column {
		anchors.centerIn: parent
		spacing: 14
		width: Math.min(420, parent.width - 80)

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			property date now: new Date()
			text: Qt.formatDateTime(now, "HH:mm")
			color: Theme.fg
			font.family: Theme.sans
			font.pointSize: 40

			Timer {
				interval: 30 * 1000
				running: true
				repeat: true
				triggeredOnStart: true
				onTriggered: parent.now = new Date()
			}
		}

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			property date now: new Date()
			text: Qt.formatDateTime(now, "dddd d MMMM")
			color: Theme.fgDim
			font.family: Theme.sans
			font.pointSize: 12

			Timer {
				interval: 60 * 1000
				running: true
				repeat: true
				triggeredOnStart: true
				onTriggered: parent.now = new Date()
			}
		}

		Item {
			width: 1
			height: 10
		}

		Text {
			anchors.horizontalCenter: parent.horizontalCenter
			text: root.user
			color: Theme.fg
			font.family: Theme.sans
			font.pointSize: 16
		}

		Text {
			width: parent.width
			visible: root.wantResponse
			text: root.prompt
			color: Theme.fgDim
			font.family: Theme.sans
			font.pointSize: 11
			horizontalAlignment: Text.AlignHCenter
			elide: Text.ElideRight
		}

		Rectangle {
			width: parent.width
			height: 44
			radius: 8
			visible: root.wantResponse
			color: Theme.bgAlt
			border.color: field.activeFocus ? Theme.accent : Theme.border
			border.width: 1

			TextInput {
				id: field

				anchors.fill: parent
				anchors.margins: 10
				verticalAlignment: TextInput.AlignVCenter
				echoMode: root.hideResponse ? TextInput.Password : TextInput.Normal
				color: Theme.fg
				font.family: Theme.sans
				font.pointSize: 12
				clip: true
				focus: true
				cursorVisible: activeFocus

				onAccepted: {
					if (!root.wantResponse)
						return;
					root.wantResponse = false;
					root.prompt = "";
					Greetd.respond(text);
					text = "";
				}
			}
		}

		Text {
			width: parent.width
			visible: root.status.length > 0
			text: root.status
			color: Theme.fgDim
			font.family: Theme.sans
			font.pointSize: 10
			wrapMode: Text.Wrap
			horizontalAlignment: Text.AlignHCenter
		}
	}
}
