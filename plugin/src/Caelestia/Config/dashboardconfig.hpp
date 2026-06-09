#pragma once

#include "configobject.hpp"

namespace caelestia::config {

class DashboardPerformance : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, showBattery, true)
    CONFIG_PROPERTY(bool, showGpu, true)
    CONFIG_PROPERTY(bool, showCpu, true)
    CONFIG_PROPERTY(bool, showMemory, true)
    CONFIG_PROPERTY(bool, showStorage, true)
    CONFIG_PROPERTY(bool, showNetwork, true)

public:
    explicit DashboardPerformance(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

class CalendarColors : public QObject {
    Q_OBJECT
    QML_ANONYMOUS
    Q_PROPERTY(QString blue READ blue CONSTANT)
    Q_PROPERTY(QString red READ red CONSTANT)
    Q_PROPERTY(QString green READ green CONSTANT)
    Q_PROPERTY(QString yellow READ yellow CONSTANT)
    Q_PROPERTY(QString orange READ orange CONSTANT)
    Q_PROPERTY(QString purple READ purple CONSTANT)
    Q_PROPERTY(QString teal READ teal CONSTANT)
    Q_PROPERTY(QString pink READ pink CONSTANT)
    Q_PROPERTY(QString brown READ brown CONSTANT)

public:
    explicit CalendarColors(QObject* parent = nullptr) : QObject(parent) {}
    QString blue() const { return "#4285F4"; }
    QString red() const { return "#EA4335"; }
    QString green() const { return "#34A853"; }
    QString yellow() const { return "#FBBC05"; }
    QString orange() const { return "#FF6D01"; }
    QString purple() const { return "#A142F4"; }
    QString teal() const { return "#009688"; }
    QString pink() const { return "#E91E63"; }
    QString brown() const { return "#795548"; }
};

class DashboardConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, showOnHover, true)
    CONFIG_PROPERTY(bool, showDashboard, true)
    CONFIG_PROPERTY(bool, showMedia, true)
    CONFIG_PROPERTY(bool, showPerformance, true)
    CONFIG_PROPERTY(bool, showWeather, true)
    CONFIG_GLOBAL_PROPERTY(int, mediaUpdateInterval, 500)
    CONFIG_GLOBAL_PROPERTY(int, resourceUpdateInterval, 1000)
    CONFIG_PROPERTY(int, dragThreshold, 50)
    CONFIG_PROPERTY(bool, useWallpaperAvatar, false)
    CONFIG_PROPERTY(int, updateInterval, 1000)
    CONFIG_SUBOBJECT(DashboardPerformance, performance)
    CONFIG_SUBOBJECT(CalendarColors, calendarColors)

public:
    explicit DashboardConfig(QObject* parent = nullptr)
        : ConfigObject(parent)
        , m_performance(new DashboardPerformance(this))
        , m_calendarColors(new CalendarColors(this)) {}
};

} // namespace caelestia::config
