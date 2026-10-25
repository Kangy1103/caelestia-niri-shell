pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import CNS.Config
import CNS.Internal
import qs.components
import qs.components.containers
import qs.services
import qs.utils

Scope {
    id: root

    property bool showing: false
    property var sessionWindows: []
    property int selectedIndex: -1
    property string targetScreen: ""

    function candidates(): var {
        return Compositor.windows.filter(window =>
            window.visible !== false && !window.tab_hidden && String(window.app_id ?? "").length > 0);
    }

    function cycle(direction: int): void {
        if (!Compositor.available)
            return;

        const windows = candidates();
        if (windows.length < 2)
            return;

        let currentIndex = -1;
        if (showing) {
            const selectedId = sessionWindows[selectedIndex]?.id;
            currentIndex = windows.findIndex(window => Compositor.sameId(window.id, selectedId));
        } else {
            currentIndex = windows.findIndex(window => Compositor.sameId(window.id, Compositor.focusedWindowId));
            if (currentIndex < 0)
                currentIndex = direction > 0 ? -1 : 0;
            targetScreen = Compositor.focusedMonitorName || (Screens.screens[0]?.name ?? "");
        }

        sessionWindows = windows;
        selectedIndex = (currentIndex + direction + windows.length) % windows.length;
        showing = true;
    }

    function commit(index: int): void {
        if (!showing)
            return;
        const selected = sessionWindows[index >= 0 ? index : selectedIndex];
        const windowId = selected?.id ?? "";

        showing = false;
        targetScreen = "";
        sessionWindows = [];
        selectedIndex = -1;

        if (windowId.length > 0)
            Qt.callLater(() => Compositor.focusWindow(windowId));
    }

    function cancel(): void {
        showing = false;
        targetScreen = "";
        sessionWindows = [];
        selectedIndex = -1;
    }

    IpcHandler {
        target: "appSwitcher"
        function next(): void { root.cycle(1); }
        function previous(): void { root.cycle(-1); }
        function commit(): void { root.commit(-1); }
        function cancel(): void { root.cancel(); }
        function state(): string {
            return JSON.stringify({
                showing: root.showing,
                selectedId: String(root.sessionWindows[root.selectedIndex]?.id ?? ""),
                focusedId: Compositor.focusedWindowId,
                selectedIndex: root.selectedIndex
            });
        }
    }

    Variants {
        model: Screens.screens

        StyledWindow {
            id: win

            required property ShellScreen modelData
            readonly property bool ownsOverlay: root.showing && modelData.name === root.targetScreen

            name: "app-switcher"
            screen: modelData
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: ownsOverlay ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            mask: ownsOverlay ? null : emptyRegion

            Region {
                id: emptyRegion
            }

            Rectangle {
                id: card

                focus: win.ownsOverlay
                KeyboardModifiers {
                    running: win.ownsOverlay && card.Window.active
                    onSampled: modifiers => {
                        if (!(modifiers & Qt.AltModifier))
                            root.commit(-1);
                    }
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                        root.cycle((event.modifiers & Qt.ShiftModifier) || event.key === Qt.Key_Backtab ? -1 : 1);
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                        root.cycle(-1);
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                        root.cycle(1);
                    } else if (event.key === Qt.Key_Escape) {
                        root.cancel();
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.commit(-1);
                    }
                    event.accepted = true;
                }

                readonly property int itemWidth: 142
                readonly property int itemSpacing: 8
                readonly property real preferredWidth: root.sessionWindows.length * (itemWidth + itemSpacing) + 36

                anchors.centerIn: parent
                width: Math.min(preferredWidth, Math.max(300, win.screen.width - 48))
                height: 242
                radius: Tokens.rounding.large
                color: Colours.palette.m3surfaceContainer
                border.width: 1
                border.color: Colours.palette.m3outlineVariant
                opacity: win.ownsOverlay ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Text {
                        text: qsTr("Switch window")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.title.small
                    }

                    Text {
                        width: parent.width
                        text: qsTr("Hold Alt · Tab / Shift+Tab cycles · Release Alt to select · Esc cancels")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.small
                        wrapMode: Text.WordWrap
                    }

                    Flickable {
                        id: windowStrip

                        width: card.width - 32
                        height: 132
                        clip: true
                        contentWidth: cards.implicitWidth
                        contentHeight: height
                        boundsBehavior: Flickable.StopAtBounds

                        function reveal(index: int): void {
                            const item = windowCards.itemAt(index);
                            if (!item)
                                return;
                            const target = item.x + item.width / 2 - width / 2;
                            contentX = Math.max(0, Math.min(contentWidth - width, target));
                        }

                        Row {
                            id: cards
                            spacing: card.itemSpacing
                            height: windowStrip.height

                            Repeater {
                                id: windowCards
                                model: root.sessionWindows

                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index

                                    width: card.itemWidth
                                    height: 122
                                    radius: Tokens.rounding.medium
                                    color: index === root.selectedIndex
                                        ? Colours.palette.m3secondaryContainer
                                        : Colours.palette.m3surfaceContainerHigh
                                    border.width: index === root.selectedIndex ? 2 : 1
                                    border.color: index === root.selectedIndex
                                        ? Colours.palette.m3primary
                                        : Colours.palette.m3outlineVariant

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 8

                                        IconImage {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            implicitSize: 42
                                            source: Icons.getAppIcon(modelData.app_id ?? "", "image-missing")
                                        }

                                        Text {
                                            width: parent.width
                                            text: modelData.title || modelData.app_id || qsTr("Window")
                                            color: index === root.selectedIndex
                                                ? Colours.palette.m3onSecondaryContainer
                                                : Colours.palette.m3onSurface
                                            font: Tokens.font.body.small
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            maximumLineCount: 2
                                            wrapMode: Text.Wrap
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.commit(index)
                                    }
                                }
                            }
                        }

                        Connections {
                            target: root
                            function onSelectedIndexChanged(): void {
                                Qt.callLater(() => windowStrip.reveal(root.selectedIndex));
                            }
                        }
                    }
                }
            }
        }
    }
}
