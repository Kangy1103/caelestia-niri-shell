#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class GreeterConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, rememberLastUser, true)
    CONFIG_PROPERTY(bool, rememberLastSession, true)
    CONFIG_PROPERTY(bool, showPowerButton, true)
    CONFIG_PROPERTY(bool, showSessionChooser, true)
    CONFIG_PROPERTY(bool, use24hClock, true)
    CONFIG_PROPERTY(double, backgroundBlur, 0.0)
    CONFIG_PROPERTY(double, backgroundOverlayOpacity, 0.4)
    CONFIG_PROPERTY(int, clockSize, 120)
    CONFIG_PROPERTY(int, dateSize, 20)
    CONFIG_PROPERTY(int, avatarSize, 60)
    CONFIG_PROPERTY(int, passwordWidth, 380)
    CONFIG_PROPERTY(QString, defaultSession, "niri-session")
    CONFIG_PROPERTY(QString, wallpaper, "")

public:
    explicit GreeterConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace caelestia::config
