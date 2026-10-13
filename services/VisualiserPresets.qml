pragma Singleton

import QtQuick
import QtQml
import CNS.Config

QtObject {
    id: root

    readonly property var _presets: [
        {
            "name": "Classic Bars",
            "description": "Full-width frequency bars using theme colours",
            "style": "bars",
            "settings": {
                "primaryColor": null,
                "secondaryColor": null,
                "sensitivity": 1.0,
                "animationDuration": 200,
                "barCount": 60,
                "rounding": 1.0,
                "spacing": 1.0,
                "blur": false,
                "autoHide": true
            }
        },
        {
            "name": "Waveform",
            "description": "Smooth continuous waveform line",
            "style": "waveform",
            "settings": {
                "primaryColor": null,
                "secondaryColor": null,
                "sensitivity": 1.0,
                "animationDuration": 150,
                "barCount": 60,
                "rounding": 0.0,
                "spacing": 0.0,
                "blur": false,
                "autoHide": true
            }
        },
        {
            "name": "Filled Waveform",
            "description": "Filled area under a smooth bezier curve",
            "style": "filled",
            "settings": {
                "primaryColor": null,
                "secondaryColor": null,
                "sensitivity": 1.0,
                "animationDuration": 200,
                "barCount": 60,
                "rounding": 0.0,
                "spacing": 0.0,
                "blur": false,
                "autoHide": true
            }
        },
        {
            "name": "Neon Pulse",
            "description": "Thin wide-spaced bars with a beat-reactive white flash",
            "style": "bars",
            "settings": {
                "primaryColor": "#00e5ff",
                "secondaryColor": "#00b8d4",
                "beatColor": "#ffffff",
                "beatReactive": true,
                "sensitivity": 1.2,
                "animationDuration": 150,
                "barCount": 40,
                "rounding": 0.5,
                "spacing": 3.0,
                "blur": false,
                "autoHide": true
            }
        },
        {
            "name": "Spectrum",
            "description": "High-density spectrum analyser with fine bars",
            "style": "bars",
            "settings": {
                "primaryColor": null,
                "secondaryColor": null,
                "beatColor": "#ffffff",
                "beatReactive": false,
                "sensitivity": 1.5,
                "animationDuration": 100,
                "barCount": 120,
                "rounding": 0.0,
                "spacing": 0.0,
                "blur": false,
                "autoHide": true
            }
        },
        {
            "name": "Minimal",
            "description": "Few wide bars with heavy rounding for a relaxed look",
            "style": "bars",
            "settings": {
                "primaryColor": "#e0e0e0",
                "secondaryColor": "#9e9e9e",
                "beatColor": "#ffffff",
                "beatReactive": false,
                "sensitivity": 0.8,
                "animationDuration": 300,
                "barCount": 20,
                "rounding": 3.0,
                "spacing": 3.0,
                "blur": false,
                "autoHide": true
            }
        }
    ]

    readonly property var presets: _presets

    readonly property string current: GlobalConfig.background.visualiser.activePreset

    readonly property string currentLabel: {
        for (var i = 0; i < _presets.length; i++) {
            if (_presets[i].name === root.current)
                return _presets[i].name;
        }
        return root.current;
    }

    readonly property var currentSettings: {
        for (var i = 0; i < _presets.length; i++) {
            if (_presets[i].name === root.current)
                return _presets[i].settings;
        }
        return _presets[0].settings;
    }

    readonly property string currentStyle: {
        for (var i = 0; i < _presets.length; i++) {
            if (_presets[i].name === root.current)
                return _presets[i].style;
        }
        return _presets[0].style;
    }

    function applyPreset(name) {
        var entry = null;
        for (var i = 0; i < _presets.length; i++) {
            if (_presets[i].name === name) {
                entry = _presets[i];
                break;
            }
        }
        if (!entry) return;

        var s = entry.settings;
        var vc = GlobalConfig.background.visualiser;

        vc.style = entry.style;
        vc.barCount = s.barCount;
        GlobalConfig.services.visualiserBars = s.barCount;
        vc.animationDuration = s.animationDuration;
        vc.sensitivity = s.sensitivity;
        vc.rounding = s.rounding;
        vc.spacing = s.spacing;
        vc.blur = s.blur;
        vc.autoHide = s.autoHide;
        vc.primaryColor = s.primaryColor || "";
        vc.secondaryColor = s.secondaryColor || "";
        vc.activePreset = name;
    }
}
