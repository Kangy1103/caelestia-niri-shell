// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260610

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property string entryId
    required property string entryText
    property bool isImageEntry: false

    signal activated
    signal deleteRequested

    implicitWidth: ListView.view ? ListView.view.width - Tokens.padding.large * 2 : 400
    implicitHeight: Tokens.sizes.launcher.itemHeight

    StateLayer {
        id: stateLayer
        radius: Tokens.rounding.large
        onClicked: root.activated()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        MaterialIcon {
            text: root.isImageEntry ? "image" : "content_paste"
            font: Tokens.font.icon.large
            color: root.isImageEntry ? Colours.palette.m3tertiary : Colours.palette.m3primary
        }

        StyledText {
            Layout.fillWidth: true
            text: root.entryText
            font: Tokens.font.body.medium
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        IconButton {
            icon: "content_copy"
            type: IconButton.Standard
            onClicked: root.activated()
        }

        IconButton {
            icon: "delete"
            type: IconButton.Standard
            onClicked: root.deleteRequested()
        }
    }
}
