pragma ComponentBehavior: Bound

import qs.components
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property string icon
    required property string title

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column

        anchors.centerIn: parent
        spacing: Config.appearance.spacing.large

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            fontStyle: Tokens.font.icon.size(Config.appearance.font.headline.large.size * 3).weight(Font.Bold).build()
}

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.title
            font.pointSize: Config.appearance.font.title.medium.size
            font.bold: true
        }
    }
}
