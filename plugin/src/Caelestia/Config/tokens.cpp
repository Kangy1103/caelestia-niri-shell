#include "tokens.hpp"
#include "monitorconfigmanager.hpp"

#include <qqmlengine.h>
#include <qstandardpaths.h>

namespace caelestia::config {

namespace {

QString configDir() {
    if (auto env = qEnvironmentVariable("CAELESTIA_CONFIG_DIR"); !env.isEmpty())
        return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/") + env + QStringLiteral("/");
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/caelestia/");
}

} // namespace

TokenConfig::TokenConfig(QObject* parent)
    : RootConfig(parent)
    , m_appearance(new AppearanceTokens(this))
    , m_sizes(new SizeTokens(this)) {
    setupFileBackend(configDir() + QStringLiteral("shell-tokens.json"));
}

TokenConfig::TokenConfig(TokenConfig* fallback, const QString& filePath, const QString& screen, QObject* parent)
    : RootConfig(parent)
    , m_appearance(new AppearanceTokens(this))
    , m_sizes(new SizeTokens(this)) {
    if (!filePath.isEmpty())
        setupFileBackend(filePath, screen);
    if (fallback)
        syncFromGlobal(fallback);
}

TokenConfig* TokenConfig::instance() {
    static TokenConfig instance;
    return &instance;
}

TokenConfig* TokenConfig::defaults() {
    if (!m_defaults)
        m_defaults = new TokenConfig(nullptr, QString(), QString(), this);
    return m_defaults;
}

TokenConfig* TokenConfig::forScreen(const QString& screen) {
    return MonitorConfigManager::instance()->tokensForScreen(screen);
}

TokenConfig* TokenConfig::create(QQmlEngine* engine, QJSEngine*) {
    auto* inst = instance();
    QQmlEngine::setObjectOwnership(inst, QQmlEngine::CppOwnership);
    return inst;
}

} // namespace caelestia::config
