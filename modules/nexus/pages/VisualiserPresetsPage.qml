import QtQuick
import QtQuick.Layouts
import Quickshell
import CNS.Config
import CNS.Services
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    isSubPage: true
    title: qsTr("Cava Visualiser")

    GridLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        columns: 1
        rowSpacing: Tokens.spacing.extraSmall / 2
        columnSpacing: 0

        SectionHeader {
            Layout.fillWidth: true
            Layout.columnSpan: 1
            first: true
            text: qsTr("Presets")
        }

        Repeater {
            id: presetList
            model: VisualiserPresets.presets

            ConnectedRect {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                Layout.columnSpan: 1
                first: index === 0
                last: index === presetList.count - 1
                implicitHeight: rowLayout.implicitHeight + Tokens.padding.medium * 2

                StateLayer {
                    onClicked: VisualiserPresets.applyPreset(modelData.name)
                }

                RowLayout {
                    id: rowLayout
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.name
                            font: Tokens.font.body.small
                            color: modelData.name === VisualiserPresets.current ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: modelData.description
                            color: Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                        }
                    }

                    StyledText {
                        text: {
                            if (modelData.style === "bars") return qsTr("Bars");
                            if (modelData.style === "waveform") return qsTr("Waveform");
                            return qsTr("Filled");
                        }
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }

                    MaterialIcon {
                        visible: modelData.name === VisualiserPresets.current
                        text: "check"
                        color: Colours.palette.m3primary
                        font: Tokens.font.icon.small
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.columnSpan: 1
            Layout.preferredHeight: Tokens.spacing.largeIncreased
        }

        SectionHeader {
            Layout.fillWidth: true
            Layout.columnSpan: 1
            text: qsTr("Custom")
        }

        ConnectedRect {
            first: true
            Layout.fillWidth: true
            implicitHeight: colorRow.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: colorRow
                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        text: qsTr("Primary colour")
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                    }

                    StyledInputField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("#rrggbb or empty for theme")
                        text: GlobalConfig.background.visualiser.primaryColor
                        validator: RegularExpressionValidator { regularExpression: /^(#[0-9a-fA-F]{6})?$/ }
                        onTextEdited: GlobalConfig.background.visualiser.primaryColor = text
                        onEditingFinished: root.forceActiveFocus()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        text: qsTr("Secondary colour")
                        font: Tokens.font.label.small
                        color: Colours.palette.m3outline
                    }

                    StyledInputField {
                        Layout.fillWidth: true
                        placeholderText: qsTr("#rrggbb or empty for theme")
                        text: GlobalConfig.background.visualiser.secondaryColor
                        validator: RegularExpressionValidator { regularExpression: /^(#[0-9a-fA-F]{6})?$/ }
                        onTextEdited: GlobalConfig.background.visualiser.secondaryColor = text
                        onEditingFinished: root.forceActiveFocus()
                    }
                }
            }
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Bar count")
            subtext: qsTr("Number of frequency bands")
            value: GlobalConfig.services.visualiserBars
            from: 10
            to: 120
            stepSize: 2
            toastOnChange: false
            onMoved: v => GlobalConfig.services.visualiserBars = v
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Sensitivity")
            subtext: qsTr("Amplitude multiplier")
            value: GlobalConfig.background.visualiser.sensitivity
            from: 0.1
            to: 5.0
            stepSize: 0.1
            toastOnChange: false
            onMoved: v => GlobalConfig.background.visualiser.sensitivity = v
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Smoothness")
            subtext: qsTr("Bar animation response time (ms)")
            value: GlobalConfig.background.visualiser.animationDuration
            from: 50
            to: 500
            stepSize: 10
            toastOnChange: false
            onMoved: v => GlobalConfig.background.visualiser.animationDuration = v
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Rounding")
            subtext: qsTr("Bar corner radius factor")
            value: GlobalConfig.background.visualiser.rounding
            from: 0
            to: 2
            stepSize: 0.25
            toastOnChange: false
            onMoved: v => GlobalConfig.background.visualiser.rounding = v
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Spacing")
            subtext: qsTr("Gap between bars")
            value: GlobalConfig.background.visualiser.spacing
            from: 0
            to: 3
            stepSize: 0.25
            toastOnChange: false
            onMoved: v => GlobalConfig.background.visualiser.spacing = v
        }

        Item {
            Layout.fillWidth: true
            Layout.columnSpan: 1
            Layout.preferredHeight: Tokens.spacing.largeIncreased
        }

        SectionHeader {
            Layout.fillWidth: true
            Layout.columnSpan: 1
            text: qsTr("Per display")
        }

        Repeater {
            id: perScreenList
            model: Quickshell.screens

            ColumnLayout {
                required property ShellScreen modelData
                required property int index

                spacing: Tokens.spacing.extraSmall / 2
                Layout.fillWidth: true

                SectionHeader {
                    Layout.fillWidth: true
                    first: index === 0
                    text: qsTr("%1 (%2 × %3)").arg(modelData.name).arg(modelData.width).arg(modelData.height)
                }

                ToggleRow {
                    Layout.fillWidth: true
                    first: true
                    text: qsTr("Visualiser")
                    subtext: qsTr("Audio visualiser on this display")
                    checked: MonitorConfigManager.configForScreen(modelData.name).background.visualiser.enabled
                    onToggled: MonitorConfigManager.configForScreen(modelData.name).background.visualiser.enabled = checked
                }

                ToggleRow {
                    Layout.fillWidth: true
                    last: true
                    text: qsTr("Auto-hide")
                    subtext: qsTr("Hide when windows are present")
                    checked: MonitorConfigManager.configForScreen(modelData.name).background.visualiser.autoHide
                    onToggled: MonitorConfigManager.configForScreen(modelData.name).background.visualiser.autoHide = checked
                }
            }
        }
    }
}
