import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import CNS
import CNS.Config
import CNS.I18n
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
    // CNS: hardware/host details that SysInfo does not surface directly
    property string sysHostname
    property string sysDevice
    property string sysKernel
    property string sysFirmware
    property string sysShell

    title: Tr.tr("About")

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

        // Parsed from the cns CLI's package listing; the sh wrapper avoids a
        // warning when the (optional) CLI isn't installed
        Process {
            running: true
            command: ["sh", "-c", "cns --version 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const m = text.match(/cns-cli\S*\s+(\d+(?:\.\d+)*)/);
                    root.cliVersion = m ? m[1] : "";
                }
            }
        }

        // CNS: DMI + hostname probes, with SysInfo as fallback
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

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: CUtils.version ? `v${CUtils.version}` : "…"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }
            }
        }

        // System
        SectionHeader {
            text: Tr.tr("System")
        }

        InfoRow {
            first: true
            label: Tr.tr("Hostname")
            value: root.sysHostname || SysInfo.hostname || "…"
        }

        InfoRow {
            label: Tr.trCtx("Device", "system model name")
            value: root.sysDevice || SysInfo.device || "…"
        }

        InfoRow {
            label: Tr.tr("Distro")
            value: SysInfo.osPrettyName || SysInfo.osName || "…"
        }

        InfoRow {
            label: Tr.tr("Kernel")
            value: root.sysKernel || SysInfo.kernel || "…"
        }

        InfoRow {
            last: true
            // TRANSLATORS: BIOS or UEFI firmware version
            label: Tr.tr("Firmware")
            value: root.sysFirmware || SysInfo.firmware || "…"
        }

        // Software
        SectionHeader {
            text: Tr.tr("Software")
        }

        InfoRow {
            first: true
            label: Tr.trCtx("Shell", "the caelestia shell itself, not a unix shell")
            value: CUtils.version || "…"
        }

        InfoRow {
            label: Tr.tr("Login shell")
            value: root.sysShell || "…"
        }

        InfoRow {
            label: Tr.trCtx("CLI", "the caelestia command line tool")
            value: root.cliVersion || "…"
        }

        InfoRow {
            label: "Quickshell"
            value: root.quickshellVersion || "…"
        }

        InfoRow {
            last: true
            label: "Qt"
            value: CUtils.qtVersion || "…"
        }

        // Plugins
        SectionHeader {
            text: Tr.tr("Plugins")
        }

        InfoRow {
            first: true
            last: true
            label: Tr.tr("Loaded plugins")
            value: root.pluginCount.toString()
        }
    }
}
