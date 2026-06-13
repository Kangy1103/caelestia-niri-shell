pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Border")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StepperRow {
            Layout.fillWidth: true
            first: true
            label: qsTr("Thickness")
            subtext: qsTr("Window border width in pixels")
            value: Config.border.thickness
            from: 2
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.border.thickness = v
        }

        StepperRow {
            Layout.fillWidth: true
            label: qsTr("Rounding")
            subtext: qsTr("Corner rounding radius")
            value: Config.border.rounding
            from: 0
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.border.rounding = v
        }

        StepperRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("Smoothing")
            subtext: qsTr("Border anti-aliasing smoothing level")
            value: Config.border.smoothing
            from: 0
            to: 30
            stepSize: 1
            onMoved: v => GlobalConfig.border.smoothing = v
        }
    }
}
