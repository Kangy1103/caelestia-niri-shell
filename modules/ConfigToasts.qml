import QtQuick
import Quickshell
import CNS
import CNS.Config

// CNS: every handler in this file was dead. It was written against the old
// config type, which exposed loaded / loadFailed / saveFailed / unknownOption.
// Upstream replaced that with settings::RootNode's
// treeLoaded / treeLoadFailed / treeSaveFailed, plus a diagnostics list for
// per-option problems. QML logged six "no signal of the target matches the
// name" warnings and the module did nothing at all.
//
// One capability is genuinely gone: the old loadFailed/unknownOption carried a
// `screen` argument naming the output, so the toasts could say which monitor
// failed. The new tree* signals report the failing RootNode instead, which
// does not expose its screen name to QML, so those toasts no longer name an
// output.
Scope {
    Connections {
        function onTreeLoaded(): void {
            if (GlobalConfig.utilities.toasts.configLoaded)
                Toaster.toast(qsTr("Config loaded"), qsTr("Config loaded successfully!"), "rule_settings");
        }

        function onTreeLoadFailed(error: string): void {
            Toaster.toast(qsTr("Failed to parse config"), error, "settings_alert", Toast.Warning);
        }

        function onTreeSaveFailed(error: string): void {
            Toaster.toast(qsTr("Failed to save config"), error, "settings_alert", Toast.Error);
        }

        // Replaces onUnknownOption: unknown keys are now diagnostics on the
        // tree rather than a dedicated signal.
        function onDiagnosticsChanged(): void {
            for (const d of GlobalConfig.diagnostics()) {
                if (d.type === DiagnosticType.UnknownOption)
                    Toaster.toast(qsTr("Unknown option in config"), d.option, "question_mark", Toast.Warning);
            }
        }

        target: GlobalConfig
    }

    Connections {
        function onTreeLoadFailed(error: string): void {
            Toaster.toast(qsTr("Failed to parse token config"), error, "settings_alert", Toast.Warning);
        }

        function onDiagnosticsChanged(): void {
            for (const d of TokenConfig.diagnostics()) {
                if (d.type === DiagnosticType.UnknownOption)
                    Toaster.toast(qsTr("Unknown option in token config"), d.option, "question_mark", Toast.Warning);
            }
        }

        target: TokenConfig
    }
}