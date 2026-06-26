.pragma library

function readBoolOverride(envGetter, envVarNames, defaultValue) {
    for (var i = 0; i < envVarNames.length; i++) {
        var value = envGetter(envVarNames[i]);
        if (value !== undefined && value !== null) {
            var normalized = String(value).toLowerCase().trim();
            if (normalized === "1" || normalized === "true" || normalized === "yes" || normalized === "on")
                return true;
            if (normalized === "0" || normalized === "false" || normalized === "no" || normalized === "off")
                return false;
        }
    }
    return defaultValue;
}

function readStringOverride(envGetter, envVarNames, defaultValue) {
    for (var i = 0; i < envVarNames.length; i++) {
        var value = envGetter(envVarNames[i]);
        if (value !== undefined && value !== null && String(value).trim().length > 0)
            return String(value).trim();
    }
    return defaultValue;
}
