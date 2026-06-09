pragma Singleton

import qs.services
import Quickshell

Singleton {
    property var screens: new Map()
    property var bars: new Map()

    function load(screen: ShellScreen, visibilities: var): void {
        screens.set(Niri.focusedMonitorName, visibilities);
    }

    function getForActive(): PersistentProperties {
        const targetName = Niri.focusedMonitorName;
        if (!targetName) return null;
        return screens.get(targetName) ?? null;
    }
}
