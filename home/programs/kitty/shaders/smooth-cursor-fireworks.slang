#language slang 2026

import kitty_custom_shader_types;

static const float TRAIL_ALPHA = 0.55;
static const float FIREWORK_ALPHA = 1.0;
static const float PARTICLE_SCALE = 1.0;
static const float BURST_DURATION = 0.7;
static const int PARTICLES = 20;
static const float BURST_START = 0.40; // fraction of the reach particles are born at, 0 collapses them onto the cursor

float hash11(float n) { return frac(sin(n * 127.1) * 43758.5453); }

// signed distance (positive inside) to a convex quad, in aspect-corrected space
float quad_sdf(float2 p, float2 c0, float2 c1, float2 c2, float2 c3) {
    float2 cs[4] = { c0, c1, c2, c3 };
    float area = 0.0;
    for (int i = 0; i < 4; i++) {
        float2 a = cs[i];
        float2 b = cs[(i + 1) % 4];
        area += a.x * b.y - b.x * a.y;
    }
    float s = area >= 0.0 ? 1.0 : -1.0;
    float m = 1e9;
    for (int i = 0; i < 4; i++) {
        float2 a = cs[i];
        float2 b = cs[(i + 1) % 4];
        float2 e = b - a;
        float2 n = float2(-e.y, e.x) / max(length(e), 1e-6);
        m = min(m, s * dot(p - a, n));
    }
    return m;
}

public float4 fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float ar = float(d.viewport_size_pixels.x) / float(d.viewport_size_pixels.y);
    float2 asp = float2(ar, 1.0);
    float2 p = t.pos * asp;

    float3 tint = d.cursor_trail_color.rgb;
    if (dot(tint, tint) < 1e-4) tint = float3(0.25, 0.78, 1.0);
    float3 outc = color.rgb;

    // ---- 1. smooth cursor trail (quad between previous and current cursor)
    float2 c0 = float2(d.cursor_trail_corners_x.x, d.cursor_trail_corners_y.x) * asp;
    float2 c1 = float2(d.cursor_trail_corners_x.y, d.cursor_trail_corners_y.y) * asp;
    float2 c2 = float2(d.cursor_trail_corners_x.z, d.cursor_trail_corners_y.z) * asp;
    float2 c3 = float2(d.cursor_trail_corners_x.w, d.cursor_trail_corners_y.w) * asp;
    // Only draw the trail while kitty reports an active, non-degenerate quad.
    // When the trail ends the corners collapse to 0, which would make the sdf
    // constant everywhere and tint the whole screen.
    float quad_w = abs(d.cursor_trail_edge.y - d.cursor_trail_edge.x);
    float quad_h = abs(d.cursor_trail_edge.z - d.cursor_trail_edge.w);
    if (d.cursor_trail_state > 0.0 && quad_w > 1e-5 && quad_h > 1e-5) {
        float sd = quad_sdf(p, c0, c1, c2, c3);
        float body = smoothstep(-0.0015, 0.0015, sd);
        float glow = exp(-max(-sd, 0.0) * 90.0) * 0.35;
        float trail = saturate(body + glow) * TRAIL_ALPHA;
        outc = lerp(outc, tint, trail * 0.6) + tint * glow * 0.25;
    }

    // ---- 2. firework burst at the cursor's new position
    float age = d.timestamp - d.cursor_trail_change_time;
    if (age >= 0.0 && age < BURST_DURATION) {
        float2 center = float2(
            (d.cursor_trail_edge.x + d.cursor_trail_edge.y) * 0.5,
            (d.cursor_trail_edge.z + d.cursor_trail_edge.w) * 0.5) * asp;
        float cell_h = abs(d.cursor_trail_edge.z - d.cursor_trail_edge.w);
        float k = age / BURST_DURATION;
        float fade = (1.0 - k) * (1.0 - k);
        float seed = floor(d.cursor_trail_change_time * 60.0);
        float3 acc = float3(0.0);
        for (int i = 0; i < PARTICLES; i++) {
            float fi = float(i) + seed * 0.37;
            float ang = hash11(fi * 1.7) * 6.2831853;
            float spd = (0.6 + hash11(fi * 3.1) * 1.4) * cell_h * 2.5 * PARTICLE_SCALE;
            float2 dir = float2(cos(ang), sin(ang));
            // Particles are born already part way out along their own radius.
            // The burst restarts on every keystroke, so without this they would
            // pile up on the cursor at k~0 and saturate into a bright disc that
            // hides the character being typed.
            float ease = BURST_START + (1.0 - BURST_START) * (1.0 - pow(1.0 - k, 2.5));
            float2 pos = center + dir * spd * ease * 1.1;
            pos.y -= 0.35 * cell_h * k * k * 2.8; // gravity
            float r = cell_h * (0.13 + 0.11 * hash11(fi * 5.3)) * (1.0 - 0.6 * k) * PARTICLE_SCALE;
            float dist = length(p - pos);
            float a = smoothstep(r, r * 0.15, dist) + exp(-dist / (r * 2.5)) * 0.25;
            float hue = hash11(fi * 7.7);
            float3 pc = lerp(tint, float3(1.0, 0.85, 0.4), hue);
            pc = lerp(pc, float3(1.0, 0.45, 0.7), step(0.8, hue));
            acc += pc * a;
        }
        outc += acc * fade * FIREWORK_ALPHA;
    }

    return float4(outc, color.a);
}
