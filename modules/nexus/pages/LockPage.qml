pragma ComponentBehavior: Bound

import QtQuick.Layouts
import CNS.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Lock screen")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Appearance")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            last: true
            text: qsTr("Recolour logo")
            subtext: qsTr("Tint the logo to match the theme")
            checked: Config.lock.recolourLogo
            onToggled: GlobalConfig.lock.recolourLogo = checked
        }

        SectionHeader {
            text: qsTr("Security")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Fingerprint unlock")
            checked: GlobalConfig.lock.enableFprint
            onToggled: GlobalConfig.lock.enableFprint = checked
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Max fingerprint tries")
            subtext: qsTr("Attempts before falling back to password")
            value: GlobalConfig.lock.maxFprintTries
            from: 1
            to: 10
            stepSize: 1
            onMoved: v => GlobalConfig.lock.maxFprintTries = v
        }

        SectionHeader {
            text: qsTr("Notifications")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Hide notifications")
            subtext: qsTr("Suppress popups while the screen is locked")
            checked: Config.lock.hideNotifs
            onToggled: GlobalConfig.lock.hideNotifs = checked
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Show extras")
            subtext: qsTr("Display weather and media on the lock screen")
            checked: Config.lock.showExtras
            onToggled: GlobalConfig.lock.showExtras = checked
        }
    }
}
