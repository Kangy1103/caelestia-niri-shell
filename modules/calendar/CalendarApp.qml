pragma Singleton

import qs.components
import qs.services
import Quickshell
import QtQuick

Singleton {
    id: root

    function open(parent: Item): void {
        if (activeWindow)
            return;
        activeWindow = calendarWindowComp.createObject(parent);
    }

    function close(): void {
        if (activeWindow) {
            activeWindow.visible = false;
            activeWindow = null;
        }
    }

    function toggle(parent: Item): void {
        if (activeWindow)
            close();
        else
            open(parent);
    }

    property var activeWindow: null

    Component {
        id: calendarWindowComp

        FloatingWindow {
            id: win

            color: Colours.tPalette.m3surface
            title: qsTr("Calendar")

            implicitWidth: 480
            implicitHeight: calContent.implicitHeight

            minimumSize.width: implicitWidth
            minimumSize.height: implicitHeight
            maximumSize.width: implicitWidth
            maximumSize.height: implicitHeight

            onVisibleChanged: {
                if (!visible) {
                    root.activeWindow = null;
                    destroy();
                }
            }

            Content {
                id: calContent
                anchors.fill: parent
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
