pragma ComponentBehavior: Bound

import qs.services
import qs.components
import CNS.Config
import "popouts" as BarPopouts
import "components"
import "components/workspaces"
import Quickshell
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property ShellScreen screen
    readonly property ScreenState screenState: ShellState.forScreen(screen)
    required property BarPopouts.Wrapper popouts
    required property bool fullscreen
    readonly property int vPadding: Tokens.padding.largeIncreased

    // Handle Workspace Popouts for Niri

    Connections {
        target: root.popouts
        function onHasCurrentChanged() {
            if (!root.popouts.hasCurrent && root.popouts.currentName === "wsWindow") {
                Niri.wsContextAnchor = null;
            }
        }
    }

    // Handle Popouts Hover

    function checkPopout(y: real): void {
        if (Niri.wsContextType === "workspaces") {
            const anchor = Niri.wsContextAnchor;
            if (!anchor) {
                popouts.hasCurrent = false;
                return;
            }
            popouts.currentCenter = Qt.binding(() => Math.round(anchor.mapToItem(root, 0, anchor.height / 2).y));
            return;
        }

        const ch = childAt(width / 2, y);
        if (!ch?.item) {
            popouts.hasCurrent = false;
            return;
        }

        const id = ch.entryId;
        const top = ch.y;
        const item = ch.item;
        const itemHeight = item.implicitHeight;

        if (id === "statusIcons") {
            const items = item.items;
            const icon = items.childAt(items.width / 2, mapToItem(items, 0, y).y);
            if (icon) {
                popouts.currentName = icon.name;
                popouts.currentCenter = Qt.binding(() => icon.mapToItem(root, 0, icon.implicitHeight / 2).y);
                popouts.hasCurrent = true;
            }
        } else if (id === "stasisStatus") {
            popouts.currentName = "stasis";
            popouts.currentCenter = Qt.binding(() => ch.mapToItem(root, 0, ch.implicitHeight / 2).y);
            popouts.hasCurrent = true;
        } else if (id === "tray") {
            const index = Math.floor(((y - top) / itemHeight) * item.items.count);
            const trayItem = item.items.itemAt(index);
            if (trayItem) {
                popouts.currentName = `traymenu${index}`;
                popouts.currentCenter = Qt.binding(() => trayItem.mapToItem(root, 0, trayItem.implicitHeight / 2).y);
                popouts.hasCurrent = true;
            }
        } else if (id === "workspaces") {
            if (popouts.blockWorkspacePopout)
                return;
            popouts.currentName = "workspaces";
            popouts.currentCenter = Qt.binding(() => {
                const centerY = ch.mapToItem(root, 0, ch.implicitHeight / 2).y;
                return Math.round(Math.max(centerY + Config.border.thickness, 350));
            });
            popouts.hasCurrent = true;
        }
    }

    function handleWheel(y: real, angleDelta: point): void {
        const ch = childAt(width / 2, y) as EntryWrapper;
        if (ch?.entryId === "workspaces" && Config.bar.scrollActions.workspaces) {
            Niri.switchToWorkspaceUpDown(angleDelta.y > 0 ? "up" : "down");
        } else if (Config.bar.scrollActions.volume) {
            if (angleDelta.y > 0)
                Audio.incrementVolume();
            else if (angleDelta.y < 0)
                Audio.decrementVolume();
        }
    }

    spacing: Tokens.spacing.large

    Repeater {
        id: repeater

        model: ScriptModel {
            values: root.Config.bar.entries.filter(e => e.enabled ?? true)
        }

        DelegateChooser {
            role: "id"

            DelegateChoice {
                roleValue: "spacer"
                delegate: EntryWrapper {
                    Layout.fillHeight: true
                }
            }
            DelegateChoice {
                roleValue: "divider"
                delegate: EntryWrapper {
                    Rectangle {
                        implicitWidth: Tokens.padding.medium
                        implicitHeight: 1
                        color: Colours.palette.m3outlineVariant
                    }
                }
            }
            DelegateChoice {
                roleValue: "logo"
                delegate: EntryWrapper {
                    OsIcon {
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    Niri.wsContextType = "workspaces";
                                    root.popouts.currentName = "wsWindow";
                                    root.popouts.hasCurrent = true;
                                }
                            }
                        }
                    }
                }
            }
            DelegateChoice {
                roleValue: "workspaces"
                delegate: EntryWrapper {
                    Layout.preferredHeight: item ? item.implicitHeight : 120
                    Workspaces {
                        screen: root.screen

                        property var anchorItem: Niri.wsContextAnchor && Niri.wsContextType !== "none" ? Niri.wsContextAnchor : null

                        onRequestWindowPopout: {
                            if (anchorItem && Config.bar.workspaces.windowRighClickContext) {
                                root.popouts.currentName = "wsWindow";
                                root.popouts.currentCenter = Qt.binding(() => Math.round(anchorItem.mapToItem(null, anchorItem.width, (anchorItem.height) / 2).y));
                                root.popouts.hasCurrent = true;
                            }
                        }
                    }
                }
            }
            DelegateChoice {
                roleValue: "stasisStatus"
                delegate: EntryWrapper {
                    StasisStatus {}
                }
            }
            DelegateChoice {
                roleValue: "activeWindow"
                delegate: EntryWrapper {
                    ActiveWindow {
                        bar: root
                        monitor: Brightness.getMonitorForScreen(root.screen)
                    }
                }
            }
            DelegateChoice {
                roleValue: "tray"
                delegate: EntryWrapper {
                    Tray {}
                }
            }
            DelegateChoice {
                roleValue: "clock"
                delegate: EntryWrapper {
                    Clock {}
                }
            }
            DelegateChoice {
                roleValue: "statusIcons"
                delegate: EntryWrapper {
                    StatusIcons {}
                }
            }
            DelegateChoice {
                roleValue: "power"
                delegate: EntryWrapper {
                    Power {
                    }
                }
            }
        }
    }

    // Cached first/last enabled items — recomputed once when repeater changes
    property Item firstEnabled: null
    property Item lastEnabled: null

    function updateEnabledCache(): void {
        let first = null;
        let last = null;
        const count = repeater.count;
        for (let i = 0; i < count; i++) {
            const item = repeater.itemAt(i);
            if (item?.enabled) {
                if (!first) first = item;
                last = item;
            }
        }
        firstEnabled = first;
        lastEnabled = last;
    }

    Connections {
        target: repeater
        function onCountChanged() { root.updateEnabledCache(); }
    }

    Component.onCompleted: updateEnabledCache()

    component EntryWrapper: Item {
        required property var modelData
        required property int index
        default property Item item
        readonly property string entryId: modelData.id

        Layout.topMargin: index === 0 ? root.vPadding : 0
        Layout.bottomMargin: index === repeater.count - 1 ? root.vPadding : 0
        Layout.alignment: Qt.AlignHCenter

        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0

        children: item
    }
}
