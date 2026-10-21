#language slang 2026
// 闪电 + 电火花光标拖尾。
//
// kitty 只在 cursor trail 动画期间提供 cursor_trail_* 数据，trail 停下后这些
// uniform 会全部变成 0。为了让闪电消失后电火花还能飞完，这里用 persist 纹理
// 记下最近两次光标移动，之后从这份状态继续算。
//
// 为什么要记两次：快速打字时每次按键都会重建特效，如果只存一次，粒子年龄永远
// 接近 0，看起来就是散不开、只在停手后才炸一下。两个槽让上一次的粒子继续飞，
// 同时也避免长按按键时所有火花排成一个圆环。
//
// 分组（见 smooth-cursor-fireworks.pipeline）：
//   STAGE 0: 记录状态，persist -> a
//   STAGE 1: a -> persist
//   STAGE 2: 全屏绘制闪电和电火花
//
// 状态存在左下角 8 个像素里（RGBA16 unorm，alpha 固定为 1 以便 rgb 不被预乘）：
//   slot 0 (t0..t3): 最新一次移动
//   slot 1 (t4..t7): 上一次移动
//   每个槽: t0 = prev_l, prev_r, prev_t
//           t1 = prev_b, cur_l,  cur_r
//           t2 = cur_t,  cur_b,  time_hi
//           t3 = time_lo, valid, 0

import kitty_custom_shader_types;

static const int STAGE = 0;

// 闪电寿命（秒）
static const float BOLT_DURATION = 0.20;
// 电火花最长寿命（秒），pipeline 的 animation_stop 必须大于它
static const float SPARK_MAX_LIFE = 0.85;
// 电火花数量
static const int SPARK_COUNT = 80;
// 闪电主干段数
static const int BOLT_SEGMENTS = 8;
// 主干横向抖动幅度，相对闪电长度
static const float JAGGEDNESS = 0.10;
// 主干核心宽度（像素）
static const float CORE_WIDTH = 1.25;
// 辉光半径（像素）
static const float GLOW_WIDTH = 6.0;
// 状态纹理里时间编码的周期（秒）
static const float TIME_WRAP = 64.0;

static const float3 CORE_COLOR = float3(1.0, 1.0, 1.0);
static const float3 GLOW_COLOR = float3(0.55, 0.52, 1.0);
static const float3 SPARK_WHITE = float3(1.0, 1.0, 1.0);
static const float3 SPARK_COLD = float3(0.82, 0.90, 1.0);
static const float MIN_BOLT_LEN = 24.0;

static float
hash11(float p) {
    p = frac(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return frac(p);
}

static float
seg_dist(float2 p, float2 a, float2 b) {
    float2 ab = b - a;
    float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-7), 0.0, 1.0);
    return length(p - (a + ab * t));
}

// 折线上的一点：端点固定，中间节点沿垂直方向随机偏移
static float2
bolt_point(float2 a, float2 b, float t, float seed) {
    float2 delta = b - a;
    float len = length(delta);
    float2 perp = float2(-delta.y, delta.x) / max(len, 1e-5);
    float node = floor(t * float(BOLT_SEGMENTS) + 0.5);
    float rnd = hash11(node * 17.17 + seed) * 2.0 - 1.0;
    float fade = sin(3.14159265 * t);
    // 短距离时按像素保底，否则一格宽的闪电看起来就是一条直线
    float amp = max(len * JAGGEDNESS, 2.5);
    return lerp(a, b, t) + perp * rnd * amp * fade;
}

// 到主干折线的最小距离
static float
main_bolt_dist(float2 p, float2 a, float2 b, float seed) {
    float min_d = 1e5;
    float2 prev = a;
    [ForceUnroll]
    for (int i = 1; i <= BOLT_SEGMENTS; i++) {
        float t = float(i) / float(BOLT_SEGMENTS);
        float2 cur = bolt_point(a, b, t, seed);
        min_d = min(min_d, seg_dist(p, prev, cur));
        prev = cur;
    }
    return min_d;
}

// 主闪电上分叉出去的三根小枝
static float
fork_dist(float2 p, float2 a, float2 b, float seed) {
    float min_d = 1e5;
    float2 delta = b - a;
    float len = length(delta);
    if (len < 20.0) return min_d;
    float2 perp = float2(-delta.y, delta.x) / max(len, 1e-5);
    float2 dir = delta / len;
    [ForceUnroll]
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float t = 0.30 + fi * 0.20;
        float2 root = bolt_point(a, b, t, seed);
        float side = lerp(-1.0, 1.0, step(0.5, hash11(seed + fi * 41.0)));
        float reach = max(len * (0.055 + 0.04 * hash11(seed + fi * 53.0)), 5.0);
        float2 along = dir * reach * (hash11(seed + fi * 67.0) - 0.35);
        float2 tip = root + perp * side * reach + along;
        float2 elbow = lerp(root, tip, 0.55) - perp * side * reach * 0.15;
        min_d = min(min_d, seg_dist(p, root, elbow));
        min_d = min(min_d, seg_dist(p, elbow, tip));
    }
    return min_d;
}

