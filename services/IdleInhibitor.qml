pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property alias enabled: props.enabled
    readonly property alias enabledSince: props.enabledSince

    onEnabledChanged: {
        if (enabled)
            props.enabledSince = new Date();
    }

    PersistentProperties {
        id: props

        property bool enabled
        property date enabledSince

        reloadableId: "idleInhibitor"
    }

    // Gate the IdleInhibitor element + its PanelWindow behind a Loader so the
    // compositor idle inhibitor is only registered while actually enabled.
    // Otherwise the window's wayland surface registers an inhibitor on load,
    // which suppresses ext-idle-notify for the whole session (breaks idle lock).
    Loader {
        active: props.enabled
        sourceComponent: Component {
            IdleInhibitor {
                enabled: true
                window: PanelWindow {
                    implicitWidth: 0
                    implicitHeight: 0
                    color: "transparent"
                    mask: Region {}
                }
            }
        }
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        target: "idleInhibitor"
    }
}
