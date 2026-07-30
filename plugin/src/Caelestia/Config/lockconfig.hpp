#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class LockConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, recolourLogo, true)
    CONFIG_PROPERTY(bool, enableHowdy, true)
    CONFIG_PROPERTY(int, maxHowdyTries, 3)
    CONFIG_PROPERTY(bool, triggerHowdyOnWake, true)
    CONFIG_GLOBAL_PROPERTY(bool, enableFprint, true)
    CONFIG_GLOBAL_PROPERTY(int, maxFprintTries, 3)
    CONFIG_PROPERTY(bool, hideNotifs, false)
    CONFIG_PROPERTY(bool, showExtras, false)

public:
    explicit LockConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
