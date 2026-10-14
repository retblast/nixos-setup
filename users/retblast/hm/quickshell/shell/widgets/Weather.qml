import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
// Theme singleton lives one dir up (declared in ../qmldir).
import ".."

// Weather in the bar. wttr.in one-liner, no API key; an empty location
// uses IP geolocation server-side. One long-lived fish loop re-fetches
// every 30 minutes (Process restarts from Timers are unreliable in
// quickshell 0.3.1). Hidden until the first successful read.
Item {
	id: root

	// Set a city name to pin the location; empty = IP-based.
	readonly property string location: ""

	property string cond: ""
	property string temp: ""

	readonly property bool ok: temp !== ""

	width: ok ? row.implicitWidth : 0
	height: Theme.barHeight
	visible: ok

	Row {
		id: row

		anchors.centerIn: parent
		spacing: 5

		IconImage {
			anchors.verticalCenter: parent.verticalCenter
			source: Theme.adwaitaIcon(root.iconName)
			implicitWidth: 16
			implicitHeight: 16
		}

		Text {
			anchors.verticalCenter: parent.verticalCenter
			anchors.verticalCenterOffset: 1
			text: root.temp
			color: Theme.fg
			font.family: Theme.sans
			font.pointSize: 9
		}
	}

	// Condition words from wttr.in's %C -> adwaita symbolic names.
	readonly property string iconName: {
		const c = cond.toLowerCase();
		if (c.includes("thunder") || c.includes("storm"))
			return "weather-storm-symbolic";
		if (c.includes("snow") || c.includes("sleet") || c.includes("hail"))
			return "weather-snow-symbolic";
		if (c.includes("shower") || c.includes("rain") || c.includes("drizzle"))
			return "weather-showers-symbolic";
		if (c.includes("fog") || c.includes("mist"))
			return "weather-fog-symbolic";
		if (c.includes("partly") || c.includes("cloudy with"))
			return "weather-few-clouds-symbolic";
		if (c.includes("cloud") || c.includes("overcast"))
			return "weather-overcast-symbolic";
		if (c.includes("sun") || c.includes("clear"))
			return "weather-clear-symbolic";
		return "weather-overcast-symbolic";
	}

	Process {
		id: fetchProcess

		// %C = condition text, %t = temperature; --max-time keeps a hung
		// network from pinning the loop. An empty read keeps the last
		// values.
		command: ["fish", "-c", "while true; curl -s --max-time 6 'https://wttr.in/"
			+ root.location + "?format=%C;%t'; echo; sleep 1800; end"]
		stdout: SplitParser {
			onRead: data => {
				const parts = data.trim().split(";");
				if (parts.length === 2 && parts[1].length > 0) {
					root.cond = parts[0].trim();
					root.temp = parts[1].trim().replace("+", "");
				}
			}
		}
	}

	Component.onCompleted: fetchProcess.running = true
}
