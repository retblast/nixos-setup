import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth

// Quick settings (GNOME parity): volume + brightness sliders, the
// toggle grid (wifi, bluetooth, night light, power profile, caffeine)
// and lock/logout actions. Same single-window pattern as NotifCenter:
// fullscreen transparent surface while open, card top-right, click
// outside closes.
//
// Toggle: SUPER+S or
//   quickshell -c shell ipc call quicksettings toggle
// State is re-probed every time the panel opens, so external changes
// (GNOME, CLI, another panel) never leave stale toggles.
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
	visible: NotifStore.openPanel === "quicksettings"

	IpcHandler {
		target: "quicksettings"

		function toggle(): void {
			NotifStore.openPanel = NotifStore.openPanel === "quicksettings"
				? ""
				: "quicksettings";
		}

		function close(): void {
			NotifStore.openPanel = "";
		}
	}

	// Re-probe the services shortly after a toggle or when the panel
	// opens; unit/network changes are not always instant.
	function probeAll() {
		wifiProbe.running = true;
		profileProbe.running = true;
		caffeineProbe.running = true;
		nightLightProbe.running = true;
		brightProbe.running = true;
	}

	Timer {
		id: delayedProbe
		interval: 800
		onTriggered: root.probeAll()
	}

	onVisibleChanged: if (visible)
		root.probeAll()

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

	// ---- state ----

	// wifi
	property bool wifiOn: false

	// power profile
	property string profile: "balanced"

	// caffeine: true while hypridle is STOPPED (screen stays on)
	property bool caffeineOn: false

	// night light: true while gammastep is active
	property bool nightLightOn: false

	// brightness percent
	property int brightness: -1

	Process {
		id: wifiProbe
		command: ["nmcli", "radio", "wifi"]
		stdout: StdioCollector {
			onStreamFinished: root.wifiOn = this.text.trim() === "enabled"
		}
	}

	Process {
		id: profileProbe
		command: ["powerprofilesctl", "get"]
		stdout: StdioCollector {
			onStreamFinished: {
				const t = this.text.trim();
				if (t.length > 0)
					root.profile = t;
			}
		}
	}

	Process {
		id: caffeineProbe
		command: ["systemctl", "--user", "is-active", "hypridle.service"]
		stdout: StdioCollector {
			onStreamFinished: root.caffeineOn = this.text.trim() !== "active"
		}
	}

	Process {
		id: nightLightProbe
		command: ["systemctl", "--user", "is-active", "gammastep.service"]
		stdout: StdioCollector {
			onStreamFinished: root.nightLightOn = this.text.trim() === "active"
		}
	}

	Process {
		id: brightProbe
		// One percent number; --scale=0 keeps fish from printing "62.5".
		command: ["fish", "-c", "math --scale=0 (brightnessctl get) '*' 100 / (brightnessctl max)"]
		stdout: StdioCollector {
			onStreamFinished: {
				const v = parseInt(this.text.trim());
				if (!isNaN(v))
					root.brightness = v;
			}
		}
	}

	// The panel card.
	Rectangle {
		id: card

		anchors {
			top: parent.top
			right: parent.right
		}
		anchors.topMargin: Theme.barHeight + 8
		anchors.rightMargin: 8

		width: 380
		height: quickCol.implicitHeight + 24
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

		Column {
			id: quickCol

			anchors.fill: parent
			anchors.margins: 12
			spacing: 12

			// ---- header ----
			Text {
				text: "Quick Settings"
				color: Theme.fg
				font.family: Theme.sans
				font.pointSize: 11
				font.bold: true
			}

			// ---- volume ----
			Item {
				width: parent.width
				height: 28

				IconImage {
					id: volIcon

					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					source: Theme.adwaitaIcon("audio-volume-high-symbolic")
					implicitWidth: 16
					implicitHeight: 16
				}

				SliderRow {
					anchors.left: volIcon.right
					anchors.right: parent.right
					anchors.leftMargin: 10
					anchors.verticalCenter: parent.verticalCenter

					max: 1
					value: root.audio ? (root.audio.volume ?? 0) : 0

					onAdjusted: v => {
						// Guard: nodes are briefly unbound during device
						// switches; writing then logs a service error.
						if (Pipewire.ready && root.audio)
							root.audio.volume = v;
					}
				}
			}

			// ---- brightness ----
			Item {
				width: parent.width
				height: 28

				IconImage {
					id: brightIcon

					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					source: Theme.adwaitaIcon("display-brightness-symbolic")
					implicitWidth: 16
					implicitHeight: 16
				}

				SliderRow {
					id: brightSlider

					anchors.left: brightIcon.right
					anchors.right: parent.right
					anchors.leftMargin: 10
					anchors.verticalCenter: parent.verticalCenter

					max: 100
					value: root.brightness >= 0 ? root.brightness : 0

					onAdjusted: v => {
						root.brightness = Math.round(v);
						brightWrite.restart();
					}

					// Debounce: one brightnessctl write per drag pause
					// instead of one process per pointer move.
					Timer {
						id: brightWrite
						interval: 250
						onTriggered: Quickshell.execDetached([
							"brightnessctl",
							"set",
							Math.max(1, root.brightness) + "%"
						])
					}
				}
			}

			// ---- toggles ----
			Grid {
				width: parent.width
				columns: 3
				spacing: 8

				ToggleTile {
					labelText: "Wi-Fi"
					iconSource: Theme.adwaitaIcon("network-wireless-symbolic")
					active: root.wifiOn
					onTap: {
						root.wifiOn = !root.wifiOn;
						Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiOn ? "on" : "off"]);
						delayedProbe.restart();
					}
				}

				ToggleTile {
					labelText: "Bluetooth"
					iconSource: Theme.adwaitaIcon("bluetooth-active-symbolic")
					active: Bluetooth.defaultAdapter !== null && Bluetooth.defaultAdapter.enabled
					onTap: if (Bluetooth.defaultAdapter !== null)
						Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
				}

				ToggleTile {
					labelText: "Night Light"
					iconSource: Theme.adwaitaIcon("night-light-symbolic")
					active: root.nightLightOn
					onTap: {
						root.nightLightOn = !root.nightLightOn;
						if (root.nightLightOn)
							nlStart.running = true;
						else
							nlStop.running = true;
						delayedProbe.restart();
					}
				}

				ToggleTile {
					labelText: {
						if (root.profile === "performance")
							return "Performance";
						if (root.profile === "power-saver")
							return "Power Saver";
						return "Balanced";
					}
					iconSource: Theme.adwaitaIcon(root.profile === "performance"
						? "power-profile-performance-symbolic"
						: root.profile === "power-saver"
							? "power-profile-power-saver-symbolic"
							: "power-profile-balanced-symbolic")
					active: root.profile !== "balanced"
					onTap: {
						const order = ["balanced", "performance", "power-saver"];
						const idx = order.indexOf(root.profile);
						root.profile = order[(idx + 1) % order.length];
						Quickshell.execDetached(["powerprofilesctl", "set", root.profile]);
						delayedProbe.restart();
					}
				}

				ToggleTile {
					labelText: "Caffeine"
					iconSource: Theme.adwaitaIcon(root.caffeineOn
						? "weather-clear-symbolic"
						: "weather-clear-night-symbolic")
					active: root.caffeineOn
					onTap: {
						root.caffeineOn = !root.caffeineOn;
						if (root.caffeineOn)
							hidleStop.running = true;
						else
							hidleStart.running = true;
						delayedProbe.restart();
					}
				}
			}

			// ---- actions ----
			Row {
				spacing: 8

				ActionTile {
					labelText: "Lock"
					iconSource: Theme.adwaitaIcon("system-lock-screen-symbolic")
					onTap: {
						NotifStore.openPanel = "";
						Quickshell.execDetached(["hyprlock"]);
					}
				}

				ActionTile {
					labelText: "Logout"
					iconSource: Theme.adwaitaIcon("system-log-out-symbolic")
					onTap: {
						NotifStore.openPanel = "";
						// Lua config mode: hyprctl dispatch wraps its
						// argument as Lua, so the argument must be a
						// hl.* expression.
						Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"]);
					}
				}
			}
		}
	}

	// Pipewire wiring for the volume slider. Nodes stay unbound until
	// tracked; without the tracker the audio iface reports empty
	// volumes and writes fail.
	readonly property var sink: Pipewire.defaultAudioSink
	readonly property var audio: sink ? sink.audio : null

	PwObjectTracker {
		objects: [root.sink]
	}

	Process {
		id: nlStart
		command: ["systemctl", "--user", "start", "gammastep.service"]
	}

	Process {
		id: nlStop
		command: ["systemctl", "--user", "stop", "gammastep.service"]
	}

	Process {
		id: hidleStop
		command: ["systemctl", "--user", "stop", "hypridle.service"]
	}

	Process {
		id: hidleStart
		command: ["systemctl", "--user", "start", "hypridle.service"]
	}

	// Hand-built slider: the shell deliberately avoids
	// QtQuick.Controls, so the slider follows the same custom-visual
	// style as the rest of the panel.
	component SliderRow: Item {
		id: slider

		property real value: 0
		property real max: 1

		signal adjusted(real value)

		height: 24

		Rectangle {
			anchors.verticalCenter: parent.verticalCenter
			width: slider.width
			height: 4
			radius: 2
			color: Theme.bg
			border.color: Theme.border
			border.width: 1
		}

		Rectangle {
			anchors.verticalCenter: parent.verticalCenter
			anchors.left: parent.left
			width: slider.width * Math.max(0, Math.min(1, slider.value / slider.max))
			height: 4
			radius: 2
			color: Theme.accent
		}

		Rectangle {
			id: knob

			anchors.verticalCenter: parent.verticalCenter
			width: 12
			height: 12
			radius: 6
			color: Theme.fg
			x: Math.max(0, Math.min(slider.width - knob.width,
				slider.width * Math.min(1, slider.value / slider.max) - knob.width / 2))
		}

		MouseArea {
			anchors.fill: parent

			function apply(x) {
				const w = slider.width;
				if (w <= 0 || slider.max <= 0)
					return;
				const frac = Math.max(0, Math.min(1, x / w));
				slider.value = frac * slider.max;
				slider.adjusted(slider.value);
			}

			onPressed: mouse => apply(mouse.x)
			onPositionChanged: mouse => {
				if (pressed)
					apply(mouse.x);
			}
		}
	}

	component ToggleTile: Rectangle {
		id: tile

		property string labelText
		property string iconSource
		property bool active

		signal tap()

		width: 114
		height: 60
		radius: 8
		color: tile.active ? Theme.accent : Theme.bg
		border.color: tile.active ? Theme.accent : Theme.border
		border.width: 1

		Column {
			anchors.centerIn: parent
			spacing: 3

			IconImage {
				anchors.horizontalCenter: parent.horizontalCenter
				source: tile.iconSource
				implicitWidth: 16
				implicitHeight: 16
			}

			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				text: tile.labelText
				color: tile.active ? Theme.fg : Theme.fgDim
				font.family: Theme.sans
				font.pointSize: 8
			}
		}

		MouseArea {
			anchors.fill: parent
			cursorShape: Qt.PointingHandCursor
			onClicked: tile.tap()
		}
	}

	component ActionTile: Rectangle {
		id: atile

		property string labelText
		property string iconSource

		signal tap()

		width: 114
		height: 40
		radius: 8
		color: Theme.bg
		border.color: Theme.border
		border.width: 1

		Row {
			anchors.centerIn: parent
			spacing: 6

			IconImage {
				source: atile.iconSource
				implicitWidth: 14
				implicitHeight: 14
				anchors.verticalCenter: parent.verticalCenter
			}

			Text {
				text: atile.labelText
				color: Theme.fgDim
				font.family: Theme.sans
				font.pointSize: 9
				anchors.verticalCenter: parent.verticalCenter
			}
		}

		MouseArea {
			anchors.fill: parent
			cursorShape: Qt.PointingHandCursor
			onClicked: atile.tap()
		}
	}
}
