pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import CNS.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

// The wallpaper picker's settings (the gear in its head): the folder it
// lists, which Wallhaven downloads are saved to as well; a Wallhaven API key;
// and whether a card set grows into the wallpaper. Each field applies on
// Enter: a folder once it's found (or made), a key after Wallhaven is asked
// whether it knows it. The switch applies as it's clicked.
//
// CNS: the source's "wallpaper command" section is gone with the engine —
// CNS sets wallpapers through its own Wallpapers service, so there is no
// command to configure. The API key lives in the bundled client's config
// (~/.config/caelestia-niri-shell/wallhaven), which is where the Nexus Web
// Wallpaper page already expects it, so this reads and writes that file
// rather than a settings key of its own.
Rectangle {
    id: card

    // The source's DesktopTheme.rad(n). Its "pill" shape rounds controls by half
    // again on top of the designed radius — that is what the source renders
    // with, and what gives the chips and fields their capsule corners. Taking
    // the bare `normal` instead leaves them rectangular.
    function rad(n: real): real { return Math.round(n * 1.5); }

    required property var config

    property real u: 1
    // The picker's try-on colours.
    property color surface: Colours.palette.m3surfaceContainerLow
    property color ink: Colours.palette.m3onSurface
    property color muted: Colours.palette.m3onSurfaceVariant
    property color accent: Colours.palette.m3primary
    property color accentInk: Colours.palette.m3onPrimary
    // Wallpapers listed from the folder now set.
    property int wallpaperCount: 0

    signal closeRequested

    // "", "checking", "missing", "relative", "failed" or "saved"
    property string folderStatus: ""
    property string pendingFolder: ""
    // "", "checking", "ok", "rejected" or "unreachable"
    property string keyStatus: ""
    property bool showKey: false

    readonly property bool folderEdited: folderField.text.trim().replace(/\/+$/, "") !== config.wallpaperDir
    readonly property bool keyEdited: keyField.text.trim() !== config.wallhavenApiKey

    readonly property string wallhavenConfPath: `${Quickshell.env("XDG_CONFIG_HOME") || `${Paths.home}/.config`}/caelestia-niri-shell/wallhaven`

    // Fresh fields each time it opens, the folder's ready to type over.
    function reset() {
        folderField.text = config.wallpaperDir;
        keyField.text = config.wallhavenApiKey;
        folderStatus = "";
        keyStatus = "";
        showKey = false;
        folderField.forceActiveFocus();
        folderField.selectAll();
    }

    // ~ and ~/… expanded, as far as the source's expandHome() did.
    function expandHome(p: string): string {
        if (p === "~")
            return Paths.home;
        if (p.startsWith("~/"))
            return `${Paths.home}/${p.slice(2)}`;
        return p;
    }

    function applyFolder() {
        const typed = folderField.text.trim().replace(/\/+$/, "");
        if (!typed || typed === config.wallpaperDir) {
            folderField.text = config.wallpaperDir;
            folderStatus = "";
            return;
        }
        const abs = expandHome(typed);
        if (!abs.startsWith("/")) {
            folderStatus = "relative";
            return;
        }
        pendingFolder = typed;
        folderStatus = "checking";
        folderCheck.exec(["test", "-d", abs]);
    }

    function createFolder() {
        folderStatus = "checking";
        folderMake.exec(["mkdir", "-p", expandHome(pendingFolder)]);
    }

    function useFolder() {
        config.wallpaperDir = pendingFolder;
        folderField.text = pendingFolder;
        folderStatus = "saved";
    }

    // Writes the key back into the bundled client's config, leaving every
    // other setting in that file alone.
    function applyKey() {
        const key = keyField.text.trim();
        keyField.text = key;
        if (!key) {
            keyStatus = "";
            return;
        }
        keyStatus = "checking";

        // Wallhaven's account settings answer only to a valid key (an unknown
        // one gets a 404).
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || keyField.text.trim() !== key)
                return;
            keyStatus = xhr.status === 200 ? "ok" : xhr.status === 401 || xhr.status === 404 ? "rejected" : "unreachable";
        };
        xhr.open("GET", "https://wallhaven.cc/api/v1/settings?apikey=" + encodeURIComponent(key));
        xhr.send();

        keyFile.reload();
        Qt.callLater(() => {
            const body = keyFile.text().replace(/api_key\s*=\s*"[^"]*"/, `api_key = "${key}"`);
            keyFile.setText(body);
        });
    }

    width: 460 * u
    height: body.implicitHeight + 40 * u
    radius: rad(20) * u
    color: Qt.alpha(surface, 0.95)
    border.width: 1
    border.color: Qt.alpha(ink, 0.12)

    Process {
        id: folderCheck

        onExited: code => {
            if (code === 0)
                card.useFolder();
            else
                card.folderStatus = "missing";
        }
    }

    Process {
        id: folderMake

        onExited: code => {
            if (code === 0)
                card.useFolder();
            else
                card.folderStatus = "failed";
        }
    }

    FileView {
        id: keyFile

        path: card.wallhavenConfPath
        printErrors: false
    }

    // Clicks stay on the card rather than reaching the deck under it.
    MouseArea {
        anchors.fill: parent
        onWheel: wheel => wheel.accepted = true
    }

    component Label: StyledText {
        font.pixelSize: 11 * card.u
        font.weight: Font.Bold
        font.letterSpacing: 1.2 * card.u
        color: card.muted
    }

    component Note: StyledText {
        width: parent.width
        wrapMode: Text.Wrap
        font.pixelSize: 12 * card.u
        color: card.muted
    }

    // CNS: the source styled its own field (background/border/focus colours and
    // padding). TextFieldBase brings CNS's own chrome already, so this only
    // sets the metrics the source's sizing was written against.
    // The source's Field is a StyledTextField, which carries its own
    // background box; TextFieldBase is bare, so the box is supplied here to
    // match the source's radius, surface, outline and focus border. The values
    // are the source's, in its theme: rad(12) radius, 1px border,
    // surface_container fill, outline_variant border, accent on focus.
    component Field: TextFieldBase {
        id: field

        width: parent.width
        height: 40 * card.u
        font.pixelSize: 13 * card.u
        verticalAlignment: TextInput.AlignVCenter
        leftPadding: 14 * card.u
        rightPadding: 14 * card.u
        color: card.ink
        placeholderTextColor: card.muted
        selectedTextColor: card.ink

        background: Rectangle {
            radius: rad(12) * card.u
            color: Colours.palette.m3surfaceContainer
            border.width: 1
            border.color: field.activeFocus ? card.accent : Colours.palette.m3outlineVariant
        }

        Keys.onEscapePressed: card.closeRequested()
    }

    component Chip: Rectangle {
        id: chip

        property string label

        signal clicked

        width: chipText.implicitWidth + 22 * card.u
        height: 28 * card.u
        radius: rad(14) * card.u
        color: chip.containsMouse ? Qt.lighter(card.accent, 1.08) : card.accent

        MouseArea {
            id: chipMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }

        StyledText {
            id: chipText

            anchors.centerIn: parent
            text: chip.label
            font.pixelSize: 12 * card.u
            font.weight: Font.DemiBold
            color: card.accentInk
        }
    }

    component Btn: Rectangle {
        id: btn

        signal clicked

        width: 32 * card.u
        height: 32 * card.u
        radius: height / 2
        color: btn.containsMouse ? Qt.alpha(card.ink, 0.1) : "transparent"

        MouseArea {
            id: btnMouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    Column {
        id: body

        x: 20 * card.u
        y: 20 * card.u
        width: parent.width - 40 * card.u
        spacing: 8 * card.u

        Item {
            width: parent.width
            height: 32 * card.u

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10 * card.u

                MaterialIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "settings"
                    fontStyle: Tokens.font.icon.size(20 * card.u).build()
                    color: card.accent
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Picker settings")
                    font.pixelSize: 16 * card.u
                    font.weight: Font.Bold
                    color: card.ink
                }
            }

            Btn {
                id: closeButton

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 32 * card.u
                height: 32 * card.u
                onClicked: card.closeRequested()

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "close"
                    fontStyle: Tokens.font.icon.size(18 * card.u).build()
                    color: card.ink
                }
            }
        }

        Item {
            width: 1
            height: 4 * card.u
        }

        Label {
            text: qsTr("WALLPAPER FOLDER")
        }

        Field {
            id: folderField

            onAccepted: card.applyFolder()
            onTextEdited: card.folderStatus = ""
            KeyNavigation.tab: keyField
        }

        Note {
            text: card.folderStatus === "checking" ? qsTr("Looking for it…")
                : card.folderStatus === "missing" ? qsTr("There's no folder there yet.")
                : card.folderStatus === "failed" ? qsTr("Couldn't create that folder.")
                : card.folderStatus === "relative" ? qsTr("Use a full path, or one starting with ~/")
                : card.folderEdited ? qsTr("Enter to use this folder")
                : (card.wallpaperCount === 1 ? qsTr("1 wallpaper") : qsTr("%1 wallpapers").arg(card.wallpaperCount)) + " " + qsTr("here. Wallhaven downloads are saved here too.")
            color: card.folderStatus === "missing" || card.folderStatus === "failed" || card.folderStatus === "relative" ? Colours.palette.m3error : card.muted
        }

        Chip {
            visible: card.folderStatus === "missing"
            label: qsTr("Create it and use it")
            onClicked: card.createFolder()
        }

        Item {
            width: 1
            height: 8 * card.u
        }

        Label {
            text: qsTr("WALLHAVEN API KEY")
        }

        Item {
            width: parent.width
            height: keyField.height

            Field {
                id: keyField

                width: parent.width - eye.width - 8 * card.u
                echoMode: card.showKey ? TextInput.Normal : TextInput.Password
                onAccepted: card.applyKey()
                onTextEdited: card.keyStatus = ""
                KeyNavigation.tab: folderField
            }

            Btn {
                id: eye

                anchors.right: parent.right
                width: 40 * card.u
                height: 40 * card.u
                radius: rad(12) * card.u
                color: eye.containsMouse ? Qt.alpha(card.ink, 0.12) : Qt.alpha(card.ink, 0.06)
                onClicked: card.showKey = !card.showKey

                MaterialIcon {
                    anchors.centerIn: parent
                    text: card.showKey ? "visibility_off" : "visibility"
                    fontStyle: Tokens.font.icon.size(18 * card.u).build()
                    color: card.ink
                }
            }
        }

        Note {
            text: card.keyStatus === "checking" ? qsTr("Asking Wallhaven…")
                : card.keyStatus === "ok" ? qsTr("Wallhaven knows this key: NSFW results are available.")
                : card.keyStatus === "rejected" ? qsTr("Wallhaven doesn't accept this key.")
                : card.keyStatus === "unreachable" ? qsTr("Saved, but Wallhaven couldn't be reached to check it.")
                : card.keyEdited ? (keyField.text.trim() ? qsTr("Enter to save the key") : qsTr("Enter to remove the key"))
                : qsTr("Optional. It unlocks NSFW results and your account's filters; find it at wallhaven.cc/settings/account")
            color: card.keyStatus === "ok" ? card.accent : card.keyStatus === "rejected" ? Colours.palette.m3error : card.muted
        }

        Item {
            width: 1
            height: 8 * card.u
        }

        Label {
            text: qsTr("SETTING A WALLPAPER")
        }

        // How a wallpaper that doesn't match the screen's aspect is drawn.
        // Lives on the Wallpapers service, not in the picker's config, because
        // it decides how the desktop paints — the picker isn't even open when
        // that changes.
        Label {
            text: qsTr("ASPECT")
        }

        Note {
            text: qsTr("Crop fills the screen and cuts off the overflow. Fit shows the whole wallpaper letterboxed. Blur fills the gaps with a blurred copy.")
        }

        Row {
            spacing: 8 * card.u

            Repeater {
                model: [["Crop", "crop"], ["Fit", "fit"], ["Blur", "blur"]]

                Chip {
                    required property var modelData

                    width: chipRow.implicitWidth + 22 * card.u
                    height: 30 * card.u
                    radius: rad(15) * card.u
                    color: Wallpapers.wallpaperFit === modelData[1] ? card.accent
                        : fitMouse.containsMouse ? Qt.alpha(card.ink, 0.12) : Qt.alpha(card.ink, 0.06)
                    border.width: 1
                    border.color: Qt.alpha(card.ink, 0.12)

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 6 * card.u

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData[0]
                            font.pixelSize: 12 * card.u
                            font.weight: Font.DemiBold
                            color: Wallpapers.wallpaperFit === modelData[1] ? card.accentInk : card.ink
                        }
                    }

                    MouseArea {
                        id: fitMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingClickCursor
                        onClicked: Wallpapers.setWallpaperFit(modelData[1])
                    }
                }
            }
        }

        // The whole row flips the switch.
        Rectangle {
            id: animateRow

            signal clicked

            readonly property bool checked: card.config.wallpaperAnimateChoice

            width: parent.width
            height: 40 * card.u
            radius: rad(12) * card.u
            color: animateRow.containsMouse ? Qt.alpha(card.ink, 0.1) : Qt.alpha(card.ink, 0.06)
            border.width: 1
            border.color: Qt.alpha(card.ink, 0.12)

            MouseArea {
                id: animateMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    card.config.wallpaperAnimateChoice = !card.config.wallpaperAnimateChoice;
                    animateRow.clicked();
                }
            }

            StyledText {
                anchors.left: parent.left
                anchors.leftMargin: 14 * card.u
                anchors.right: track.left
                anchors.rightMargin: 12 * card.u
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Grow the chosen card into the wallpaper")
                elide: Text.ElideRight
                font.pixelSize: 13 * card.u
                color: card.ink
            }

            // The switch, as round as the theme's controls.
            Rectangle {
                id: track

                anchors.right: parent.right
                anchors.rightMargin: 8 * card.u
                anchors.verticalCenter: parent.verticalCenter
                width: 42 * card.u
                height: 24 * card.u
                radius: Math.min(height / 2, animateRow.radius)
                color: animateRow.checked ? card.accent : Qt.alpha(card.ink, 0.16)

                Behavior on color {
                    ColorAnimation {
                        duration: 160
                    }
                }

                Rectangle {
                    readonly property real inset: 3 * card.u

                    x: animateRow.checked ? parent.width - width - inset : inset
                    y: inset
                    width: parent.height - inset * 2
                    height: width
                    radius: Math.max(0, track.radius - inset)
                    color: animateRow.checked ? card.accentInk : card.ink

                    Behavior on x {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        Note {
            text: animateRow.checked ? qsTr("The card comes to the middle of the screen and grows into the wallpaper, then the picker closes.")
                : qsTr("The wallpaper changes straight away and the deck stays open, for more browsing.")
        }
    }
}