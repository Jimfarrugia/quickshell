#version 440
// Uniform tray tint. Most tray icons are alpha-shaped and are tinted by their
// alpha. Some (Tailscale) are drawn on an opaque square, where alpha alone
// would fill the whole square: when all four corners are opaque, the corner
// color is treated as background and the luminance distance from it becomes
// the mask, so dim and lit marks keep their relative strength.
//
// After editing, regenerate the committed .qsb from this directory:
//   /usr/lib/qt6/bin/qsb --qt6 -o tray-tint.frag.qsb tray-tint.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 tint;
};

layout(binding = 1) uniform sampler2D source;

const vec3 luma = vec3(0.2126, 0.7152, 0.0722);

void main() {
    vec4 c = texture(source, qt_TexCoord0);
    vec4 c00 = texture(source, vec2(0.0, 0.0));
    vec4 c10 = texture(source, vec2(1.0, 0.0));
    vec4 c01 = texture(source, vec2(0.0, 1.0));
    vec4 c11 = texture(source, vec2(1.0, 1.0));

    float cornerAlpha = min(min(c00.a, c10.a), min(c01.a, c11.a));
    float opaqueBackground = step(0.99, cornerAlpha);

    // Corners are opaque on this path, so their premultiplied rgb is straight rgb.
    float backgroundLuma = dot((c00.rgb + c10.rgb + c01.rgb + c11.rgb) * 0.25, luma);
    float pixelLuma = c.a > 0.0 ? dot(c.rgb / c.a, luma) : backgroundLuma;
    float range = max(max(backgroundLuma, 1.0 - backgroundLuma), 0.001);
    float contrast = clamp(abs(pixelLuma - backgroundLuma) / range, 0.0, 1.0);

    float mask = mix(c.a, c.a * contrast, opaqueBackground);
    fragColor = tint * (mask * qt_Opacity);
}
