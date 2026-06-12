// Created by Kangy w/ OpenCode AI Assistance
// Version: 0.1.0-20260612

pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property real progress: 1
    property real dropletRadius: 40
    property real finalRadius: 20

    readonly property alias contentItem: content
    default property alias contentData: content.data

    implicitWidth: content.childrenRect.width
    implicitHeight: content.childrenRect.height

    visible: progress < 1

    Item {
        id: content
        anchors.fill: parent
    }

    ShaderEffect {
        id: shader
        anchors.fill: parent
        source: content
        mesh: Qt.size(1, 1)

        property real progress: root.progress
        property real dropletRadius: root.dropletRadius
        property real finalRadius: root.finalRadius
        property real iWidth: width
        property real iHeight: height

        fragmentShader: "
            uniform sampler2D source;
            uniform lowp float qt_Opacity;
            uniform float progress;
            uniform float dropletRadius;
            uniform float finalRadius;
            uniform float iWidth;
            uniform float iHeight;
            varying highp vec2 qt_TexCoord0;

            float sdRoundedBox(vec2 p, vec2 halfSize, float r) {
                vec2 d = abs(p) - halfSize + r;
                return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
            }

            float smin(float a, float b, float k) {
                float h = max(k - abs(a - b), 0.0) / k;
                return min(a, b) - h * h * k * 0.25;
            }

            void main() {
                vec2 res = vec2(iWidth, iHeight);
                vec2 p = (qt_TexCoord0 - 0.5) * res;

                float t = 1.0 - progress;

                float riseT = smoothstep(0.0, 0.45, t);
                float riseCY = mix(
                    res.y * 0.5 - dropletRadius,
                    -dropletRadius * 0.1,
                    riseT
                );

                float expandT = smoothstep(0.45, 1.0, t);
                float bubbleCY = mix(riseCY, 0.0, expandT);

                float bubbleHalfW = mix(dropletRadius * 1.2, res.x * 0.5 - finalRadius, expandT);
                float bubbleHalfH = mix(dropletRadius * 1.3, res.y * 0.5 - finalRadius, expandT);
                float cornerR = mix(dropletRadius, finalRadius, expandT);

                float bubbleBottom = bubbleCY + bubbleHalfH;
                float neckW = mix(dropletRadius * 1.8, 0.0, smoothstep(0.12, 0.45, t));
                float neckCY = (bubbleBottom + res.y * 0.5) * 0.5;
                float neckHH = max(0.0, (res.y * 0.5 - bubbleBottom) * 0.5);

                float bubbleSdf = sdRoundedBox(
                    vec2(p.x, p.y - bubbleCY),
                    vec2(bubbleHalfW, bubbleHalfH),
                    cornerR
                );

                float neckSdf = neckW > 0.1
                    ? sdRoundedBox(vec2(p.x, p.y - neckCY), vec2(neckW, neckHH), 0.0)
                    : 1e9;

                float sdf = smin(bubbleSdf, neckSdf, dropletRadius * 0.25);

                float finalSdf = sdRoundedBox(p, res * 0.5 - finalRadius, finalRadius);
                sdf = mix(sdf, finalSdf, smoothstep(0.45, 0.85, t));

                float alpha = 1.0 - smoothstep(-2.0, 0.0, sdf);

                vec4 srcColor = texture(source, qt_TexCoord0);
                gl_FragColor = srcColor * alpha * qt_Opacity;
            }
        "
    }
}
