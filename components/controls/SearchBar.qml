import QtQuick
import CNS.Config
import qs.components
import qs.services

TextFieldBase {
    id: root

    readonly property alias bg: bg
    readonly property alias searchIcon: searchIcon
    readonly property alias clearIcon: clearIcon

    leftPadding: searchIcon.width + searchIcon.anchors.leftMargin + Tokens.spacing.medium
    rightPadding: clearIcon.width + clearIcon.anchors.rightMargin + Tokens.spacing.medium
    topPadding: Tokens.padding.large
    bottomPadding: Tokens.padding.large

    onPressed: {
        if (!stateLayer.disabled)
            stateLayer.press(stateLayer.mouseX, stateLayer.mouseY);
    }

    background: StyledRect {
        id: bg

        radius: Tokens.rounding.extraSmall
        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 1)

        StateLayer {
            id: stateLayer

            radius: Tokens.rounding.extraSmall
        }
    }

    MaterialIcon {
        id: searchIcon

        x: Tokens.padding.large
        anchors.verticalCenter: parent.verticalCenter

        text: "search"
        color: Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.medium
    }

    MaterialIcon {
        id: clearIcon

        anchors.right: parent.right
        anchors.rightMargin: Tokens.padding.large
        anchors.verticalCenter: parent.verticalCenter

        text: "close"
        color: Colours.palette.m3onSurfaceVariant
        fontStyle: Tokens.font.icon.medium
        visible: root.text.length > 0

        StateLayer {
            anchors.fill: parent
            anchors.margins: -8
            radius: Tokens.rounding.full
            onClicked: root.clear()
        }
    }

    placeholderText: qsTr("Search")

    // Emitted whenever the clear button would be shown (text non-empty on non-empty)
    signal textNonEmpty
}
