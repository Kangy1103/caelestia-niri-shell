pragma ComponentBehavior: Bound

import ".."
import "../components"
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.containers
import qs.services
import Caelestia.Config
import qs.utils
import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property Session session

    property bool clockShowIcon: Config.bar.clock.showIcon ?? true
    property bool clockBackground: Config.bar.clock.background ?? false
    property bool clockShowDate: Config.bar.clock.showDate ?? false
    property bool persistent: Config.bar.persistent ?? true
    property bool showOnHover: Config.bar.showOnHover ?? true
    property int dragThreshold: Config.bar.dragThreshold ?? 20
    property bool showAudio: Config.bar.status.showAudio ?? true
    property bool showMicrophone: Config.bar.status.showMicrophone ?? true
    property bool showKbLayout: Config.bar.status.showKbLayout ?? false
    property bool showNetwork: Config.bar.status.showNetwork ?? true
    property bool showWifi: Config.bar.status.showWifi ?? true
    property bool showBluetooth: Config.bar.status.showBluetooth ?? true
    property bool showBattery: Config.bar.status.showBattery ?? true
    property bool showLockStatus: Config.bar.status.showLockStatus ?? true
    property bool activeWindowCompact: Config.bar.activeWindow.compact ?? false
    property bool activeWindowInverted: Config.bar.activeWindow.inverted ?? false
    property bool trayBackground: Config.bar.tray.background ?? false
    property bool trayCompact: Config.bar.tray.compact ?? false
    property bool trayRecolour: Config.bar.tray.recolour ?? false
    property int workspacesShown: Config.bar.workspaces.shown ?? 5
    property bool workspacesActiveIndicator: Config.bar.workspaces.activeIndicator ?? true
    property bool workspacesOccupiedBg: Config.bar.workspaces.occupiedBg ?? false
    property bool workspacesShowWindows: Config.bar.workspaces.showWindows ?? false
    property bool workspacesPerMonitor: Config.bar.workspaces.perMonitorWorkspaces ?? true
    property bool scrollWorkspaces: Config.bar.scrollActions.workspaces ?? true
    property bool scrollVolume: Config.bar.scrollActions.volume ?? true
    property bool scrollBrightness: Config.bar.scrollActions.brightness ?? true
    property bool popoutTray: Config.bar.popouts.tray ?? true
    property bool popoutStatusIcons: Config.bar.popouts.statusIcons ?? true
    property bool isDistLogo: Config.general.isDistLogo ?? false

    anchors.fill: parent

    Component.onCompleted: {
        if (Config.bar.entries) {
            entriesModel.clear();
            for (let i = 0; i < Config.bar.entries.length; i++) {
                const entry = Config.bar.entries[i];
                entriesModel.append({
                    id: entry.id,
                    enabled: entry.enabled !== false
                });
            }
        }
    }

    function saveConfig(entryIndex, entryEnabled) {
        Config.bar.clock.showIcon = root.clockShowIcon;
        Config.bar.clock.background = root.clockBackground;
        Config.bar.clock.showDate = root.clockShowDate;
        Config.bar.activeWindow.compact = root.activeWindowCompact;
        Config.bar.activeWindow.inverted = root.activeWindowInverted;
        Config.bar.persistent = root.persistent;
        Config.bar.showOnHover = root.showOnHover;
        Config.bar.dragThreshold = root.dragThreshold;
        Config.bar.status.showAudio = root.showAudio;
        Config.bar.status.showMicrophone = root.showMicrophone;
        Config.bar.status.showKbLayout = root.showKbLayout;
        Config.bar.status.showNetwork = root.showNetwork;
        Config.bar.status.showWifi = root.showWifi;
        Config.bar.status.showBluetooth = root.showBluetooth;
        Config.bar.status.showBattery = root.showBattery;
        Config.bar.status.showLockStatus = root.showLockStatus;
        Config.bar.tray.background = root.trayBackground;
        Config.bar.tray.compact = root.trayCompact;
        Config.bar.tray.recolour = root.trayRecolour;
        Config.bar.workspaces.shown = root.workspacesShown;
        Config.bar.workspaces.activeIndicator = root.workspacesActiveIndicator;
        Config.bar.workspaces.occupiedBg = root.workspacesOccupiedBg;
        Config.bar.workspaces.showWindows = root.workspacesShowWindows;
        Config.bar.workspaces.perMonitorWorkspaces = root.workspacesPerMonitor;
        Config.bar.scrollActions.workspaces = root.scrollWorkspaces;
        Config.bar.scrollActions.volume = root.scrollVolume;
        Config.bar.scrollActions.brightness = root.scrollBrightness;
        Config.bar.popouts.tray = root.popoutTray;
        Config.bar.popouts.statusIcons = root.popoutStatusIcons;
        Config.general.isDistLogo = root.isDistLogo;

        const entries = [];
        for (let i = 0; i < entriesModel.count; i++) {
            const entry = entriesModel.get(i);
            let enabled = entry.enabled;
            if (entryIndex !== undefined && i === entryIndex) {
                enabled = entryEnabled;
            }
            entries.push({
                id: entry.id,
                enabled: enabled
            });
        }
        Config.bar.entries = entries;
    }

    ListModel {
        id: entriesModel
    }

    ClippingRectangle {
        id: taskbarClippingRect
        anchors.fill: parent
        anchors.margins: Config.appearance.padding.medium
        anchors.leftMargin: 0
        anchors.rightMargin: Config.appearance.padding.medium

        radius: taskbarBorder.innerRadius
        color: "transparent"

        Loader {
            id: taskbarLoader

            anchors.fill: parent
            anchors.margins: Config.appearance.padding.largeIncreased + Config.appearance.padding.medium
            anchors.leftMargin: Config.appearance.padding.largeIncreased
            anchors.rightMargin: Config.appearance.padding.largeIncreased

            sourceComponent: taskbarContentComponent
        }
    }

    InnerBorder {
        id: taskbarBorder
        leftThickness: 0
        rightThickness: Config.appearance.padding.medium
    }

    Component {
        id: taskbarContentComponent

        StyledFlickable {
            id: sidebarFlickable
            flickableDirection: Flickable.VerticalFlick
            contentHeight: sidebarLayout.height

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: sidebarFlickable
            }

            ColumnLayout {
                id: sidebarLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top

                spacing: Config.appearance.spacing.large

                RowLayout {
                    spacing: Config.appearance.spacing.medium

                    StyledText {
                        text: qsTr("Taskbar")
                        font.pointSize: Config.appearance.font.title.medium.size
                        font.weight: 500
                    }
                }

                SectionContainer {
                    Layout.fillWidth: true
                    alignTop: true

                    StyledText {
                        text: qsTr("Status Icons")
                        font.pointSize: Config.appearance.font.body.medium.size
                    }

                    ConnectedButtonGroup {
                        rootItem: root

                        options: [
                            {
                                label: qsTr("Speakers"),
                                propertyName: "showAudio",
                                onToggled: function (checked) {
                                    root.showAudio = checked;
                                    root.saveConfig();
                                }
                            },
                            {
                                label: qsTr("Microphone"),
                                propertyName: "showMicrophone",
                                onToggled: function (checked) {
                                    root.showMicrophone = checked;
                                    root.saveConfig();
                                }
                            },
                            {
                                label: qsTr("Keyboard"),
                                propertyName: "showKbLayout",
                                onToggled: function (checked) {
                                    root.showKbLayout = checked;
                                    root.saveConfig();
                                }
                            },
                            {
                                label: qsTr("Network"),
                                propertyName: "showNetwork",
                                onToggled: function (checked) {
                                    root.showNetwork = checked;
                                    root.saveConfig();
                                }
                            },
                            {
                                label: qsTr("Wifi"),
                                propertyName: "showWifi",
                                onToggled: function (checked) {
                                    root.showWifi = checked;
                                    root.saveConfig();
                                }
                            },
                            {
                                label: qsTr("Bluetooth"),
                                propertyName: "showBluetooth",
                                onToggled: function (checked) {
                                    root.showBluetooth = checked;
                                    root.saveConfig();
                                }
                            },
                            {
                                label: qsTr("Battery"),
                                propertyName: "showBattery",
                                onToggled: function (checked) {
                                    root.showBattery = checked;
                                    root.saveConfig();
                                }
                            },
                            {
                                label: qsTr("Capslock"),
                                propertyName: "showLockStatus",
                                onToggled: function (checked) {
                                    root.showLockStatus = checked;
                                    root.saveConfig();
                                }
                            }
                        ]
                    }
                }

                RowLayout {
                    id: mainRowLayout
                    Layout.fillWidth: true
                    spacing: Config.appearance.spacing.large

                    ColumnLayout {
                        id: leftColumnLayout
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: Config.appearance.spacing.large

                        SectionContainer {
                            Layout.fillWidth: true
                            alignTop: true

                            StyledText {
                                text: qsTr("Icon")
                                font.pointSize: Config.appearance.font.body.medium.size
                            }

                            SwitchRow {
                                label: qsTr("Use distro logo")
                                checked: root.isDistLogo
                                onToggled: checked => {
                                    root.isDistLogo = checked;
                                    root.saveConfig();
                                }
                            }
                        }

                        SectionContainer {
                            Layout.fillWidth: true
                            alignTop: true

                            StyledText {
                                text: qsTr("Workspaces")
                                font.pointSize: Config.appearance.font.body.medium.size
                            }

                            StyledRect {
                                Layout.fillWidth: true
                                implicitHeight: workspacesShownRow.implicitHeight + Config.appearance.padding.largeIncreased * 2
                                radius: Config.appearance.rounding.large
                                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                                Behavior on implicitHeight {
                                    Anim {}
                                }

                                RowLayout {
                                    id: workspacesShownRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Config.appearance.padding.largeIncreased
                                    spacing: Config.appearance.spacing.large

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: qsTr("Shown")
                                    }

                                    CustomSpinBox {
                                        min: 1
                                        max: 20
                                        value: root.workspacesShown
                                        onValueModified: value => {
                                            root.workspacesShown = value;
                                            root.saveConfig();
                                        }
                                    }
                                }
                            }

                            StyledRect {
                                Layout.fillWidth: true
                                implicitHeight: workspacesActiveIndicatorRow.implicitHeight + Config.appearance.padding.largeIncreased * 2
                                radius: Config.appearance.rounding.large
                                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                                Behavior on implicitHeight {
                                    Anim {}
                                }

                                RowLayout {
                                    id: workspacesActiveIndicatorRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Config.appearance.padding.largeIncreased
                                    spacing: Config.appearance.spacing.large

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: qsTr("Active indicator")
                                    }

                                    StyledSwitch {
                                        checked: root.workspacesActiveIndicator
                                        onToggled: {
                                            root.workspacesActiveIndicator = checked;
                                            root.saveConfig();
                                        }
                                    }
                                }
                            }

                            StyledRect {
                                Layout.fillWidth: true
                                implicitHeight: workspacesOccupiedBgRow.implicitHeight + Config.appearance.padding.largeIncreased * 2
                                radius: Config.appearance.rounding.large
                                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                                Behavior on implicitHeight {
                                    Anim {}
                                }

                                RowLayout {
                                    id: workspacesOccupiedBgRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Config.appearance.padding.largeIncreased
                                    spacing: Config.appearance.spacing.large

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: qsTr("Occupied background")
                                    }

                                    StyledSwitch {
                                        checked: root.workspacesOccupiedBg
                                        onToggled: {
                                            root.workspacesOccupiedBg = checked;
                                            root.saveConfig();
                                        }
                                    }
                                }
                            }

                            StyledRect {
                                Layout.fillWidth: true
                                implicitHeight: workspacesShowWindowsRow.implicitHeight + Config.appearance.padding.largeIncreased * 2
                                radius: Config.appearance.rounding.large
                                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                                Behavior on implicitHeight {
                                    Anim {}
                                }

                                RowLayout {
                                    id: workspacesShowWindowsRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Config.appearance.padding.largeIncreased
                                    spacing: Config.appearance.spacing.large

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: qsTr("Show windows")
                                    }

                                    StyledSwitch {
                                        checked: root.workspacesShowWindows
                                        onToggled: {
                                            root.workspacesShowWindows = checked;
                                            root.saveConfig();
                                        }
                                    }
                                }
                            }

                            StyledRect {
                                Layout.fillWidth: true
                                implicitHeight: workspacesPerMonitorRow.implicitHeight + Config.appearance.padding.largeIncreased * 2
                                radius: Config.appearance.rounding.large
                                color: Colours.layer(Colours.palette.m3surfaceContainer, 2)

                                Behavior on implicitHeight {
                                    Anim {}
                                }

                                RowLayout {
                                    id: workspacesPerMonitorRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Config.appearance.padding.largeIncreased
                                    spacing: Config.appearance.spacing.large

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: qsTr("Per monitor workspaces")
                                    }

                                    StyledSwitch {
                                        checked: root.workspacesPerMonitor
                                        onToggled: {
                                            root.workspacesPerMonitor = checked;
                                            root.saveConfig();
                                        }
                                    }
                                }
                            }
                        }

                        SectionContainer {
                            Layout.fillWidth: true
                            alignTop: true

                            StyledText {
                                text: qsTr("Scroll Actions")
                                font.pointSize: Config.appearance.font.body.medium.size
                            }

                            ConnectedButtonGroup {
                                rootItem: root

                                options: [
                                    {
                                        label: qsTr("Workspaces"),
                                        propertyName: "scrollWorkspaces",
                                        onToggled: function (checked) {
                                            root.scrollWorkspaces = checked;
                                            root.saveConfig();
                                        }
                                    },
                                    {
                                        label: qsTr("Volume"),
                                        propertyName: "scrollVolume",
                                        onToggled: function (checked) {
                                            root.scrollVolume = checked;
                                            root.saveConfig();
                                        }
                                    },
                                    {
                                        label: qsTr("Brightness"),
                                        propertyName: "scrollBrightness",
                                        onToggled: function (checked) {
                                            root.scrollBrightness = checked;
                                            root.saveConfig();
                                        }
                                    }
                                ]
                            }
                        }
                    }

                    ColumnLayout {
                        id: middleColumnLayout
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: Config.appearance.spacing.large

                        SectionContainer {
                            Layout.fillWidth: true
                            alignTop: true

                            StyledText {
                                text: qsTr("Clock")
                                font.pointSize: Config.appearance.font.body.medium.size
                            }
                            
                            SwitchRow {
                                label: qsTr("Background")
                                checked: root.clockBackground
                                onToggled: checked => {
                                    root.clockBackground = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                label: qsTr("Show date")
                                checked: root.clockShowDate
                                onToggled: checked => {
                                    root.clockShowDate = checked;
                                    root.saveConfig();
                                }
                            }


                            SwitchRow {
                                label: qsTr("Show clock icon")
                                checked: root.clockShowIcon
                                onToggled: checked => {
                                    root.clockShowIcon = checked;
                                    root.saveConfig();
                                }
                            }
                        }

                        SectionContainer {
                            Layout.fillWidth: true
                            alignTop: true

                            StyledText {
                                text: qsTr("Bar Behavior")
                                font.pointSize: Config.appearance.font.body.medium.size
                            }

                            SwitchRow {
                                label: qsTr("Persistent")
                                checked: root.persistent
                                onToggled: checked => {
                                    root.persistent = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                label: qsTr("Show on hover")
                                checked: root.showOnHover
                                onToggled: checked => {
                                    root.showOnHover = checked;
                                    root.saveConfig();
                                }
                            }

                            SectionContainer {
                                contentSpacing: Config.appearance.spacing.large

                                SliderInput {
                                    Layout.fillWidth: true

                                    label: qsTr("Drag threshold")
                                    value: root.dragThreshold
                                    from: 0
                                    to: 100
                                    suffix: "px"
                                    validator: IntValidator {
                                        bottom: 0
                                        top: 100
                                    }
                                    formatValueFunction: val => Math.round(val).toString()
                                    parseValueFunction: text => parseInt(text)

                                    onValueModified: newValue => {
                                        root.dragThreshold = Math.round(newValue);
                                        root.saveConfig();
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        id: rightColumnLayout
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: Config.appearance.spacing.large

                        SectionContainer {
                            Layout.fillWidth: true
                            alignTop: true

                            StyledText {
                                text: qsTr("Popouts")
                                font.pointSize: Config.appearance.font.body.medium.size
                            }

                            SwitchRow {
                                label: qsTr("Tray")
                                checked: root.popoutTray
                                onToggled: checked => {
                                    root.popoutTray = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                label: qsTr("Status icons")
                                checked: root.popoutStatusIcons
                                onToggled: checked => {
                                    root.popoutStatusIcons = checked;
                                    root.saveConfig();
                                }
                            }
                        }


                        SectionContainer {
                            Layout.fillWidth: true
                            alignTop: true

                            StyledText {
                                text: qsTr("Active window")
                                font.pointSize: Config.appearance.font.body.medium.size
                            }

                            SwitchRow {
                                label: qsTr("Compact")
                                checked: root.activeWindowCompact
                                onToggled: checked => {
                                    root.activeWindowCompact = checked;
                                    root.saveConfig();
                                }
                            }

                            SwitchRow {
                                label: qsTr("Inverted")
                                checked: root.activeWindowInverted
                                onToggled: checked => {
                                    root.activeWindowInverted = checked;
                                    root.saveConfig();
                                }
                            }
                        }

                        SectionContainer {
                            Layout.fillWidth: true
                            alignTop: true

                            StyledText {
                                text: qsTr("Tray Settings")
                                font.pointSize: Config.appearance.font.body.medium.size
                            }

                            ConnectedButtonGroup {
                                rootItem: root

                                options: [
                                    {
                                        label: qsTr("Background"),
                                        propertyName: "trayBackground",
                                        onToggled: function (checked) {
                                            root.trayBackground = checked;
                                            root.saveConfig();
                                        }
                                    },
                                    {
                                        label: qsTr("Compact"),
                                        propertyName: "trayCompact",
                                        onToggled: function (checked) {
                                            root.trayCompact = checked;
                                            root.saveConfig();
                                        }
                                    },
                                    {
                                        label: qsTr("Recolour"),
                                        propertyName: "trayRecolour",
                                        onToggled: function (checked) {
                                            root.trayRecolour = checked;
                                            root.saveConfig();
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }
            }
        }
    }
}
