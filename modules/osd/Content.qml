pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import qs.utils
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Brightness.Monitor monitor
    required property var visibilities

    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left

    implicitWidth: layout.implicitWidth + Config.appearance.padding.largeIncreased * 2
    implicitHeight: layout.implicitHeight + Config.appearance.padding.largeIncreased * 2

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        spacing: Config.appearance.spacing.large

        // Speaker volume
        CustomMouseArea {
            implicitWidth: TokenConfig.sizes.osd.sliderWidth
            implicitHeight: TokenConfig.sizes.osd.sliderHeight

            function onWheel(event: WheelEvent) {
                if (event.angleDelta.y > 0)
                    Audio.incrementVolume();
                else if (event.angleDelta.y < 0)
                    Audio.decrementVolume();
            }

            FilledSlider {
                anchors.fill: parent

                icon: Icons.getVolumeIcon(value, Audio.muted)
                value: Audio.volume
                onMoved: Audio.setVolume(value)
            }
        }

        // Microphone volume
        WrappedLoader {
            shouldBeActive: Config.osd.enableMicrophone && (!Config.osd.enableBrightness || !root.visibilities.session)

            sourceComponent: CustomMouseArea {
                implicitWidth: TokenConfig.sizes.osd.sliderWidth
                implicitHeight: TokenConfig.sizes.osd.sliderHeight

                function onWheel(event: WheelEvent) {
                    if (event.angleDelta.y > 0)
                        Audio.incrementSourceVolume();
                    else if (event.angleDelta.y < 0)
                        Audio.decrementSourceVolume();
                }

                FilledSlider {
                    anchors.fill: parent

                    icon: Icons.getMicVolumeIcon(value, Audio.sourceMuted)
                    value: Audio.sourceVolume
                    onMoved: Audio.setSourceVolume(value)
                }
            }
        }

        // Brightness
        WrappedLoader {
            shouldBeActive: Config.osd.enableBrightness

            sourceComponent: CustomMouseArea {
                implicitWidth: TokenConfig.sizes.osd.sliderWidth
                implicitHeight: TokenConfig.sizes.osd.sliderHeight

                function onWheel(event: WheelEvent) {
                    const monitor = root.monitor;
                    if (!monitor)
                        return;
                    if (event.angleDelta.y > 0)
                        monitor.setBrightness(monitor.brightness + 0.1);
                    else if (event.angleDelta.y < 0)
                        monitor.setBrightness(monitor.brightness - 0.1);
                }

                FilledSlider {
                    anchors.fill: parent

                    icon: `brightness_${(Math.round(value * 6) + 1)}`
                    value: root.monitor?.brightness ?? 0
                    onMoved: root.monitor?.setBrightness(value)
                }
            }
        }
    }

    component WrappedLoader: Loader {
        required property bool shouldBeActive

        Layout.preferredHeight: shouldBeActive ? TokenConfig.sizes.osd.sliderHeight : 0
        opacity: shouldBeActive ? 1 : 0
        active: opacity > 0
        asynchronous: true
        visible: active

        Behavior on Layout.preferredHeight {
            Anim {
                easing.bezierCurve: TokenConfig.appearance.curves.emphasized
            }
        }

        Behavior on opacity {
            Anim {}
        }
    }
}
