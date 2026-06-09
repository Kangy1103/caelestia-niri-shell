// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260603

import qs.components
import qs.components.effects
import qs.services
import Caelestia.Config
import qs.utils
import QtQuick

Item {
    id: root

    implicitWidth: Math.round(Config.appearance.font.title.medium.size * 1.2)
    implicitHeight: Math.round(Config.appearance.font.title.medium.size * 1.2)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const visibilities = Visibilities.getForActive();
            visibilities.launcher = !visibilities.launcher;
        }
    }

    Loader {
        anchors.centerIn: parent
        sourceComponent: Config.general.isDistLogo ? distroIcon : caelestiaLogo
    }

    Component {
        id: caelestiaLogo

        Logo {
            implicitWidth: Math.round(Config.appearance.font.title.medium.size * 1.6)
            implicitHeight: Math.round(Config.appearance.font.title.medium.size * 1.6)
        }
    }

    Component {
        id: distroIcon

        ColouredIcon {
            source:  SysInfo.osLogo
            implicitSize: Math.round(Config.appearance.font.title.medium.size * 1.2)
            width: implicitWidth
            height: implicitHeight
            colour: Colours.palette.m3tertiary
        }
    }
}