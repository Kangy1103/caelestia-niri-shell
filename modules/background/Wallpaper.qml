pragma ComponentBehavior: Bound

import qs.components
import qs.components.filedialog
import qs.components.widgets
import qs.services
import CNS.Config
import qs.utils
import CNS
import QtQuick

Item {
    id: root

    property string source: Wallpapers.current
    property string screenName: ""
    readonly property bool ready: impl.ready
    readonly property bool transitioning: impl.transitioning

    anchors.fill: parent

    Loader {
        z: 1
        anchors.fill: parent

        active: !root.source || impl.failed
        asynchronous: true

        sourceComponent: StyledRect {
            color: Colours.palette.m3surfaceContainer

            Row {
                anchors.centerIn: parent
                spacing: Tokens.spacing.extraExtraLarge

                MaterialIcon {
                    text: "sentiment_stressed"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.size(Tokens.font.headline.large.pointSize * 5).build()
}

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Tokens.spacing.small

                    StyledText {
                        text: qsTr("Wallpaper missing?")
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Tokens.font.headline.large.pointSize * 2
                        font.bold: true
                    }

                    StyledRect {
                        implicitWidth: selectWallText.implicitWidth + Tokens.padding.largeIncreased * 2
                        implicitHeight: selectWallText.implicitHeight + Tokens.padding.extraSmall * 2

                        radius: Tokens.rounding.full
                        color: Colours.palette.m3primary

                        FileDialog {
                            id: dialog

                            title: qsTr("Select a wallpaper")
                            filterLabel: qsTr("Image or Video files")
                            filters: Images.validImageExtensions.concat(["mp4", "mkv", "webm", "mov", "avi", "m4v"])
                            onAccepted: path => Wallpapers.setWallpaper(path)
                        }

                        StateLayer {
                            radius: parent.radius
                            color: Colours.palette.m3onPrimary

                            onClicked: {
                                dialog.open();
                            }
                        }

                        StyledText {
                            id: selectWallText

                            anchors.centerIn: parent

                            text: qsTr("Set it now!")
                            color: Colours.palette.m3onPrimary
                            font.pointSize: Tokens.font.title.medium.pointSize
                        }
                    }
                }
            }
        }
    }

    WallpaperImpl {
        id: impl
        anchors.fill: parent
        source: root.source
        screenName: root.screenName
    }
}
