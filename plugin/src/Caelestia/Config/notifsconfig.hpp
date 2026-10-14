#pragma once

#include "settings/objectnode.hpp"
#include "common.hpp"
#include "enums.hpp"

namespace caelestia::config {

class NotifsConfig : public settings::ObjectNode {
    CONFIG_NODE(NotifsConfig, settings::ObjectNode)

    // CNS: per-screen notification visibility. Toasts.qml filters every toast
    // through Config.notifs.enabled, and ServicesPage exposes a per-display
    // toggle. This property existed in main but was dropped in the settings
    // API migration; undefined evaluated false and silently hid all toasts.
    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_GLOBAL_PROPERTY(bool, expire, true)
    CONFIG_GLOBAL_ENUM_PROPERTY(NotifsFullscreen, fullscreen, NotifsFullscreen::On)
    CONFIG_GLOBAL_PROPERTY(int, defaultExpireTimeout, 5000)
    CONFIG_GLOBAL_PROPERTY(int, fullscreenExpireTimeout, 2000)
    CONFIG_PROPERTY(qreal, clearThreshold, 0.3)
    CONFIG_PROPERTY(int, expandThreshold, 20)
    CONFIG_GLOBAL_PROPERTY(bool, actionOnClick, true)
    CONFIG_GLOBAL_PROPERTY(bool, soundEnabled, true)
    CONFIG_GLOBAL_PROPERTY(QString, soundNormal, u"root:/assets/sounds/normal/notification.wav"_s)
    CONFIG_GLOBAL_PROPERTY(QString, soundCritical, u"root:/assets/sounds/critical/critical.wav"_s)
    CONFIG_GLOBAL_PROPERTY(QString, soundUnlock, u"root:/assets/sounds/unlock/unlock.wav"_s)
    CONFIG_GLOBAL_PROPERTY(QString, soundLogin, u"root:/assets/sounds/login/login.wav"_s)
    CONFIG_PROPERTY(int, groupPreviewNum, 3)
    CONFIG_PROPERTY(bool, openExpanded, false)
};

} // namespace caelestia::config
