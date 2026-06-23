pragma Singleton

import CNS.Config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Searcher {
    id: root

    property string currentScheme
    property string currentVariant
    property string currentSchemeName: currentScheme.split(" ")[0] || ""
    property var schemeItems: []
    property string lastNonDynamicScheme: "catppuccin mocha"

    readonly property var schemeModeMap: ({
        "caelestia default": "both",
        "catppuccin frappe": "dark",
        "catppuccin latte": "light",
        "catppuccin macchiato": "dark",
        "catppuccin mocha": "dark",
        "darkgreen hard": "dark",
        "darkgreen medium": "dark",
        "dracula medium": "dark",
        "dynamic default": "both",
        "everblush medium": "dark",
        "everforest hard": "dark",
        "everforest medium": "both",
        "everforest soft": "dark",
        "gruvbox hard": "both",
        "gruvbox medium": "both",
        "gruvbox soft": "both",
        "nord medium": "dark",
        "onedark default": "dark",
        "rosepine dawn": "light",
        "rosepine main": "dark",
        "rosepine moon": "dark",
        "shadotheme default": "dark",
        "solarized medium": "dark",
        "tokyonight medium": "dark"
    })

    // Path to the schemes data JSON file (bundled with the shell)
    readonly property string schemesDataPath: Qt.resolvedUrl("scheme.json")
    // Path to store current scheme state
    readonly property string schemeStatePath: `${Paths.state}/scheme.json`

    // Convert snake_case to camelCase
    function snakeToCamel(str: string): string {
        return str.replace(/_([a-z])/g, (match, letter) => letter.toUpperCase());
    }

    function transformMatugenOutput(data: var, mode: string): var {
        const colours = {};
        const matugenColors = data.colors;

        for (const [name, values] of Object.entries(matugenColors)) {
            const camelName = snakeToCamel(name);
            // Get the color for the specified mode
            let colorObj = values[mode] || values["default"];
            
            // Handle matugen 4.0.0 structure where color is nested in an object
            let hexColor = (typeof colorObj === 'object' && colorObj !== null) ? colorObj.color : colorObj;
            
            if (hexColor && typeof hexColor === 'string') {
                colours[camelName] = hexColor.replace("#", "");
            }
        }

        // Add palette key colors from palettes if available
        if (data.palettes) {
            const palettes = data.palettes;
            const extractPaletteColor = (p) => {
                if (!p || !p["40"]) return "";
                let val = p["40"];
                return (typeof val === 'object' && val !== null ? val.color : val).replace("#", "");
            };

            if (palettes.primary) colours["primary_paletteKeyColor"] = extractPaletteColor(palettes.primary);
            if (palettes.secondary) colours["secondary_paletteKeyColor"] = extractPaletteColor(palettes.secondary);
            if (palettes.tertiary) colours["tertiary_paletteKeyColor"] = extractPaletteColor(palettes.tertiary);
            if (palettes.neutral) colours["neutral_paletteKeyColor"] = extractPaletteColor(palettes.neutral);
            if (palettes.neutral_variant) colours["neutral_variant_paletteKeyColor"] = extractPaletteColor(palettes.neutral_variant);
        }

        // Add success colors (not in matugen)
        if (mode === "light") {
            colours["success"] = "4F6354";
            colours["onSuccess"] = "FFFFFF";
            colours["successContainer"] = "D1E8D5";
            colours["onSuccessContainer"] = "0C1F13";
        } else {
            colours["success"] = "B5CCBA";
            colours["onSuccess"] = "213528";
            colours["successContainer"] = "374B3E";
            colours["onSuccessContainer"] = "D1E9D6";
        }

        return colours;
    }

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}scheme `.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.flavour}`;
    }

    function reload(): void {
        schemeStateFile.reload();
    }

    // Regenerate dynamic scheme from current wallpaper
    function regenerateDynamic(): void {
        if (root.currentScheme.startsWith("dynamic")) {
            setScheme("dynamic", "default");
        }
    }

    // Set a scheme by name and flavour, with optional mode override
    function setScheme(name: string, flavour: string, forceMode: string): void {
        // Handle dynamic scheme generation
        if (name === "dynamic") {
            const wallpaper = Wallpapers.current;
            if (!wallpaper) {
                console.warn("Cannot set dynamic scheme: no wallpaper set");
                return;
            }
            const mode = forceMode || (Colours.light ? "light" : "dark");
            const variant = root.currentVariant || "tonalspot";

            // Persist current colours through the transition so variant changes
            // via CLI see name=dynamic, not the old scheme name.
            let currentColours = {};
            try {
                const oldState = JSON.parse(schemeStateFile.text());
                currentColours = oldState.colours || {};
            } catch (e) {}

            const stateData = {
                name: "dynamic",
                flavour: "default",
                mode: mode,
                variant: variant,
                colours: currentColours,
                lastNonDynamicScheme: root.lastNonDynamicScheme
            };
            schemeStateFile.watchChanges = false;
            schemeStateFile.setText(JSON.stringify(stateData, null, 2));
            schemeStateFile.watchChanges = true;
            root.currentScheme = "dynamic default";

            // Use matugen for color generation from wallpaper (Quickshell UI)
            dynamicSchemeGenerator.wallpaper = wallpaper;
            dynamicSchemeGenerator.variant = variant;
            dynamicSchemeGenerator.mode = mode;
            dynamicSchemeGenerator.run();

            // Also run external color generation for terminal/GTK/apps
            Wallpapers.runColorGeneration(wallpaper, variant);
            return;
        }

        const schemeData = schemesDataFile.json;
        if (!schemeData || !schemeData[name] || !schemeData[name][flavour]) {
            console.warn(`Scheme not found: ${name} ${flavour}`);
            return;
        }

        const colours = schemeData[name][flavour];
        const mode = forceMode || (Colours.light ? "light" : "dark");

        // Track last non-dynamic scheme for restore
        root.lastNonDynamicScheme = `${name} ${flavour}`;

        // Save to state file
        const stateData = {
            name: name,
            flavour: flavour,
            mode: mode,
            variant: root.currentVariant || "tonalspot",
            colours: colours,
            lastNonDynamicScheme: root.lastNonDynamicScheme
        };

        schemeStateFile.watchChanges = false;
        schemeStateFile.setText(JSON.stringify(stateData, null, 2));
        schemeStateFile.watchChanges = true;
        root.currentScheme = `${name} ${flavour}`;

        // Load the colours immediately
        Colours.load(JSON.stringify(stateData), false);
    }

    list: schemes.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes
    keys: ["name", "flavour"]
    weights: [0.9, 0.1]

    Variants {
        id: schemes

        Scheme {}
    }

    // Load schemes from local JSON file
    FileView {
        id: schemesDataFile

        property var json: null

        path: Qt.resolvedUrl("scheme.json")

        onLoaded: {
            try {
                json = JSON.parse(text());
                const list = Object.entries(json).map(([name, f]) => Object.entries(f).map(([flavour, colours]) => ({
                                name,
                                flavour,
                                colours
                            })));

                const flat = [];
                for (const s of list)
                    for (const f of s)
                        flat.push(f);

                // Add dynamic scheme (single entry with default flavour)
                // Variant is selected separately via M3Variants drawer
                flat.push({
                    name: "dynamic",
                    flavour: "default",
                    colours: {}
                });

                schemes.model = flat.sort((a, b) => (a.name + a.flavour).localeCompare((b.name + b.flavour)));

                // Build UI list: dynamic first, then alphabetical
                const sorted = flat.sort((a, b) => {
                    if (a.name === "dynamic" && b.name !== "dynamic") return -1;
                    if (b.name === "dynamic" && a.name !== "dynamic") return 1;
                    return (a.name + a.flavour).localeCompare(b.name + b.flavour);
                });
                root.schemeItems = sorted;
            } catch (e) {
                console.error("Failed to parse schemes data:", e);
            }
        }
    }

    // Load current scheme state from state file
    FileView {
        id: schemeStateFile

        path: root.schemeStatePath
        watchChanges: true

        onLoaded: {
            try {
                const state = JSON.parse(text());
                root.currentScheme = `${state.name} ${state.flavour}`;
                root.currentVariant = state.variant || "tonalspot";
                root.lastNonDynamicScheme = state.lastNonDynamicScheme || "catppuccin mocha";
            } catch (e) {
                // State file doesn't exist or is invalid, use defaults
                root.currentScheme = "catppuccin mocha";
                root.currentVariant = "tonalspot";
                root.lastNonDynamicScheme = "catppuccin mocha";
            }
        }

        onFileChanged: reload()
    }

    // IPC handler — receive the same `colours reload` call that Colours.qml handles.
    // Ensures Schemes.currentScheme / currentVariant update when the CLI writes state.
    IpcHandler {
        target: "colours"
        function reload(): void { schemeStateFile.reload() }
    }

    // Process for ensuring state directory exists before writing
    Process {
        id: schemeStateWriter

        property string _pendingContent

        command: ["mkdir", "-p", Paths.state]
        running: false

        function write(content: string): void {
            _pendingContent = content;
            schemeStateWriter.running = true;
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0 && _pendingContent) {
                schemeStateFile.watchChanges = false;
                schemeStateFile.setText(_pendingContent);
                schemeStateFile.watchChanges = true;
            }
        }
    }

    // Process for generating dynamic scheme from wallpaper using matugen
    Process {
        id: dynamicSchemeGenerator

        property string wallpaper
        property string variant
        property string mode
        property string outputBuffer: ""
        property int retryCount: 0

        running: false

        function run(): void {
            outputBuffer = "";
            // Convert variant name to matugen type
            let matugenType = "scheme-tonal-spot";
            const variantMap = {
                "content": "scheme-content",
                "expressive": "scheme-expressive",
                "fidelity": "scheme-fidelity",
                "fruitsalad": "scheme-fruit-salad",
                "monochrome": "scheme-monochrome",
                "neutral": "scheme-neutral",
                "rainbow": "scheme-rainbow",
                "tonalspot": "scheme-tonal-spot",
                "vibrant": "scheme-vibrant"
            };
            if (variantMap[variant]) {
                matugenType = variantMap[variant];
            }

            const colorSource = Wallpapers.getColorSource(wallpaper);
            command = ["matugen", "image", colorSource, "--dry-run", "--json", "hex", "--mode", mode, "--type", matugenType, "--source-color-index", "0"];
            
            // If it's a video and the frame might not exist yet, we should check/retry
            if (Wallpapers.isPathVideo(wallpaper)) {
            }
            
            running = true;
        }

        stdout: SplitParser {
            onRead: data => {
                dynamicSchemeGenerator.outputBuffer += data;
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.error("Matugen exited with code:", exitCode);
                return;
            }

            try {
                const matugenData = JSON.parse(outputBuffer);
                const colours = root.transformMatugenOutput(matugenData, mode);
                const stateData = {
                    name: "dynamic",
                    flavour: "default",
                    mode: mode,
                    variant: variant,
                    colours: colours,
                    lastNonDynamicScheme: root.lastNonDynamicScheme
                };

                schemeStateWriter.write(JSON.stringify(stateData, null, 2));
                root.currentScheme = "dynamic default";
                Colours.load(JSON.stringify(stateData), false);
            } catch (e) {
                console.error("Failed to parse matugen output:", e);
            }
        }

        stderr: SplitParser {
            onRead: data => {
                console.error("Matugen error:", data);
            }
        }
    }

    component Scheme: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string flavour: modelData.flavour
        readonly property var colours: modelData.colours

        function onClicked(list: var): void {
            list.visibilities.launcher = false;
            root.setScheme(name, flavour);
        }
    }
}
