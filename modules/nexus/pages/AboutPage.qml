import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import CNS
import CNS.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    // Plugin support is not wired up yet; always 0 for now
    readonly property int pluginCount: 0

    property string quickshellVersion
    property string cliVersion
    property string sysHostname
    property string sysDevice
    property string sysKernel
    property string sysFirmware
    property string sysShell

    title: qsTr("About")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // e.g. "Quickshell 0.3.0 (revision ...)"
        Process {
            running: true
            command: ["quickshell", "--version"]
            stdout: StdioCollector {
                onStreamFinished: root.quickshellVersion = text.trim().split(" ")[1] ?? ""
            }
        }

        // Parsed from the caelestia CLI's package listing; the sh wrapper avoids a
        // warning when the (optional) CLI isn't installed
        Process {
            running: true
            command: ["sh", "-c", "caelestia --version 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const m = text.match(/caelestia-cli\S*\s+(\d+(?:\.\d+)*)/);
                    root.cliVersion = m ? m[1] : "";
                }
            }
        }

        Process {
            running: true
            command: ["sh", "-c", "hostname 2>/dev/null"]
            stdout: StdioCollector { onStreamFinished: root.sysHostname = text.trim() }
        }

        Process {
            running: true
            command: ["sh", "-c", "cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || uname -n 2>/dev/null"]
            stdout: StdioCollector { onStreamFinished: root.sysDevice = text.trim() }
        }

        Process {
            running: true
            command: ["uname", "-r"]
            stdout: StdioCollector { onStreamFinished: root.sysKernel = text.trim() }
        }

        Process {
            running: true
            command: ["sh", "-c", "cat /sys/devices/virtual/dmi/id/bios_version 2>/dev/null"]
            stdout: StdioCollector { onStreamFinished: root.sysFirmware = text.trim() }
        }

        Process {
            running: true
            command: ["sh", "-c", "basename \"${SHELL:-}\" 2>/dev/null || echo ''"]
            stdout: StdioCollector { onStreamFinished: root.sysShell = text.trim() }
        }

        // Hero
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: hero.implicitHeight + Tokens.padding.extraLarge * 2

            ColumnLayout {
                id: hero

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.largeIncreased * 2
                spacing: Tokens.spacing.small

                AnimatedLogo {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: implicitHeight
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.small
                    text: "Caelestia"
                    font: Tokens.font.headline.builders.large.width(110).build()
                }
            }
        }

        // System
        SectionHeader {
            text: qsTr("System")
        }

        InfoRow {
            first: true
            label: qsTr("Hostname")
            value: root.sysHostname || SysInfo.hostname || "…"
        }

        InfoRow {
            label: qsTr("Device")
            value: root.sysDevice || SysInfo.device || "…"
        }

        InfoRow {
            label: qsTr("Distro")
            value: SysInfo.osPrettyName || SysInfo.osName || "…"
        }

        InfoRow {
            label: qsTr("Kernel")
            value: root.sysKernel || SysInfo.kernel || "…"
        }

        InfoRow {
            last: true
            label: qsTr("Firmware")
            value: root.sysFirmware || SysInfo.firmware || "…"
        }

        // Software
        SectionHeader {
            text: qsTr("Software")
        }

        InfoRow {
            first: true
            label: qsTr("Shell")
            value: root.sysShell || "…"
        }

        InfoRow {
            label: qsTr("CLI")
            value: root.cliVersion || "…"
        }

        InfoRow {
            label: qsTr("Quickshell")
            value: root.quickshellVersion || "…"
        }

        InfoRow {
            last: true
            label: qsTr("Qt")
            value: CUtils.qtVersion || "…"
        }

        // Plugins
        SectionHeader {
            text: qsTr("Plugins")
        }

        InfoRow {
            first: true
            last: true
            label: qsTr("Loaded plugins")
            value: root.pluginCount.toString()
        }
    }
}
