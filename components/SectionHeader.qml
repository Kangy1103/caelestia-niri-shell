import qs.components
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property string title
    property string description: ""

    spacing: 0

    StyledText {
        Layout.topMargin: Config.appearance.spacing.extraExtraLarge
        text: root.title
        font.pointSize: Config.appearance.font.body.large.size
        font.weight: 500
    }

    StyledText {
        visible: root.description !== ""
        text: root.description
        color: Colours.palette.m3outline
    }
}
