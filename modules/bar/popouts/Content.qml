// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.2.0-20260610

pragma ComponentBehavior: Bound

import "./kblayout"
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Caelestia.Config
import qs.components

Item {
    id: root

    required property Item wrapper
    readonly property PopoutState popouts: root.wrapper ? root.wrapper.popoutState : null
    readonly property Popout currentPopout: content.children.find(c => c.shouldBeActive) ?? null
    readonly property Item current: currentPopout?.item ?? null

    readonly property real margin: Config.appearance.padding.largeIncreased
    implicitWidth: (currentPopout?.implicitWidth ?? 0) + margin
    implicitHeight: (currentPopout?.implicitHeight ?? 0) + margin

    Item {
        id: content

        anchors.fill: parent
        anchors.margins: Config.appearance.padding.large

        // Niri workspace context popout — uses Niri.wsContextAnchor
        Popout {
            name: "wsWindow"
            sourceComponent:
            WsContextPopout {}
        }

        Popout {
            id: networkPopout

            name: "network"
            sourceComponent: Network {
                popouts: root.popouts
                view: "wireless"
            }
        }

        Popout {
            name: "ethernet"
            sourceComponent: Network {
                popouts: root.popouts
                view: "ethernet"
            }
        }

        Popout {
            id: passwordPopout

            name: "wirelesspassword"
            sourceComponent: WirelessPassword {
                popouts: root.popouts
                network: (networkPopout.item as Network)?.passwordNetwork ?? null
            }
        }

        Popout {
            name: "bluetooth"
            sourceComponent: Bluetooth {
                popouts: root.popouts
            }
        }

        Popout {
            name: "battery"
            sourceComponent: Battery {}
        }

        Popout {
            name: "audio"
            sourceComponent: Audio {
                popouts: root.popouts
            }
        }

        Popout {
            name: "kblayout"
            sourceComponent: KbLayout {}
        }

        Popout {
            name: "lockstatus"
            sourceComponent: LockStatus {}
        }

        Popout {
            name: "stasis"
            sourceComponent: Stasis {}
        }

        Repeater {
            model: ScriptModel {
                values: SystemTray.items.values.filter(i => !GlobalConfig.bar.tray.hiddenIcons.includes(i.id))
            }

            Popout {
                id: trayMenu

                required property SystemTrayItem modelData
                required property int index

                name: `traymenu${index}`
                sourceComponent: trayMenuComp

                Connections {
                    function onHasCurrentChanged(): void {
                        if (root.popouts.hasCurrent && trayMenu.shouldBeActive) {
                            trayMenu.sourceComponent = null;
                            trayMenu.sourceComponent = trayMenuComp;
                        }
                    }

                    target: root.popouts
                }

                Component {
                    id: trayMenuComp

                    TrayMenu {
                        popouts: root.popouts
                        trayItem: trayMenu.modelData.menu // qmllint disable unresolved-type
                    }
                }
            }
        }
    }

    component Popout: Loader {
        id: popout

        required property string name
        readonly property bool shouldBeActive: root.popouts ? root.popouts.currentName === name : false

        anchors.centerIn: parent

        opacity: 0
        active: false

        states: State {
            name: "active"
            when: popout.shouldBeActive

            PropertyChanges {
                popout.active: true
                popout.opacity: 1
            }
        }

        transitions: [
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    Anim {
                        property: "opacity"
                        type: Anim.DefaultEffects
                    }
                    PropertyAction {
                        property: "active"
                    }
                }
            },
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        property: "active"
                    }
                    Anim {
                        property: "opacity"
                        type: Anim.SlowEffects
                    }
                }
            }
        ]
    }
}