static float2
encode_time(float t) {
    float q = max(t, 0.0) / TIME_WRAP;
    return float2(floor(q) / 65535.0, fract(q));
}

static float
decode_time(float2 v) {
    return (round(v.x * 65535.0) + v.y) * TIME_WRAP;
}

static float2
texel_uv(int i, float2 vp) {
    return (float2(float(i), 0.0) + 0.5) / vp;
}

// 状态记录阶段：新移动写 slot 0，旧的 slot 0 挪到 slot 1
static float4
update_state(KittyTextures t, KittyCustomShaderData d) {
    float2 vp = float2(d.viewport_size_pixels);
    float2 group_px = floor(t.viewport.zw * vp + 1e-3);
    int2 px = int2(floor(t.pos * group_px));
    if (px.y != 0 || px.x > 7) return float4(0.0, 0.0, 0.0, 0.0);
    int i = px.x;

    float4 old = t.persist.Sample(texel_uv(i, vp));
    if (d.cursor_trail_state <= 0.5) return float4(old.rgb, 1.0);

    float4 s2 = t.persist.Sample(texel_uv(2, vp));
    float4 s3 = t.persist.Sample(texel_uv(3, vp));
    float last_time = decode_time(float2(s2.z, s3.x));
    bool fresh = s3.y < 0.9 || d.cursor_trail_change_time > last_time + 1e-4;
    if (!fresh) return float4(old.rgb, 1.0);

    if (i < 4) {
        // 新状态写入 slot 0
        if (i == 0) return float4(d.cursor_trail_prev_edge.x, d.cursor_trail_prev_edge.y, d.cursor_trail_prev_edge.z, 1.0);
        if (i == 1) return float4(d.cursor_trail_prev_edge.w, d.cursor_trail_edge.x, d.cursor_trail_edge.y, 1.0);
        float2 enc = encode_time(d.cursor_trail_change_time);
        if (i == 2) return float4(d.cursor_trail_edge.z, d.cursor_trail_edge.w, enc.x, 1.0);
        return float4(enc.y, step(1e-3, d.cursor_trail_change_time), 0.0, 1.0);
    }
    // 旧的 slot 0 挪到 slot 1
    float4 prev = t.persist.Sample(texel_uv(i - 4, vp));
    return float4(prev.rgb, 1.0);
}

static float4
copy_state(KittyTextures t, KittyCustomShaderData d) {
    float2 vp = float2(d.viewport_size_pixels);
    float2 group_px = floor(t.viewport.zw * vp + 1e-3);
    int2 px = int2(floor(t.pos * group_px));
    if (px.y != 0 || px.x > 7) return float4(0.0, 0.0, 0.0, 0.0);
    float4 v = t.a.Sample(texel_uv(px.x, vp));
    return float4(v.rgb, 1.0);
}

