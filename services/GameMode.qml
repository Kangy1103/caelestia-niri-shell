pragma Singleton

import qs.services
import Caelestia.Config
import Caelestia
import Quickshell
import Quickshell.Io
import QtQuick

// Ported from upstream caelestia-dots/shell GameMode.qml (GPL-3.0)
// Adapted for Niri (no Hyprland dynamic config — uses include file toggle instead)
// and CNS shell module GPU reduction.
Singleton {
    id: root

    property alias enabled: props.enabled

    readonly property string templatePath: "/home/kangy/.config/niri/cns/gaming.kdl.template"
    readonly property string activePath: "/home/kangy/.config/niri/cns/gaming.kdl"

    onEnabledChanged: {
        if (enabled) {
            writeRunner.running = true;
            if (Config.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Gaming mode enabled"), qsTr("Niri animations + blur disabled, shell effects reduced"), "sports_esports");
        } else {
            cleanupRunner.running = true;
            if (Config.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Gaming mode disabled"), qsTr("Niri settings and shell effects restored"), "sports_esports");
        }
    }

    Process {
        id: writeRunner
        command: ["cp", root.templatePath, root.activePath]
        running: false
    }

    Process {
        id: cleanupRunner
        command: ["rm", "-f", root.activePath]
        running: false
    }

    PersistentProperties {
        id: props

        property bool enabled

        reloadableId: "gameMode"
    }

    IpcHandler {
        target: "gameMode"

        function isEnabled(): bool {
            return root.enabled;
        }

        function toggle(): void {
            root.enabled = !root.enabled;
        }

        function enable(): void {
            root.enabled = true;
        }

        function disable(): void {
            root.enabled = false;
        }
    }
}
