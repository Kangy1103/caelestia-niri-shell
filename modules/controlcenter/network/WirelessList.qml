pragma ComponentBehavior: Bound

import ".."
import "../components"
import "."
import qs.components
import qs.components.controls
import qs.components.containers
import qs.components.effects
import qs.services
import Caelestia.Config
import qs.utils
import Quickshell
import QtQuick
import QtQuick.Layouts

DeviceList {
    id: root

    required property Session session

    title: qsTr("Networks (%1)").arg(Nmcli.networks.length)
    description: qsTr("All available WiFi networks")
    activeItem: session.network.active

    titleSuffix: Component {
        StyledText {
            visible: Nmcli.scanning
            text: qsTr("Scanning...")
            color: Colours.palette.m3primary
            font.pointSize: Config.appearance.font.label.large.size
        }
    }

    model: ScriptModel {
        values: [...Nmcli.networks].sort((a, b) => {
            if (a.active !== b.active)
                return b.active - a.active;
            return b.strength - a.strength;
        })
    }

    headerComponent: Component {
        RowLayout {
            spacing: Config.appearance.spacing.medium

            StyledText {
                text: qsTr("Settings")
                font.pointSize: Config.appearance.font.title.medium.size
                font.weight: 500
            }

            Item {
                Layout.fillWidth: true
            }

            ToggleButton {
                toggled: Nmcli.wifiEnabled
                icon: "wifi"
                accent: "Tertiary"
                iconSize: Config.appearance.font.body.medium.size
                horizontalPadding: Config.appearance.padding.medium
                verticalPadding: Config.appearance.padding.small

                onClicked: {
                    Nmcli.toggleWifi(null);
                }
            }

            ToggleButton {
                toggled: Nmcli.scanning
                icon: "wifi_find"
                accent: "Secondary"
                iconSize: Config.appearance.font.body.medium.size
                horizontalPadding: Config.appearance.padding.medium
                verticalPadding: Config.appearance.padding.small

                onClicked: {
                    Nmcli.rescanWifi();
                }
            }

            ToggleButton {
                toggled: !root.session.network.active
                icon: "settings"
                accent: "Primary"
                iconSize: Config.appearance.font.body.medium.size
                horizontalPadding: Config.appearance.padding.medium
                verticalPadding: Config.appearance.padding.small

                onClicked: {
                    if (root.session.network.active)
                        root.session.network.active = null;
                    else {
                        root.session.network.active = root.view.model.get(0)?.modelData ?? null;
                    }
                }
            }
        }
    }

    delegate: Component {
        StyledRect {
            required property var modelData

            width: ListView.view ? ListView.view.width : undefined

            color: Qt.alpha(Colours.tPalette.m3surfaceContainer, root.activeItem === modelData ? Colours.tPalette.m3surfaceContainer.a : 0)
            radius: Config.appearance.rounding.large

            StateLayer {
                function onClicked(): void {
                    root.session.network.active = modelData;
                    if (modelData && modelData.ssid) {
                        root.checkSavedProfileForNetwork(modelData.ssid);
                    }
                }
            }

            RowLayout {
                id: rowLayout

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Config.appearance.padding.medium

                spacing: Config.appearance.spacing.large

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: icon.implicitHeight + Config.appearance.padding.medium * 2

                    radius: Config.appearance.rounding.large
                    color: modelData.active ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainerHigh

                    MaterialIcon {
                        id: icon

                        anchors.centerIn: parent
                        text: Icons.getNetworkIcon(modelData.strength, modelData.isSecure)
                        font.pointSize: Config.appearance.font.title.medium.size
                        fill: modelData.active ? 1 : 0
                        color: modelData.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        maximumLineCount: 1

                        text: modelData.ssid || qsTr("Unknown")
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Config.appearance.spacing.medium

                        StyledText {
                            Layout.fillWidth: true
                            text: {
                                if (modelData.active)
                                    return qsTr("Connected");
                                if (modelData.isSecure && modelData.security && modelData.security.length > 0) {
                                    return modelData.security;
                                }
                                if (modelData.isSecure)
                                    return qsTr("Secured");
                                return qsTr("Open");
                            }
                            color: modelData.active ? Colours.palette.m3primary : Colours.palette.m3outline
                            font.pointSize: Config.appearance.font.label.large.size
                            font.weight: modelData.active ? 500 : 400
                            elide: Text.ElideRight
                        }
                    }
                }

                StyledRect {
                    implicitWidth: implicitHeight
                    implicitHeight: connectIcon.implicitHeight + Config.appearance.padding.small * 2

                    radius: Config.appearance.rounding.full
                    color: Qt.alpha(Colours.palette.m3primaryContainer, modelData.active ? 1 : 0)

                    StateLayer {
                        function onClicked(): void {
                            if (modelData.active) {
                                Nmcli.disconnectFromNetwork();
                            } else {
                                NetworkConnection.handleConnect(modelData, root.session, null);
                            }
                        }
                    }

                    MaterialIcon {
                        id: connectIcon

                        anchors.centerIn: parent
                        text: modelData.active ? "link_off" : "link"
                        color: modelData.active ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                    }
                }
            }

            implicitHeight: rowLayout.implicitHeight + Config.appearance.padding.medium * 2
        }
    }

    onItemSelected: function (item) {
        session.network.active = item;
        if (item && item.ssid) {
            checkSavedProfileForNetwork(item.ssid);
        }
    }

    function checkSavedProfileForNetwork(ssid: string): void {
        if (ssid && ssid.length > 0) {
            Nmcli.loadSavedConnections(() => {});
        }
    }
}
