pragma Singleton

import Quickshell
import Quickshell.Io
import Caelestia
import QtQuick

Singleton {
    id: root

    property string sinkName: ""
    property string activePort: ""
    property bool ready: false

    readonly property var ports: [
        { id: "analog-output-lineout", name: "Line Out" },
        { id: "analog-output-headphones", name: "Headphones" }
    ]

    function toggle(): void {
        if (!root.ready) return;
        const next = root.activePort === ports[0].id ? ports[1].id : ports[0].id;
        setPort(next);
    }

    function lineout(): void {
        if (!root.ready) return;
        setPort("analog-output-lineout");
    }

    function headphones(): void {
        if (!root.ready) return;
        setPort("analog-output-headphones");
    }

    function setPort(port: string): void {
        root.activePort = port;
        toggleProc.command = ["pactl", "set-sink-port", root.sinkName, port];
        toggleProc.running = true;

        const portName = ports.find(p => p.id === port)?.name ?? port;
        Toaster.toast(qsTr("Audio port switched"), qsTr("Now using: %1").arg(portName), "headphones");
    }

    Process {
        id: initProc
        running: true
        command: ["sh", "-c", "SINK=$(pactl get-default-sink); PORT=$(pactl list sinks | awk -v s=\"$SINK\" 'index($0, \"Name: \" s) > 0 {f=1} f && /Active Port:/ {gsub(/[ \\t]/, \"\", $NF); print $NF; exit}'); echo \"$SINK|$PORT\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split("|");
                if (parts.length >= 2) {
                    root.sinkName = parts[0];
                    root.activePort = parts[1];
                    root.ready = true;
                }
            }
        }
    }

    Process {
        id: toggleProc
    }

    IpcHandler {
        target: "audioPort"

        function toggle(): void {
            root.toggle();
        }

        function lineout(): void {
            root.lineout();
        }

        function headphones(): void {
            root.headphones();
        }
    }
}
