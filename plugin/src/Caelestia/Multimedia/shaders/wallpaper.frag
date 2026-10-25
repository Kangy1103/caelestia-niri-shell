#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float zoom;
};
layout(binding = 1) uniform sampler2D from;
layout(binding = 2) uniform sampler2D to;
vec4 boundedSample(sampler2D tex, vec2 uv) {
    if (any(lessThan(uv, vec2(0))) || any(greaterThan(uv, vec2(1))))
        return vec4(0);
    return texture(tex, uv);
}
void main() {
    vec2 oldUv = (qt_TexCoord0 - vec2(0.5)) / mix(1.0, zoom, progress) + vec2(0.5);
    vec2 newUv = (qt_TexCoord0 - vec2(0.5)) / mix(zoom, 1.0, progress) + vec2(0.5);
    fragColor = mix(boundedSample(from, oldUv), boundedSample(to, newUv), progress) * qt_Opacity;
}
