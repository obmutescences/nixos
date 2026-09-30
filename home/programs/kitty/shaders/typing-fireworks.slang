#language slang 2026

import kitty_custom_shader_types;

static const float FIREWORK_ALPHA = 0.8;

float hash21(float2 p) {
    p = frac(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return frac(p.x * p.y);
}

float soft_disc(float2 p, float radius) {
    return 1.0 - smoothstep(radius, radius * 0.18, length(p));
}

public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float2 center = d.mouse_pos.xy;
    if (center.x < 0.0 || center.y < 0.0 || center.x > 1.0 || center.y > 1.0) return color;
    float burst = 1.0 - saturate(t.animation_progress);
    float particles = 0.0;

    for (int i = 0; i < 24; ++i) {
        float fi = float(i);
        float angle = 6.2831853 * fi / 24.0 + hash21(float2(fi, 7.0)) * 0.35;
        float distance = (0.012 + hash21(float2(fi, 19.0)) * 0.045) * (1.0 - burst);
        float2 particle = center + float2(cos(angle), sin(angle)) * distance;
        particles += soft_disc(t.pos - particle, 0.0015 + 0.0015 * burst);
    }

    particles = min(particles, 1.0) * burst * FIREWORK_ALPHA;
    return float4(color.rgb + float3(1.0, 0.25, 0.04) * particles, color.a);
}
