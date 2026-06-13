// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260610


pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CNS.Config
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    function refresh() {
        kb.refresh();
    }

    spacing: Config.appearance.spacing.small
    width: TokenConfig.sizes.bar.kbLayoutWidth

    Component.onCompleted: kb.start()

    KbLayoutModel {
        id: kb
    }

    StyledText {
        Layout.topMargin: Config.appearance.padding.medium
        Layout.rightMargin: Config.appearance.padding.extraSmall
        text: qsTr("Keyboard Layouts")
    }

    ListView {
        id: list

        model: kb.visibleModel

        Layout.fillWidth: true
        Layout.rightMargin: Config.appearance.padding.extraSmall
        Layout.topMargin: Config.appearance.spacing.small

        clip: true
        interactive: true
        implicitHeight: Math.min(contentHeight, 320)
        visible: kb.visibleModel.count > 0
        spacing: Config.appearance.spacing.small

        add: Transition {
            NumberAnimation {
                properties: "opacity"
                from: 0
                to: 1
                duration: 140
            }
            NumberAnimation {
                properties: "y"
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        remove: Transition {
            NumberAnimation {
                properties: "opacity"
                to: 0
                duration: 100
            }
        }
        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: 180
                easing.type: Easing.OutCubic
            }
        }
        displaced: Transition {
            NumberAnimation {
                properties: "y"
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        delegate: Item {
            id: kbDelegate

            required property int layoutIndex
            required property string label
            readonly property bool isDisabled: layoutIndex > 3

            width: list.width
            height: Math.max(36, rowText.implicitHeight + Config.appearance.padding.small)

            StyledText {
                id: rowText

                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Config.appearance.padding.extraSmall
                anchors.rightMargin: Config.appearance.padding.extraSmall
                text: kbDelegate.label
                elide: Text.ElideRight
                opacity: kbDelegate.isDisabled ? 0.4 : 1.0
            }
        }
    }

    Rectangle {
        visible: kb.activeLabel.length > 0
        Layout.fillWidth: true
        Layout.rightMargin: Config.appearance.padding.extraSmall
        Layout.topMargin: Config.appearance.spacing.small

        implicitHeight: 1
        color: Colours.palette.m3onSurfaceVariant
        opacity: 0.35
    }

    RowLayout {
        id: activeRow

        visible: kb.activeLabel.length > 0
        Layout.fillWidth: true
        Layout.rightMargin: Config.appearance.padding.extraSmall
        Layout.topMargin: Config.appearance.spacing.small
        spacing: Config.appearance.spacing.small

        opacity: 1
        scale: 1

        MaterialIcon {
            text: "keyboard"
            color: Colours.palette.m3primary
        }

        StyledText {
            Layout.fillWidth: true
            text: kb.activeLabel
            elide: Text.ElideRight
            color: Colours.palette.m3primary
        }

        Connections {
            function onActiveLabelChanged() {
                if (!activeRow.visible)
                    return;
                popIn.restart();
            }

            target: kb
        }

        SequentialAnimation {
            id: popIn

            running: false

            ParallelAnimation {
                NumberAnimation {
                    target: activeRow
                    property: "opacity"
                    to: 0.0
                    duration: 70
                }
                NumberAnimation {
                    target: activeRow
                    property: "scale"
                    to: 0.92
                    duration: 70
                }
            }

            ParallelAnimation {
                NumberAnimation {
                    target: activeRow
                    property: "opacity"
                    to: 1.0
                    duration: 160
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: activeRow
                    property: "scale"
                    to: 1.0
                    duration: 220
                    easing.type: Easing.OutBack
                }
            }
        }
    }

    IconTextButton {
        Layout.fillWidth: true
        Layout.topMargin: Config.appearance.spacing.medium
        inactiveColour: Colours.palette.m3primaryContainer
        inactiveOnColour: Colours.palette.m3onPrimaryContainer
        verticalPadding: Config.appearance.padding.extraSmall
        text: qsTr("Next Layout")
        icon: "arrow_forward"

        onClicked: kb.cycleLayout()
    }
}
