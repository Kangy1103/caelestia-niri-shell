pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var list
    required property var modelData

    readonly property string entryId: modelData?.entryId ?? ""
    readonly property string entryText: modelData?.entryText ?? ""
    readonly property bool isImageEntry: modelData?.isImage ?? false

    readonly property string displayText: isImageEntry ? "image" : entryText

    function onClicked(): void {
        Quickshell.execDetached(["sh", "-c", "cliphist decode '" + root.entryId + "' | wl-copy"]);
        root.list.visibilities.launcher = false;
    }

    implicitHeight: TokenConfig.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Config.appearance.rounding.small

        function onClicked(): void {
            root.onClicked();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Config.appearance.padding.large
        anchors.rightMargin: Config.appearance.padding.large
        spacing: Config.appearance.spacing.large

        // Icon
        MaterialIcon {
            text: root.isImageEntry ? "image" : "content_paste"
            font.pointSize: Config.appearance.font.headline.large.size
            color: root.isImageEntry ? Colours.palette.m3tertiary : Colours.palette.m3primary
            Layout.alignment: Qt.AlignVCenter
        }

        // Text content
        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.displayText
            font.pointSize: Config.appearance.font.body.small.size
            elide: Text.ElideRight
            maximumLineCount: 1
            color: root.isImageEntry ? Colours.palette.m3outline : Colours.palette.m3onSurface
        }

        // Copy button
        StyledRect {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            radius: Config.appearance.rounding.small
            color: "transparent"

            StateLayer {
                radius: parent.radius
                color: Colours.palette.m3primary

                function onClicked(): void {
                    Quickshell.execDetached([
                        "sh", "-c",
                        "cliphist decode '" + root.entryId + "' | wl-copy"
                    ]);
                    copyFeedback.opacity = 1;
                    copyFeedbackTimer.start();
                }
            }

            MaterialIcon {
                id: copyIcon
                anchors.centerIn: parent
                text: "content_copy"
                font.pointSize: Config.appearance.font.body.medium.size
                color: Colours.palette.m3outline
                opacity: copyFeedback.opacity === 0 ? 1 : 0

                Behavior on opacity {
                    Anim {
                        duration: Config.appearance.anim.durations.small
                    }
                }
            }

            MaterialIcon {
                id: copyFeedback
                anchors.centerIn: parent
                text: "check"
                font.pointSize: Config.appearance.font.body.medium.size
                color: Colours.palette.m3outline
                opacity: 0

                Behavior on opacity {
                    Anim {
                        duration: Config.appearance.anim.durations.small
                    }
                }
            }

            Timer {
                id: copyFeedbackTimer
                interval: 800
                onTriggered: copyFeedback.opacity = 0
            }
        }

        // Delete button
        StyledRect {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            radius: Config.appearance.rounding.small
            color: "transparent"

            StateLayer {
                radius: parent.radius
                color: Colours.palette.m3error

                function onClicked(): void {
                    Quickshell.execDetached(["cliphist", "delete", root.entryId]);
                    root.list.removeClipEntry(root.entryId);
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: "delete"
                font.pointSize: Config.appearance.font.body.medium.size
                color: Colours.palette.m3error
            }
        }
    }
}
