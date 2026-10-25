pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import CNS.Multimedia
import qs.components
import qs.services

// Caelestia's live Visual + two snapshot transition design, with CNS's existing
// zoom/easing, fit modes and wallpaper-fan handoff retained.
Item {
    id: root

    property string source: Wallpapers.current
    property string screenName: ""
    property ShaderEffectSource capture1
    property ShaderEffectSource capture2
    property ShaderEffectSource currentCapture
    property real transitionProgress: 1
    property bool completed: false
    property bool capturePending: false
    readonly property bool immediate: Wallpapers.showPreview || Wallpapers.pickerCovers === screenName
    readonly property bool transitioning: transitionProgress < 1
    readonly property bool ready: live.ready && live.source === source
    readonly property bool failed: live.error

    function markDrawn(): void {
        if (ready && source && (!Wallpapers.pickerCovers || Wallpapers.pickerCovers === screenName))
            Wallpapers.drawn = source;
    }

    function ensureCaptures(): void {
        if (capture1)
            return;
        capture1 = snapshot.createObject(root);
        capture2 = snapshot.createObject(root);
        currentCapture = capture1;
    }

    function releaseCaptures(): void {
        capturePending = false;
        currentCapture = null;
        const first = capture1;
        const second = capture2;
        // Unload the shader before destroying its input textures. Clearing a
        // sampler on a still-loaded shader produces invalid-provider warnings.
        capture1 = null;
        capture2 = null;
        // Frozen ShaderEffectSource layers can retain their texture even after
        // sourceItem is cleared. Destroy the temporary objects after use.
        if (first) first.destroy();
        if (second) second.destroy();
    }

    function showReady(): void {
        if (!ready)
            return;
        markDrawn();
        if (!transitioning)
            return;
        if (immediate) {
            transitionProgress = 1;
            releaseCaptures();
        } else {
            transitionAnim.restart();
        }
    }

    function captured(item: ShaderEffectSource): void {
        item.visible = false;
        if (!capturePending || item !== currentCapture || !source)
            return;
        capturePending = false;
        transition.item.from = item;
        transitionProgress = 0;
        live.source = source;
        showReady();
    }

    onReadyChanged: showReady()

    onFailedChanged: {
        if (failed) {
            transitionAnim.stop();
            transitionProgress = 1;
            releaseCaptures();
        }
    }

    onSourceChanged: {
        if (!completed)
            return;
        transitionAnim.stop();
        if (!source || !live.source) {
            transitionProgress = 1;
            releaseCaptures();
            live.source = source;
            return;
        }
        // A pending snapshot already captures the displayed scene. Its
        // completion reads the latest source, so coalesce faster requests
        // instead of rescheduling a texture that may still be sampled.
        if (capturePending)
            return;
        ensureCaptures();
        capturePending = true;
        if (transitioning) {
            currentCapture = currentCapture === capture1 ? capture2 : capture1;
            currentCapture.sourceItem = transition.item;
        } else {
            currentCapture.sourceItem = liveCanvas;
        }
        currentCapture.visible = true;
        currentCapture.scheduleUpdate();
    }

    Component.onCompleted: {
        completed = true;
        live.source = source;
        showReady();
    }

    Connections {
        target: Wallpapers
        function onDrawnChanged(): void {
            // Selecting a wallpaper already shown in the live preview need not
            // change source or emit readyChanged again.
            if (!Wallpapers.drawn)
                Qt.callLater(root.markDrawn);
        }
        function onPickerCoversChanged(): void { Qt.callLater(root.markDrawn); }
    }

    Anim {
        id: transitionAnim
        target: root
        property: "transitionProgress"
        to: 1
        onFinished: root.releaseCaptures()
    }

    Component {
        id: snapshot

        ShaderEffectSource {
            anchors.fill: parent
            live: false
            visible: false
            onScheduledUpdateCompleted: root.captured(this)
        }
    }

    Item {
        id: liveCanvas
        anchors.fill: parent

        Loader {
            anchors.fill: parent
            active: Wallpapers.wallpaperFit === "blur" && live.type === VisualSource.Still
            sourceComponent: Visual {
                source: live.source
                fillMode: VisualSource.PreserveAspectCrop
                animate: false
                opacity: ready ? 1 : 0
                layer.enabled: opacity > 0
                layer.effect: MultiEffect {
                    autoPaddingEnabled: false
                    blurEnabled: true
                    blur: 1
                    blurMax: 64
                }
                Behavior on opacity { NumberAnimation { duration: 220 } }
            }
        }

        Visual {
            id: live
            anchors.fill: parent
            playing: !GameMode.enabled
            animate: false
            fillMode: Wallpapers.wallpaperFit === "crop" ? VisualSource.PreserveAspectCrop : VisualSource.PreserveAspectFit
        }
    }

    // The complete texture/shader graph exists only for a transition. This
    // frees frozen snapshot textures as well as the live transition target.
    Loader {
        id: transition
        anchors.fill: parent
        active: root.capture1 !== null
        visible: root.transitioning

        sourceComponent: ShaderEffect {
            property Item from
            property Item to: liveTexture
            property real progress: root.transitionProgress
            property real zoom: root.immediate ? 1 : 0.8
            fragmentShader: "qrc:/CNS/Multimedia/shaders/wallpaper.frag.qsb"

            ShaderEffectSource {
                id: liveTexture
                anchors.fill: parent
                sourceItem: root.transitioning ? liveCanvas : null
                live: true
                hideSource: true
                visible: false
            }
        }
    }
}
