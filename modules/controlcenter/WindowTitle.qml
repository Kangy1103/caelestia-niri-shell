import qs.components
import qs.services
import Caelestia.Config
import Quickshell
import QtQuick

StyledRect {
    id: root

    required property ShellScreen screen
    required property Session session

    implicitHeight: text.implicitHeight + Config.appearance.padding.medium
    color: Colours.tPalette.m3surfaceContainer

    StyledText {
        id: text

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom

        text: qsTr("Settings — %1").arg(root.session.active)
        font.capitalization: Font.Capitalize
        font.pointSize: Config.appearance.font.body.large.size
        font.weight: 500
    }

    Item {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Config.appearance.padding.medium

        implicitWidth: implicitHeight
        implicitHeight: closeIcon.implicitHeight + Config.appearance.padding.extraSmall

        StateLayer {
            radius: Config.appearance.rounding.full

            function onClicked(): void {
                QsWindow.window.destroy();
            }
        }

        MaterialIcon {
            id: closeIcon

            anchors.centerIn: parent
            text: "close"
        }
    }
}
