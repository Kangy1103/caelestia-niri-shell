pragma ComponentBehavior: Bound

import qs.components
import Caelestia.Config
import qs.services
import Caelestia
import Quickshell
import QtQuick

Item {
    id: root

    readonly property int spacing: Config.appearance.spacing.small
    property bool flag
    property var _yCache: []
    property int _totalHeight: 0

    implicitWidth: TokenConfig.sizes.utilities.toastWidth - Config.appearance.padding.medium * 2
    implicitHeight: _totalHeight

    onFlagChanged: _recalcLayout()

    function _recalcLayout(): void {
        Qt.callLater(_doRecalc);
    }

    function _doRecalc(): void {
        const positions = [];
        let h = 0;
        let visible = 0;
        for (let i = 0; i < repeater.count; i++) {
            const item = repeater.itemAt(i);
            if (!item) { positions[i] = h; continue; }
            const closed = item.modelData?.closed ?? true;
            const hidden = !closed && visible >= Config.utilities.maxToasts;
            if (!closed && !hidden) {
                positions[i] = h;
                h += (item.implicitHeight || 0) + spacing;
                visible++;
            } else {
                positions[i] = h;
            }
        }
        root._yCache = positions;
        root._totalHeight = h > 0 ? h - spacing : 0;
    }

    Repeater {
        id: repeater

        model: ScriptModel {
            values: {
                const toasts = [];
                let count = 0;
                for (const toast of Toaster.toasts) {
                    toasts.push(toast);
                    if (!toast.closed) {
                        count++;
                        if (count > Config.utilities.maxToasts)
                            break;
                    }
                }
                return toasts;
            }
            onValuesChanged: root.flagChanged()
        }

        ToastWrapper {}
    }

    component ToastWrapper: MouseArea {
        id: toast

        required property int index
        required property Toast modelData

        readonly property bool previewHidden: {
            let extraHidden = 0;
            for (let i = 0; i < index; i++)
                if (Toaster.toasts[i].closed)
                    extraHidden++;
            return index >= Config.utilities.maxToasts + extraHidden;
        }

        onPreviewHiddenChanged: {
            if (initAnim.running && previewHidden)
                initAnim.stop();
        }

        opacity: modelData.closed || previewHidden ? 0 : 1
        scale: modelData.closed || previewHidden ? 0.7 : 1

        anchors.bottomMargin: root._yCache[index] ?? 0

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitHeight: toastInner.implicitHeight

        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: modelData.close()

        Component.onCompleted: modelData.lock(this)

        Anim {
            id: initAnim

            Component.onCompleted: running = !toast.previewHidden

            target: toast
            properties: "opacity,scale"
            from: 0
            to: 1
            duration: Config.appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: TokenConfig.appearance.curves.expressiveDefaultSpatial
        }

        ParallelAnimation {
            running: toast.modelData.closed
            onStarted: {
                toast.anchors.bottomMargin = toast.anchors.bottomMargin;
                root._recalcLayout();
            }
            onFinished: toast.modelData.unlock(toast)

            Anim {
                target: toast
                property: "opacity"
                to: 0
            }
            Anim {
                target: toast
                property: "scale"
                to: 0.7
            }
        }

        ToastItem {
            id: toastInner

            modelData: toast.modelData
        }

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on anchors.bottomMargin {
            Anim {
                duration: Config.appearance.anim.durations.expressiveDefaultSpatial
                easing.bezierCurve: TokenConfig.appearance.curves.expressiveDefaultSpatial
            }
        }
    }
}
