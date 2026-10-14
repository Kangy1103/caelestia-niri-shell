#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(binding = 0) uniform sampler2D source;
layout(std140, binding = 1) uniform Uniforms { float qt_Opacity; };

void main()
{
    vec4 c = texture(source, qt_TexCoord0);
    float a = clamp(c.a * 15.0 - 6.0, 0.0, 1.0);
    fragColor = vec4(c.rgb, a) * qt_Opacity;
}
