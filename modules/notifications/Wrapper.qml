import QtQuick
import Quickshell
import CNS.Config
import qs.components

Item {
    id: root

    required property ShellScreen screen
    required property DrawerVisibilities visibilities
    required property Item sidebarPanel
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel
    property alias utilitiesPanel: content.utilitiesPanel

    readonly property bool displayEnabled: MonitorConfigManager.configForScreen(root.screen.name).notifs.enabled ?? true

    visible: height > 0 && displayEnabled
    anchors.topMargin: -5
    implicitWidth: Math.max(sidebarPanel.width, content.implicitWidth)
    implicitHeight: displayEnabled ? content.implicitHeight : 0

    Content {
        id: content

        anchors.topMargin: -root.anchors.topMargin
        visibilities: root.visibilities
    }
}
