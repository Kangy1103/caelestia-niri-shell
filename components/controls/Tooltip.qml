import QtQuick
import qs.services

Item {
    id: root

    required property Item target
    required property string text
    property int delay: 500

    width: 0
    height: 0

    Timer {
        id: showTimer
        interval: root.delay
        onTriggered: {
            if (root.text !== "") {
                Niri.tooltipText = root.text
                Niri.tooltipTarget = root.target
            }
        }
    }

    Connections {
        target: root.target
        function onHoveredChanged() {
            if (target.hovered) {
                showTimer.start()
            } else {
                showTimer.stop()
                if (Niri.tooltipTarget === root.target)
                    Niri.tooltipTarget = null
            }
        }
    }

    Component.onDestruction: {
        if (Niri.tooltipTarget === root.target)
            Niri.tooltipTarget = null
    }
}
