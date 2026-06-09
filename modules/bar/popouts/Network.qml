// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.2-20260603

pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Item wrapper

    property string connectingToSsid: ""
    property string view: "wireless" // "wireless" or "ethernet"
    property var passwordNetwork: null
    property bool showPasswordDialog: false

    spacing: Config.appearance.spacing.small
    width: TokenConfig.sizes.bar.networkWidth

    ScriptModel {
        id: wifiNetworks
        values: [...Nmcli.networks].sort((a, b) => {
            if (a.active !== b.active)
                return b.active - a.active;
            return b.strength - a.strength;
        }).slice(0, 8)
    }

    ScriptModel {
        id: ethernetDevicesModel
        values: [...Nmcli.ethernetDevices].sort((a, b) => {
            if (a.connected !== b.connected)
                return b.connected - a.connected;
            return (a.interface || "").localeCompare(b.interface || "");
        }).slice(0, 8)
    }

    StyledText {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: Config.appearance.padding.medium
        Layout.rightMargin: Config.appearance.padding.extraSmall
        text: qsTr("Wifi %1").arg(Nmcli.wifiEnabled ? "enabled" : "disabled")
        font.weight: 500
    }

    Toggle {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        label: qsTr("Enabled")
        checked: Nmcli.wifiEnabled
        toggle.onToggled: Nmcli.enableWifi(checked)
    }

    StyledText {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: Config.appearance.spacing.small
        Layout.rightMargin: Config.appearance.padding.extraSmall
        text: qsTr("%1 networks available").arg(Nmcli.networks.length)
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Config.appearance.font.label.large.size
    }

    Repeater {
        model: root.view === "wireless" ? wifiNetworks : 0

        RowLayout {
            id: networkItem

            required property Nmcli.AccessPoint modelData
            readonly property bool isConnecting: root.connectingToSsid === modelData.ssid

            Layout.fillWidth: true
            Layout.rightMargin: Config.appearance.padding.extraSmall
            spacing: Config.appearance.spacing.small

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
            }

            MaterialIcon {
                text: Icons.getNetworkIcon(networkItem.modelData.strength)
                color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            MaterialIcon {
                visible: networkItem.modelData.isSecure
                text: "lock"
                fontStyle: Tokens.font.icon.size(Config.appearance.font.label.large.size).build()
}

            StyledText {
                Layout.leftMargin: Config.appearance.spacing.small / 2
                Layout.rightMargin: Config.appearance.spacing.small / 2
                Layout.fillWidth: true
                text: networkItem.modelData.ssid
                elide: Text.ElideRight
                font.weight: networkItem.modelData.active ? 500 : 400
                color: networkItem.modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: wirelessConnectIcon.implicitHeight + Config.appearance.padding.extraSmall

                radius: Config.appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, networkItem.modelData.active ? 1 : 0)

                StyledBusyIndicator {
                    anchors.fill: parent
                    running: networkItem.isConnecting
                }

                StateLayer {
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    disabled: networkItem.isConnecting || !Nmcli.wifiEnabled

                    function onClicked(): void {
                        if (networkItem.modelData.active) {
                            Nmcli.disconnectFromNetwork();
                        } else {
                            root.connectingToSsid = networkItem.modelData.ssid;
                            NetworkConnection.handleConnect(networkItem.modelData, null, network => {
                                // Password is required - show password popout
                                root.passwordNetwork = network;
                                root.showPasswordDialog = true;
                                root.wrapper.currentName = "wirelesspassword";
                            });
                        }
                    }
                }

                MaterialIcon {
                    id: wirelessConnectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: networkItem.modelData.active ? "link_off" : "link"
                    color: networkItem.modelData.active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    opacity: networkItem.isConnecting ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }
        }
    }

    StyledRect {
        visible: root.view === "wireless"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: Config.appearance.spacing.small
        Layout.fillWidth: true
        implicitHeight: rescanBtn.implicitHeight + Config.appearance.padding.extraSmall * 2

        radius: Config.appearance.rounding.full
        color: Colours.palette.m3primaryContainer

        StateLayer {
            color: Colours.palette.m3onPrimaryContainer
            disabled: Nmcli.scanning || !Nmcli.wifiEnabled

            function onClicked(): void {
                Nmcli.rescanWifi();
            }
        }

        RowLayout {
            id: rescanBtn

            anchors.centerIn: parent
            spacing: Config.appearance.spacing.small
            opacity: Nmcli.scanning ? 0 : 1

            MaterialIcon {
                id: scanIcon

                animate: true
                text: "wifi_find"
                color: Colours.palette.m3onPrimaryContainer
            }

            StyledText {
                text: qsTr("Rescan networks")
                color: Colours.palette.m3onPrimaryContainer
            }

            Behavior on opacity {
                Anim {}
            }
        }

        StyledBusyIndicator {
            anchors.centerIn: parent
            strokeWidth: Config.appearance.padding.extraSmall / 2
            bgColour: "transparent"
            implicitHeight: parent.implicitHeight - Config.appearance.padding.small * 2
            running: Nmcli.scanning
        }
    }

    // Ethernet section
    StyledText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Config.appearance.padding.medium : 0
        Layout.rightMargin: Config.appearance.padding.extraSmall
        text: qsTr("Ethernet")
        font.weight: 500
    }

    StyledText {
        visible: root.view === "ethernet"
        Layout.preferredHeight: visible ? implicitHeight : 0
        Layout.topMargin: visible ? Config.appearance.spacing.small : 0
        Layout.rightMargin: Config.appearance.padding.extraSmall
        text: qsTr("%1 devices available").arg(Nmcli.ethernetDevices.length)
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Config.appearance.font.label.large.size
    }

    Repeater {
        visible: root.view === "ethernet"
        model: root.view === "ethernet" ? ethernetDevicesModel : 0

        RowLayout {
            id: ethItem
            required property var modelData
            readonly property bool loading: false

            Layout.fillWidth: true
            Layout.rightMargin: Config.appearance.padding.extraSmall
            spacing: Config.appearance.spacing.small

            opacity: 0
            scale: 0.7

            Component.onCompleted: {
                opacity = 1;
                scale = 1;
            }

            Behavior on opacity {
                Anim {}
            }

            Behavior on scale {
                Anim {}
            }

            MaterialIcon {
                text: "cable"
                color: ethItem.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }

            StyledText {
                Layout.leftMargin: Config.appearance.spacing.small / 2
                Layout.rightMargin: Config.appearance.spacing.small / 2
                Layout.fillWidth: true
                text: ethItem.modelData.connection || ethItem.modelData.interface || qsTr("Unknown")
                elide: Text.ElideRight
                font.weight: ethItem.modelData.connected ? 500 : 400
                color: ethItem.modelData.connected ? Colours.palette.m3primary : Colours.palette.m3onSurface
            }

            StyledRect {
                implicitWidth: implicitHeight
                implicitHeight: connectIcon.implicitHeight + Config.appearance.padding.extraSmall

                radius: Config.appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, ethItem.modelData.connected ? 1 : 0)

                StyledBusyIndicator {
                    anchors.fill: parent
                    running: ethItem.loading
                }

                StateLayer {
                    color: ethItem.modelData.connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    disabled: ethItem.loading

                    function onClicked(): void {
                        if (ethItem.modelData.connected && ethItem.modelData.connection) {
                            Nmcli.disconnectEthernet(ethItem.modelData.connection, () => {});
                        } else {
                            Nmcli.connectEthernet(ethItem.modelData.connection || "", ethItem.modelData.interface || "", () => {});
                        }
                    }
                }

                MaterialIcon {
                    id: connectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: ethItem.modelData.connected ? "link" : "link_off"
                    color: ethItem.modelData.connected ? "#131317" : Colours.palette.m3onSurfaceVariant
                    fill: 1

                    opacity: ethItem.loading ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }
        }
    }

    // Reset connecting state when network changes
    Connections {
        target: Nmcli

        function onActiveChanged(): void {
            if (Nmcli.active && root.connectingToSsid === Nmcli.active.ssid) {
                root.connectingToSsid = "";
                // Close password dialog if we successfully connected
                if (root.showPasswordDialog && root.passwordNetwork && Nmcli.active.ssid === root.passwordNetwork.ssid) {
                    root.showPasswordDialog = false;
                    root.passwordNetwork = null;
                    if (root.wrapper.currentName === "wirelesspassword") {
                        root.wrapper.currentName = "network";
                    }
                }
            }
        }

        function onConnectionFailed(ssid): void {
            if (root.connectingToSsid === ssid) {
                root.connectingToSsid = "";
            }
        }

        function onScanningChanged(): void {
            if (!Nmcli.scanning)
                scanIcon.rotation = 0;
        }
    }

    Connections {
        function onCurrentNameChanged(): void {
            // Clear password network when leaving password dialog
            if (root.wrapper.currentName !== "wirelesspassword" && root.showPasswordDialog) {
                root.showPasswordDialog = false;
                root.passwordNetwork = null;
            }
        }

        target: root.wrapper
    }

    component Toggle: RowLayout {
        required property string label
        property alias checked: toggle.checked
        property alias toggle: toggle

        Layout.fillWidth: true
        Layout.rightMargin: Config.appearance.padding.extraSmall
        spacing: Config.appearance.spacing.large

        StyledText {
            Layout.fillWidth: true
            text: parent.label
        }

        StyledSwitch {
            id: toggle
        }
    }
}
