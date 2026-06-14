// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260614

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CNS.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property var modelData
    required property bool isDownloading

    signal clicked()
    signal download()

    readonly property real itemMargin: Tokens.spacing.large / 2
    readonly property real itemRadius: Tokens.rounding.extraLarge

    visible: !!modelData

    StateLayer {
        anchors.fill: parent
        anchors.leftMargin: root.itemMargin
        anchors.rightMargin: root.itemMargin
        anchors.topMargin: root.itemMargin
        anchors.bottomMargin: root.itemMargin
        radius: root.itemRadius
        onClicked: root.clicked()
    }

    StyledClippingRect {
        anchors.fill: parent
        anchors.leftMargin: root.itemMargin
        anchors.rightMargin: root.itemMargin
        anchors.topMargin: root.itemMargin
        anchors.bottomMargin: root.itemMargin
        color: Colours.tPalette.m3surfaceContainer
        radius: root.itemRadius

        Image {
            source: root.modelData ? root.modelData.url_thumb : ""
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true

            opacity: status === Image.Ready ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 300 } }

            onStatusChanged: {
                if (status === Image.Error && root.modelData) {
                    console.warn("Failed to load web wallpaper thumb:", root.modelData.url_thumb);
                }
            }
        }

        StyledRect {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)
            visible: root.isDownloading

            StyledBusyIndicator {
                anchors.centerIn: parent
            }
        }

        StyledRect {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 30
            color: Qt.rgba(0, 0, 0, 0.4)

            StyledText {
                anchors.centerIn: parent
                width: parent.width - 10
                text: root.modelData ? root.modelData.slug : ""
                font: Tokens.font.body.small
                color: "white"
                elide: Text.ElideMiddle
                horizontalAlignment: Text.AlignHCenter
            }
        }

        IconButton {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 4
            icon: "download"
            visible: root.modelData && !root.isDownloading
            onClicked: root.download()
        }
    }
}
