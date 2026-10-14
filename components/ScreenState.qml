import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool utilities
    property bool sidebar

    // CNS: the four extra panels plus the weather-location editor toggle.
    // Dropped by the sync, but still referenced by Panels.qml, the panel
    // Wrappers, and ContentWindow's keyboardFocus/mask bindings.
    property bool keybinds
    property bool calendar
    property bool clipboard
    property bool notepad
    property bool editingWeatherLocation

    // Dashboard state
    property int dashboardTab
    property date dashboardDate: new Date()
}
