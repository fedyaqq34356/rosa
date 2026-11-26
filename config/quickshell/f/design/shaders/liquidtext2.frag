#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float t;
    vec4 color;
};

layout(binding = 1) uniform sampler2D srcA;
layout(binding = 2) uniform sampler2D srcB;

void main() {
    vec2 uv = qt_TexCoord0;
    float s = sin(3.14159265 * clamp(t, 0.0, 1.0));
    float e = t * t * (3.0 - 2.0 * t);
    float f = mix(texture(srcA, uv).a, texture(srcB, uv).a, e);
    float th = mix(0.5, 0.34, s);
    float w = mix(0.5, 0.025, s);
    float a = clamp((f - th) / (2.0 * w) + 0.5, 0.0, 1.0);
    fragColor = vec4(color.rgb * a, a) * color.a * qt_Opacity;
}
