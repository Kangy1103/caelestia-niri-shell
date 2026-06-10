pragma Singleton

import qs.services
import Quickshell

Singleton {
    property var screens: ({})
    property var bars: new Map()
    property string launcherMode: ""

    function load(screen: ShellScreen, visibilities: var): void {
        screens[screen.name] = visibilities;
    }

    function getForActive(): PersistentProperties {
        const targetName = Niri.focusedMonitorName;
        if (!targetName) return null;
        return screens[targetName] ?? null;
    }
}
