pragma ComponentBehavior: Bound

import QtQuick.Layouts
import CNS.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Session")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("General")
        }

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Enabled")
            checked: Config.session.enabled
            onToggled: GlobalConfig.session.enabled = checked
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Drag threshold")
            subtext: qsTr("Pixels dragged before the session panel opens")
            value: Config.session.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.session.dragThreshold = v
        }

        ToggleRow {
            Layout.fillWidth: true
            last: true
            text: qsTr("Vim keybinds")
            subtext: qsTr("Navigate session actions with keyboard shortcuts")
            checked: Config.session.vimKeybinds
            onToggled: GlobalConfig.session.vimKeybinds = checked
        }
    }
}
