#pragma once

#include <QByteArray>
#include <QJsonObject>
#include <QLocalSocket>
#include <QObject>
#include <QString>
#include <QTimer>
#include <QtQmlIntegration>
#include <QVariantList>

namespace caelestia {

/// UmbrielIpc — additive IPC backend for the Umbriel compositor.
///
/// Umbriel subscriptions send complete snapshots. This class deliberately keeps
/// those records raw for now; the QML compositor facade can normalise them to
/// CNS's existing Niri-facing shape in a later port step.
class UmbrielIpc final : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(QVariantList workspaces READ workspaces NOTIFY workspacesChanged)
    Q_PROPERTY(QVariantList windows READ windows NOTIFY windowsChanged)
    Q_PROPERTY(QVariantList outputs READ outputs NOTIFY outputsChanged)
    Q_PROPERTY(bool inOverview READ inOverview NOTIFY inOverviewChanged)
    Q_PROPERTY(QVariantList keyboardLayoutNames READ keyboardLayoutNames NOTIFY keyboardLayoutChanged)
    Q_PROPERTY(int keyboardLayoutIndex READ keyboardLayoutIndex NOTIFY keyboardLayoutChanged)

public:
    explicit UmbrielIpc(QObject* parent = nullptr);
    ~UmbrielIpc() override;

    [[nodiscard]] bool available() const;
    [[nodiscard]] const QVariantList& workspaces() const;
    [[nodiscard]] const QVariantList& windows() const;
    [[nodiscard]] const QVariantList& outputs() const;
    [[nodiscard]] bool inOverview() const;
    [[nodiscard]] const QVariantList& keyboardLayoutNames() const;
    [[nodiscard]] int keyboardLayoutIndex() const;

    /// Send an Umbriel action such as "overview-toggle" or "window-close:<id>".
    /// Returns false when the event connection is not available.
    Q_INVOKABLE bool action(const QString& actionName);

signals:
    void availableChanged();
    void workspacesChanged();
    void windowsChanged();
    void outputsChanged();
    void inOverviewChanged();
    void keyboardLayoutChanged();

private slots:
    void connectToUmbriel();
    void onEventConnected();
    void onEventDisconnected();
    void onEventReadyRead();
    void onEventError(QLocalSocket::LocalSocketError error);

private:
    [[nodiscard]] static QString socketPath();
    void processEventLine(const QByteArray& line);
    void scheduleReconnect();
    void sendCommand(const QJsonObject& command);
    void setAvailable(bool available);

    QLocalSocket m_eventSocket;
    QTimer m_reconnectTimer;
    QByteArray m_readBuffer;
    int m_reconnectDelay = 1000;
    bool m_available = false;

    QVariantList m_workspaces;
    QVariantList m_windows;
    QVariantList m_outputs;
    bool m_inOverview = false;
    QVariantList m_keyboardLayoutNames;
    int m_keyboardLayoutIndex = 0;
};

} // namespace caelestia
