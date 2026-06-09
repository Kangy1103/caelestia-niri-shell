import ".."
import qs.components
import qs.components.controls
import qs.components.effects
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

StyledRect {
    id: root

    property var options: [] // Array of {label: string, propertyName: string, onToggled: function}
    property var rootItem: null // The root item that contains the properties we want to bind to
    property string title: "" // Optional title text

    Layout.fillWidth: true
    implicitHeight: layout.implicitHeight + Config.appearance.padding.largeIncreased * 2
    radius: Config.appearance.rounding.large
    color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
    clip: true

    Behavior on implicitHeight {
        Anim {}
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Config.appearance.padding.largeIncreased
        spacing: Config.appearance.spacing.large

        StyledText {
            visible: root.title !== ""
            text: root.title
            font.pointSize: Config.appearance.font.body.medium.size
        }

        RowLayout {
            id: buttonRow
            Layout.alignment: Qt.AlignHCenter
            spacing: Config.appearance.spacing.small

            Repeater {
                id: repeater
                model: root.options

                delegate: TextButton {
                    id: button
                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    text: modelData.label

                    property bool _checked: false

                    checked: _checked
                    toggle: false
                    type: TextButton.Tonal

                    // Create binding in Component.onCompleted
                    Component.onCompleted: {
                        if (root.rootItem && modelData.propertyName) {
                            const propName = modelData.propertyName;
                            const rootItem = root.rootItem;
                            _checked = Qt.binding(function () {
                                return rootItem[propName] ?? false;
                            });
                        }
                    }

                    // Match utilities Toggles radius styling
                    // Each button has full rounding (not connected) since they have spacing
                    radius: stateLayer.pressed ? Config.appearance.rounding.small / 2 : internalChecked ? Config.appearance.rounding.small : Config.appearance.rounding.large

                    // Match utilities Toggles inactive color
                    inactiveColour: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                    // Adjust width similar to utilities toggles
                    Layout.preferredWidth: implicitWidth + (stateLayer.pressed ? Config.appearance.padding.largeIncreased : internalChecked ? Config.appearance.padding.small : 0)

                    onClicked: {
                        if (modelData.onToggled && root.rootItem && modelData.propertyName) {
                            const currentValue = root.rootItem[modelData.propertyName] ?? false;
                            modelData.onToggled(!currentValue);
                        }
                    }

                    Behavior on Layout.preferredWidth {
                        Anim {
                            duration: Config.appearance.anim.durations.expressiveFastSpatial
                            easing.bezierCurve: TokenConfig.appearance.curves.expressiveFastSpatial
                        }
                    }

                    Behavior on radius {
                        Anim {
                            duration: Config.appearance.anim.durations.expressiveFastSpatial
                            easing.bezierCurve: TokenConfig.appearance.curves.expressiveFastSpatial
                        }
                    }
                }
            }
        }
    }
}
