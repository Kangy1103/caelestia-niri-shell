pragma ComponentBehavior: Bound

import qs.services
import Quickshell
import Quickshell.Io

Scope {
    id: root

    IpcHandler {
        target: "keybinds"

        function open(): void {
            const visibilities = Visibilities.getForActive()
            visibilities.keybinds = true
        }

        function close(): void {
            const visibilities = Visibilities.getForActive()
            visibilities.keybinds = false
        }

        function toggle(): void {
            const visibilities = Visibilities.getForActive()
            visibilities.keybinds = !visibilities.keybinds
        }
    }
}
