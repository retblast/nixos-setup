pragma Singleton
import QtQuick
import Quickshell

// Palette + type tokens for the greeter. The greeter runs as the
// "greeter" user and cannot read the user's generated Theme.qml, so the
// values are duplicated here on purpose. Keep in sync with retTheme
// (users/retblast/hm/shell-theme.nix).
Singleton {
	readonly property color bg: "#1d1d20"
	readonly property color bgAlt: "#252529"
	readonly property color fg: "#ffffff"
	readonly property color fgDim: "#b8b8bd"
	readonly property color accent: "#3584e4"
	readonly property color border: "#3a3a40"
	readonly property string sans: "SF Pro Text"
}
