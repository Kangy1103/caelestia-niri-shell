import qs.components
import qs.services
import CNS.Config
import QtQuick

Item {
    id: root

    required property Schemes.Scheme modelData
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

        StyledRect {
            id: preview

            anchors.verticalCenter: parent.verticalCenter

            border.width: 1
            border.color: Qt.alpha(`#${root.modelData?.colours?.outline}`, 0.5)

            color: `#${root.modelData?.colours?.surface}`
            radius: Tokens.rounding.small
            implicitWidth: parent.height * 0.8
            implicitHeight: parent.height * 0.8

            Item {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right

                implicitWidth: parent.implicitWidth / 2
                clip: true

                StyledRect {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right

                    implicitWidth: preview.implicitWidth
                    color: `#${root.modelData?.colours?.primary}`
                    radius: Tokens.rounding.small
                }
            }
        }

        Column {
            anchors.left: preview.right
            anchors.leftMargin: Tokens.spacing.large
            anchors.verticalCenter: parent.verticalCenter

            width: parent.width - preview.width - anchors.leftMargin - (current.active ? current.width + Tokens.spacing.large : 0)
            spacing: 0

            StyledText {
                text: root.modelData?.flavour ?? ""
                font.pointSize: Tokens.font.body.medium.pointSize
            }

            StyledText {
                text: root.modelData?.name ?? ""
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

            active: `${root.modelData?.name} ${root.modelData?.flavour}` === Schemes.currentScheme
            asynchronous: true

            sourceComponent: MaterialIcon {
                text: "check"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.size(Tokens.font.title.medium.pointSize).build()
}
        }
    }
}
