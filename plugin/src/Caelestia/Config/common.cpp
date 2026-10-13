#include "common.hpp"

#include <qstandardpaths.h>

namespace caelestia::config {

using Qt::StringLiterals::operator""_s;

Q_LOGGING_CATEGORY(lcConfig, "caelestia.config", QtInfoMsg)

QString configDir() {
    // CNS honours CAELESTIA_CONFIG_DIR (set by //@ pragma Env in shell.qml).
    // The fallback must stay CNS-namespaced too — if the shell is ever started
    // without that pragma, an un-namespaced dir would silently read an empty
    // config rather than erroring.
    const QByteArray env = qgetenv("CAELESTIA_CONFIG_DIR");
    if (!env.isEmpty())
        return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + u'/' + QString::fromUtf8(env) + u'/';
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation) + u"/caelestia-niri-shell"_s;
}

QString monitorConfigDir() {
    return configDir() + u"/monitors"_s;
}

} // namespace caelestia::config
