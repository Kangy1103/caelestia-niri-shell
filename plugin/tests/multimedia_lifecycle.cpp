#include "../src/Caelestia/Multimedia/visualsource.hpp"
#include "../src/Caelestia/Multimedia/imagecache.hpp"
#include "../src/Caelestia/Multimedia/imagecacheworker.hpp"
#include "../src/Caelestia/Multimedia/ktxencoder.hpp"

#include <QTemporaryDir>
#include <QFile>
#include <QQuickWindow>
#include <QtTest>
#include <memory>

using namespace caelestia::shell::multimedia;

class MultimediaTest : public QObject {
    Q_OBJECT
private slots:
    void fitKeepsAspectAndNeverUpscales() {
        const QSize native(1200, 2400), bucket(3584, 1536);
        const auto fit = ktx::fitFor(native, bucket, Qt::KeepAspectRatio);
        QCOMPARE(fit.scaled, QSize(768, 1536));
        QImage image(native, QImage::Format_RGB32);
        image.fill(Qt::red);
        const auto fitted = ktx::fitted(image, bucket, Qt::KeepAspectRatio);
        QCOMPARE(fitted.size(), fit.scaled);
        QCOMPARE(fitted.pixelColor(100, 100), QColor(Qt::red));
        QCOMPARE(ktx::fitted(image, QSize(4096, 4096), Qt::KeepAspectRatio).size(), native);
    }

    void losslessCacheAndReopen() {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        QImage image(QSize(512, 256), QImage::Format_ARGB32);
        for (int x = 0; x < image.width(); ++x)
            for (int y = 0; y < image.height(); ++y)
                image.setPixelColor(x, y, QColor(x % 256, y, (x + y) % 256, 255));
        {
            ImageCacheWorker worker(dir.path());
            worker.open();
            worker.storeImage("test", image, image.size(), Qt::KeepAspectRatio);
            QCOMPARE(QImage(dir.filePath("test.png")), image);
            worker.touch("test");
        }
        {
            ImageCacheWorker worker(dir.path());
            worker.open();
            QCOMPARE(QImage(dir.filePath("test.png")), image);
        }
    }

    void missingImageStillPublishesPath() {
        QQuickWindow window;
        QQuickItem item(window.contentItem());
        item.setSize(QSizeF(300, 200));
        VisualSource source;
        source.setSizeSource(&item);
        source.setSource("/definitely-missing-wallpaper.png");
        QVERIFY(!source.imagePath().isEmpty());
    }

    void cacheReconcilesAndEnforcesBudget() {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        // Sparse files exercise the byte budget without allocating 600 MiB.
        for (const QString name : {QString("a.png"), QString("b.png")}) {
            QFile file(dir.filePath(name));
            QVERIFY(file.open(QIODevice::WriteOnly));
            QVERIFY(file.resize(300ll * 1024 * 1024));
        }
        ImageCacheWorker worker(dir.path());
        worker.open();
        const int remaining = int(QFile::exists(dir.filePath("a.png")))
            + int(QFile::exists(dir.filePath("b.png")));
        QCOMPARE(remaining, 1);
    }

    void sourceChangesAndDestruction() {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        QImage image(QSize(800, 400), QImage::Format_RGB32);
        image.fill(Qt::blue);
        const auto path = dir.filePath("image.png");
        QVERIFY(image.save(path));
        QQuickWindow window;
        for (int i = 0; i < 50; ++i) {
            auto item = std::make_unique<QQuickItem>(window.contentItem());
            item->setSize(QSizeF(300, 200));
            auto source = std::make_unique<VisualSource>();
            source->setSizeSource(item.get());
            source->setSource(path);
            QCOMPARE(source->type(), VisualSource::Type::Still);
            QVERIFY(!source->imagePath().isEmpty());
            source->setFillMode(VisualSource::FillMode::PreserveAspectFit);
            source->setSource(dir.filePath("missing.mp4"));
            source->setPlaying(true);
            source->setSource(path);
            source->setPlaying(false);
            source->setSource("");
            QVERIFY(source->imagePath().isEmpty());
            if (i % 2) item.reset();
            source.reset();
            QCoreApplication::processEvents();
        }
    }
};

QTEST_MAIN(MultimediaTest)
#include "multimedia_lifecycle.moc"
