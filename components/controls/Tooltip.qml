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
                Compositor.tooltipText = root.text
                Compositor.tooltipTarget = root.target
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
                if (Compositor.tooltipTarget === root.target)
                    Compositor.tooltipTarget = null
            }
        }
    }

    Component.onDestruction: {
        if (Compositor.tooltipTarget === root.target)
            Compositor.tooltipTarget = null
    }
}
