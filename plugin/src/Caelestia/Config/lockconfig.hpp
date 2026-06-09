#pragma once

#include "configobject.hpp"
#include "tokens.hpp"

namespace caelestia::config {

class LockConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, recolourLogo, true)
    CONFIG_GLOBAL_PROPERTY(bool, enableFprint, true)
    CONFIG_GLOBAL_PROPERTY(int, maxFprintTries, 3)
    CONFIG_PROPERTY(bool, hideNotifs, false)
    CONFIG_PROPERTY(bool, showExtras, false)

    Q_PROPERTY(QObject* sizes READ lockSizes CONSTANT)

    [[nodiscard]] QObject* lockSizes() const {
        return TokenConfig::instance()->sizes()->lock();
    }

public:
    explicit LockConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
