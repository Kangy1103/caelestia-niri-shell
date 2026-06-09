pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property Session session

    spacing: Config.appearance.spacing.large

    SettingsHeader {
        icon: "cable"
        title: qsTr("Ethernet settings")
    }

    StyledText {
        Layout.topMargin: Config.appearance.spacing.extraExtraLarge
        text: qsTr("Ethernet devices")
        font.pointSize: Config.appearance.font.body.large.size
        font.weight: 500
    }

    StyledText {
        text: qsTr("Available ethernet devices")
        color: Colours.palette.m3outline
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: ethernetInfo.implicitHeight + Config.appearance.padding.largeIncreased * 2

        radius: Config.appearance.rounding.large
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: ethernetInfo

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Config.appearance.padding.largeIncreased

            spacing: Config.appearance.spacing.small / 2

            StyledText {
                text: qsTr("Total devices")
            }

            StyledText {
                text: qsTr("%1").arg(Nmcli.ethernetDevices.length)
                color: Colours.palette.m3outline
                font.pointSize: Config.appearance.font.label.large.size
            }

            StyledText {
                Layout.topMargin: Config.appearance.spacing.large
                text: qsTr("Connected devices")
            }

            StyledText {
                text: qsTr("%1").arg(Nmcli.ethernetDevices.filter(d => d.connected).length)
                color: Colours.palette.m3outline
                font.pointSize: Config.appearance.font.label.large.size
            }
        }
    }
}
