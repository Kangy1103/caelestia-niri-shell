import qs.components
import qs.services
import Caelestia.Config
import QtQuick

Item {
    id: root

    required property M3Variants.Variant modelData
    required property var list

    implicitHeight: TokenConfig.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Config.appearance.rounding.small

        function onClicked(): void {
            root.modelData?.onClicked(root.list);
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Config.appearance.padding.large
        anchors.rightMargin: Config.appearance.padding.large
        anchors.margins: Config.appearance.padding.small

        MaterialIcon {
            id: icon

            text: root.modelData?.icon ?? ""
            fontStyle: Tokens.font.icon.size(Config.appearance.font.headline.large.size).build()
anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: Config.appearance.spacing.largeIncreased
            anchors.verticalCenter: icon.verticalCenter

            width: parent.width - icon.width - anchors.leftMargin - (current.active ? current.width + Config.appearance.spacing.large : 0)
            spacing: 0

            StyledText {
                text: root.modelData?.name ?? ""
                font.pointSize: Config.appearance.font.body.medium.size
            }

            StyledText {
                text: root.modelData?.description ?? ""
                font.pointSize: Config.appearance.font.label.large.size
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }

        Loader {
            id: current

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            active: root.modelData?.variant === Schemes.currentVariant
            asynchronous: true

            sourceComponent: MaterialIcon {
                text: "check"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.size(Config.appearance.font.title.medium.size).build()
}
        }
    }
}
