import qs.components
import qs.components.effects
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    default property alias content: contentColumn.data
    property real contentSpacing: Config.appearance.spacing.largeIncreased
    property bool alignTop: false

    Layout.fillWidth: true
    implicitHeight: contentColumn.implicitHeight + Config.appearance.padding.largeIncreased * 2

    radius: Config.appearance.rounding.large
    color: Colours.transparency.enabled ? Colours.layer(Colours.palette.m3surfaceContainer, 2) : Colours.palette.m3surfaceContainerHigh

    ColumnLayout {
        id: contentColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: root.alignTop ? parent.top : undefined
        anchors.verticalCenter: root.alignTop ? undefined : parent.verticalCenter
        anchors.margins: Config.appearance.padding.largeIncreased

        spacing: root.contentSpacing
    }
}
