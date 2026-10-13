pragma ComponentBehavior: Bound

import qs.services
import Quickshell
import Quickshell.Io

Scope {
    id: root

    IpcHandler {
        target: "calendar-app"

        function open(): void {
            CalendarApp.open(root);
        }

        function close(): void {
            CalendarApp.close();
        }

        function toggle(): void {
            CalendarApp.toggle(root);
        }
    }
}
