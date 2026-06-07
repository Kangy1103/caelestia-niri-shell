pragma Singleton

import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string niriConfig: `${Paths.home}/.config/niri/config.kdl`
    readonly property string scriptsDir: `${Quickshell.shellDir}/modules/keybinds/scripts`
    readonly property string stateDir: `${Paths.state}/keybinds`
    readonly property string cacheFile: `${stateDir}/keybinds.json`

    property var keybinds: []
    property bool loading: false
    property bool initialized: false
    property string error: ""

    function refresh(): void {
        loading = true;
        generator.running = true;
    }

    Component.onCompleted: {
        createStateDir.running = true;
    }

    Process {
        id: createStateDir
        command: ["mkdir", "-p", root.stateDir]
        onExited: {
            root.refresh();
        }
    }

    Process {
        id: generator

        command: [
            "sh", "-c",
            `set -o pipefail; python3 '${root.scriptsDir}/expand.py' | ` +
            `python3 '${root.scriptsDir}/extract_binds.py' | ` +
            `python3 '${root.scriptsDir}/dedupe_binds.py' | ` +
            `python3 '${root.scriptsDir}/pretty_print_binds.py' > '${root.cacheFile}'`
        ]

        onExited: (code, exitStatus) => {
            root.loading = false;
            if (code === 0) {
                root.error = "";
                cacheFileView.reload();
            } else {
                root.error = qsTr("Failed to generate keybinds");
            }
        }
    }

    FileView {
        id: cacheFileView
        path: root.cacheFile
        watchChanges: true

        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.keybinds = data;
                root.initialized = true;
                root.error = "";
            } catch (e) {
                root.keybinds = [];
                root.error = qsTr("Failed to parse keybinds");
            }
        }
    }
}
