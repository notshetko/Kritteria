#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float uTime;
    float uEnergy;
    float uParticles;
    vec4 uColorA;
    vec4 uColorB;
    vec4 uColorC;
};

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float circleSdf(vec2 p, vec2 center, float radius) {
    return length(p - center) - radius;
}

float smoothUnion(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

void main() {
    vec2 uv = qt_TexCoord0;
    float t = uTime;

    // Small, graphic, kawaii-like cluster of puffs: intentionally not realistic smoke.
    // The shape occupies only the centre of the lyric widget; the rest stays truly transparent.
    vec2 p = (uv - vec2(0.5)) * vec2(3.85, 3.95);
    p += vec2(
        sin(t * 0.31 + p.y * 1.7) * 0.035 + sin(t * 0.17) * 0.025,
        cos(t * 0.27 + p.x * 1.4) * 0.035 + cos(t * 0.21) * 0.018
    );

    float d = (length(vec2(p.x / 0.78, (p.y - 0.14) / 0.35)) - 1.0) * 0.35;
    d = smoothUnion(d, circleSdf(p, vec2(-0.52, 0.03), 0.34), 0.18);
    d = smoothUnion(d, circleSdf(p, vec2(-0.27, -0.25), 0.40), 0.18);
    d = smoothUnion(d, circleSdf(p, vec2(0.08, -0.34), 0.43), 0.18);
    d = smoothUnion(d, circleSdf(p, vec2(0.43, -0.15), 0.37), 0.18);
    d = smoothUnion(d, circleSdf(p, vec2(0.62, 0.08), 0.29), 0.16);

    // A tiny slow wobble keeps the outline alive without turbulent/cloud-photography noise.
    float n = noise2(p * 2.0 + vec2(t * 0.12, -t * 0.09));
    d += (n - 0.5) * 0.035 + sin(p.x * 5.0 + t * 0.42) * 0.012;
    d -= uEnergy * 0.018;

    float body = 1.0 - smoothstep(-0.045, 0.12, d);
    float edgeGlow = exp(-abs(d) * 13.0) * 0.095;
    float alpha = (body * 0.38 + edgeGlow) * (0.66 + uEnergy * 0.08);

    // Gentle, flat pastel bands rather than realistic volumetric shading.
    float band = smoothstep(-0.7, 0.7, p.x + sin(t * 0.18 + p.y * 2.0) * 0.12);
    vec3 cloud = mix(uColorA.rgb, uColorB.rgb, band * 0.72);
    float highlight = 1.0 - smoothstep(-0.25, 0.38, p.y + sin(p.x * 2.6 + t * 0.2) * 0.035) * body;
    cloud = mix(cloud, uColorC.rgb, highlight * 0.28);
    cloud *= 0.94 + n * 0.08;

    // A few low-contrast sparkles remain inside the shape, never across the widget rectangle.
    vec2 grid = uv * vec2(10.0, 6.0);
    vec2 cell = floor(grid);
    vec2 local = fract(grid) - vec2(0.5);
    float seed = hash21(cell);
    vec2 particleDrift = vec2(
        sin(t * (0.16 + seed * 0.08) + seed * 8.0),
        cos(t * (0.14 + seed * 0.07) + seed * 11.0)
    ) * 0.10;
    float particle = exp(-dot(local - particleDrift, local - particleDrift) * 115.0);
    particle *= uParticles * smoothstep(0.76, 0.94, seed) * body * 0.035;
    cloud = mix(cloud, mix(uColorA.rgb, uColorC.rgb, seed), particle * 1.4);
    alpha = clamp(alpha + particle, 0.0, 0.48);

    // Explicitly erase the shader's rectangular edge zone so no widget bounds can show through.
    float edgeDistance = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    float edgeFade = smoothstep(0.0, 0.12, edgeDistance);
    alpha *= edgeFade;

    // Premultiplied alpha is required by Qt Quick's scene graph.
    fragColor = vec4(cloud * alpha, alpha) * qt_Opacity;
}
