pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // All bars share the full response, including the detailed tooltip.
    property var info: ({})
    readonly property string state: info.alt ?? "idle_waiting"
    readonly property string profile: info.profile ?? "default"
    readonly property string tooltip: info.tooltip ?? "Stasis: waiting"

    function toggleInhibit(): void {
        info = Object.assign({}, info, {
            alt: state === "manually_inhibited" ? "idle_waiting" : "manually_inhibited"
        });
        Quickshell.execDetached(["/usr/bin/stasis", "toggle-inhibit"]);
    }

    function selectProfile(name: string): void {
        info = Object.assign({}, info, { profile: name });
        Quickshell.execDetached(["/usr/bin/stasis", "profile", name]);
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!poll.running) poll.running = true
    }

    Process {
        id: poll
        command: ["/usr/bin/stasis", "info", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const next = JSON.parse(text.trim());
                    if (next && typeof next === "object" && !Array.isArray(next))
                        root.info = next;
                } catch (error) {
                    // Keep the last complete status if the daemon is restarting.
                }
            }
        }
    }
}
