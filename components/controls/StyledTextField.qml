pragma ComponentBehavior: Bound

import ".."
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Controls

TextField {
    id: root

    color: Colours.palette.m3onSurface
    placeholderTextColor: Colours.palette.m3outline
    font.family: Config.appearance.font.body.family
    font.pointSize: Config.appearance.font.body.small.size
    renderType: Text.QtRendering
    cursorVisible: !readOnly

    background: null

    cursorDelegate: StyledRect {
        id: cursor

        implicitWidth: 2
        color: Colours.palette.m3primary
        radius: Config.appearance.rounding.large
        
        // Hide immediately when focus is lost
        opacity: root.activeFocus && root.cursorVisible ? 1 : 0

        Timer {
            // Only run blink timer when focused
            running: root.activeFocus && root.cursorVisible
            repeat: true
            interval: 500
            onTriggered: cursor.opacity = (cursor.opacity === 1 ? 0 : 1)
            
            // Ensure cursor is visible when starting focus or moving
            onRunningChanged: if (running) cursor.opacity = 1
        }

        // Reset visibility when typing or moving cursor
        Connections {
            target: root
            function onCursorPositionChanged() {
                if (root.activeFocus) cursor.opacity = 1
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: 100 }
        }
    }

    Behavior on color {
        CAnim {}
    }

    Behavior on placeholderTextColor {
        CAnim {}
    }
}
