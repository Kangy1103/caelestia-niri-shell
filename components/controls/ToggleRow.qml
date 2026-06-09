import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property string label
    property alias checked: toggle.checked
    property alias toggle: toggle

    Layout.fillWidth: true
    spacing: Config.appearance.spacing.large

    StyledText {
        Layout.fillWidth: true
        text: root.label
    }

    StyledSwitch {
        id: toggle

        cLayer: 2
    }
}
