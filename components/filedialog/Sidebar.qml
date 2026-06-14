pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CNS.Config
import qs.components
import qs.components.filedialog
import qs.services

StyledRect {
    id: root

    required property var dialog

    implicitWidth: Sizes.sidebarWidth
    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: inner

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.extraSmall

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.padding.extraSmall / 2
            Layout.bottomMargin: Tokens.spacing.medium
            text: qsTr("Home")
            color: Colours.palette.m3onSurface
            font: Tokens.font.body.builders.large.weight(Font.Bold).build()
        }

        Repeater {
            model: [
                { name: "Home", path: ["Home"] },
                { name: "Downloads", path: ["Home", "Downloads"] },
                { name: "Desktop", path: ["Home", "Desktop"] },
                { name: "Documents", path: ["Home", "Documents"] },
                { name: "Music", path: ["Home", "Music"] },
                { name: "Pictures", path: ["Home", "Pictures"] },
                { name: "Videos", path: ["Home", "Videos"] },
            ]

            StyledRect {
                id: place

                required property var modelData
                readonly property bool selected: {
                    const cwd = root.dialog.cwd;
                    const p = modelData.path;
                    if (cwd.length !== p.length) return false;
                    for (let i = 0; i < p.length; i++) {
                        if (cwd[i] !== p[i]) return false;
                    }
                    return true;
                }

                Layout.fillWidth: true
                implicitHeight: placeInner.implicitHeight + Tokens.padding.medium * 2

                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.palette.m3secondaryContainer, selected ? 1 : 0)

                StateLayer {
                    color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    onClicked: root.dialog.cwd = modelData.path
                }

                RowLayout {
                    id: placeInner

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.large
                    anchors.rightMargin: Tokens.padding.large

                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: {
                            const p = modelData.name;
                            if (p === "Home")
                                return "home";
                            if (p === "Downloads")
                                return "file_download";
                            if (p === "Desktop")
                                return "desktop_windows";
                            if (p === "Documents")
                                return "description";
                            if (p === "Music")
                                return "music_note";
                            if (p === "Pictures")
                                return "image";
                            if (p === "Videos")
                                return "video_library";
                            return "folder";
                        }
                        color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.medium
                        fill: place.selected ? 1 : 0

                        Behavior on fill {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.spacing.medium
            Layout.bottomMargin: Tokens.spacing.medium
            text: qsTr("Storage")
            color: Colours.palette.m3onSurface
            font: Tokens.font.body.builders.large.weight(Font.Bold).build()
        }

        Repeater {
            model: [
                { name: "File System", path: ["/"] },
                { name: "Media", path: ["/", "mnt", "Media"] },
                { name: "Gogeta", path: ["/", "mnt", "Gogeta"] },
                { name: "Vegito", path: ["/", "mnt", "Vegito"] },
            ]

            StyledRect {
                id: storagePlace

                required property var modelData
                readonly property bool selected: {
                    const cwd = root.dialog.cwd;
                    const p = modelData.path;
                    if (cwd.length !== p.length) return false;
                    for (let i = 0; i < p.length; i++) {
                        if (cwd[i] !== p[i]) return false;
                    }
                    return true;
                }

                Layout.fillWidth: true
                implicitHeight: storageInner.implicitHeight + Tokens.padding.medium * 2

                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.palette.m3secondaryContainer, selected ? 1 : 0)

                StateLayer {
                    color: storagePlace.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    onClicked: root.dialog.cwd = modelData.path
                }

                RowLayout {
                    id: storageInner

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.large
                    anchors.rightMargin: Tokens.padding.large

                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: {
                            const p = modelData.name;
                            if (p === "File System")
                                return "computer";
                            return "hard_drive";
                        }
                        color: storagePlace.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.medium
                        fill: storagePlace.selected ? 1 : 0

                        Behavior on fill {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: storagePlace.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
