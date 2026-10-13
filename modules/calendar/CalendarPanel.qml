pragma ComponentBehavior: Bound

import qs.services
import Quickshell
import Quickshell.Io

Scope {
    id: root

    IpcHandler {
        target: "calendar"

        function open(): void {
            const screenState = ShellState.forActive()
            screenState.calendar = true
        }

        function close(): void {
            const screenState = ShellState.forActive()
            screenState.calendar = false
        }

        function toggle(): void {
            const screenState = ShellState.forActive()
            screenState.calendar = !screenState.calendar
        }
    }
}
