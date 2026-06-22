import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import CNS.Config
import qs.components
import qs.components.controls
import qs.components.effects
import qs.components.images
import qs.services
import QtMultimedia

Item {
    id: root

    function encodeFileUrl(path) {
        if (!path) return "";
        return "file://" + path.split('/').map(s => encodeURIComponent(s)).join('/');
    }

    readonly property string xdgDataDirs: Quickshell.env("XDG_DATA_DIRS")
    property string screenName: ""
    property bool isPrimaryScreen: !Quickshell.screens?.length || screenName === Quickshell.screens[0]?.name

    signal launchRequested

    function resolveSoundUrl(configPath: string): string {
        if (!configPath) return "";
        if (configPath.startsWith("root:"))
            return "file://" + Quickshell.shellPath(configPath.substring(5));
        if (configPath.startsWith("/"))
            return "file://" + configPath;
        return configPath;
    }

    function playLoginSound(): void {
        if (!GlobalConfig.notifs.soundEnabled) return;
        const url = root.resolveSoundUrl(GlobalConfig.notifs.soundLogin);
        if (!url) return;
        loginSound.source = url;
        loginSound.play();
    }

    SoundEffect {
        id: loginSound
        volume: 0.5
    }

    property bool pendingPasswordResponse: false
    property bool passwordSubmitRequested: false
    property bool cancelingExternalAuthForPassword: false
    property int defaultAuthTimeoutMs: 10000
    property int externalAuthTimeoutMs: 30000
    property int memoryFlushDelayMs: 120
    property string pendingLaunchCommand: ""
    property var pendingLaunchEnv: []
    property int passwordFailureCount: 0
    property int passwordAttemptLimitHint: 0
    property string authFeedbackMessage: ""
    property bool authFailed: false
    property bool greeterWallpaperOverrideExists: false
    property string pendingUsername: ""

    // ── Greetd connections ──────────────────────────────────────────────────

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired) {
                root.pendingPasswordResponse = true;
                authTimeout.interval = root.defaultAuthTimeoutMs;
                authTimeout.restart();
                if (root.passwordSubmitRequested)
                    root.submitBufferedPassword();
            } else if (error) {
                authTimeout.stop();
                GreeterState.pamState = "error";
                root.authFeedbackMessage = message;
                inputField.text = "";
                GreeterState.passwordBuffer = "";
                placeholderDelay.restart();
            } else {
                root.authFeedbackMessage = message;
            }
        }

        function onReadyToLaunch() {
            root.playLoginSound();
            root.authFeedbackMessage = "";
            var sessionCmd = GreeterState.selectedSession || GreeterState.sessionExecs[GreeterState.currentSessionIndex] || "niri-session";
            var sessionPath = GreeterState.selectedSessionPath || GreeterState.sessionPaths[GreeterState.currentSessionIndex] || "";
            GreetdMemory.setLastSessionId(sessionPath);
            GreetdMemory.setLastSuccessfulUser(GreeterState.username);
            root.pendingLaunchCommand = sessionCmd;
            root.pendingLaunchEnv = ["XDG_SESSION_TYPE=wayland"];
            memoryFlushTimer.restart();
        }

        function onAuthFailure(message) {
            GreeterState.pamState = "fail";
            root.authFeedbackMessage = "Incorrect password";
            root.authFailed = true;
            GreeterState.showPasswordInput = false;
            inputField.text = "";
            GreeterState.passwordBuffer = "";
            root.pendingPasswordResponse = false;
            authTimeout.stop();
            placeholderDelay.restart();
        }

        function onError(message) {
            GreeterState.pamState = "error";
            root.authFeedbackMessage = "Authentication error";
            GreeterState.showPasswordInput = false;
            inputField.text = "";
            GreeterState.passwordBuffer = "";
            root.pendingPasswordResponse = false;
            authTimeout.stop();
        }

        function onLaunched() {
            // Quickshell will exit; greetd replaces compositor with target session
        }
    }

    Timer {
        id: authTimeout
        interval: root.defaultAuthTimeoutMs
        onTriggered: {
            if (root.pendingPasswordResponse) {
                root.pendingPasswordResponse = false;
                GreeterState.showPasswordInput = false;
                GreeterState.pamState = "fail";
                root.authFeedbackMessage = "Authentication timed out";
                inputField.text = "";
                GreeterState.passwordBuffer = "";
            }
        }
    }

    Timer {
        id: memoryFlushTimer
        interval: root.memoryFlushDelayMs
        onTriggered: {
            var sessionCommand = root.pendingLaunchCommand;
            var launchEnv = root.pendingLaunchEnv;
            root.pendingLaunchCommand = "";
            root.pendingLaunchEnv = [];
            Greetd.launch(sessionCommand.split(" "), launchEnv);
        }
    }

    Timer {
        id: placeholderDelay
        interval: 4000
        onTriggered: { root.authFeedbackMessage = ""; root.authFailed = false; }
    }

    // ── Session scanning ────────────────────────────────────────────────────

    UsersService { id: localUsersService }
    SessionsService { id: localSessionsService }

    function refreshSessionList() {
        var newList = [];
        var newExecs = [];
        var newPaths = [];
        for (var i = 0; i < localSessionsService.count; i++) {
            var s = localSessionsService.sessions.get(i);
            newList.push(s.name);
            newExecs.push(s.exec);
            newPaths.push(s.path);
        }
        if (newList.length === 0) {
            newList = ["Niri"];
            newExecs = ["niri-session"];
            newPaths = [""];
        }
        GreeterState.sessionList = newList;
        GreeterState.sessionExecs = newExecs;
        GreeterState.sessionPaths = newPaths;
        finalizeSessionSelection();
    }

    function finalizeSessionSelection() {
        var savedSession = "";
        if (GreetdSettings.rememberLastSession && GreetdMemory.lastSessionId)
            savedSession = GreetdMemory.lastSessionId;
        if (savedSession) {
            for (var i = 0; i < GreeterState.sessionPaths.length; i++) {
                if (GreeterState.sessionPaths[i] === savedSession) {
                    GreeterState.currentSessionIndex = i;
                    GreeterState.selectedSession = GreeterState.sessionExecs[i];
                    GreeterState.selectedSessionPath = GreeterState.sessionPaths[i];
                    return;
                }
            }
        }
        GreeterState.currentSessionIndex = 0;
        GreeterState.selectedSession = GreeterState.sessionExecs[0] || "";
        GreeterState.selectedSessionPath = GreeterState.sessionPaths[0] || "";
    }

    // ── User handling ───────────────────────────────────────────────────────

    function submitUsername(rawValue) {
        var user = (rawValue || "").trim();
        if (!user) return;
        GreeterState.username = user;
        GreeterState.usernameInput = user;
        GreeterState.showPasswordInput = true;
        PortalService.getGreeterUserProfileImage(user);
        GreeterState.passwordBuffer = "";
        root.pendingPasswordResponse = false;
    }

    function submitBufferedPassword() {
        root.pendingPasswordResponse = false;
        authTimeout.interval = root.defaultAuthTimeoutMs;
        authTimeout.restart();
        Greetd.respond(GreeterState.passwordBuffer || "");
        GreeterState.passwordBuffer = "";
        inputField.text = "";
        return true;
    }

    function requestPasswordSessionTransition() {
        var hasPasswordBuffer = GreeterState.passwordBuffer && GreeterState.passwordBuffer.length > 0;
        if (!passwordSubmitRequested && !hasPasswordBuffer) return;
        if (cancelingExternalAuthForPassword) return;
        root.pendingPasswordResponse = false;
        authTimeout.interval = root.defaultAuthTimeoutMs;
        authTimeout.stop();
        Greetd.cancelSession();
    }

    function startAuthSession(submitPassword) {
        if (!GreeterState.showPasswordInput || !GreeterState.username) return;
        if (submitPassword && GreeterState.passwordBuffer) {
            passwordSubmitRequested = true;
            root.pendingPasswordResponse = false;
            authTimeout.interval = root.defaultAuthTimeoutMs;
            authTimeout.restart();
            Greetd.createSession(GreeterState.username);
        } else {
            root.pendingPasswordResponse = false;
            authTimeout.interval = root.defaultAuthTimeoutMs;
            authTimeout.restart();
            Greetd.createSession(GreeterState.username);
        }
    }

    Connections {
        target: GreetdSettings
        function onSettingsLoadedChanged() {
            if (GreetdSettings.settingsLoaded) {
                if (isPrimaryScreen) {
                    applyLastSuccessfulUser();
                    finalizeSessionSelection();
                }
            }
        }
        function onRememberLastUserChanged() {
            if (!isPrimaryScreen) return;
            if (!GreetdSettings.rememberLastUser && GreetdMemory.lastSuccessfulUser)
                GreetdMemory.setLastSuccessfulUser("");
            applyLastSuccessfulUser();
        }
        function onRememberLastSessionChanged() {
            if (!isPrimaryScreen) return;
            if (!GreetdSettings.rememberLastSession && GreetdMemory.lastSessionId)
                GreetdMemory.setLastSessionId("");
            finalizeSessionSelection();
        }
    }

    FileView {
        id: greeterWallpaperOverrideFile
        path: GreetdSettings.greeterWallpaperOverridePath
        printErrors: false
        onLoaded: { root.greeterWallpaperOverrideExists = true; }
        onLoadFailed: { root.greeterWallpaperOverrideExists = false; }
    }

    Component.onCompleted: {
        if (isPrimaryScreen) {
            applyLastSuccessfulUser();
            refreshSessionList();
        }
        greeterWallpaperOverrideFile.reload();
    }

    function applyLastSuccessfulUser() {
        if (!GreetdSettings.settingsLoaded || !GreetdSettings.rememberLastUser) return;
        var lastUser = GreetdMemory.lastSuccessfulUser;
        if (lastUser && !GreeterState.showPasswordInput && !GreeterState.username) {
            GreeterState.username = lastUser;
            GreeterState.usernameInput = lastUser;
            GreeterState.showPasswordInput = true;
            PortalService.getGreeterUserProfileImage(lastUser);
        }
    }

    // ── Background layers ──────────────────────────────────────────────────

    Rectangle {
        anchors.fill: parent
        color: Colours.palette.m3surface
        z: 0
    }

    Image {
        id: wallpaperBackground
        anchors.fill: parent
        source: {
            if (GlobalConfig.greeter.wallpaper !== "")
                return encodeFileUrl(GlobalConfig.greeter.wallpaper);
            if (GreetdSettings.greeterWallpaperPath !== "" && root.greeterWallpaperOverrideExists)
                return encodeFileUrl(GreetdSettings.greeterWallpaperPath);
            var p = Wallpapers.current || Config.paths.wallpaper || "";
            if (!p) return "";
            var src = Wallpapers.getColorSource(p);
            return src.startsWith("/") ? "file://" + src : src;
        }
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: parent.width
        sourceSize.height: parent.height
        z: 1
        visible: status === Image.Ready || status === Image.Loading

        layer.enabled: false
    }

    Rectangle {
        anchors.fill: parent
        z: 2
        color: Qt.alpha("#000000", 0.4)
    }

    // ── Clock ──────────────────────────────────────────────────────────────

    Item {
        id: clockContainer
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.2
        z: 3

        function calcTopOff(metrics) {
            return metrics.tightBoundingRect.y - metrics.boundingRect.y;
        }

        implicitWidth: hours.implicitWidth + Tokens.spacing.small + minutes.implicitWidth
        implicitHeight: hourMetrics.tightBoundingRect.height

        StyledText {
            id: hours
            y: -clockContainer.calcTopOff(hourMetrics)
            text: GreetdSettings.greeterUse24HourClock ? Time.hourStr : Time.hour12Str
            color: Colours.palette.m3primary
            font.pixelSize: 120
            font.weight: Font.Light

            TextMetrics {
                id: hourMetrics
                text: hours.text
                font: hours.font
            }
        }

        StyledText {
            id: minutes
            anchors.right: parent.right
            y: -clockContainer.calcTopOff(minuteMetrics)
            text: Time.minuteStr
            color: Colours.palette.m3secondary
            font.pixelSize: 120
            font.weight: Font.Light

            TextMetrics {
                id: minuteMetrics
                text: minutes.text
                font: minutes.font
            }
        }

        Loader {
            anchors.left: minutes.left
            anchors.leftMargin: minuteMetrics.tightBoundingRect.x
            y: hourMetrics.tightBoundingRect.height - implicitHeight
            active: !GreetdSettings.greeterUse24HourClock
            sourceComponent: Rectangle {
                color: Colours.tPalette.m3surfaceContainerHigh
                radius: Tokens.rounding.large
                implicitWidth: minuteMetrics.tightBoundingRect.width
                implicitHeight: amPmMetrics.tightBoundingRect.height + Tokens.padding.large * 2

                StyledText {
                    id: amPm
                    anchors.centerIn: parent
                    width: amPmMetrics.tightBoundingRect.width
                    height: amPmMetrics.tightBoundingRect.height
                    transform: Translate {
                        x: -amPmMetrics.tightBoundingRect.x
                        y: -clockContainer.calcTopOff(amPmMetrics)
                    }
                    text: Time.amPmStr
                    color: Colours.palette.m3onSurface
                    font.pixelSize: 28
                    font.weight: Font.Light
                    TextMetrics {
                        id: amPmMetrics
                        text: amPm.text
                        font: amPm.font
                    }
                }
            }
        }
    }

    // ── Date ───────────────────────────────────────────────────────────────

    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: clockContainer.bottom
        anchors.topMargin: Tokens.spacing.small
        z: 3
        text: Time.format("dddd, MMMM d").toUpperCase()
        color: Colours.palette.m3onSurface
        font.pixelSize: 20
        opacity: 0.9
    }

    // ── Auth column ────────────────────────────────────────────────────────

    Item {
        id: authColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: clockContainer.bottom
        anchors.topMargin: 120
        width: 380
        height: authContent.height
        z: 3

        Column {
            id: authContent
            width: parent.width
            spacing: 16

            // ── Profile image ──
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 120
                height: 120

                CnsCircularImage {
                    anchors.fill: parent
                    imageSource: PortalService.profileImage
                        ? (PortalService.profileImage.startsWith("/")
                            ? encodeFileUrl(PortalService.profileImage)
                            : PortalService.profileImage)
                        : ""
                    fallbackIcon: "person"
                }

                TapHandler {
                    onTapped: {
                        if (!GreeterState.showPasswordInput)
                            userPickerPopup.visible = !userPickerPopup.visible;
                        if (GreeterState.showPasswordInput) {
                            inputField.forceActiveFocus();
                        }
                    }
                }
            }

            // ── Combined input field (username or password) ──
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !GreeterState.showPasswordInput || GreeterState.username.length > 0
                text: GreeterState.username || "Select user"
                color: Colours.palette.m3onSurface
                font: Tokens.font.body.builders.large.weight(Font.DemiBold).build()

                TapHandler {
                    onTapped: {
                        if (!GreeterState.showPasswordInput && localUsersService.count > 1)
                            userPickerPopup.visible = !userPickerPopup.visible;
                    }
                }
            }

            Rectangle {
                id: inputArea
                width: parent.width
                height: 48
                radius: Tokens.rounding.full
                color: Colours.tPalette.m3surfaceContainer
                border.color: root.authFailed
                    ? Colours.palette.m3error
                    : (inputField.activeFocus ? Colours.palette.m3primary : "transparent")
                border.width: root.authFailed ? 2 : (inputField.activeFocus ? 2 : 0)

                Row {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 8

                    Item {
                        width: 40
                        height: parent.height

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: GreeterState.showPasswordInput ? "lock" : "person"
                            color: Colours.palette.m3onSurfaceVariant
                            fontStyle: Tokens.font.icon.medium
                        }
                    }

                    TextField {
                        id: inputField
                        width: parent.width - 40 - (enterButton.visible ? 40 : 0) - 8
                        height: parent.height
                        echoMode: GreeterState.showPasswordInput ? TextInput.Password : TextInput.Normal
                        placeholderText: GreeterState.showPasswordInput ? "Password" : "Username"
                        color: Colours.palette.m3onSurface
                        placeholderTextColor: Colours.palette.m3onSurfaceVariant
                        background: Rectangle { color: "transparent"; radius: Tokens.rounding.full }
                        font: Tokens.font.body.large
                        verticalAlignment: Qt.AlignVCenter

                        onTextChanged: {
                            if (GreeterState.showPasswordInput)
                                GreeterState.passwordBuffer = text;
                            else
                                GreeterState.usernameInput = text;
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                                if (GreeterState.showPasswordInput) {
                                    startAuthSession(true);
                                } else {
                                    submitUsername(text);
                                }
                            }
                            if (event.key === Qt.Key_Escape) {
                                if (GreeterState.showPasswordInput) {
                                    GreeterState.showPasswordInput = false;
                                    GreeterState.passwordBuffer = "";
                                    text = "";
                                }
                            }
                        }
                    }

                    Item {
                        id: enterButton
                        width: 40
                        height: parent.height
                        visible: !GreeterState.showPasswordInput
                            ? GreeterState.usernameInput.length > 0
                            : GreeterState.passwordBuffer.length > 0

                        MaterialIcon {
                            anchors.centerIn: parent
                            text: "arrow_forward"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.medium
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!GreeterState.showPasswordInput) {
                                    submitUsername(inputField.text);
                                } else {
                                    startAuthSession(true);
                                }
                            }
                        }
                    }
                }
            }

            // ── Auth feedback ──
            Column {
                width: parent.width
                spacing: 4

                // Caps lock warning
                StyledText {
                    width: parent.width
                    visible: Niri.capsLock && GreeterState.showPasswordInput
                    text: "Caps Lock is ON"
                    color: Colours.palette.m3warning || Colours.palette.m3error
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    opacity: 1
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // Auth error / info message
                StyledText {
                    id: feedbackText
                    width: parent.width
                    visible: root.authFeedbackMessage.length > 0
                    text: root.authFeedbackMessage
                    color: GreeterState.pamState === "fail" || GreeterState.pamState === "error"
                        ? Colours.palette.m3error
                        : Colours.palette.m3primary
                    font.pixelSize: 14
                    font.weight: GreeterState.pamState === "fail" ? Font.DemiBold : Font.Normal
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    opacity: root.authFeedbackMessage.length > 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
        }
    }

    // ── User picker popup ──────────────────────────────────────────────────

    Popup {
        id: userPickerPopup
        parent: authColumn
        x: 0
        y: -height - 8
        width: authColumn.width
        padding: 0
        modal: true
        dim: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.extraLarge
            border.color: Colours.palette.m3outlineVariant
            border.width: 1
        }

        contentItem: ListView {
            implicitHeight: Math.min(usersModel.count * 48, 240)
            clip: true
            model: ListModel { id: usersModel }

            delegate: Rectangle {
                required property string displayName
                required property string username
                width: ListView.view.width
                height: 48
                color: optionMouse.containsMouse ? Colours.layer(Colours.palette.m3primaryContainer, 1) : "transparent"
                radius: Tokens.rounding.small

                StyledText {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.spacing.large
                    text: displayName
                    color: GreeterState.username === username ? Colours.palette.m3primary : Colours.palette.m3onSurface
                    font: Tokens.font.body.large
                }

                MouseArea {
                    id: optionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        GreeterState.username = username;
                        GreeterState.showPasswordInput = true;
                        PortalService.getGreeterUserProfileImage(username);
                        userPickerPopup.close();
                        inputField.forceActiveFocus();
                    }
                }
            }
        }
    }

    // ── Session chooser ────────────────────────────────────────────────────

    CnsDropdown {
        id: sessionDropdown
        anchors.right: parent.right
        anchors.rightMargin: 28
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        z: 3
        text: "Session"
        currentValue: GreeterState.currentSessionIndex >= 0 && GreeterState.currentSessionIndex < GreeterState.sessionList.length
            ? GreeterState.sessionList[GreeterState.currentSessionIndex]
            : (GreeterState.sessionList.length > 0 ? GreeterState.sessionList[0] : "")
        options: GreeterState.sessionList
        openUpwards: true
        maxPopupHeight: 300
        popupWidth: 220
        onValueChanged: value => {
            for (var i = 0; i < GreeterState.sessionList.length; i++) {
                if (GreeterState.sessionList[i] === value) {
                    GreeterState.currentSessionIndex = i;
                    GreeterState.selectedSession = GreeterState.sessionExecs[i];
                    GreeterState.selectedSessionPath = GreeterState.sessionPaths[i];
                    break;
                }
            }
        }
    }

    // ── Power menu ─────────────────────────────────────────────────────────

    property string pendingAction: ""
    property int powerConfirmCountdown: 0
    property bool powerConfirmActive: false

    function confirmPower(action) {
        pendingAction = action;
        powerConfirmCountdown = 5;
        powerConfirmActive = true;
        powerConfirmTimer.restart();
    }

    Timer {
        id: powerConfirmTimer
        interval: 1000
        repeat: true
        onTriggered: {
            powerConfirmCountdown -= 1;
            if (powerConfirmCountdown <= 0) {
                running = false;
                powerConfirmActive = false;
                if (pendingAction === "poweroff")
                    Quickshell.execDetached(["systemctl", "poweroff"]);
                else if (pendingAction === "reboot")
                    Quickshell.execDetached(["systemctl", "reboot"]);
                pendingAction = "";
            }
        }
    }

    Column {
        id: powerMenuColumn
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        z: 3
        spacing: 8

        IconButton {
            icon: powerConfirmActive && pendingAction === "poweroff" ? "timer" : "power_settings_new"
            onClicked: {
                if (powerConfirmActive && pendingAction === "poweroff") {
                    powerConfirmTimer.stop();
                    powerConfirmActive = false;
                    pendingAction = "";
                } else {
                    confirmPower("poweroff");
                }
            }
        }
        IconButton {
            icon: powerConfirmActive && pendingAction === "reboot" ? "timer" : "restart_alt"
            onClicked: {
                if (powerConfirmActive && pendingAction === "reboot") {
                    powerConfirmTimer.stop();
                    powerConfirmActive = false;
                    pendingAction = "";
                } else {
                    confirmPower("reboot");
                }
            }
        }
    }

    // ── Power confirmation overlay ──────────────────────────────────────────

    Rectangle {
        visible: powerConfirmActive
        anchors.centerIn: parent
        width: 200
        height: 60
        z: 10
        radius: Tokens.rounding.extraLarge
        color: Colours.tPalette.m3surfaceContainer

        StyledText {
            anchors.centerIn: parent
            text: pendingAction === "poweroff"
                ? "Shutdown in " + powerConfirmCountdown + "..."
                : "Reboot in " + powerConfirmCountdown + "..."
            color: Colours.palette.m3onSurface
            font: Tokens.font.body.large

            TapHandler {
                onTapped: {
                    powerConfirmTimer.stop();
                    powerConfirmActive = false;
                    pendingAction = "";
                }
            }
        }
    }

    // ── User & Session loading ──────────────────────────────────────────────

    Connections {
        target: localUsersService
        function onReadyChanged() {
            if (localUsersService.ready && isPrimaryScreen) {
                usersModel.clear();
                for (var i = 0; i < localUsersService.count; i++) {
                    var u = localUsersService.users.get(i);
                    usersModel.append({ displayName: u.displayName, username: u.username });
                }
                if (!GreeterState.username && localUsersService.count === 1) {
                    GreeterState.username = localUsersService.users.get(0).username;
                    GreeterState.usernameInput = localUsersService.users.get(0).username;
                    GreeterState.showPasswordInput = true;
                    PortalService.getGreeterUserProfileImage(GreeterState.username);
                }
            }
        }
    }

    Connections {
        target: localSessionsService
        function onReadyChanged() {
            if (localSessionsService.ready && isPrimaryScreen)
                refreshSessionList();
        }
    }
}
