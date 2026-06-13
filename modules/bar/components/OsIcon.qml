// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.2.0-20260610

import QtQuick
import CNS.Config
import qs.components
import qs.components.effects
import qs.services
import qs.utils

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
        asynchronous: true
        anchors.centerIn: parent
        sourceComponent: SysInfo.isDefaultLogo ? caelestiaLogo : distroIcon
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
            source: SysInfo.osLogo
            implicitSize: Math.round(Config.appearance.font.title.medium.size * 1.2)
            width: implicitWidth
            height: implicitHeight
            colour: Colours.palette.m3tertiary
        }
    }
}
