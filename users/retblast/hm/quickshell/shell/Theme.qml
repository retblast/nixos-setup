pragma Singleton
import Quickshell

// Generated from users/retblast/hm/shell-theme.nix (retTheme).
// Regenerated on every rebuild; do not edit here.
Singleton {
    id: root

    property string sans: "SF Pro Text"
    property int sansSize: 10
    property string mono: "SF Mono"
    property int monoSize: 10

    property string bg: "#1d1d20"
    property string bgAlt: "#242428"
    property string fg: "#ffffff"
    property string fgDim: "#9a9a9f"
    property string accent: "#3584e4"
    property string urgent: "#e01b24"
    property string border: "rgba(53, 132, 228, 0.7)"

    readonly property int barHeight: 34
    readonly property int dockHeight: 56
}
