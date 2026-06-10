pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    readonly property real iconFontSize: 32

    implicitHeight: togglesRow.implicitHeight + Config.appearance.padding.medium * 2
    implicitWidth: togglesRow.implicitWidth + Config.appearance.padding.medium * 2
    radius: Config.appearance.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    RowLayout {
        id: togglesRow
        anchors.centerIn: parent
        spacing: Config.appearance.spacing.largeIncreased

        Toggle {
            icon: "wifi"
            font.pointSize: root.iconFontSize
            checked: Network.wifiEnabled
            visible: Config.dashboard.toggles?.showWifi ?? true
            onClicked: Network.toggleWifi()
        }

        Toggle {
            icon: "bluetooth"
            font.pointSize: root.iconFontSize
            checked: Bluetooth.defaultAdapter?.enabled ?? false
            visible: Config.dashboard.toggles?.showBluetooth ?? true
            onClicked: {
                const adapter = Bluetooth.defaultAdapter;
                if (adapter)
                    adapter.enabled = !adapter.enabled;
            }
        }

        Toggle {
            icon: "mic"
            font.pointSize: root.iconFontSize
            checked: !Audio.sourceMuted
            visible: Config.dashboard.toggles?.showMic ?? true
            onClicked: {
                const audio = Audio.source?.audio;
                if (audio)
                    audio.muted = !audio.muted;
            }
        }

        Toggle {
            icon: "vpn_key"
            font.pointSize: root.iconFontSize
            checked: VPN.connected
            enabled: !VPN.connecting
            visible: (Config.dashboard.toggles?.showVpn ?? true) && Config.utilities.vpn.provider.some(p => typeof p === "object" ? (p.enabled === true) : false)
            onClicked: VPN.toggle()
        }

        Toggle {
            icon: "do_not_disturb_on"
            font.pointSize: root.iconFontSize
            checked: Notifs.dnd
            visible: Config.dashboard.toggles?.showDnd ?? true
            onClicked: Notifs.dnd = !Notifs.dnd
        }

        Toggle {
            icon: "sports_esports"
            font.pointSize: root.iconFontSize
            checked: GameMode.enabled
            visible: Config.dashboard.toggles?.showGameMode ?? true
            onClicked: GameMode.toggle()
        }

        Toggle {
            icon: "settings"
            font.pointSize: root.iconFontSize
            inactiveOnColour: Colours.palette.m3onSurfaceVariant
            visible: Config.dashboard.toggles?.showSettings ?? true
            onClicked: Quickshell.execDetached(["qs", "-c", "caelestia-niri-shell", "ipc", "call", "controlCenter", "open"])
        }
    }
}
