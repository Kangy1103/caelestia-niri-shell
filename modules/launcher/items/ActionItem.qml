import qs.components
import qs.services
import CNS.Config
import qs.modules.launcher.services
import QtQuick

Item {
    id: root

    required property Actions.Action modelData
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
            fontStyle: Tokens.font.icon.size(Config.appearance.font.headline.large.size).build()
anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.large
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width
            implicitHeight: name.implicitHeight + desc.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.name ?? ""
                font.pointSize: Config.appearance.font.body.medium.size
            }

            StyledText {
                id: desc

                text: root.modelData?.desc ?? ""
                font.pointSize: Config.appearance.font.label.large.size
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: root.width - icon.width - Tokens.rounding.large * 2

                anchors.top: name.bottom
            }
        }
    }
}
