#include "../src/Caelestia/Internal/umbrielipc.hpp"

#include <QCoreApplication>
#include <QLocalServer>
#include <QLocalSocket>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QtTest>

#include <memory>

class UmbrielIpcLifecycleTest : public QObject {
    Q_OBJECT

private slots:
    void init() {
        QVERIFY(directory.isValid());
        server = std::make_unique<QLocalServer>();
        const QString path = directory.filePath(QString::number(++sequence));
        qputenv("UMBRIEL_SOCKET", path.toUtf8());
        QVERIFY(server->listen(path));
    }

    void cleanup() {
        server.reset();
    }

    void destroyConnectedClient() {
        for (int iteration = 0; iteration < 10; ++iteration) {
            auto client = std::make_unique<caelestia::UmbrielIpc>();
            QTRY_VERIFY(client->available());
            QTRY_VERIFY(server->hasPendingConnections());
            std::unique_ptr<QLocalSocket> peer(server->nextPendingConnection());
            QSignalSpy changes(client.get(), &caelestia::UmbrielIpc::availableChanged);

            // A socket destructor must not restart an already-destroyed timer
            // or access the client's other destroyed members during teardown.
            client.reset();
            QCOMPARE(changes.count(), 0);
            QTRY_COMPARE(peer->state(), QLocalSocket::UnconnectedState);
        }
        QTest::qWait(1200);
    }

    void reconnectAfterPeerDisconnect() {
        auto client = std::make_unique<caelestia::UmbrielIpc>();
        QTRY_VERIFY(client->available());
        QTRY_VERIFY(server->hasPendingConnections());
        std::unique_ptr<QLocalSocket> peer(server->nextPendingConnection());
        peer->abort();
        QTRY_VERIFY(!client->available());
        QTRY_VERIFY_WITH_TIMEOUT(client->available(), 3000);
        QTRY_VERIFY(server->hasPendingConnections());
        std::unique_ptr<QLocalSocket> replacement(server->nextPendingConnection());
        QCOMPARE(replacement->state(), QLocalSocket::ConnectedState);
    }

    void destroyWithReconnectPending() {
        auto client = std::make_unique<caelestia::UmbrielIpc>();
        QTRY_VERIFY(client->available());
        QTRY_VERIFY(server->hasPendingConnections());
        std::unique_ptr<QLocalSocket> peer(server->nextPendingConnection());
        peer->abort();
        QTRY_VERIFY(!client->available());
        client.reset();
        QTest::qWait(1200);
        QVERIFY(!server->hasPendingConnections());
    }

private:
    QTemporaryDir directory;
    std::unique_ptr<QLocalServer> server;
    int sequence = 0;
};

QTEST_GUILESS_MAIN(UmbrielIpcLifecycleTest)
#include "umbrielipc_lifecycle.moc"
