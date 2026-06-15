pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import CNS.Blobs
import CNS.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.bar

StyledWindow {
    id: root

    readonly property alias bar: bar
    readonly property alias interactionWrapper: interactions

    readonly property bool hasSpecialWorkspace: false  // Niri: no special workspaces
    readonly property bool hasFullscreen: Niri.hasFullscreen

    property real fsTransitionProg: hasFullscreen ? 1 : 0
    readonly property real sdfBorderOffset: 2 * fsTransitionProg
    readonly property real borderThickness: contentItem.Config.border.thickness * (1 - fsTransitionProg)
    readonly property real borderRounding: contentItem.Config.border.rounding * (1 - fsTransitionProg)
    readonly property real shadowOpacity: 0.7 * (1 - fsTransitionProg)
    readonly property bool _panelsAnimating: {
        const d = panels.dashboard;
        const l = panels.launcher;
        const s = panels.sidebar;
        return (d.offsetScale > 0 && d.offsetScale < 1) ||
               (l.offsetScale > 0 && l.offsetScale < 1) ||
               (s.offsetScale > 0 && s.offsetScale < 1);
    }
    readonly property real borderLayoutThickness: hasFullscreen ? 0 : contentItem.Config.border.thickness

    property color surfaceColour: Colours.tPalette.m3surface

    readonly property int dragMaskPadding: 0  // Niri: no Hypr monitor data

    onHasFullscreenChanged: {
        if (hasFullscreen) {
            visibilities.launcher = false;
            visibilities.session = false;
            visibilities.dashboard = false;
            panels.popouts.close();
        }
    }

    name: "drawers"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: fsTransitionProg > 0 && contentItem.Config.general.showOverFullscreen ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: visibilities.launcher || visibilities.session || visibilities.keybinds || visibilities.editingWeatherLocation || visibilities.dashboard || visibilities.calendar || visibilities.clipboard || visibilities.notepad || panels.popouts.isDetached ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: hasFullscreen ? emptyRegion : (visibilities.launcher || visibilities.calendar || visibilities.keybinds || visibilities.sidebar || visibilities.notepad || visibilities.clipboard ? fullScreenRegion : regions)

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Behavior on fsTransitionProg {
        Anim {}
    }

    Behavior on surfaceColour {
        CAnim {}
    }

    Region {
        id: emptyRegion

        x: panels.notifications.x + bar.implicitWidth
        y: panels.notifications.y + root.borderThickness
        width: panels.notifications.width
        height: panels.notifications.height

        Region {
            x: root.width - width
            y: panels.osdWrapper.y + root.borderThickness
            width: panels.osdWrapper.width * (1 - panels.osd.offsetScale) + root.borderThickness
            height: panels.osd.height
        }
    }

    Region {
        id: fullScreenRegion
        x: bar.implicitWidth
        y: root.borderThickness
        width: root.width - bar.implicitWidth - root.borderThickness
        height: root.height - root.borderThickness * 2
    }

    Regions {
        id: regions

        bar: bar
        panels: panels
        win: root
    }

    StyledRect {
        anchors.fill: parent
        opacity: (visibilities.session && Config.session.enabled) || panels.popouts.detachedMode !== "" ? 0.5 : 0
        color: Colours.palette.m3scrim

        Behavior on opacity {
            Anim {
                type: Anim.SlowEffects
            }
        }
    }

    Item {
        anchors.fill: parent
        opacity: root.surfaceColour.a
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: root.shadowOpacity > 0 && !root._panelsAnimating
            blurMax: 15
            shadowColor: Qt.alpha(Colours.palette.m3shadow, Math.max(0, root.shadowOpacity))
        }

        BlobGroup {
            id: blobGroup

            color: root.surfaceColour
            smoothing: root.contentItem.Config.border.smoothing
        }

        BlobInvertedRect {
            anchors.fill: parent
            anchors.margins: -50
            group: blobGroup
            radius: root.borderRounding
            borderLeft: bar.implicitWidth - anchors.margins - root.sdfBorderOffset
            borderRight: root.borderThickness - anchors.margins - root.sdfBorderOffset
            borderTop: root.borderThickness - anchors.margins - root.sdfBorderOffset
            borderBottom: root.borderThickness - anchors.margins - root.sdfBorderOffset
        }

        PanelBg {
            id: dashBg

            panel: panels.dashboard
            deformAmount: 0.1
        }

        PanelBg {
            id: launcherBg

            panel: panels.launcher
            deformAmount: 0.1
        }

        PanelBg {
            id: sessionBg

            panel: panels.sessionWrapper
            deformAmount: 0.2
            x: panels.sessionWrapper.x + panels.session.x + bar.implicitWidth
            implicitWidth: panels.session.width
        }

        PanelBg {
            id: sidebarBg

            panel: panels.sidebar
            deformAmount: 0.03
            implicitHeight: panel.height * (1 / rawDeformMatrix.m22) + 2
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [utilsBg]
            bottomLeftRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
        }

        PanelBg {
            id: osdBg

            panel: panels.osdWrapper
            deformAmount: 0.25
            x: panels.osdWrapper.x + panels.osd.x + bar.implicitWidth
            implicitWidth: panels.osd.width
        }

        PanelBg {
            id: notifsBg

            panel: panels.notifications
        }

        PanelBg {
            id: utilsBg

            panel: panels.utilities
            deformAmount: panels.sidebar.visible ? 0.1 : 0.15
            exclude: panels.sidebar.offsetScale > 0.08 ? [] : [sidebarBg]
            topLeftRadius: Math.max(0, Math.min(1, panels.sidebar.offsetScale / 0.3)) * radius
        }

        PanelBg {
            id: popoutBg

            property real extraWidth: panels.popouts.isDetached ? 0 : 0.2

            panel: panels.popoutsWrapper
            deformAmount: panels.popouts.isDetached ? 0.05 : panels.popouts.hasCurrent ? 0.15 : 0.1
            x: panels.popoutsWrapper.x + panels.popouts.x + bar.implicitWidth - panels.popouts.width * extraWidth
            implicitWidth: panels.popouts.width * (1 + extraWidth)

            Behavior on extraWidth {
                Anim {}
            }
        }

        PanelBg {
            id: clipboardBg

            panel: panels.clipboard
            deformAmount: 0.1
        }

        PanelBg {
            id: notepadBg

            panel: panels.notepad
            deformAmount: 0.1
        }

        PanelBg {
            id: calendarBg

            panel: panels.calendar
            deformAmount: 0.1
        }

        PanelBg {
            id: keybindsBg

            panel: panels.keybinds
            deformAmount: 0.1
        }
    }

    DrawerVisibilities {
        id: visibilities

        Component.onCompleted: Visibilities.load(root.screen, this)
    }

    Interactions {
        id: interactions

        screen: root.screen
        popouts: panels.popouts
        visibilities: visibilities
        panels: panels
        bar: bar
        borderThickness: root.borderLayoutThickness
        fullscreen: root.hasFullscreen

        Panels {
            id: panels

            screen: root.screen
            visibilities: visibilities
            bar: bar
            borderThickness: root.borderThickness

            utilities.horizontalStretch: (sidebarBg.rawDeformMatrix.m11 - 1) / 2 + 1
            utilities.deformMatrix: utilsBg.rawDeformMatrix

            dashboard.transform: Matrix4x4 {
                matrix: dashBg.deformMatrix
            }
            launcher.transform: Matrix4x4 {
                matrix: launcherBg.deformMatrix
            }
            session.transform: Matrix4x4 {
                matrix: sessionBg.deformMatrix
            }
            sidebar.transform: Matrix4x4 {
                matrix: sidebarBg.deformMatrix
            }
            osd.transform: Matrix4x4 {
                matrix: osdBg.deformMatrix
            }
            notifications.transform: Matrix4x4 {
                matrix: notifsBg.deformMatrix
            }
            utilities.transform: Matrix4x4 {
                matrix: utilsBg.deformMatrix
            }
            popouts.transform: Matrix4x4 {
                matrix: popoutBg.deformMatrix
            }
            clipboard.transform: Matrix4x4 {
                matrix: clipboardBg.deformMatrix
            }
            notepad.transform: Matrix4x4 {
                matrix: notepadBg.deformMatrix
            }
            calendar.transform: Matrix4x4 {
                matrix: calendarBg.deformMatrix
            }
            keybinds.transform: Matrix4x4 {
                matrix: keybindsBg.deformMatrix
            }
        }

        BarWrapper {
            id: bar

            anchors.top: parent.top
            anchors.bottom: parent.bottom

            screen: root.screen
            visibilities: visibilities
            popouts: panels.popouts

            fullscreen: root.hasFullscreen

            Component.onCompleted: Visibilities.bars.set(root.screen, this)
        }
    }

    // Tooltip overlay — renders above all content, escapes clipping
    Rectangle {
        id: workspaceTooltip

        visible: Niri.tooltipTarget !== null
        z: 10000

        x: {
            if (Niri.tooltipTarget === null) return 0
            var cx = Niri.mousePos.x + 16
            if (cx + width > parent.width)
                cx = parent.width - width - 4
            return cx
        }
        y: {
            if (Niri.tooltipTarget === null) return 0
            var cy = Niri.mousePos.y - height / 2
            if (cy < 4) cy = 4
            if (cy + height > parent.height) cy = parent.height - height - 4
            return cy
        }

        width: Math.min(tooltipLabel.implicitWidth + 16, 350)
        height: tooltipLabel.implicitHeight + 10
        color: Colours.palette.m3surfaceContainerHighest
        radius: 8
        border.color: Colours.palette.m3outlineVariant
        border.width: 1
        clip: true

        StyledText {
            id: tooltipLabel
            anchors.centerIn: parent
            text: Niri.tooltipText
            width: parent.width - 16
            color: Colours.palette.m3onSurface
            font.pointSize: 10
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    component PanelBg: BlobRect {
        required property Item panel
        property real deformAmount: 0.15

        group: blobGroup
        x: panel.x + bar.implicitWidth
        y: panel.y + root.borderThickness
        implicitWidth: panel.width
        implicitHeight: panel.height
        radius: Tokens.rounding.extraLarge
        deformScale: (deformAmount * Config.appearance.deformScale) / 10000
    }
}
