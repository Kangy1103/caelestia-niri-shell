#pragma once

#include "configobject.hpp"
#include "tokens.hpp"

namespace caelestia::config {

class OsdConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(int, hideDelay, 2000)
    CONFIG_PROPERTY(bool, enableBrightness, true)
    CONFIG_PROPERTY(bool, enableMicrophone, false)

    Q_PROPERTY(QObject* sizes READ osdSizes CONSTANT)

    [[nodiscard]] QObject* osdSizes() const {
        return TokenConfig::instance()->sizes()->osd();
    }

public:
    explicit OsdConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
