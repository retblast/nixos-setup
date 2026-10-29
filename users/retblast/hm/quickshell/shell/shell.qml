//@ pragma UseQApplication
import Quickshell
import Quickshell.Hyprland

ShellRoot {
    id: root

    // The main display: the external screen with the EDID description
    // "CRT HDMI" when it is connected, the focused monitor otherwise.
    // The bar and the dock follow it, so unplugging the external screen
    // moves them back to the laptop instead of leaving them on a screen
    // that is gone.
    readonly property var mainScreen: {
        const monitors = Hyprland.monitors.values;
        let main = null;
        for (const monitor of monitors) {
            if (monitor.description === "CRT HDMI") {
                main = monitor;
                break;
            }
        }
        if (!main)
            main = Hyprland.focusedMonitor;
        if (!main)
            return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
        for (const screen of Quickshell.screens) {
            if (screen.name === main.name)
                return screen;
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    // The screen that has the keyboard focus. The transient windows
    // follow it, so an indicator or an overlay shows up where the user
    // is working.
    readonly property var focusedScreen: {
        const monitor = Hyprland.focusedMonitor;
        if (!monitor)
            return root.mainScreen;
        for (const screen of Quickshell.screens) {
            if (screen.name === monitor.name)
                return screen;
        }
        return root.mainScreen;
    }

    Bar {
        screen: root.mainScreen
    }

    Dock {
        screen: root.mainScreen
    }

    OSD {
        screen: root.focusedScreen
    }

    Toasts {
        targetScreen: root.focusedScreen
    }

    Overview {
        screen: root.focusedScreen
    }

    NotifCenter {
        screen: root.focusedScreen
    }

    QuickSettings {
        screen: root.focusedScreen
    }
}
