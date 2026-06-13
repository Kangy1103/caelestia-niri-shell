#include "visualiserbars.hpp"

#include <algorithm>
#include <cmath>
#include <qbrush.h>
#include <qpainter.h>
#include <qpainterpath.h>
#include <qpen.h>

namespace caelestia::internal {

VisualiserBars::VisualiserBars(QQuickItem* parent)
    : QQuickPaintedItem(parent) {
    setAntialiasing(true);
}

void VisualiserBars::advance(qreal dt) {
    if (m_displayValues.isEmpty() || m_settled)
        return;

    // dt is in seconds (from FrameAnimation.frameTime), convert to ms
    const qreal dtMs = dt * 1000.0;
    const qreal tau = m_animationDuration / 3.0;
    const qreal alpha = 1.0 - std::exp(-dtMs / tau);

    bool allSettled = true;

    for (qsizetype i = 0; i < m_displayValues.size(); ++i) {
        const double diff = m_targetValues[i] - m_displayValues[i];

        if (std::abs(diff) > 0.001) {
            m_displayValues[i] += diff * alpha;
            allSettled = false;
        } else {
            m_displayValues[i] = m_targetValues[i];
        }
    }

    update();

    if (allSettled && !m_settled) {
        m_settled = true;
        emit settledChanged();
    }
}

void VisualiserBars::paint(QPainter* painter) {
    if (m_displayValues.isEmpty())
        return;

    painter->setRenderHint(QPainter::Antialiasing, true);
    painter->setPen(Qt::NoPen);

    const qreal h = height();
    const qreal maxBarHeight = h * 0.4;

    QLinearGradient gradient(0, h - maxBarHeight, 0, h);
    gradient.setColorAt(0, m_primaryColor);
    gradient.setColorAt(1, m_secondaryColor);
    painter->setBrush(gradient);

    if (m_mode == Waveform || m_mode == FilledWaveform) {
        QPen pen(m_primaryColor, 2.0);
        if (m_mode == FilledWaveform)
            painter->setPen(Qt::NoPen);
        else
            painter->setPen(pen);

        drawWaveformSide(painter, false);
        drawWaveformSide(painter, true);
    } else {
        drawSide(painter, false);
        drawSide(painter, true);
    }
}

void VisualiserBars::drawSide(QPainter* painter, bool rightSide) {
    const qreal w = width();
    const qreal h = height();
    const auto count = m_displayValues.size();

    if (count == 0)
        return;

    const qreal sideWidth = w * 0.4;
    const qreal slotWidth = sideWidth / static_cast<qreal>(count);
    const qreal barWidth = std::max(1.0, slotWidth - m_spacing);

    const qreal sideOffset = rightSide ? w * 0.6 : 0;
    const qreal maxBarHeight = h * 0.4;

    for (qsizetype i = 0; i < count; ++i) {
        const qsizetype valueIndex = rightSide ? i : (count - i - 1);
        const qreal value = std::clamp(m_displayValues[valueIndex] * m_sensitivity, 0.0, 1.0);
        const qreal barHeight = value * maxBarHeight;

        if (barHeight <= 0)
            continue;

        const qreal x = static_cast<qreal>(i) * slotWidth + sideOffset;
        const qreal y = h - barHeight;
        const qreal r = std::min({ m_rounding, barWidth / 2.0, barHeight });

        QPainterPath path;
        path.moveTo(x, h);
        path.lineTo(x, y + r);

        if (r > 0) {
            path.arcTo(x, y, r * 2, r * 2, 180, -90);
            path.lineTo(x + barWidth - r, y);
            path.arcTo(x + barWidth - r * 2, y, r * 2, r * 2, 90, -90);
        } else {
            path.lineTo(x, y);
            path.lineTo(x + barWidth, y);
        }

        path.lineTo(x + barWidth, h);
        path.closeSubpath();

        painter->drawPath(path);
    }
}

void VisualiserBars::drawWaveformSide(QPainter* painter, bool rightSide) {
    const qreal w = width();
    const qreal h = height();
    const auto count = m_displayValues.size();

    if (count < 2)
        return;

    const qreal sideWidth = w * 0.4;
    const qreal slotWidth = sideWidth / static_cast<qreal>(count);
    const qreal sideOffset = rightSide ? w * 0.6 : 0;
    const qreal maxBarHeight = h * 0.4;

    QPainterPath path;

    for (qsizetype i = 0; i < count; ++i) {
        const qsizetype valueIndex = rightSide ? i : (count - i - 1);
        const qreal value = std::clamp(m_displayValues[valueIndex] * m_sensitivity, 0.0, 1.0);
        const qreal barHeight = value * maxBarHeight;
        const qreal x = static_cast<qreal>(i) * slotWidth + sideOffset + slotWidth / 2.0;
        const qreal y = h - barHeight;

        if (i == 0) {
            path.moveTo(x, y);
        } else {
            const auto prev = rightSide ? i - 1 : (count - i);
            const qreal prevValue = std::clamp(m_displayValues[prev] * m_sensitivity, 0.0, 1.0);
            const qreal prevBarHeight = prevValue * maxBarHeight;
            const qreal prevX = static_cast<qreal>(i - 1) * slotWidth + sideOffset + slotWidth / 2.0;
            const qreal prevY = h - prevBarHeight;
            const qreal ctrlX = (prevX + x) / 2.0;

            path.cubicTo(ctrlX, prevY, ctrlX, y, x, y);
        }
    }

    if (m_mode == FilledWaveform) {
        const qreal lastX = rightSide
            ? static_cast<qreal>(count - 1) * slotWidth + sideOffset + slotWidth / 2.0
            : sideOffset + slotWidth / 2.0;
        const qreal firstX = rightSide
            ? sideOffset + slotWidth / 2.0
            : static_cast<qreal>(count - 1) * slotWidth + sideOffset + slotWidth / 2.0;
        path.lineTo(lastX, h);
        path.lineTo(firstX, h);
        path.closeSubpath();
        painter->drawPath(path);
    } else {
        painter->drawPath(path);
    }
}

QVector<double> VisualiserBars::values() const {
    return m_targetValues;
}

void VisualiserBars::setValues(const QVector<double>& values) {
    m_targetValues = values;

    if (m_displayValues.size() != values.size()) {
        m_displayValues.resize(values.size(), 0.0);
    }

    if (m_settled) {
        m_settled = false;
        emit settledChanged();
    }

    emit valuesChanged();
}

bool VisualiserBars::settled() const {
    return m_settled;
}

QColor VisualiserBars::primaryColor() const {
    return m_primaryColor;
}

void VisualiserBars::setPrimaryColor(const QColor& color) {
    if (m_primaryColor == color)
        return;
    m_primaryColor = color;
    emit primaryColorChanged();
    update();
}

QColor VisualiserBars::secondaryColor() const {
    return m_secondaryColor;
}

void VisualiserBars::setSecondaryColor(const QColor& color) {
    if (m_secondaryColor == color)
        return;
    m_secondaryColor = color;
    emit secondaryColorChanged();
    update();
}

qreal VisualiserBars::rounding() const {
    return m_rounding;
}

void VisualiserBars::setRounding(qreal rounding) {
    if (qFuzzyCompare(m_rounding, rounding))
        return;
    m_rounding = rounding;
    emit roundingChanged();
    update();
}

qreal VisualiserBars::spacing() const {
    return m_spacing;
}

void VisualiserBars::setSpacing(qreal spacing) {
    if (qFuzzyCompare(m_spacing, spacing))
        return;
    m_spacing = spacing;
    emit spacingChanged();
    update();
}

int VisualiserBars::animationDuration() const {
    return m_animationDuration;
}

void VisualiserBars::setAnimationDuration(int duration) {
    if (m_animationDuration == duration)
        return;
    m_animationDuration = duration;
    emit animationDurationChanged();
}

VisualiserBars::Mode VisualiserBars::mode() const {
    return m_mode;
}

void VisualiserBars::setMode(Mode mode) {
    if (m_mode == mode)
        return;
    m_mode = mode;
    emit modeChanged();
    update();
}

qreal VisualiserBars::sensitivity() const {
    return m_sensitivity;
}

void VisualiserBars::setSensitivity(qreal sensitivity) {
    sensitivity = std::clamp(sensitivity, 0.1, 5.0);
    if (qFuzzyCompare(m_sensitivity, sensitivity))
        return;
    m_sensitivity = sensitivity;
    emit sensitivityChanged();
    update();
}

} // namespace caelestia::internal