// 画一次移动对应的闪电和火花，叠加到 rgb 上
static float3
draw_burst(KittyCustomShaderData d, float2 p, float2 vp, float4 s0, float4 s1, float4 s2, float4 s3, float spark_scale, float3 rgb) {
    float change_time = decode_time(float2(s2.z, s3.x));
    float age = d.timestamp - change_time;
    if (change_time <= 0.0 || age < 0.0 || age > SPARK_MAX_LIFE) return rgb;

    // 光标矩形（UV，原点在左下），转成像素空间方便算距离
    float4 prev_edge = float4(s0.x, s0.y, s0.z, s1.x);
    float4 cur_edge = float4(s1.y, s1.z, s2.x, s2.y);
    float2 prev_c = float2((prev_edge.x + prev_edge.y) * 0.5, (prev_edge.z + prev_edge.w) * 0.5) * vp;
    float2 cur_c = float2((cur_edge.x + cur_edge.y) * 0.5, (cur_edge.z + cur_edge.w) * 0.5) * vp;
    // 第一次移动时没有上一个位置，就只在光标处分叉
    if (dot(prev_edge, prev_edge) < 1e-6) prev_c = cur_c;

    float len = length(cur_c - prev_c);
    float seed = floor(change_time * 1000.0) * 0.013;

    // 远离闪电和火花的像素直接跳过，省掉整个循环
    if (seg_dist(p, prev_c, cur_c) > 150.0 + len * 0.12) return rgb;

    float size_k = smoothstep(4.0, 60.0, len);

    // ---- 1. 闪电本体（一格的小移动不画，否则辉光会在光标周围糊成一圈） ----
    if (len >= MIN_BOLT_LEN && age < BOLT_DURATION) {
        float k = age / BOLT_DURATION;
        float flash = pow(1.0 - k, 0.8);
        float flicker = 0.90 + 0.10 * sin(age * 95.0 + seed * 7.0);

        float main_d = main_bolt_dist(p, prev_c, cur_c, seed);
        float fork_d = fork_dist(p, prev_c, cur_c, seed);
        float aa = max(fwidth(main_d), 0.65);
        float wide = smoothstep(MIN_BOLT_LEN, 120.0, len);
        float gw = lerp(3.0, GLOW_WIDTH, wide);

        float core = 1.0 - smoothstep(CORE_WIDTH, CORE_WIDTH + aa, main_d);
        float fork_core = 1.0 - smoothstep(CORE_WIDTH * 0.72, CORE_WIDTH * 0.72 + aa, fork_d);
        float glow = exp(-main_d * main_d / (gw * gw));
        float fork_glow = exp(-fork_d * fork_d / (gw * gw * 0.55));
        float halo = exp(-main_d / 26.0) * 0.08 * wide;

        float glow_amt = max(glow, fork_glow * 0.5) * flash * flicker * 0.50;
        float core_amt = max(core, fork_core * 0.7) * flash * flicker;

        rgb = lerp(rgb, GLOW_COLOR, clamp(glow_amt, 0.0, 1.0));
        rgb = lerp(rgb, CORE_COLOR, clamp(core_amt, 0.0, 1.0));
        rgb += GLOW_COLOR * (halo * flash * flicker);
    }

    // ---- 2. 电火花 ----
    float3 sparks = float3(0.0);
    float2 delta = cur_c - prev_c;
    float2 tangent = delta / max(len, 1e-4);
    float2 normal = float2(-tangent.y, tangent.x);

    int spark_count = max(1, int(lerp(20.0, float(SPARK_COUNT), size_k) * spark_scale));
    [ForceUnroll]
    for (int i = 0; i < SPARK_COUNT; i++) {
        if (i >= spark_count) break;
        float fi = float(i);
        float life = 0.35 + 0.50 * hash11(fi * 1.7 + seed);

        // 每颗火花有自己的时间偏移，连发时不会同时处在同一半径上
        float aa = age + (hash11(fi * 2.9 + seed) - 0.5) * 0.10;
        if (aa <= 0.0 || aa >= life) continue;
        float k = aa / life;
        float h = hash11(fi * 3.1 + seed * 1.7);
        float2 origin;
        float2 dir;
        if (hash11(fi * 4.7 + seed) < 0.30) {
            // 从新光标位置向四周撒开
            origin = cur_c;
            float ang = 6.2831853 * hash11(fi * 5.9 + seed);
            dir = float2(cos(ang), sin(ang));
        } else {
            // 其余沿闪电路径喷出，角度和速度都比之前开
            origin = bolt_point(prev_c, cur_c, h, seed);
            float side = hash11(fi * 7.3 + seed) * 2.0 - 1.0;
            float along = (hash11(fi * 9.1 + seed) - 0.5) * 1.8;
            dir = normalize(normal * side * 1.3 + tangent * along + float2(0.0, 0.5));
        }

        // 初速高、迅速减速：按下后的头一两帧就能看到粒子散开，而不是挤在光标上
        float speed = 220.0 + 260.0 * hash11(fi * 6.1 + seed);
        float decay = 5.0 + 2.0 * hash11(fi * 6.9 + seed);
        float travel = (1.0 - exp(-decay * aa)) / decay;
        float2 pos = origin + dir * speed * travel + float2(0.0, -55.0 * aa * aa);
        // 很小的白色光点，不带辉光
        float r = 0.9 + 0.7 * hash11(fi * 8.3 + seed);
        float dist = length(p - pos);
        float spot = 1.0 - smoothstep(r * 0.45, r, dist);
        float fade = pow(1.0 - k, 1.2);
        float twinkle = 0.85 + 0.15 * sin(aa * 80.0 + fi * 7.0);
        float3 c = lerp(SPARK_COLD, SPARK_WHITE, step(0.7, hash11(fi * 11.3 + seed)));
        sparks += c * spot * 2.4 * fade * twinkle;
    }
    return rgb + sparks;
}

// 绘制阶段：先画上一批，再画最新一批
static float4
draw_effect(float4 color, KittyTextures t, KittyCustomShaderData d) {
    float2 vp = float2(d.viewport_size_pixels) * t.viewport.zw;
    float2 state_vp = float2(d.viewport_size_pixels);
    float4 a0 = t.persist.Sample(texel_uv(0, state_vp));
    float4 a1 = t.persist.Sample(texel_uv(1, state_vp));
    float4 a2 = t.persist.Sample(texel_uv(2, state_vp));
    float4 a3 = t.persist.Sample(texel_uv(3, state_vp));
    float4 b0 = t.persist.Sample(texel_uv(4, state_vp));
    float4 b1 = t.persist.Sample(texel_uv(5, state_vp));
    float4 b2 = t.persist.Sample(texel_uv(6, state_vp));
    float4 b3 = t.persist.Sample(texel_uv(7, state_vp));

    float2 p = t.pos * vp;
    float3 rgb = color.rgb;
    if (b3.y > 0.5) rgb = draw_burst(d, p, vp, b0, b1, b2, b3, 0.5, rgb);
    if (a3.y > 0.5) rgb = draw_burst(d, p, vp, a0, a1, a2, a3, 1.0, rgb);
    return float4(rgb, color.a);
}

public float4
fragment_main(float4 color, KittyTextures t, KittyCustomShaderData d) {
    if (STAGE == 0) return update_state(t, d);
    if (STAGE == 1) return copy_state(t, d);
    return draw_effect(color, t, d);
}
