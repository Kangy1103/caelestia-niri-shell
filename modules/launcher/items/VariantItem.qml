import qs.components
import qs.services
import CNS.Config
import QtQuick

Item {
    id: root

    required property M3Variants.Variant modelData
    required property var list

    implicitHeight: TokenConfig.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.small

        onClicked: {
            root.modelData?.onClicked(root.list);
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        anchors.margins: Tokens.padding.small

        MaterialIcon {
            id: icon

            text: root.modelData?.icon ?? ""
            fontStyle: Tokens.font.icon.size(Tokens.font.headline.large.pointSize).build()
anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.largeIncreased
            anchors.verticalCenter: icon.verticalCenter

            width: parent.width - icon.width - anchors.leftMargin - (current.active ? current.width + Tokens.spacing.large : 0)
            spacing: 0

            StyledText {
                text: root.modelData?.name ?? ""
                font.pointSize: Tokens.font.body.medium.pointSize
            }

            StyledText {
                text: root.modelData?.description ?? ""
                font.pointSize: Tokens.font.label.large.pointSize
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
                fontStyle: Tokens.font.icon.size(Tokens.font.title.medium.pointSize).build()
}
        }
    }
}
