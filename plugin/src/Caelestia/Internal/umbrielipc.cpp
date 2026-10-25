#include "umbrielipc.hpp"

#include <QDir>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QProcessEnvironment>
#include <QDebug>

#include <memory>

namespace caelestia {

UmbrielIpc::UmbrielIpc(QObject* parent)
    : QObject(parent) {
    m_reconnectTimer.setSingleShot(true);
    connect(&m_reconnectTimer, &QTimer::timeout, this, &UmbrielIpc::connectToUmbriel);

    connect(&m_eventSocket, &QLocalSocket::connected, this, &UmbrielIpc::onEventConnected);
    connect(&m_eventSocket, &QLocalSocket::disconnected, this, &UmbrielIpc::onEventDisconnected);
    connect(&m_eventSocket, &QLocalSocket::readyRead, this, &UmbrielIpc::onEventReadyRead);
    connect(&m_eventSocket, &QLocalSocket::errorOccurred, this, &UmbrielIpc::onEventError);

    connectToUmbriel();
}

UmbrielIpc::~UmbrielIpc() {
    // Member destruction precedes QObject's automatic disconnection. Closing
    // the socket must not invoke slots that access already-destroyed members.
    QObject::disconnect(&m_eventSocket, nullptr, this, nullptr);
    m_reconnectTimer.stop();
    m_eventSocket.abort();
}

bool UmbrielIpc::available() const { return m_available; }
const QVariantList& UmbrielIpc::workspaces() const { return m_workspaces; }
const QVariantList& UmbrielIpc::windows() const { return m_windows; }
const QVariantList& UmbrielIpc::outputs() const { return m_outputs; }
bool UmbrielIpc::inOverview() const { return m_inOverview; }
const QVariantList& UmbrielIpc::keyboardLayoutNames() const { return m_keyboardLayoutNames; }
int UmbrielIpc::keyboardLayoutIndex() const { return m_keyboardLayoutIndex; }

QString UmbrielIpc::socketPath() {
    const auto env = QProcessEnvironment::systemEnvironment();
    const QString configuredPath = env.value(QStringLiteral("UMBRIEL_SOCKET"));
    if (!configuredPath.isEmpty())
        return configuredPath;

    const QString runtimeDir = env.value(QStringLiteral("XDG_RUNTIME_DIR"));
    const QString waylandDisplay = env.value(QStringLiteral("WAYLAND_DISPLAY"));
    if (runtimeDir.isEmpty() || waylandDisplay.isEmpty())
        return {};

    return QDir(runtimeDir).filePath(QStringLiteral("umbriel-%1.sock").arg(waylandDisplay));
}

void UmbrielIpc::connectToUmbriel() {
    const QString path = socketPath();
    if (path.isEmpty()) {
        qWarning() << "UmbrielIpc: UMBRIEL_SOCKET and socket fallback inputs are unavailable";
        scheduleReconnect();
        return;
    }

    if (m_eventSocket.state() != QLocalSocket::UnconnectedState)
        m_eventSocket.abort();

    m_readBuffer.clear();
    m_eventSocket.connectToServer(path);
}

void UmbrielIpc::onEventConnected() {
    qDebug() << "UmbrielIpc: Connected; subscribing to compositor snapshots";

    const QJsonObject subscription{
        {QStringLiteral("cmd"), QStringLiteral("subscribe")},
        {QStringLiteral("events"), QJsonArray{
            QStringLiteral("windows"),
            QStringLiteral("workspaces"),
            QStringLiteral("outputs"),
            QStringLiteral("overview"),
            QStringLiteral("keyboard_layout"),
        }},
    };
    const QByteArray payload = QJsonDocument(subscription).toJson(QJsonDocument::Compact) + '\n';
    m_eventSocket.write(payload);
    m_eventSocket.flush();
    m_reconnectDelay = 1000;
    setAvailable(true);
}

void UmbrielIpc::onEventDisconnected() {
    setAvailable(false);
    m_readBuffer.clear();
    scheduleReconnect();
}

void UmbrielIpc::onEventReadyRead() {
    m_readBuffer.append(m_eventSocket.readAll());

    int position = 0;
    while ((position = static_cast<int>(m_readBuffer.indexOf('\n'))) >= 0) {
        const QByteArray line = m_readBuffer.left(position).trimmed();
        m_readBuffer.remove(0, position + 1);
        if (!line.isEmpty())
            processEventLine(line);
    }
}

void UmbrielIpc::onEventError(QLocalSocket::LocalSocketError error) {
    if (error == QLocalSocket::PeerClosedError)
        return;
    qWarning() << "UmbrielIpc: Socket error:" << m_eventSocket.errorString();
    scheduleReconnect();
}

void UmbrielIpc::processEventLine(const QByteArray& line) {
    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(line, &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        qWarning() << "UmbrielIpc: Invalid event JSON:" << parseError.errorString();
        return;
    }

    const QJsonObject message = document.object();
    if (message.contains(QStringLiteral("err"))) {
        qWarning() << "UmbrielIpc: Subscription error:" << message.value(QStringLiteral("err"));
        m_eventSocket.abort();
        return;
    }

    const QString family = message.value(QStringLiteral("event")).toString();
    const QJsonValue data = message.value(QStringLiteral("data"));
    if (family == QStringLiteral("workspaces")) {
        m_workspaces = data.toArray().toVariantList();
        emit workspacesChanged();
    } else if (family == QStringLiteral("windows")) {
        m_windows = data.toArray().toVariantList();
        emit windowsChanged();
    } else if (family == QStringLiteral("outputs")) {
        m_outputs = data.toArray().toVariantList();
        emit outputsChanged();
    } else if (family == QStringLiteral("overview")) {
        const bool open = data.toObject().value(QStringLiteral("open")).toBool();
        if (m_inOverview != open) {
            m_inOverview = open;
            emit inOverviewChanged();
        }
    } else if (family == QStringLiteral("keyboard_layout")) {
        const QJsonObject keyboard = data.toObject();
        m_keyboardLayoutNames = keyboard.value(QStringLiteral("names")).toArray().toVariantList();
        m_keyboardLayoutIndex = keyboard.value(QStringLiteral("current_index")).toInt();
        emit keyboardLayoutChanged();
    }
}

void UmbrielIpc::scheduleReconnect() {
    if (m_reconnectTimer.isActive())
        return;
    m_reconnectTimer.start(m_reconnectDelay);
    m_reconnectDelay = qMin(m_reconnectDelay * 2, 30000);
}

void UmbrielIpc::sendCommand(const QJsonObject& command) {
    const QString path = socketPath();
    if (path.isEmpty()) {
        qWarning() << "UmbrielIpc: Cannot send command without a socket path";
        return;
    }

    auto* socket = new QLocalSocket(this);
    const auto responseBuffer = std::make_shared<QByteArray>();
    const QByteArray payload = QJsonDocument(command).toJson(QJsonDocument::Compact) + '\n';

    connect(socket, &QLocalSocket::connected, socket, [socket, payload]() {
        socket->write(payload);
        socket->flush();
    });
    connect(socket, &QLocalSocket::readyRead, socket, [socket, responseBuffer]() {
        responseBuffer->append(socket->readAll());
        if (!responseBuffer->contains('\n'))
            return;

        QJsonParseError parseError;
        const QJsonDocument response = QJsonDocument::fromJson(responseBuffer->trimmed(), &parseError);
        if (parseError.error != QJsonParseError::NoError || !response.isObject()) {
            qWarning() << "UmbrielIpc: Invalid command response:" << parseError.errorString();
        } else if (response.object().contains(QStringLiteral("err"))) {
            qWarning() << "UmbrielIpc: Command rejected:" << response.object().value(QStringLiteral("err"));
        }
        socket->disconnectFromServer();
    });
    connect(socket, &QLocalSocket::disconnected, socket, &QObject::deleteLater);
    connect(socket, &QLocalSocket::errorOccurred, socket, [socket](QLocalSocket::LocalSocketError error) {
        if (error != QLocalSocket::PeerClosedError)
            qWarning() << "UmbrielIpc: Command socket error:" << socket->errorString();
        socket->abort();
        socket->deleteLater();
    });

    socket->connectToServer(path);
}

bool UmbrielIpc::action(const QString& actionName) {
    if (!m_available || actionName.isEmpty())
        return false;

    sendCommand({
        {QStringLiteral("cmd"), QStringLiteral("msg")},
        {QStringLiteral("arg"), actionName},
    });
    return true;
}

void UmbrielIpc::setAvailable(bool available) {
    if (m_available == available)
        return;
    m_available = available;
    emit availableChanged();
}

} // namespace caelestia
