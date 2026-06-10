#include "tokens.hpp"
#include "config.hpp"
#include "monitorconfigmanager.hpp"

#include <qqmlengine.h>
#include <qstandardpaths.h>

namespace caelestia::config {

namespace {

QString configDir() {
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + QStringLiteral("/caelestia-niri-shell/");
}

} // namespace

TokenConfig::TokenConfig(QObject* parent)
    : RootConfig(parent)
    , m_appearance(new AppearanceTokens(this))
    , m_sizes(new SizeTokens(this))
    , m_font(new FontTokens(this))
    , m_anim(new AnimTokens(this)) {
    setupFileBackend(configDir() + QStringLiteral("shell-tokens.json"));
}

TokenConfig::TokenConfig(TokenConfig* fallback, const QString& filePath, const QString& screen, QObject* parent)
    : RootConfig(parent)
    , m_appearance(new AppearanceTokens(this))
    , m_sizes(new SizeTokens(this))
    , m_font(new FontTokens(this))
    , m_anim(new AnimTokens(this)) {
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

    auto* appearance = GlobalConfig::instance()->appearance();
    inst->m_font->bindFont(appearance->font());
    inst->m_anim->bindDurations(appearance->anim()->durations());
    inst->m_anim->bindCurves(inst->appearance()->curves());

    return inst;
}

FontTokens* TokenConfig::font() const {
    return m_font;
}

AnimTokens* TokenConfig::anim() const {
    return m_anim;
}

} // namespace caelestia::config
