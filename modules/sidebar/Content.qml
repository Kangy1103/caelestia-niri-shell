import QtQuick
import QtQuick.Layouts
import CNS.Config
import qs.components
import qs.services

Item {
    id: root

    required property Props props
    readonly property ScreenState screenState: ShellState.forScreen(screen)

    ColumnLayout {
        id: layout

        anchors.fill: parent
        spacing: Tokens.spacing.medium

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Tokens.rounding.large
            color: Colours.tPalette.m3surfaceContainerLow

            NotifDock {
                props: root.props
            }
        }

        StyledRect {
            Layout.topMargin: Tokens.padding.large - layout.spacing
            Layout.fillWidth: true
            implicitHeight: 1

            color: Colours.tPalette.m3outlineVariant
        }
    }
}
