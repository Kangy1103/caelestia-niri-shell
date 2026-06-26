import qs.components
import qs.services
import CNS.Config
import CNS
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property var list
    readonly property string math: list.search.text.slice(`${Config.launcher.actionPrefix}calc `.length)

    function onClicked(): void {
        Quickshell.execDetached(["wl-copy", Qalculator.eval(math, false)]);
        root.list.visibilities.launcher = false;
    }

    implicitHeight: TokenConfig.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.full

        onClicked: {
            root.onClicked();
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.large

        spacing: Tokens.spacing.large

        MaterialIcon {
            text: "function"
            fontStyle: Tokens.font.icon.size(Tokens.font.headline.large.pointSize).build()
Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            id: result

            color: {
                if (text.includes("error: ") || text.includes("warning: "))
                    return Colours.palette.m3error;
                if (!root.math)
                    return Colours.palette.m3onSurfaceVariant;
                return Colours.palette.m3onSurface;
            }

            text: root.math.length > 0 ? Qalculator.eval(root.math) : qsTr("Type an expression to calculate")
            elide: Text.ElideLeft

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }

        StyledRect {
            color: Colours.palette.m3tertiary
            radius: Tokens.rounding.large
            clip: true

            implicitWidth: (stateLayer.containsMouse ? label.implicitWidth + label.anchors.rightMargin : 0) + icon.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: Math.max(label.implicitHeight, icon.implicitHeight) + Tokens.padding.extraSmall * 2

            Layout.alignment: Qt.AlignVCenter

            StateLayer {
                id: stateLayer

                color: Colours.palette.m3onTertiary

                onClicked: {
                    Quickshell.execDetached([...Config.general.apps.terminal, "fish", "-C", `exec qalc -i '${root.math}'`]);
                    root.list.visibilities.launcher = false;
                }
            }

            StyledText {
                id: label

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: icon.left
                anchors.rightMargin: Tokens.spacing.small

                text: qsTr("Open in calculator")
                color: Colours.palette.m3onTertiary
                font.pointSize: Tokens.font.body.medium.pointSize

                opacity: stateLayer.containsMouse ? 1 : 0

                Behavior on opacity {
                    Anim {}
                }
            }

            MaterialIcon {
                id: icon

                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: Tokens.padding.medium

                text: "open_in_new"
                color: Colours.palette.m3onTertiary
                fontStyle: Tokens.font.icon.size(Tokens.font.title.medium.pointSize).build()
}

            Behavior on implicitWidth {
                Anim {
                    easing: Tokens.anim.emphasized
                }
            }
        }
    }
}
