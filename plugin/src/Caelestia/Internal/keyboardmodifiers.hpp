#pragma once

#include <qguiapplication.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qtimer.h>

namespace caelestia {

// Wayland can update modifiers without delivering a key event (including when
// a layer surface gains focus after Alt has already been released).
class KeyboardModifiers : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)

public:
    explicit KeyboardModifiers(QObject* parent = nullptr) : QObject(parent) {
        m_timer.setInterval(16);
        m_timer.setTimerType(Qt::PreciseTimer);
        connect(&m_timer, &QTimer::timeout, this, [this] {
            emit sampled(static_cast<int>(QGuiApplication::queryKeyboardModifiers()));
        });
    }

    [[nodiscard]] bool running() const { return m_timer.isActive(); }

    void setRunning(bool running) {
        if (running == m_timer.isActive())
            return;
        if (running)
            m_timer.start();
        else
            m_timer.stop();
        emit runningChanged();
    }

signals:
    void runningChanged();
    void sampled(int modifiers);

private:
    QTimer m_timer;
};

} // namespace caelestia
