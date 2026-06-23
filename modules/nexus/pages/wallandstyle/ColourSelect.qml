pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import CNS
import CNS.Config
import qs.components
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Colours")
    isSubPage: true

    readonly property string currentKey: Schemes.currentScheme
    readonly property string currentModeClass: Schemes.schemeModeMap[currentKey] || "both"
    readonly property bool isDynamic: currentKey === "dynamic default"
    property bool variantExpanded: false

    readonly property var filteredSchemeItems: {
        const items = [];
        for (const s of Schemes.schemeItems) {
            if (s.name !== "dynamic")
                items.push(s);
        }
        return items;
    }

    readonly property var variantItems: [
        { key: "vibrant", icon: "sentiment_very_dissatisfied", name: qsTr("Vibrant"), description: qsTr("A high chroma palette. The primary palette's chroma is at maximum.") },
        { key: "tonalspot", icon: "android", name: qsTr("Tonal Spot"), description: qsTr("Default for Material theme colours. A pastel palette with a low chroma.") },
        { key: "expressive", icon: "compare_arrows", name: qsTr("Expressive"), description: qsTr("A medium chroma palette. The primary palette's hue is different from the seed colour, for variety.") },
        { key: "fidelity", icon: "compare", name: qsTr("Fidelity"), description: qsTr("Matches the seed colour, even if the seed colour is very bright (high chroma).") },
        { key: "content", icon: "sentiment_calm", name: qsTr("Content"), description: qsTr("Almost identical to fidelity.") },
        { key: "fruitsalad", icon: "nutrition", name: qsTr("Fruit Salad"), description: qsTr("A playful theme - the seed colour's hue does not appear in the theme.") },
        { key: "rainbow", icon: "looks", name: qsTr("Rainbow"), description: qsTr("A playful theme - the seed colour's hue does not appear in the theme.") },
        { key: "neutral", icon: "contrast", name: qsTr("Neutral"), description: qsTr("Close to grayscale, a hint of chroma.") },
        { key: "monochrome", icon: "filter_b_and_w", name: qsTr("Monochrome"), description: qsTr("All colours are grayscale, no chroma.") }
    ]

    // Shell directly to CLI for scheme changes — single source of truth.
    // In-memory properties are set for immediate UI feedback.
    function selectScheme(name, flavour) {
        const key = name + " " + flavour;
        const targetMode = Schemes.schemeModeMap[key];

        Schemes.currentScheme = name + " " + flavour;

        const args = ["cns", "scheme", "set", "--notify", "-n", name, "-f", flavour];
        if (targetMode === "light" && !Colours.light) {
            args.push("-m", "light");
        } else if (targetMode === "dark" && Colours.light) {
            args.push("-m", "dark");
        }
        Quickshell.execDetached(args);
    }

    function modeLabel(modeClass) {
        if (modeClass === "light") return qsTr("Light");
        if (modeClass === "dark") return qsTr("Dark");
        return qsTr("Light & dark");
    }

    function variantName(key) {
        for (const v of root.variantItems) {
            if (v.key === key) return v.name;
        }
        return key;
    }

    function capitalize(str) {
        return str.charAt(0).toUpperCase() + str.slice(1);
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // ── Group 1: Dynamic + Dark theme ──
        ToggleRow {
            Layout.fillWidth: true
            first: true
            last: false
            toastOnChange: false

            text: qsTr("Dynamic")
            subtext: qsTr("Default") + " · " + modeLabel("both")
            checked: root.isDynamic

            onToggled: {
                if (checked) {
                    root.selectScheme("dynamic", "default");
                } else {
                    const parts = Schemes.lastNonDynamicScheme.split(" ");
                    root.selectScheme(parts[0], parts.slice(1).join(" "));
                }
            }
        }

        ToggleRow {
            Layout.fillWidth: true
            first: false
            last: true

            text: qsTr("Dark theme")
            subtext: {
                if (currentModeClass === "light") return qsTr("Scheme only supports light mode");
                if (currentModeClass === "dark") return qsTr("Scheme only supports dark mode");
                return "";
            }
            checked: !Colours.light
            enabled: currentModeClass === "both" || isDynamic
            toastOnChange: enabled
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }

        // ── Group 2: Variant picker (collapsible) ──
        ConnectedRect {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large - parent.spacing
            first: true
            last: !root.variantExpanded
            implicitHeight: variantHeader.implicitHeight + variantHeader.anchors.margins * 2

            StateLayer {
                onClicked: root.variantExpanded = !root.variantExpanded
            }

            RowLayout {
                id: variantHeader

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: {
                        for (const v of root.variantItems) {
                            if (v.key === Schemes.currentVariant) return v.icon;
                        }
                        return "android";
                    }
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.icon.medium
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Tonal Variant")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                        animate: true
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.variantName(Schemes.currentVariant)
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                        animate: true
                    }
                }

                MaterialIcon {
                    text: "chevron_right"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.icon.medium
                    rotation: root.variantExpanded ? 90 : 0

                    Behavior on rotation {
                        Anim {
                            type: Anim.DefaultEffects
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            clip: true
            implicitHeight: root.variantExpanded ? variantListCol.implicitHeight : 0

            Behavior on implicitHeight {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            ColumnLayout {
                id: variantListCol

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: 0

                Repeater {
                    id: variantList

                    model: root.variantItems

                    delegate: StyledRect {
                        required property var modelData
                        required property int index

                        readonly property bool isActive: Schemes.currentVariant === modelData.key

                        Layout.fillWidth: true
                        implicitHeight: variantRow.implicitHeight + variantRow.anchors.margins * 2

                        color: isActive ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainer, 0)

                        topLeftRadius: isActive ? Tokens.rounding.extraLargeIncreased : (index === 0 ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall)
                        topRightRadius: isActive ? Tokens.rounding.extraLargeIncreased : (index === 0 ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall)
                        bottomLeftRadius: isActive ? Tokens.rounding.extraLargeIncreased : (index === variantList.model.count - 1 ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall)
                        bottomRightRadius: isActive ? Tokens.rounding.extraLargeIncreased : (index === variantList.model.count - 1 ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall)

                        Behavior on topLeftRadius { Anim { type: Anim.DefaultEffects } }
                        Behavior on topRightRadius { Anim { type: Anim.DefaultEffects } }
                        Behavior on bottomLeftRadius { Anim { type: Anim.DefaultEffects } }
                        Behavior on bottomRightRadius { Anim { type: Anim.DefaultEffects } }

                        StateLayer {
                            anchors.fill: parent
                            onClicked: M3Variants.setVariant(modelData.key)
                        }

                        RowLayout {
                            id: variantRow

                            anchors.fill: parent
                            anchors.margins: Tokens.padding.medium
                            anchors.leftMargin: Tokens.padding.largeIncreased
                            anchors.rightMargin: Tokens.padding.largeIncreased
                            spacing: Tokens.spacing.medium

                            MaterialIcon {
                                text: isActive ? "check" : ""
                                color: isActive ? Colours.palette.m3onSecondaryContainer : "transparent"
                                font: Tokens.font.icon.medium
                                visible: isActive
                                Layout.preferredWidth: isActive ? implicitWidth : 0
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font: Tokens.font.body.small
                                    elide: Text.ElideRight
                                    animate: true
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.description
                                    color: isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3outline
                                    font: Tokens.font.label.small
                                    elide: Text.ElideRight
                                    animate: true
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Group 3: Colour schemes ──
        SectionHeader {
            text: qsTr("Colour schemes")
        }

        Repeater {
            model: root.filteredSchemeItems

            delegate: StyledRect {
                required property var modelData
                required property int index

                readonly property string key: modelData.name + " " + modelData.flavour
                readonly property string modeClass: Schemes.schemeModeMap[key] || "both"
                readonly property bool isActive: root.currentKey === key

                Layout.fillWidth: true
                implicitHeight: schemeRow.implicitHeight + schemeRow.anchors.margins * 2

                color: isActive ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainer, 0)

                topLeftRadius: isActive ? Tokens.rounding.extraLargeIncreased : (index === 0 ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall)
                topRightRadius: isActive ? Tokens.rounding.extraLargeIncreased : (index === 0 ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall)
                bottomLeftRadius: isActive ? Tokens.rounding.extraLargeIncreased : (index === root.filteredSchemeItems.length - 1 ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall)
                bottomRightRadius: isActive ? Tokens.rounding.extraLargeIncreased : (index === root.filteredSchemeItems.length - 1 ? Tokens.rounding.extraLarge : Tokens.rounding.extraSmall)

                opacity: root.isDynamic ? 0.4 : 1.0

                Behavior on topLeftRadius { Anim { type: Anim.DefaultEffects } }
                Behavior on topRightRadius { Anim { type: Anim.DefaultEffects } }
                Behavior on bottomLeftRadius { Anim { type: Anim.DefaultEffects } }
                Behavior on bottomRightRadius { Anim { type: Anim.DefaultEffects } }

                StateLayer {
                    anchors.fill: parent
                    onClicked: root.selectScheme(modelData.name, modelData.flavour)
                }

                RowLayout {
                    id: schemeRow

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: isActive ? "check" : ""
                        color: isActive ? Colours.palette.m3onSecondaryContainer : "transparent"
                        font: Tokens.font.icon.medium
                        visible: isActive
                        Layout.preferredWidth: isActive ? implicitWidth : 0
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: capitalize(modelData.name)
                            font: Tokens.font.body.small
                            elide: Text.ElideRight
                            animate: true
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: capitalize(modelData.flavour) + " · " + modeLabel(modeClass)
                            color: isActive ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3outline
                            font: Tokens.font.label.small
                            elide: Text.ElideRight
                            animate: true
                        }
                    }
                }
            }
        }
    }
}
