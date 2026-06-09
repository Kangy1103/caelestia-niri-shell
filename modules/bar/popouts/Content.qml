// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260603

pragma ComponentBehavior: Bound

import qs.components
import Caelestia.Config
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

Item {
    id: root

    required property Item wrapper

    anchors.centerIn: parent

    implicitWidth: (content.children.find(c => c.shouldBeActive)?.implicitWidth ?? 0) + Config.appearance.padding.largeIncreased * 2
    implicitHeight: (content.children.find(c => c.shouldBeActive)?.implicitHeight ?? 0) + Config.appearance.padding.largeIncreased * 2

    // Persistent storage for the password network - survives network popout deactivation
    property var pendingPasswordNetwork: null

    Item {
        id: content

        anchors.fill: parent
        anchors.margins: Config.appearance.padding.largeIncreased

        Popout {
            name: "wsWindow"
            sourceComponent:
            // Bind y to currentCenter for dynamic following
            WsContextPopout {}
        }

        Popout {
            id: networkPopout

            name: "network"
            sourceComponent: Network {
                wrapper: root.wrapper
                view: "wireless"
                onPasswordNetworkChanged: {
                    // Capture network to persistent storage whenever it changes
                    if (passwordNetwork) {
                        root.pendingPasswordNetwork = passwordNetwork;
                    }
                }
            }
        }

        Popout {
            name: "ethernet"
            sourceComponent: Network {
                wrapper: root.wrapper
                view: "ethernet"
            }
        }

        Popout {
            id: passwordPopout

            name: "wirelesspassword"
            sourceComponent: WirelessPassword {
                wrapper: root.wrapper
                // Use the persistent copy, not a binding to the network popout's item
                network: root.pendingPasswordNetwork
            }
        }

        Popout {
            name: "bluetooth"
            sourceComponent: Bluetooth {
                wrapper: root.wrapper
            }
        }

        Popout {
            name: "battery"
            source: "Battery.qml"
        }

        Popout {
            name: "audio"
            sourceComponent: Audio {
                wrapper: root.wrapper
            }
        }

        Popout {
            name: "kblayout"
            source: "KbLayout.qml"
        }

        Popout {
            name: "lockstatus"
            source: "LockStatus.qml"
        }

        Popout {
            name: "stasis"
            source: "Stasis.qml"
        }

        Repeater {
            model: ScriptModel {
                values: [...SystemTray.items.values]
            }

            Popout {
                id: trayMenu

                required property SystemTrayItem modelData
                required property int index

                name: `traymenu${index}`
                sourceComponent: trayMenuComp

                Connections {
                    target: root.wrapper

                    function onHasCurrentChanged(): void {
                        if (root.wrapper.hasCurrent && trayMenu.shouldBeActive) {
                            trayMenu.sourceComponent = null;
                            trayMenu.sourceComponent = trayMenuComp;
                        }
                    }
                }

                Component {
                    id: trayMenuComp

                    TrayMenu {
                        popouts: root.wrapper
                        trayItem: trayMenu.modelData.menu
                    }
                }
            }
        }
    }

    component Popout: Loader {
        id: popout

        required property string name
        property bool shouldBeActive: root.wrapper.currentName === name

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right

        asynchronous: true
        opacity: 0
        scale: 0.8
        active: false

        states: State {
            name: "active"
            when: popout.shouldBeActive

            PropertyChanges {
                popout.active: true
                popout.opacity: 1
                popout.scale: 1
            }
        }

        transitions: [
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    Anim {
                        properties: "opacity,scale"
                        duration: Config.appearance.anim.durations.small
                    }
                    PropertyAction {
                        target: popout
                        property: "active"
                    }
                }
            },
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        target: popout
                        property: "active"
                    }
                    Anim {
                        properties: "opacity,scale"
                    }
                }
            }
        ]
    }
}
