pragma ComponentBehavior: Bound

import ".."
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    required property var dialog

    implicitWidth: Sizes.sidebarWidth
    implicitHeight: inner.implicitHeight + Config.appearance.padding.medium * 2

    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: inner

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Config.appearance.padding.medium
        spacing: Config.appearance.spacing.small / 2

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Config.appearance.padding.extraSmall / 2
            Layout.bottomMargin: Config.appearance.spacing.large
            text: qsTr("Files")
            color: Colours.palette.m3onSurface
            font.pointSize: Config.appearance.font.body.large.size
            font.bold: true
        }

        Repeater {
            model: ["Home", "Downloads", "Desktop", "Documents", "Music", "Pictures", "Videos"]

            StyledRect {
                id: place

                required property string modelData
                readonly property bool selected: modelData === root.dialog.cwd[root.dialog.cwd.length - 1]

                Layout.fillWidth: true
                implicitHeight: placeInner.implicitHeight + Config.appearance.padding.medium * 2

                radius: Config.appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3secondaryContainer, selected ? 1 : 0)

                StateLayer {
                    color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface

                    function onClicked(): void {
                        if (place.modelData === "Home")
                            root.dialog.cwd = ["Home"];
                        else
                            root.dialog.cwd = ["Home", place.modelData];
                    }
                }

                RowLayout {
                    id: placeInner

                    anchors.fill: parent
                    anchors.margins: Config.appearance.padding.medium
                    anchors.leftMargin: Config.appearance.padding.largeIncreased
                    anchors.rightMargin: Config.appearance.padding.largeIncreased

                    spacing: Config.appearance.spacing.large

                    MaterialIcon {
                        text: {
                            const p = place.modelData;
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
                        font.pointSize: Config.appearance.font.title.medium.size
                        fill: place.selected ? 1 : 0

                        Behavior on fill {
                            Anim {}
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: place.modelData
                        color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        font.pointSize: Config.appearance.font.body.medium.size
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
