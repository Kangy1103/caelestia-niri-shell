pragma ComponentBehavior: Bound

import qs.services
import Quickshell
import Quickshell.Io

Scope {
    id: root

    IpcHandler {
        target: "calendar"

        function open(): void {
            const visibilities = Visibilities.getForActive()
            visibilities.calendar = true
        }

        function close(): void {
            const visibilities = Visibilities.getForActive()
            visibilities.calendar = false
        }

        function toggle(): void {
            const visibilities = Visibilities.getForActive()
            visibilities.calendar = !visibilities.calendar
        }
    }
}
