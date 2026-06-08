import qs.components.containers
import qs.components.widgets
import qs.services
import qs.config
import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property PersistentProperties visibilities
    required property Item panel
    readonly property int padding: Appearance.padding.xl

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right

    implicitWidth: Config.notifs.sizes.width + padding * 2

    readonly property real _cachedContentHeight: list.contentHeight

    implicitHeight: {
        const height = _cachedContentHeight;
        if (height === 0)
            return 0;

        let h = height;
        if (visibilities && panel) {
            if (visibilities.osd) {
                const maxH = panel.osd.y - Config.border.rounding * 2 - padding * 2;
                if (h > maxH)
                    h = maxH;
            }

            if (visibilities.session) {
                const maxH = panel.session.y - Config.border.rounding * 2 - padding * 2;
                if (h > maxH)
                    h = maxH;
            }
        }

        return Math.min((QsWindow.window?.screen?.height ?? 0) - Config.border.thickness * 2, h + padding * 2);
    }

    ClippingWrapperRectangle {
        anchors.fill: parent
        anchors.margins: root.padding

        color: "transparent"
        radius: Appearance.rounding.normal

        StyledListView {
            id: list

            model: ScriptModel {
                values: [...Notifs.popups].reverse()
            }

            anchors.fill: parent

            orientation: Qt.Vertical
            spacing: 0
            cacheBuffer: QsWindow.window?.screen.height ?? 0

            delegate: Item {
                id: wrapper

                required property Notifs.Notif modelData
                required property int index
                readonly property alias nonAnimHeight: notif.nonAnimHeight
                property int idx

                onIndexChanged: {
                    if (index !== -1)
                        idx = index;
                }

                implicitWidth: notif.implicitWidth
                implicitHeight: notif.implicitHeight + (idx === 0 ? 0 : Appearance.spacing.md)

                ListView.onRemove: removeAnim.start()

                SequentialAnimation {
                    id: removeAnim

                    PropertyAction {
                        target: wrapper
                        property: "ListView.delayRemove"
                        value: true
                    }
                    PropertyAction {
                        target: wrapper
                        property: "enabled"
                        value: false
                    }
                    PropertyAction {
                        target: wrapper
                        property: "implicitHeight"
                        value: 0
                    }
                    PropertyAction {
                        target: wrapper
                        property: "z"
                        value: 1
                    }
                    Anim {
                        target: notif
                        property: "x"
                        to: (notif.x >= 0 ? Config.notifs.sizes.width : -Config.notifs.sizes.width) * 2
                        duration: Appearance.anim.durations.normal
                        easing.bezierCurve: Appearance.anim.curves.emphasized
                    }
                    PropertyAction {
                        target: wrapper
                        property: "ListView.delayRemove"
                        value: false
                    }
                }

                ClippingRectangle {
                    anchors.top: parent.top
                    anchors.topMargin: wrapper.idx === 0 ? 0 : Appearance.spacing.md

                    color: "transparent"
                    radius: notif.radius
                    implicitWidth: notif.implicitWidth
                    implicitHeight: notif.implicitHeight

                    Notification {
                        id: notif

                        modelData: wrapper.modelData
                    }
                }
            }

            move: Transition {
                Anim {
                    property: "y"
                }
            }

            displaced: Transition {
                Anim {
                    property: "y"
                }
            }

            ExtraIndicator {
                anchors.top: parent.top
                extra: {
                    const count = list.count;
                    if (count === 0 || list.contentHeight <= list.height)
                        return 0;
                    const ratio = list.contentY / (list.contentHeight - list.height);
                    return Math.min(count, Math.floor(Math.max(0, ratio) * count));
                }
            }

            ExtraIndicator {
                anchors.bottom: parent.bottom
                extra: {
                    const count = list.count;
                    if (count === 0 || list.contentHeight <= list.height)
                        return 0;
                    const scrollBottom = list.contentHeight - (list.contentY + list.height);
                    const ratio = scrollBottom / (list.contentHeight - list.height);
                    return Math.min(count, Math.floor(Math.max(0, ratio) * count));
                }
            }
        }
    }

    Behavior on implicitHeight {
        Anim {}
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.expressiveDefaultSpatial
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
    }
}
