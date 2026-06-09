import qs.components
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property string icon
    required property string title

    spacing: Config.appearance.spacing.large
    Layout.alignment: Qt.AlignHCenter

    MaterialIcon {
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: root.icon
        font.pointSize: Config.appearance.font.headline.large.size * 3
        font.bold: true
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        animate: true
        text: root.title
        font.pointSize: Config.appearance.font.title.medium.size
        font.bold: true
    }
}
