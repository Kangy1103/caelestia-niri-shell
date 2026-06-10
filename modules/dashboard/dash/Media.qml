import qs.components
import qs.components.misc
import qs.services
import Caelestia.Config
import qs.utils
import Caelestia.Services
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real playerProgress: {
        const active = Players.active;
        return active?.length ? active.position / active.length : 0;
    }

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: TokenConfig.sizes.dashboard.mediaWidth
    implicitHeight: TokenConfig.sizes.dashboard.mediaWidth * 2.5

    Behavior on playerProgress {
        Anim {
            duration: Config.appearance.anim.durations.large
        }
    }

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: Config.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    ServiceRef {
        service: BeatTracker
    }

    Shape {
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Colours.layer(Colours.palette.m3surfaceContainerHigh, 2)
            strokeWidth: TokenConfig.sizes.dashboard.mediaProgressThickness
            capStyle: Config.appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap

            PathAngleArc {
                centerX: cover.x + cover.width / 2
                centerY: cover.y + cover.height / 2
                radiusX: (cover.width + TokenConfig.sizes.dashboard.mediaProgressThickness) / 2 + Config.appearance.spacing.small
                radiusY: (cover.height + TokenConfig.sizes.dashboard.mediaProgressThickness) / 2 + Config.appearance.spacing.small
                startAngle: -90 - TokenConfig.sizes.dashboard.mediaProgressSweep / 2
                sweepAngle: TokenConfig.sizes.dashboard.mediaProgressSweep
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: Colours.palette.m3primary
            strokeWidth: TokenConfig.sizes.dashboard.mediaProgressThickness
            capStyle: Config.appearance.rounding.scale === 0 ? ShapePath.SquareCap : ShapePath.RoundCap

            PathAngleArc {
                centerX: cover.x + cover.width / 2
                centerY: cover.y + cover.height / 2
                radiusX: (cover.width + TokenConfig.sizes.dashboard.mediaProgressThickness) / 2 + Config.appearance.spacing.small
                radiusY: (cover.height + TokenConfig.sizes.dashboard.mediaProgressThickness) / 2 + Config.appearance.spacing.small
                startAngle: -90 - TokenConfig.sizes.dashboard.mediaProgressSweep / 2
                sweepAngle: TokenConfig.sizes.dashboard.mediaProgressSweep * root.playerProgress
            }

            Behavior on strokeColor {
                CAnim {}
            }
        }
    }

    StyledClippingRect {
        id: cover

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Config.appearance.padding.largeIncreased + TokenConfig.sizes.dashboard.mediaProgressThickness + Config.appearance.spacing.small

        implicitHeight: width
        color: Colours.tPalette.m3surfaceContainerHigh
        radius: Infinity

        MaterialIcon {
            anchors.centerIn: parent

            grade: 200
            text: "art_track"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.size((parent.width * 0.4) || 1).build()
}

        Image {
            id: image

            anchors.fill: parent

            source: Players.active?.trackArtUrl ?? ""
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: width
            sourceSize.height: height
        }
    }

    StyledText {
        id: title

        anchors.top: cover.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Config.appearance.spacing.large

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
        color: Colours.palette.m3primary
        font.pointSize: Config.appearance.font.body.medium.size

        width: parent.implicitWidth - Config.appearance.padding.largeIncreased * 2
        elide: Text.ElideRight
    }

    StyledText {
        id: album

        anchors.top: title.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Config.appearance.spacing.small

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (Players.active?.trackAlbum ?? qsTr("No media")) || qsTr("Unknown album")
        color: Colours.palette.m3outline
        font.pointSize: Config.appearance.font.label.large.size

        width: parent.implicitWidth - Config.appearance.padding.largeIncreased * 2
        elide: Text.ElideRight
    }

    StyledText {
        id: artist

        anchors.top: album.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Config.appearance.spacing.small

        animate: true
        horizontalAlignment: Text.AlignHCenter
        text: (Players.active?.trackArtist ?? qsTr("No media")) || qsTr("Unknown artist")
        color: Colours.palette.m3secondary

        width: parent.implicitWidth - Config.appearance.padding.largeIncreased * 2
        elide: Text.ElideRight
    }

    Row {
        id: controls

        anchors.top: artist.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Config.appearance.spacing.medium

        spacing: Config.appearance.spacing.small

        Control {
            icon: "skip_previous"
            canUse: Players.active?.canGoPrevious ?? false

            function onClicked(): void {
                Players.active?.previous();
            }
        }

        Control {
            icon: Players.active?.isPlaying ? "pause" : "play_arrow"
            canUse: Players.active?.canTogglePlaying ?? false

            function onClicked(): void {
                Players.active?.togglePlaying();
            }
        }

        Control {
            icon: "skip_next"
            canUse: Players.active?.canGoNext ?? false

            function onClicked(): void {
                Players.active?.next();
            }
        }
    }

    readonly property real bongoSpeed: {
        var bpm = 0;
        try { bpm = BeatTracker.bpm || 0; } catch(e) {}
        return bpm > 0 ? bpm / Config.services.mediaGifSpeedAdjustment : 0.5;
    }

    AnimatedImage {
        id: bongocat

        anchors.top: controls.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Config.appearance.spacing.small
        anchors.bottomMargin: Config.appearance.padding.largeIncreased
        anchors.margins: Config.appearance.padding.largeIncreased * 2

        playing: Players.active?.isPlaying ?? false
        speed: root.bongoSpeed
        source: Paths.absolutePath(Config.paths.mediaGif)
        asynchronous: true
        fillMode: AnimatedImage.PreserveAspectFit
    }

    component Control: StyledRect {
        id: control

        required property string icon
        required property bool canUse
        function onClicked(): void {
        }

        implicitWidth: Math.max(icon.implicitWidth, icon.implicitHeight) + Config.appearance.padding.extraSmall
        implicitHeight: implicitWidth

        StateLayer {
            disabled: !control.canUse
            radius: Config.appearance.rounding.full

            onClicked: {
                control.onClicked();
            }
        }

        MaterialIcon {
            id: icon

            anchors.centerIn: parent
            anchors.verticalCenterOffset: fontStyle.pointSize * 0.05

            animate: true
            text: control.icon
            color: control.canUse ? Colours.palette.m3onSurface : Colours.palette.m3outline
            fontStyle: Tokens.font.icon.size(Config.appearance.font.title.medium.size).build()
}
    }
}
