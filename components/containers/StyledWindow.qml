import Quickshell
import Quickshell.Wayland
import CNS.Config

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    required property string name

    WlrLayershell.namespace: `caelestia-${name}`
    color: "transparent"
    Config.screen: screen.name
    Tokens.screen: screen.name

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name
}
