// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.3.0-20260621

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property var sessions: ListModel { id: sessionsModel }
    readonly property int count: sessionsModel.count

    property int currentIndex: 0
    property string selectedSession: ""
    property string selectedSessionPath: ""
    property bool ready: false

    function finalizeSelection() {
        if (currentIndex >= 0 && currentIndex < sessionsModel.count) {
            selectedSession = sessionsModel.get(currentIndex).exec;
            selectedSessionPath = sessionsModel.get(currentIndex).path;
        }
    }

    function selectSession(name) {
        for (var i = 0; i < sessionsModel.count; i++) {
            if (sessionsModel.get(i).name === name) {
                currentIndex = i;
                finalizeSelection();
                return;
            }
        }
    }

    property var _buf: ""

    Process {
        id: scanProc

        command: [
            "sh", "-c",
            `for dir in /usr/share/wayland-sessions /usr/share/xsessions /usr/local/share/wayland-sessions /usr/local/share/xsessions; do
                [ -d "$dir" ] && for f in "$dir"/*.desktop; do
                    [ -f "$f" ] || continue;
                    name=$(sed -n 's/^Name=//p' "$f" | head -1);
                    exec=$(sed -n 's/^Exec=//p' "$f" | head -1);
                    [ -n "$name" ] && [ -n "$exec" ] && printf '%s|%s|%s\\n' "$name" "$exec" "$f";
                done;
            done`
        ]

        stdout: SplitParser {
            onRead: line => {
                root._buf += line + "\n";
            }
        }

        onExited: {
            var seen = {};
            var lines = root._buf.trim().split("\n");
            root._buf = "";

            for (var i = 0; i < lines.length; i++) {
                if (!lines[i]) continue;
                var parts = lines[i].split("|");
                if (parts.length >= 3) {
                    var name = parts[0];
                    var exec = parts[1];
                    var path = parts[2];
                    if (!seen[name]) {
                        seen[name] = true;
                        sessionsModel.append({ name: name, exec: exec, path: path });
                    }
                }
            }

            root.ready = true;
            root.finalizeSelection();
            console.info("SessionsService: loaded", sessionsModel.count, "sessions");
        }

        running: true
    }
}
