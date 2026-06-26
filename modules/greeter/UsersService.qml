// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.3.0-20260621

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property var users: ListModel { id: usersModel }
    readonly property int count: usersModel.count
    property bool ready: false

    function displayName(username) {
        for (var i = 0; i < usersModel.count; i++) {
            if (usersModel.get(i).username === username)
                return usersModel.get(i).displayName;
        }
        return username;
    }

    function usernameForDisplay(display) {
        for (var i = 0; i < usersModel.count; i++) {
            if (usersModel.get(i).displayName === display)
                return usersModel.get(i).username;
        }
        return display;
    }

    Process {
        id: userProcess

        command: ["getent", "passwd"]

        stdout: SplitParser {
            onRead: line => {
                var parts = line.split(":");
                if (parts.length < 7) return;
                var uid = parseInt(parts[2]);
                var shell = parts[6];
                var home = parts[5];
                if (uid >= 1000 && uid < 60000
                    && parts[0] !== "nobody"
                    && !shell.endsWith("nologin") && !shell.endsWith("false")
                    && home !== "/var/empty") {
                    var gecos = parts[4] || "";
                    usersModel.append({
                        username: parts[0],
                        uid: uid,
                        gecos: gecos,
                        home: home,
                        shell: shell,
                        displayName: gecos.trim().length > 0 ? gecos.trim() : parts[0]
                    });
                }
            }
        }

        onExited: {
            root.ready = true;
            console.info("UsersService: loaded", usersModel.count, "users");
        }

        running: true
    }
}
