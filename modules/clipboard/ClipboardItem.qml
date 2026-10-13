// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.2.0-20260610

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import CNS.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property string entryId: ""
    property string entryText: ""
    property bool isImageEntry: false
    property bool selected: false

    signal activated
    signal deleteRequested

    implicitWidth: ListView.view ? ListView.view.width - Tokens.padding.large * 2 : 400
    implicitHeight: Tokens.sizes.launcher.itemHeight

    StyledRect {
        id: highlight
        anchors.fill: parent
        radius: Tokens.rounding.medium
        color: root.selected ? Qt.alpha(Colours.palette.m3primary, 0.12) : "transparent"
        border.color: root.selected ? Colours.palette.m3primary : "transparent"
        border.width: root.selected ? 1 : 0
    }

    StateLayer {
        id: stateLayer
        anchors.fill: parent
        radius: Tokens.rounding.medium
        z: 0
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
            font: Tokens.font.icon.small
            z: 1
        onClicked: root.activated()
        }

        IconButton {
            icon: "delete"
            font: Tokens.font.icon.small
            z: 1
            onClicked: root.deleteRequested()
        }
    }
}
