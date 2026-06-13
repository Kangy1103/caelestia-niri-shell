import QtQuick
import QtQuick.Layouts
import Quickshell
import CNS
import CNS.Config
import CNS.Services
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Display")

    ColumnLayout {
        id: layout

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Component {
            id: sepComp

            SectionHeader {
                Layout.fillWidth: true
                text: qsTr("Global presets")
                Layout.topMargin: Tokens.spacing.largeIncreased
            }
        }

        Component {
            id: navRowComp

            NavRow {
                Layout.fillWidth: true
                first: true
                last: true
                icon: "tune"
                label: qsTr("Visualiser presets")
                status: VisualiserPresets.currentLabel
                onClicked: root.nState.openSubPage(1)
            }
        }

        Component {
            id: sectionComp

            ColumnLayout {
                required property ShellScreen modelData
                required property bool isFirst

                spacing: Tokens.spacing.extraSmall / 2
                Layout.fillWidth: true

                SectionHeader {
                    Layout.fillWidth: true
                    first: isFirst
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
                    text: qsTr("Auto-hide")
                    subtext: qsTr("Hide when windows are present")
                    checked: MonitorConfigManager.configForScreen(modelData.name).background.visualiser.autoHide
                    onToggled: MonitorConfigManager.configForScreen(modelData.name).background.visualiser.autoHide = checked
                }

                ToggleRow {
                    Layout.fillWidth: true
                    text: qsTr("Blur")
                    subtext: qsTr("Blur wallpaper behind visualiser bars")
                    checked: MonitorConfigManager.configForScreen(modelData.name).background.visualiser.blur
                    onToggled: MonitorConfigManager.configForScreen(modelData.name).background.visualiser.blur = checked
                }

                StepperRow {
                    Layout.fillWidth: true
                    label: qsTr("Rounding")
                    subtext: qsTr("Bar corner radius factor")
                    value: MonitorConfigManager.configForScreen(modelData.name).background.visualiser.rounding
                    from: 0
                    to: 2
                    stepSize: 0.25
                    toastOnChange: false
                    onMoved: v => MonitorConfigManager.configForScreen(modelData.name).background.visualiser.rounding = v
                }

                StepperRow {
                    Layout.fillWidth: true
                    last: true
                    label: qsTr("Spacing")
                    subtext: qsTr("Gap between bars")
                    value: MonitorConfigManager.configForScreen(modelData.name).background.visualiser.spacing
                    from: 0
                    to: 3
                    stepSize: 0.25
                    toastOnChange: false
                    onMoved: v => MonitorConfigManager.configForScreen(modelData.name).background.visualiser.spacing = v
                }
            }
        }

        Component.onCompleted: Qt.callLater(function() {
            var screens = Quickshell.screens;
            for (var i = 0; i < screens.length; i++) {
                sectionComp.createObject(layout, {
                    modelData: screens[i],
                    isFirst: i === 0
                });
            }
            sepComp.createObject(layout);
            navRowComp.createObject(layout);
        })
    }
}
