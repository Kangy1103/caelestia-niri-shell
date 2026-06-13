pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import CNS.Config
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

/**
 * PolkitDialog — authentication prompt overlay for niri-caelestia-shell.
 *
 * Shown as a full-screen layer-shell surface on the Overlay layer whenever
 * PolkitService.active is true.  The card design mirrors the lock screen's
 * Material Design 3 aesthetic.
 */
Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData

        screen: modelData

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "caelestia-polkit"
        WlrLayershell.keyboardFocus: PolkitService.active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        color: "transparent"

        // ── Visible only when a polkit request is in flight ───────────────────
        visible: PolkitService.active

        // ── Backdrop scrim ────────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            opacity: win.visible ? 1 : 0

            Behavior on opacity {
                Anim { duration: Tokens.anim.durations.normal }
            }
        }

        // ── Centred dialog card ───────────────────────────────────────────────
        Item {
            anchors.centerIn: parent
            implicitWidth: card.implicitWidth
            implicitHeight: card.implicitHeight
            width: implicitWidth
            height: implicitHeight

            // Animate card entry
            opacity: win.visible ? 1 : 0
            scale: win.visible ? 1 : 0.92

            Behavior on opacity {
                Anim { duration: Tokens.anim.durations.normal }
            }
            Behavior on scale {
                Anim {
                    duration: Tokens.anim.durations.expressiveDefaultSpatial
                    easing: Tokens.anim.expressiveDefaultSpatial
                }
            }

            StyledRect {
                id: card

                // Width governed by notification panel width × 1.6 for readability
                implicitWidth: Math.min(480, win.screen?.width ?? 480)
                implicitHeight: cardLayout.implicitHeight + Config.appearance.padding.largeIncreased * 2

                radius: Config.appearance.rounding.large
                color: Colours.tPalette.m3surfaceContainer

                // ── Keyboard handling ──────────────────────────────────────
                focus: win.visible
                Keys.onReturnPressed: dialogContent.trySubmit()
                Keys.onEnterPressed:  dialogContent.trySubmit()
                Keys.onEscapePressed: PolkitService.cancel()

                // ── Card content layout ────────────────────────────────────
                ColumnLayout {
                    id: cardLayout

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Config.appearance.padding.largeIncreased

                    spacing: Config.appearance.spacing.medium

                    // Header — icon + title
                    RowLayout {
                        spacing: Config.appearance.spacing.medium

                        StyledRect {
                            implicitWidth: headerIcon.font.pointSize + Config.appearance.padding.medium * 2
                            implicitHeight: implicitWidth
                            radius: Config.appearance.rounding.full
                            color: Colours.palette.m3secondaryContainer

                            MaterialIcon {
                                id: headerIcon
                                anchors.centerIn: parent
                                text: "admin_panel_settings"
                                color: Colours.palette.m3onSecondaryContainer
                                fontStyle: Tokens.font.icon.size(Config.appearance.font.title.medium.size).build()
}
                        }

                        ColumnLayout {
                            spacing: 2

                            StyledText {
                                text: qsTr("Authentication Required")
                                font.pointSize: Config.appearance.font.title.medium.size
                                font.weight: Font.DemiBold
                                color: Colours.palette.m3onSurface
                            }

                            StyledText {
                                visible: PolkitService.subjectName.length > 0
                                text: PolkitService.subjectName
                                font.pointSize: Config.appearance.font.label.large.size
                                color: Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }

                    // Polkit message
                    Loader {
                        active: PolkitService.cleanMessage.length > 0
                        visible: active
                        Layout.fillWidth: true

                        sourceComponent: StyledRect {
                            implicitHeight: msgText.implicitHeight + Config.appearance.padding.small * 2
                            radius: Config.appearance.rounding.small
                            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)

                            StyledText {
                                id: msgText
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: Config.appearance.padding.small

                                text: PolkitService.cleanMessage
                                font.pointSize: Config.appearance.font.body.small.size
                                color: Colours.palette.m3onSurfaceVariant
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }
                        }
                    }

                    // ── Input row ──────────────────────────────────────────
                    Item {
                        id: dialogContent

                        Layout.fillWidth: true
                        implicitHeight: inputBar.implicitHeight

                        // Helper called by Enter key or Authenticate button
                        function trySubmit(): void {
                            if (PolkitService.interactionAvailable && inputField.text.length > 0)
                                PolkitService.submit(inputField.text);
                        }

                        StyledRect {
                            id: inputBar
                            anchors.left: parent.left
                            anchors.right: parent.right
                            implicitHeight: inputRow.implicitHeight + Config.appearance.padding.small * 2

                            color: Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.75)
                            radius: Config.appearance.rounding.full
                            border.width: inputField.hasFocus ? 2 : 0
                            border.color: PolkitService.submitting
                                ? Colours.palette.m3secondary
                                : Colours.palette.m3primary

                            CAnim { properties: "color,border.width,border.color" }

                            RowLayout {
                                id: inputRow

                                anchors.fill: parent
                                anchors.margins: Config.appearance.padding.small
                                spacing: Config.appearance.spacing.medium

                                // State icon / busy indicator
                                Item {
                                    implicitWidth: implicitHeight
                                    implicitHeight: stateIcon.implicitHeight + Config.appearance.padding.extraSmall * 2

                                    MaterialIcon {
                                        id: stateIcon
                                        anchors.centerIn: parent
                                        animate: true
                                        text: PolkitService.submitting ? "hourglass_top" : "lock"
                                        color: PolkitService.submitting
                                            ? Colours.palette.m3secondary
                                            : Colours.palette.m3onSurfaceVariant
                                        fontStyle: Tokens.font.icon.size(Config.appearance.font.body.medium.size).build()
opacity: PolkitService.submitting ? 0 : 1
                                        Behavior on opacity { Anim {} }
                                    }

                                    StyledBusyIndicator {
                                        anchors.fill: parent
                                        running: PolkitService.submitting
                                    }
                                }

                                // Password / visible input
                                StyledTextField {
                                    id: inputField

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    placeholderText: PolkitService.cleanPrompt
                                    echoMode: PolkitService.responseVisible
                                        ? TextInput.Normal
                                        : TextInput.Password
                                    enabled: PolkitService.interactionAvailable && !PolkitService.submitting
                                    font.pointSize: Config.appearance.font.body.small.size

                                    Keys.onReturnPressed: dialogContent.trySubmit()
                                    Keys.onEnterPressed:  dialogContent.trySubmit()
                                    Keys.onEscapePressed: PolkitService.cancel()

                                    // Clear field on each new authentication flow
                                    Connections {
                                        target: PolkitService
                                        function onActiveChanged(): void {
                                            inputField.text = "";
                                            if (PolkitService.active)
                                                inputField.forceActiveFocus();
                                        }
                                        function onInteractionAvailableChanged(): void {
                                            if (PolkitService.interactionAvailable) {
                                                inputField.text = "";
                                                inputField.forceActiveFocus();
                                            }
                                        }
                                    }
                                }

                                // Submit arrow button
                                StyledRect {
                                    implicitWidth: implicitHeight
                                    implicitHeight: submitIcon.implicitHeight + Config.appearance.padding.small * 2

                                    color: inputField.text.length > 0 && PolkitService.interactionAvailable
                                        ? Colours.palette.m3primary
                                        : Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0.8)
                                    radius: Config.appearance.rounding.full

                                    CAnim { properties: "color" }

                                    StateLayer {
                                        color: inputField.text.length > 0 && PolkitService.interactionAvailable
                                            ? Colours.palette.m3onPrimary
                                            : Colours.palette.m3onSurface
                                        radius: Config.appearance.rounding.full

                                        onClicked: {
                                            dialogContent.trySubmit();
                                        }
                                    }

                                    MaterialIcon {
                                        id: submitIcon
                                        anchors.centerIn: parent
                                        text: "arrow_forward"
                                        color: inputField.text.length > 0 && PolkitService.interactionAvailable
                                            ? Colours.palette.m3onPrimary
                                            : Colours.palette.m3onSurface
                                        fontStyle: Tokens.font.icon.size(Config.appearance.font.body.medium.size).weight(500).build()
CAnim { properties: "color" }
                                    }
                                }
                            }
                        }
                    }

                    // ── Error / retry message ──────────────────────────────
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: errorText.implicitHeight

                        StyledText {
                            id: errorText
                            anchors.left: parent.left
                            anchors.right: parent.right

                            visible: PolkitService.failedAttempts > 0 && PolkitService.active
                            opacity: PolkitService.failedAttempts > 0 && PolkitService.active ? 1 : 0
                            text: qsTr("Incorrect password. Please try again.")
                            color: Colours.palette.m3error
                            font.pointSize: Config.appearance.font.label.large.size
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                            Behavior on opacity { Anim {} }
                        }
                    }

                    // ── Action buttons ─────────────────────────────────────
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: Config.appearance.spacing.medium

                        // Cancel button
                        StyledRect {
                            implicitWidth: cancelText.implicitWidth + Config.appearance.padding.large * 2
                            implicitHeight: cancelText.implicitHeight + Config.appearance.padding.small * 2

                            radius: Config.appearance.rounding.full
                            color: Colours.layer(Colours.palette.m3surfaceContainerHigh, 1)

                            StateLayer {
                                radius: Config.appearance.rounding.full
                                color: Colours.palette.m3onSurface

                                onClicked: {
                                    PolkitService.cancel();
                                }
                            }

                            StyledText {
                                id: cancelText
                                anchors.centerIn: parent
                                text: qsTr("Cancel")
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Config.appearance.font.label.large.size
                                font.weight: Font.Medium
                            }
                        }

                        // Authenticate button
                        StyledRect {
                            implicitWidth: authenticateText.implicitWidth + Config.appearance.padding.large * 2
                            implicitHeight: authenticateText.implicitHeight + Config.appearance.padding.small * 2

                            radius: Config.appearance.rounding.full
                            color: inputField.text.length > 0 && PolkitService.interactionAvailable
                                ? Colours.palette.m3primary
                                : Qt.alpha(Colours.palette.m3primary, 0.4)

                            CAnim { properties: "color" }

                            StateLayer {
                                radius: Config.appearance.rounding.full
                                color: Colours.palette.m3onPrimary
                                enabled: inputField.text.length > 0 && PolkitService.interactionAvailable

                                onClicked: {
                                    dialogContent.trySubmit();
                                }
                            }

                            StyledText {
                                id: authenticateText
                                anchors.centerIn: parent
                                text: qsTr("Authenticate")
                                color: Colours.palette.m3onPrimary
                                font.pointSize: Config.appearance.font.label.large.size
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
            }
        }
    }
}
