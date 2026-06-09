pragma ComponentBehavior: Bound

import qs.components.effects
import qs.services
import Caelestia.Config
import qs.utils
import Quickshell.Services.SystemTray
import QtQuick

MouseArea {
    id: root

    required property SystemTrayItem modelData

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    implicitWidth: Config.appearance.font.body.small.size * 2
    implicitHeight: Config.appearance.font.body.small.size * 2

    onClicked: event => {
        if (event.button === Qt.LeftButton)
            modelData.activate();
        else
            modelData.secondaryActivate();
    }

    ColouredIcon {
        id: icon

        anchors.fill: parent
        source: Icons.getTrayIcon(root.modelData.id, root.modelData.icon, Config.bar.tray.iconSubs)
        colour: Colours.palette.m3secondary
        layer.enabled: Config.bar.tray.recolour
    }
}