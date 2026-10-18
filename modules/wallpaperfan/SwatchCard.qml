pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import CNS.Config
import qs.components
import qs.services

// One wallpaper as a card in the picker's deck: its picture, the colour chips
// of the scheme it would give the desktop, its name and details. A local
// wallpaper's chips come from the palette cache (matugen, as a dry run); a
// Wallhaven result wears the colours Wallhaven reports for the image instead.
//
// CNS notes, against the source this is ported from:
//  - `paletteCache` is passed in rather than reaching for a singleton; the
//    source's WallpaperSwatches is a Singleton, this module is a Scope.
//  - `Colors.*` -> Colours.palette.m3*. Corner radii keep the source's literal
//    values: `DesktopTheme.rad(n)` is identity in the source's packaging build.
//  - `Glyph` -> MaterialIcon. The source's PanelDecor frame is dropped: it is
//    the desktop theme's window decoration, which has no Niri/CNS equivalent.
//  - The picture decodes at a fixed size rather than from the live item width,
//    and the card is grown by its own size rather than scaled by the deck.
//    Binding decode size to an animating width made Qt re-decode the image on
//    every frame of the grow/shrink, and a scale transform magnified an
//    already-rasterised card. Both were visible as a blank or blurry card.
//  - renderType is forced back to QtRendering on every text element here. CNS's
//    global StyledText sets Text.NativeRendering, which rasterises at the item's
//    own size and is then transformed like a bitmap — inside the deck's
//    scale+rotation that made all card text blocky. Upstream has no renderType
//    anywhere, so its default was already correct.
Item {
    id: card

    // The source's DesktopTheme.rad(n). Its "pill" shape rounds controls by half
    // again on top of the designed radius — that is what the source renders
    // with, and what gives the chips and fields their capsule corners. Taking
    // the bare `normal` instead leaves them rectangular.
    function rad(n: real): real { return Math.round(n * 1.5); }

    required property var entry
    property var paletteCache

    // The picture to draw. The source makes this explicit so a video's still
    // (a grabbed frame) can stand in for the file itself.
    property string picture: entry ? entry.fileUrl : ""
    property var imageColors: []

    property real u: 1
    property real front: 0
    property real dim: 0
    property bool current: false
    property bool favourite: false
    property bool saved: false
    property real download: -1
    property string title: ""
    property string meta: ""

    // The texture the card in front shows while a video plays in the preview
    // behind (a ShaderEffectSource), and how much of it shows.
    property var art: null
    property real artAspect: 16 / 10
    property real artOpacity: 1

    // Where the band of light is across the picture, 0..1; none outside
    // about -0.3..1.3. Driven by the picker's choose animation.
    property real shine: -1

    readonly property alias hovered: mouse.containsMouse

    signal clicked
    signal doubleClicked

    readonly property real pad: 9 * u
    readonly property real radius: rad(16) * u
    readonly property real thumbRadius: rad(10) * u
    readonly property real chipHeight: 22 * u

    // Fixed decode size, scaled by how big this card actually gets drawn.
    // A deck card sits at 1:1, but the chosen card is magnified by midScale
    // (up to 2.4x) while it rises — decoding for the deck size alone left the
    // big card upscaling a 340px texture to ~800px, which read as a blurry
    // card. Scaling the decode keeps it sharp without re-decoding per frame.
    property real decodeScale: 1
    readonly property size decodeSize: Qt.size(Math.ceil(340 * decodeScale), Math.ceil(220 * decodeScale))

    // Pre-loads this card's picture ahead of time, so a slot handed a new
    // wallpaper shows it at once instead of flashing empty.
    function preload(size: real): void {
        if (!entry || !picture || preloader.status === Image.Ready)
            return;
        preloader.sourceSize = card.decodeSize;
        preloader.source = card.picture;
    }

    Image {
        id: preloader

        visible: false
        asynchronous: true
        cache: true
        sourceSize: Qt.size(1, 1)
    }

    // The "current" tag pops (the picker calls it when a chosen card is set).
    function popTag() {
        pop.restart();
    }

    implicitWidth: 212 * u
    implicitHeight: pad + thumb.height + 8 * u + chipHeight * 5 + 9 * u + titleText.height + 2 * u + metaText.height + pad + 2 * u

    // Ink that reads on `c`.
    function inkOn(c: color): color {
        const q = Qt.color(c);
        const l = 0.2126 * q.r + 0.7152 * q.g + 0.0722 * q.b;
        return l > 0.5 ? Qt.rgba(0, 0, 0, 0.78) : Qt.rgba(1, 1, 1, 0.9);
    }

    // The scheme this wallpaper would give the desktop. Supplied by the picker
    // (which reads it out of the palette cache) rather than derived here, as
    // the source does.
    property var scheme: null

    // A local wallpaper with no scheme read yet falls back to its own palette
    // entry, so a card is never left undressed while the scan catches up.
    readonly property var effectiveScheme: scheme
        || (entry && !entry.item && paletteCache ? paletteCache.scheme(entry.fileName) : null)

    readonly property var dress: effectiveScheme ? paletteCache.dressOf(effectiveScheme)
        : imageColors && imageColors.length > 0 && paletteCache ? paletteCache.dressFrom(imageColors) : {
            surface: Colours.palette.m3surfaceContainer,
            raised: Colours.palette.m3surfaceContainerHigh,
            low: Colours.palette.m3surfaceContainerLow,
            ink: Colours.palette.m3onSurface,
            muted: Colours.palette.m3onSurfaceVariant,
            line: Colours.palette.m3outlineVariant,
            accent: Colours.palette.m3primary,
            accentInk: Colours.palette.m3onPrimary
        }

    // The five chips, top to bottom.
    readonly property var chips: effectiveScheme ? [
        { label: "primary", fill: effectiveScheme.primary },
        { label: "secondary", fill: effectiveScheme.secondary },
        { label: "tertiary", fill: effectiveScheme.tertiary },
        { label: "container", fill: effectiveScheme.primary_container },
        { label: "surface", fill: effectiveScheme.surface_container_highest }
    ] : imageColors && imageColors.length > 0 ? imageColors.slice(0, 5).map(c => ({ label: "", fill: c })) : []

    RectangularShadow {
        anchors.fill: body
        offset.y: (8 + 10 * card.front) * card.u
        blur: (22 + 18 * card.front) * card.u
        radius: body.radius
        color: Qt.rgba(0, 0, 0, 0.42 + 0.18 * card.front)
    }

    Rectangle {
        id: body

        anchors.fill: parent
        radius: card.radius
        antialiasing: true
        color: card.dress.surface
        border.width: Math.max(1, card.u * (1 + card.front * 0.6))
        border.color: Qt.tint(Qt.alpha(card.dress.line, 0.85), Qt.alpha(card.dress.accent, card.front * 0.85))

        // ── The wallpaper ────────────────────────────────────────────────
        Rectangle {
            id: thumbBase

            x: card.pad
            y: card.pad
            width: parent.width - card.pad * 2
            height: Math.round(width * 10 / 16)
            color: card.dress.raised
            antialiasing: true
            radius: card.thumbRadius

            MaterialIcon {
                anchors.centerIn: parent
                visible: thumb.status !== Image.Ready
                text: thumb.status === Image.Error ? "broken_image" : card.entry && card.entry.video ? "movie" : "image"
                fontStyle: Tokens.font.icon.size(22 * card.u).build()
                renderType: Text.QtRendering
                color: Qt.alpha(card.dress.muted, 0.5)
            }
        }

        Image {
            id: thumb

            anchors.fill: thumbBase
            source: card.picture
            fillMode: Image.PreserveAspectCrop
            // Fixed, not bound to the live width: see the note at the top.
            sourceSize: card.decodeSize
            asynchronous: true
            cache: true
            smooth: true
            antialiasing: true
            opacity: status === Image.Ready ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        Loader {
            anchors.fill: thumbBase
            active: !!card.art
            visible: card.artOpacity > 0
            opacity: card.artOpacity
            sourceComponent: CardPicture {
                source: card.art
                sourceAspect: card.artAspect
                shine: card.shine
            }
        }

        // Rounds the picture's corners: a frame in the card's own colour whose
        // inside edge is the rounded corner (cheaper than a mask).
        Rectangle {
            visible: card.thumbRadius > 0
            x: thumbBase.x - border.width
            y: thumbBase.y - border.width
            width: thumbBase.width + border.width * 2
            height: thumbBase.height + border.width * 2
            radius: card.thumbRadius + border.width
            antialiasing: true
            color: "transparent"
            border.width: 5 * card.u
            border.color: card.dress.surface
        }

        // The wallpaper on screen now.
        Rectangle {
            id: currentTag

            x: thumbBase.x + 7 * card.u
            y: thumbBase.y + thumbBase.height - height - 7 * card.u
            visible: card.current
            width: currentRow.implicitWidth + 12 * card.u
            height: 19 * card.u
            radius: rad(9.5) * card.u
            antialiasing: true
            color: card.dress.accent
            transformOrigin: Item.Left

            Row {
                id: currentRow

                anchors.centerIn: parent
                spacing: 3 * card.u

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "check"
                    fontStyle: Tokens.font.icon.size(12 * card.u).build()
                    renderType: Text.QtRendering
                    color: card.dress.accentInk
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("current")
                    font.pixelSize: 10 * card.u
                    font.weight: Font.Bold
                    renderType: Text.QtRendering
                    font.letterSpacing: 0.4 * card.u
                    color: card.dress.accentInk
                }
            }

            // Pops in when the card is set.
            SequentialAnimation {
                id: pop

                NumberAnimation {
                    target: currentTag
                    property: "scale"
                    from: 0.4
                    to: 1.12
                    duration: 200
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: currentTag
                    property: "scale"
                    to: 1
                    duration: 160
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Rectangle {
            visible: card.favourite
            x: thumbBase.x + thumbBase.width - width - 6 * card.u
            y: thumbBase.y + 6 * card.u
            width: 24 * card.u
            height: width
            radius: width / 2
            antialiasing: true
            color: Qt.rgba(0, 0, 0, 0.42)

            MaterialIcon {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 0.5 * card.u
                text: "favorite"
                fontStyle: Tokens.font.icon.size(14 * card.u).build()
                renderType: Text.QtRendering
                color: "#ff5c7a"
            }
        }

        Rectangle {
            visible: card.saved
            x: thumbBase.x + thumbBase.width - width - 6 * card.u
            y: thumbBase.y + thumbBase.height - height - 6 * card.u
            width: 24 * card.u
            height: width
            radius: width / 2
            antialiasing: true
            color: Qt.rgba(0, 0, 0, 0.5)

            MaterialIcon {
                anchors.centerIn: parent
                text: "download_done"
                fontStyle: Tokens.font.icon.size(14 * card.u).build()
                renderType: Text.QtRendering
                color: "white"
            }
        }

        // Download progress along the foot of the picture.
        Rectangle {
            visible: card.download >= 0
            x: thumbBase.x
            y: thumbBase.y + thumbBase.height - height
            width: thumbBase.width * Math.max(0.02, card.download)
            height: 3 * card.u
            color: card.dress.accent

            Behavior on width {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        // ── The chips ────────────────────────────────────────────────────
        Column {
            id: chipColumn

            x: card.pad
            y: thumbBase.y + thumbBase.height + 8 * card.u
            width: thumbBase.width

            Repeater {
                model: 5

                Rectangle {
                    id: chip

                    required property int index

                    readonly property var spec: card.chips[index] ?? null
                    readonly property real r: card.thumbRadius * 0.7

                    width: chipColumn.width
                    height: card.chipHeight
                    antialiasing: true
                    topLeftRadius: index === 0 ? r : 0
                    topRightRadius: index === 0 ? r : 0
                    bottomLeftRadius: index === 4 ? r : 0
                    bottomRightRadius: index === 4 ? r : 0
                    // Not read yet: a quiet ramp of the card's own colour.
                    color: spec ? spec.fill : Qt.tint(card.dress.raised, Qt.rgba(1, 1, 1, 0.02 + 0.025 * (4 - index)))

                    StyledText {
                        anchors.left: parent.left
                        anchors.leftMargin: 8 * card.u
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !!chip.spec && chip.spec.label !== ""
                        text: chip.spec ? chip.spec.label.toUpperCase() : ""
                        font.pixelSize: 8.5 * card.u
                        font.weight: Font.Bold
                        renderType: Text.QtRendering
                        font.letterSpacing: 1.1 * card.u
                        color: card.inkOn(chip.color)
                        opacity: 0.85
                    }

                    StyledText {
                        anchors.right: parent.right
                        anchors.rightMargin: 8 * card.u
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !!chip.spec
                        text: chip.spec ? String(chip.spec.fill).toUpperCase() : ""
                        font.pixelSize: 9.5 * card.u
                        font.weight: Font.Medium
                        renderType: Text.QtRendering
                        color: card.inkOn(chip.color)
                    }
                }
            }
        }

        // ── Name and details ─────────────────────────────────────────────
        StyledText {
            id: titleText

            x: card.pad + 2 * card.u
            y: chipColumn.y + chipColumn.height + 9 * card.u
            width: thumbBase.width - 4 * card.u
            text: card.title
            elide: Text.ElideRight
            font.pixelSize: 13 * card.u
            font.weight: Font.DemiBold
            renderType: Text.QtRendering
            color: card.dress.ink
        }

        StyledText {
            id: metaText

            x: titleText.x
            y: titleText.y + titleText.height + 2 * card.u
            width: titleText.width
            text: card.meta
            elide: Text.ElideRight
            font.pixelSize: 10 * card.u
            renderType: Text.QtRendering
            color: card.dress.muted
        }

        Rectangle {
            anchors.fill: parent
            visible: opacity > 0
            opacity: card.hovered ? 0 : card.dim
            radius: parent.radius
            antialiasing: true
            color: "black"
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
        onDoubleClicked: card.doubleClicked()
    }

    // The tag pops in when this card is set, not when the deck reaches it.
    Connections {
        target: Wallpapers

        function onActualCurrentChanged(): void {
            Qt.callLater(() => {
                if (card.current && card.front > 0.5)
                    pop.restart();
            });
        }
    }
}