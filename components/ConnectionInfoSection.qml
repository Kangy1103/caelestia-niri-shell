import qs.components
import qs.components.effects
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property var deviceDetails

    spacing: Config.appearance.spacing.small / 2

    StyledText {
        text: qsTr("IP Address")
    }

    StyledText {
        text: root.deviceDetails?.ipAddress || qsTr("Not available")
        color: Colours.palette.m3outline
        font.pointSize: Config.appearance.font.label.large.size
    }

    StyledText {
        Layout.topMargin: Config.appearance.spacing.large
        text: qsTr("Subnet Mask")
    }

    StyledText {
        text: root.deviceDetails?.subnet || qsTr("Not available")
        color: Colours.palette.m3outline
        font.pointSize: Config.appearance.font.label.large.size
    }

    StyledText {
        Layout.topMargin: Config.appearance.spacing.large
        text: qsTr("Gateway")
    }

    StyledText {
        text: root.deviceDetails?.gateway || qsTr("Not available")
        color: Colours.palette.m3outline
        font.pointSize: Config.appearance.font.label.large.size
    }

    StyledText {
        Layout.topMargin: Config.appearance.spacing.large
        text: qsTr("DNS Servers")
    }

    StyledText {
        text: (root.deviceDetails && root.deviceDetails.dns && root.deviceDetails.dns.length > 0) ? root.deviceDetails.dns.join(", ") : qsTr("Not available")
        color: Colours.palette.m3outline
        font.pointSize: Config.appearance.font.label.large.size
        wrapMode: Text.Wrap
        Layout.maximumWidth: parent.width
    }
}
