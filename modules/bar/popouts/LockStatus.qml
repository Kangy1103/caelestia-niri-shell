import qs.components
import qs.services
import Caelestia.Config
import QtQuick
import QtQuick.Layouts

// Lock status display - uses Niri service for reactive state
ColumnLayout {
    id: root

    spacing: Config.appearance.spacing.small

    StyledText {
        text: qsTr("Capslock: %1").arg(Niri.capsLock ? "Enabled" : "Disabled")
    }

    StyledText {
        text: qsTr("Numlock: %1").arg(Niri.numLock ? "Enabled" : "Disabled")
    }
}
