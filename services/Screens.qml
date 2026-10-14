pragma Singleton

import Quickshell
import CNS.Config

Singleton {
    id: root

    // CNS: stale ShellScreen copies become dangling during hotplug and expose
    // default values (including an empty name). Exclude them before resolving
    // per-screen config so a disconnect cannot create a bogus empty-name entry.
    readonly property list<ShellScreen> screens: Quickshell.screens.filter(s => s && s.name && GlobalConfig.forScreen(s.name).enabled)

    function isExcluded(screen: ShellScreen): bool {
        return !screen || !screen.name || !GlobalConfig.forScreen(screen.name).enabled;
    }
}
