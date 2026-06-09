pragma ComponentBehavior: Bound

import "services"
import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import Quickshell
import QtQuick

Item {
    id: root

    required property var wrapper
    required property PersistentProperties visibilities
    required property var panels

    readonly property int padding: Config.appearance.padding.largeIncreased
    readonly property int rounding: Config.appearance.rounding.large

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: searchWrapper.height + listWrapper.height + padding * 2

    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter

    Item {
        id: listWrapper

        implicitWidth: list.width
        implicitHeight: list.height + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: searchWrapper.top
        anchors.bottomMargin: root.padding

        ContentList {
            id: list

            wrapper: root.wrapper
            visibilities: root.visibilities
            panels: root.panels
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }

    StyledRect {
        id: modeIndicator

        visible: list.activeMode !== "apps"
        color: Colours.tPalette.m3tertiaryContainer
        radius: Config.appearance.rounding.full

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: searchWrapper.top
        anchors.bottomMargin: Config.appearance.spacing.small

        implicitWidth: modeRow.implicitWidth + Config.appearance.padding.medium * 2
        implicitHeight: modeRow.implicitHeight + Config.appearance.padding.extraSmall * 2

        Row {
            id: modeRow
            anchors.centerIn: parent
            spacing: Config.appearance.spacing.extraSmall

            MaterialIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    switch (list.activeMode) {
                    case "actions": return "terminal";
                    case "calc": return "calculate";
                    case "clip": return "content_paste";
                    case "web": return "travel_explore";
                    case "scheme": return "palette";
                    case "variant": return "format_paint";
                    case "wallpapers": return "wallpaper";
                    case "emoji": return "mood";
                    default: return "search";
                    }
                }
                color: Colours.palette.m3onTertiaryContainer
                fontStyle: Tokens.font.icon.size(Config.appearance.font.label.large.size).build()
}

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    switch (list.activeMode) {
                    case "actions": return qsTr("Actions");
                    case "calc": return qsTr("Calculator");
                    case "clip": return qsTr("Clipboard");
                    case "web": return qsTr("Web Search");
                    case "scheme": return qsTr("Colour Scheme");
                    case "variant": return qsTr("Variant");
                    case "wallpapers": return qsTr("Wallpapers");
                    case "emoji": return qsTr("Emoji Picker");
                    default: return "";
                    }
                }
                color: Colours.palette.m3onTertiaryContainer
                font.pointSize: Config.appearance.font.label.medium.size
                font.bold: true
            }
        }

        Behavior on opacity {
            Anim {
                duration: Config.appearance.anim.durations.small
            }
        }
    }

    StyledRect {
        id: searchWrapper

        color: Colours.tPalette.m3surfaceContainer
        radius: Config.appearance.rounding.small

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding

        implicitHeight: Math.max(searchIcon.implicitHeight, search.implicitHeight, clearIcon.implicitHeight)

        MaterialIcon {
            id: searchIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: root.padding

            text: "search"
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledTextField {
            id: search

            anchors.left: searchIcon.right
            anchors.right: clearIcon.left
            anchors.leftMargin: Config.appearance.spacing.small
            anchors.rightMargin: Config.appearance.spacing.small

            topPadding: Config.appearance.padding.large
            bottomPadding: Config.appearance.padding.large

            placeholderText: qsTr("Type \"%1\" for commands").arg(Config.launcher.actionPrefix)

            onAccepted: {
                const currentItem = list.currentList?.currentItem;
                if (currentItem) {
                    if (list.showWallpapers) {
                        if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                            Wallpapers.previewColourLock = true;
                        Wallpapers.setWallpaper(currentItem.modelData.path);
                        root.visibilities.launcher = false;
                    } else if (text.startsWith(Config.launcher.actionPrefix)) {
                        if (text.startsWith(`${Config.launcher.actionPrefix}calc `))
                            currentItem.onClicked();
                        else if (text.startsWith(`${Config.launcher.actionPrefix}clip `))
                            currentItem.onClicked();
                        else if (text.startsWith(`${Config.launcher.actionPrefix}web `))
                            currentItem.onClicked();
                        else if (text.startsWith(`${Config.launcher.actionPrefix}emoji `))
                             currentItem.currentItem?.onClicked();
                        else
                            currentItem.modelData.onClicked(list.currentList);
                    } else {
                        Apps.launch(currentItem.modelData);
                        root.visibilities.launcher = false;
                    }
                }
            }

            Keys.onUpPressed: {
                if (list.activeMode === "emoji")
                    list.currentList.currentItem?.moveUp();
                else
                    list.currentList?.decrementCurrentIndex();
            }
            Keys.onDownPressed: {
                if (list.activeMode === "emoji")
                    list.currentList.currentItem?.moveDown();
                else
                    list.currentList?.incrementCurrentIndex();
            }
            Keys.onLeftPressed: {
                if (list.activeMode === "emoji")
                    list.currentList.currentItem?.moveLeft();
                else
                    event.accepted = false;
            }
            Keys.onRightPressed: {
                if (list.activeMode === "emoji")
                    list.currentList.currentItem?.moveRight();
                else
                    event.accepted = false;
            }
            Keys.onEscapePressed: root.visibilities.launcher = false

            Keys.onPressed: event => {
                // Ignore events if we're not focused
                if (!search.focus)
                    return;

                if (list.activeMode === "emoji") {
                    if (event.key === Qt.Key_PageUp) {
                        list.currentList.currentItem?.prevCategory();
                        event.accepted = true;
                        return;
                    } else if (event.key === Qt.Key_PageDown) {
                        list.currentList.currentItem?.nextCategory();
                        event.accepted = true;
                        return;
                    }
                }

                if (event.modifiers & Qt.ControlModifier) {
                    if (event.key === Qt.Key_J) {
                        if (list.activeMode === "emoji")
                            list.currentList.currentItem?.incrementCurrentIndex();
                        else
                            list.currentList?.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_K) {
                        if (list.activeMode === "emoji")
                            list.currentList.currentItem?.decrementCurrentIndex();
                        else
                            list.currentList?.decrementCurrentIndex();
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Tab) {
                    if (list.activeMode === "emoji")
                        list.currentList.currentItem?.incrementCurrentIndex();
                    else
                        list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                    if (list.activeMode === "emoji")
                        list.currentList.currentItem?.decrementCurrentIndex();
                    else
                        list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                }
            }

            Connections {
                target: root.visibilities

                function onLauncherChanged(): void {
                    if (root.visibilities.launcher) {
                        search.focus = true;
                        if (root.visibilities.clipboardRequested) {
                            search.text = Config.launcher.actionPrefix + "clip ";
                            root.visibilities.clipboardRequested = false;
                        }
                    } else {
                        search.text = "";
                        const current = list.currentList;
                        if (current)
                            current.currentIndex = 0;
                    }
                }

                function onSessionChanged(): void {
                    if (root.visibilities.launcher && !root.visibilities.session)
                        search.focus = true;
                }
            }
        }

        MaterialIcon {
            id: clearIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: root.padding

            width: search.text ? implicitWidth : implicitWidth / 2
            opacity: {
                if (!search.text)
                    return 0;
                if (mouse.pressed)
                    return 0.7;
                if (mouse.containsMouse)
                    return 0.8;
                return 1;
            }

            text: "close"
            color: Colours.palette.m3onSurfaceVariant

            MouseArea {
                id: mouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: search.text ? Qt.PointingHandCursor : undefined

                onClicked: search.text = ""
            }

            Behavior on width {
                Anim {
                    duration: Config.appearance.anim.durations.small
                }
            }

            Behavior on opacity {
                Anim {
                    duration: Config.appearance.anim.durations.small
                }
            }
        }
    }
}
