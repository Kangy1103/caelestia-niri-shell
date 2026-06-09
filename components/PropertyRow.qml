import qs.components
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property string label
    required property string value
    property bool showTopMargin: false

    spacing: Config.appearance.spacing.small / 2

    StyledText {
        Layout.topMargin: root.showTopMargin ? Config.appearance.spacing.large : 0
        text: root.label
    }

    StyledText {
        text: root.value
        color: Colours.palette.m3outline
        font.pointSize: Config.appearance.font.label.large.size
    }
}
