import qs.components
import qs.components.controls
import qs.services
import CNS.Config
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    // Comfortable width to fit 4 workspace buttons in single row
    implicitWidth: 720
    implicitHeight: content.implicitHeight + Config.appearance.padding.largeIncreased * 2

    property var client: null

    Connections {
        target: Niri // Listen to the Niri singleton
        function onFocusedWindowChanged(): void {
            root.client = Niri.focusedWindow || Niri.lastFocusedWindow || null;
        }
    }

    Component.onCompleted: {
        root.client = Niri.focusedWindow || Niri.lastFocusedWindow;
    }

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Config.appearance.padding.largeIncreased
        spacing: Config.appearance.spacing.large

        // ***************************************************
        // WORKSPACE SECTION
        CollapsibleSection {
            id: moveWorkspaceDropdown
            Layout.fillWidth: true
            title: qsTr("Move Window to Workspace")

            GridLayout {
                id: wsGrid
                columns: 4
                rowSpacing: Config.appearance.spacing.large
                columnSpacing: Config.appearance.spacing.large
                Layout.fillWidth: true

                Repeater {
                    model: Niri.currentOutputWorkspaces

                    WorkspaceButton {
                        required property var modelData
                        readonly property bool isCurrent: modelData.is_focused

                        Layout.fillWidth: true
                        active: isCurrent
                        text: modelData.name ?? ("Workspace " + modelData.idx)
                        disabled: isCurrent

                        function onClicked(): void {
                            Niri.moveWindowToWorkspace(modelData.idx);
                        }
                    }
                }
            }
        }

        // ***************************************************
        // UTILITIES SECTION
        CollapsibleSection {
            id: utilities
            Layout.fillWidth: true
            title: qsTr("Window Utilities")
            expanded: true

            //  toggleWindowOpacity
            //  expandColumnToAvailable
            //  centerWindow
            //  screenshotWindow
            //  keyboardShortcutsInhibitWindow
            //  toggleWindowedFullscreen
            //  toggleFullscreen
            //  toggleMaximize

            GridLayout {
                columns: 3
                rowSpacing: Config.appearance.spacing.large
                columnSpacing: Config.appearance.spacing.large
                Layout.fillWidth: true

                // Row 1: Main window controls
                ActionButton {
                    Layout.fillWidth: true
                    icon: root.client?.is_fullscreen ? "fullscreen_exit" : "fullscreen"
                    text: qsTr("Fullscreen")
                    active: root.client?.is_fullscreen ?? false
                    function onClicked(): void {
                        Niri.toggleFullscreen();
                    }
                }

                ActionButton {
                    Layout.fillWidth: true
                    icon: "fullscreen_exit"
                    text: qsTr("Fake Fullscreen")
                    function onClicked(): void {
                        Niri.toggleWindowedFullscreen();
                    }
                }

                ActionButton {
                    Layout.fillWidth: true
                    icon: "center_focus_strong"
                    text: qsTr("Center Window")
                    disabled: !root.client
                    function onClicked(): void {
                        Niri.centerWindow();
                    }
                }

                // Row 2: Secondary actions
                ActionButton {
                    Layout.fillWidth: true
                    icon: "block"
                    text: qsTr("Inhibit Shortcuts")
                    function onClicked(): void {
                        Niri.keyboardShortcutsInhibitWindow();
                    }
                }

                ActionButton {
                    Layout.fillWidth: true
                    Layout.columnSpan: 2
                    icon: "photo_camera"
                    text: qsTr("Screenshot Window")
                    accent: true
                    function onClicked(): void {
                        Niri.screenshotWindow();
                    }
                }
            }
        }
    }

    // ***************************************************
    // COMPONENTS

    component Rect: StyledRect {
        radius: Config.appearance.rounding.small
        color: Colours.tPalette.m3surfaceContainer
    }

    // Workspace button - pill style for workspace selection
    component WorkspaceButton: StyledRect {
        id: wsBtn

        property bool active: false
        property alias disabled: stateLayer.disabled
        property alias text: label.text

        function onClicked(): void {}

        radius: Config.appearance.rounding.full
        color: active ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHigh

        implicitHeight: label.implicitHeight + Config.appearance.padding.extraSmall * 2
        implicitWidth: label.implicitWidth + Config.appearance.padding.medium * 2

        Behavior on color {
            CAnim {}
        }

        StateLayer {
            id: stateLayer
            radius: parent.radius
            color: active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

            onClicked: {
                wsBtn.onClicked();
            }
        }

        StyledText {
            id: label
            anchors.centerIn: parent
            color: active ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            font.pointSize: Config.appearance.font.label.large.size
            font.weight: active ? Font.Medium : Font.Normal

            Behavior on color {
                CAnim {}
            }
        }
    }

    // Action button - card style for utility actions
    component ActionButton: StyledRect {
        id: actionBtn

        property alias disabled: actionStateLayer.disabled
        property alias text: actionLabel.text
        property alias icon: actionIcon.text
        property bool accent: false
        property bool active: false

        function onClicked(): void {}

        radius: Config.appearance.rounding.small
        color: active ? Colours.palette.m3primaryContainer : accent ? Colours.palette.m3primaryContainer : Colours.palette.m3surfaceContainerHigh
        opacity: disabled ? 0.5 : 1

        implicitHeight: contentCol.implicitHeight + Config.appearance.padding.medium * 2
        implicitWidth: Math.max(contentCol.implicitWidth + Config.appearance.padding.medium * 2, 100)

        Behavior on color {
            CAnim {}
        }

        Behavior on opacity {
            Anim {
                duration: Config.appearance.anim.durations.small
            }
        }

        StateLayer {
            id: actionStateLayer
            radius: parent.radius
            color: active || accent ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface

            onClicked: {
                actionBtn.onClicked();
            }
        }

        Column {
            id: contentCol
            anchors.centerIn: parent
            spacing: Config.appearance.spacing.medium

            MaterialIcon {
                id: actionIcon
                anchors.horizontalCenter: parent.horizontalCenter
                color: active || accent ? Colours.palette.m3onPrimaryContainer : actionBtn.disabled ? Colours.palette.m3onSurfaceVariant : Colours.palette.m3onSurface
                fontStyle: Tokens.font.icon.size(Config.appearance.font.title.medium.size).build()
text: "radio_button_unchecked"

                Behavior on color {
                    CAnim {}
                }
            }

            StyledText {
                id: actionLabel
                anchors.horizontalCenter: parent.horizontalCenter
                color: active || accent ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.body.small.size
                horizontalAlignment: Text.AlignHCenter

                Behavior on color {
                    CAnim {}
                }
            }
        }
    }
}