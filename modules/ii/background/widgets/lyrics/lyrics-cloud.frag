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


// Fractal brownian motion gives the cloud a living, shader-like flow without photo-real smoke.
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    mat2 twist = mat2(1.62, -1.18, 1.18, 1.62);
    for (int octave = 0; octave < 5; ++octave) {
        value += noise2(p) * amplitude;
        p = twist * p + vec2(3.7, -2.4);
        amplitude *= 0.5;
    }
    return value / 0.96875;
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

    // Two low-frequency fields warp the puff silhouette continuously, like a stylized Minecraft cloud shader.
    // The drift is never reset, so the pattern flows rather than restarting a keyframe animation.
    vec2 drift = vec2(t * 0.030, -t * 0.021);
    vec2 warp = vec2(
        fbm(p * 1.55 + drift),
        fbm(p * 1.55 + vec2(9.1, -3.8) - drift.yx)
    );
    vec2 cloudP = p + (warp - 0.5) * 0.20;

    float d = (length(vec2(cloudP.x / 0.78, (cloudP.y - 0.14) / 0.35)) - 1.0) * 0.35;
    d = smoothUnion(d, circleSdf(cloudP, vec2(-0.52, 0.03), 0.34), 0.18);
    d = smoothUnion(d, circleSdf(cloudP, vec2(-0.27, -0.25), 0.40), 0.18);
    d = smoothUnion(d, circleSdf(cloudP, vec2(0.08, -0.34), 0.43), 0.18);
    d = smoothUnion(d, circleSdf(cloudP, vec2(0.43, -0.15), 0.37), 0.18);
    d = smoothUnion(d, circleSdf(cloudP, vec2(0.62, 0.08), 0.29), 0.16);

    // Large cloudy swells and a finer, drifting texture subtly reshape the silhouette.
    float swell = fbm(cloudP * 2.35 + drift * 1.35);
    float detail = fbm(cloudP * 5.4 - drift * 1.7 + vec2(2.8, 6.2));
    d += (swell - 0.5) * 0.105 + (detail - 0.5) * 0.035;
    d -= uEnergy * 0.012;

    float body = 1.0 - smoothstep(-0.052, 0.115, d);
    float edgeGlow = exp(-abs(d) * 13.0) * (0.065 + swell * 0.035);
    float cloudVolume = 0.62 + smoothstep(0.28, 0.78, swell) * 0.26 + detail * 0.12;
    float alpha = (body * 0.34 * cloudVolume + edgeGlow) * (0.66 + uEnergy * 0.08);

    // Gentle, flat pastel bands rather than realistic volumetric shading.
    float band = smoothstep(-0.7, 0.7, cloudP.x + (swell - 0.5) * 0.42 + sin(t * 0.18 + cloudP.y * 2.0) * 0.12);
    vec3 cloud = mix(uColorA.rgb, uColorB.rgb, band * 0.72);
    float highlight = 1.0 - smoothstep(-0.25, 0.38, cloudP.y + sin(cloudP.x * 2.6 + t * 0.2) * 0.035 + (detail - 0.5) * 0.12) * body;
    cloud = mix(cloud, uColorC.rgb, highlight * (0.22 + swell * 0.12));
    cloud *= 0.88 + swell * 0.16 + detail * 0.05;

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
