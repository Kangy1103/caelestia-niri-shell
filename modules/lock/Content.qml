// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260610

import qs.components
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    required property var lock
    property bool showLeft: true
    property bool showRight: true
    spacing: 0
    clip: true

    Item {
        visible: root.showLeft
        Layout.fillWidth: true
        implicitHeight: weather.implicitHeight
        WeatherInfo { id: weather; rootHeight: root.height }
    }
    Rectangle {
        visible: root.showLeft
        Layout.fillWidth: true
        height: 1
        color: Qt.alpha(Colours.palette.m3outlineVariant, 0.35)
    }
    Item {
        visible: root.showLeft
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Tokens.padding.largeIncreased * 4
        Fetch { rootHeight: root.height }
    }
    Rectangle {
        visible: root.showLeft && media.implicitHeight > 0
        Layout.fillWidth: true
        height: 1
        color: Qt.alpha(Colours.palette.m3outlineVariant, 0.35)
    }
    Item {
        visible: root.showLeft
        Layout.fillWidth: true
        implicitHeight: media.implicitHeight
        Media { id: media; lock: root.lock }
    }
    Item {
        visible: root.showRight
        Layout.fillWidth: true
        implicitHeight: resources.implicitHeight
        Resources { id: resources }
    }
    Rectangle {
        visible: root.showRight
        Layout.fillWidth: true
        height: 1
        color: Qt.alpha(Colours.palette.m3outlineVariant, 0.35)
    }
    Item {
        visible: root.showRight
        Layout.fillWidth: true
        Layout.fillHeight: true
        NotifDock { anchors.fill: parent; lock: root.lock }
    }
}
