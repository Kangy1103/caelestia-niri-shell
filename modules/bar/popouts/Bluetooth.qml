pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import qs.utils
import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Item wrapper

    width: 300
    spacing: Config.appearance.spacing.small

    StyledText {
        Layout.topMargin: Config.appearance.padding.medium
        Layout.rightMargin: Config.appearance.padding.extraSmall
        text: qsTr("Bluetooth %1").arg(BluetoothAdapterState.toString(Bluetooth.defaultAdapter?.state).toLowerCase())
        font.weight: 500
    }

    Toggle {
        label: qsTr("Enabled")
        checked: Bluetooth.defaultAdapter?.enabled ?? false
        toggle.onToggled: {
            const adapter = Bluetooth.defaultAdapter;
            if (adapter)
                adapter.enabled = checked;
        }
    }

    Toggle {
        label: qsTr("Discovering")
        checked: Bluetooth.defaultAdapter?.discovering ?? false
        toggle.onToggled: {
            const adapter = Bluetooth.defaultAdapter;
            if (adapter)
                adapter.discovering = checked;
        }
    }

    StyledText {
        Layout.topMargin: Config.appearance.spacing.small
        Layout.rightMargin: Config.appearance.padding.extraSmall
        text: {
            const devices = Bluetooth.devices.values;
            let available = qsTr("%1 device%2 available").arg(devices.length).arg(devices.length === 1 ? "" : "s");
            const connected = devices.filter(d => d.connected).length;
            if (connected > 0)
                available += qsTr(" (%1 connected)").arg(connected);
            return available;
        }
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Config.appearance.font.label.large.size
    }

    Repeater {
        model: ScriptModel {
            values: [...Bluetooth.devices.values].sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired)).slice(0, 5)
        }

        RowLayout {
            id: device

            required property BluetoothDevice modelData
            readonly property bool loading: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting

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
                text: Icons.getBluetoothIcon(device.modelData.icon)
            }

            StyledText {
                Layout.leftMargin: Config.appearance.spacing.small / 2
                Layout.rightMargin: Config.appearance.spacing.small / 2
                Layout.fillWidth: true
                text: device.modelData.name
                elide: Text.ElideRight
            }

            MaterialIcon {
                visible: device.modelData.state === BluetoothDeviceState.Connected // qmllint disable unresolved-type
                text: Icons.getBatteryIcon(device.modelData.batteryAvailable ? device.modelData.battery * 100 : -1)
                color: device.modelData.battery < 0.2 ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
            }

            StyledRect {
                id: connectBtn

                implicitWidth: implicitHeight
                implicitHeight: connectIcon.implicitHeight + Config.appearance.padding.extraSmall

                radius: Config.appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, device.modelData.state === BluetoothDeviceState.Connected ? 1 : 0)

                StyledBusyIndicator {
                    anchors.fill: parent
                    running: device.loading
                }

                StateLayer {
                    color: device.modelData.state === BluetoothDeviceState.Connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    disabled: device.loading

                    function onClicked(): void {
                        device.modelData.connected = !device.modelData.connected;
                    }
                }

                MaterialIcon {
                    id: connectIcon

                    anchors.centerIn: parent
                    animate: true
                    text: device.modelData.connected ? "link_off" : "link"
                    color: device.modelData.state === BluetoothDeviceState.Connected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

                    opacity: device.loading ? 0 : 1

                    Behavior on opacity {
                        Anim {}
                    }
                }
            }

            Loader {
                visible: status === Loader.Ready
                asynchronous: true
                active: device.modelData.bonded
                sourceComponent: Item {
                    implicitWidth: connectBtn.implicitWidth
                    implicitHeight: connectBtn.implicitHeight

                    StateLayer {
                        radius: Config.appearance.rounding.full

                        function onClicked(): void {
                            device.modelData.forget();
                        }
                    }

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "delete"
                    }
                }
            }
        }
    }

    StyledRect {
        Layout.topMargin: Config.appearance.spacing.small
        implicitWidth: expandBtn.implicitWidth + Config.appearance.padding.medium * 2
        implicitHeight: expandBtn.implicitHeight + Config.appearance.padding.extraSmall

        radius: Config.appearance.rounding.large
        color: Colours.palette.m3primaryContainer

        StateLayer {
            color: Colours.palette.m3onPrimaryContainer

            function onClicked(): void {
                root.wrapper.detach("bluetooth");
            }
        }

        RowLayout {
            id: expandBtn

            anchors.centerIn: parent
            spacing: Config.appearance.spacing.small

            StyledText {
                Layout.leftMargin: Config.appearance.padding.small
                text: qsTr("Settings")
                color: Colours.palette.m3onPrimaryContainer
            }

            MaterialIcon {
                text: "chevron_right"
                color: Colours.palette.m3onPrimaryContainer
                fontStyle: Tokens.font.icon.size(Config.appearance.font.title.medium.size).build()
}
        }
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
