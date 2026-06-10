// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260610


import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property DrawerVisibilities visibilities

    implicitWidth: icon.implicitHeight + TokenConfig.appearance.padding.small
    implicitHeight: icon.implicitHeight

    StateLayer {
        // Cursed workaround to make the height larger than the parent
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + TokenConfig.appearance.padding.small
        radius: Config.appearance.rounding.full
        onClicked: root.visibilities.session = !root.visibilities.session
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: -1

        text: "power_settings_new"
        color: Colours.palette.m3error
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()
    }
}
