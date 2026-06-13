pragma ComponentBehavior: Bound

import qs.services
import CNS.Config
import QtQuick

Item {
    id: root

    // Constants
    readonly property Item anchorWs: Niri.wsContextAnchor
    readonly property int anchorWsCount: {
        if (Niri.wsContextType === "workspace" || Niri.wsContextType === "workspaces")
            return 1;
        // For item context, check if anchor has wsWindowCount (WindowIcon) or use 1
        return anchorWs?.wsWindowCount ?? anchorWs?.windowCount ?? 1;
    }
    readonly property real itemH: anchorWs ? (anchorWs.height + Config.bar.workspaces.windowIconGap * 2) : Config.bar.workspaces.windowIconSize
    readonly property real expandedW: Config.bar.workspaces.windowContextWidth - Config.bar.workspaces.windowIconSize

    implicitHeight: anchorWs ? ((itemH + Config.appearance.padding.extraSmall) * anchorWsCount) : itemH - Config.appearance.padding.medium
    implicitWidth: root.expandedW
}
