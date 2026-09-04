#!/usr/bin/env python3
"""noctalia 动态 fcitx5 主题生成器。

调色板来源: noctalia 5.x 不再把取色结果写成独立 JSON, 而是直接重写模板输出。
本脚本读取其中信息最全的 kitty 主题 (每次壁纸/配色变化都被 noctalia 重写):
    ~/.config/kitty/themes/noctalia.conf

颜色策略:
    背景 panel.png   = 与选择框同一颜色 (同色相同饱和度), 亮度压到 HSL L=0.25
    选择框 highlight = 生成色 (accent), 亮度钳制到 HSL L∈[0.62, 0.85]
    文字             = foreground / 选择框内所有文字 = color4 (secondary)

重新生成:
    panel.png / highlight.png / menu_panel.png / theme.conf

不含 fcitx5 重载逻辑 —— 由外部 (如 run_reload.sh 里的 fcitx5 -r) 负责。
纯 stdlib, 无第三方依赖。
"""

import colorsys
import math
import os
import struct
import sys
import zlib

N = 128  # 9-patch 源图边长
THEME_DIR = os.path.dirname(os.path.abspath(__file__))
KITTY_THEME = os.path.expanduser("~/.config/kitty/themes/noctalia.conf")

BG_LIGHTNESS = 0.25  # 背景: 与选择框同色, 仅降低亮度
HL_LIGHTNESS = (0.62, 0.85)  # 选择框亮度区间


def load_palette():
    """解析 kitty 主题文件 -> {角色: '#RRGGBB'}"""
    kv = {}
    with open(KITTY_THEME, "r", encoding="utf-8") as f:
        for line in f:
            parts = line.split(None, 1)
            if len(parts) == 2 and parts[1].strip().startswith("#"):
                val = parts[1].strip()
                if len(val) == 7:
                    try:
                        int(val[1:], 16)
                    except ValueError:
                        continue
                    kv.setdefault(parts[0], val.upper())
    required = ["active_border_color", "foreground"]
    missing = [k for k in required if k not in kv]
    if missing:
        raise ValueError(f"{KITTY_THEME} 缺少关键颜色: {missing}")
    return kv


def hexv(h):
    return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16))


def to_hls(h):
    r, g, b = hexv(h)
    return colorsys.rgb_to_hls(r / 255, g / 255, b / 255)


def from_hls(h, l, s):
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    return f"#{round(r * 255):02X}{round(g * 255):02X}{round(b * 255):02X}"


def clamp_l(hexcolor, lo, hi):
    """保持色相/饱和度, 把亮度钳制到 [lo, hi]。"""
    h, l, s = to_hls(hexcolor)
    return from_hls(h, min(max(l, lo), hi), s)


def derive(pal):
    accent = pal.get("active_border_color") or pal.get("color2")
    h, _, s = to_hls(accent)
    bg = from_hls(h, BG_LIGHTNESS, s)  # 同色低亮度
    highlight = clamp_l(accent, *HL_LIGHTNESS)  # 亮色选择框
    return {
        "bg": bg,
        "on_surface": pal["foreground"],
        "primary": highlight,
        "on_primary": pal.get("active_tab_foreground") or bg,  # 选中文字用暗色
        "outline": pal.get("color8") or accent,  # 分隔线/菜单描边
        "secondary": pal.get("color4") or highlight,  # 选择框文字 (kitty color4)
        "menu_border": accent,
    }


def write_png(path, w, h, rgba):
    def chunk(typ, data):
        c = struct.pack(">I", len(data)) + typ + data
        return c + struct.pack(">I", zlib.crc32(typ + data) & 0xFFFFFFFF)

    raw = bytearray()
    for y in range(h):
        raw.append(0)
        raw += rgba[y * w * 4 : (y + 1) * w * 4]
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    with open(path, "wb") as f:
        f.write(
            b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", ihdr)
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
            + chunk(b"IEND", b"")
        )


def rrect_sdf(px, py, cx, cy, hw, hh, r):
    qx = abs(px - cx) - (hw - r)
    qy = abs(py - cy) - (hh - r)
    ax, ay = max(qx, 0.0), max(qy, 0.0)
    return math.hypot(ax, ay) + min(max(qx, qy), 0.0) - r


def coverage(sdf):
    return min(max(0.5 - sdf, 0.0), 1.0)


def gen_rounded(path, color, radius):
    """实心圆角矩形 (9-patch 四角保留原样)。"""
    cr, cg, cb = hexv(color)
    c = (N - 1) / 2.0
    buf = bytearray(N * N * 4)
    for y in range(N):
        for x in range(N):
            a = coverage(rrect_sdf(x + 0.5, y + 0.5, c, c, c, c, radius))
            o = (y * N + x) * 4
            buf[o], buf[o + 1], buf[o + 2] = cr, cg, cb
            buf[o + 3] = round(a * 255)
    write_png(path, N, N, buf)


def gen_bordered(path, border_color, fill_color, radius, border):
    """圆角矩形 + 均匀描边环 (用于 Menu 背景)。"""
    br, bg_, bb = hexv(border_color)
    fr, fg, fb = hexv(fill_color)
    c = (N - 1) / 2.0
    hw_in = c - border
    r_in = radius - border
    buf = bytearray(N * N * 4)
    for y in range(N):
        for x in range(N):
            a_out = coverage(rrect_sdf(x + 0.5, y + 0.5, c, c, c, c, radius))
            a_in = coverage(rrect_sdf(x + 0.5, y + 0.5, c, c, hw_in, hw_in, r_in))
            a = a_in + a_out * (1.0 - a_in)
            o = (y * N + x) * 4
            if a > 0:
                buf[o] = round((fr * a_in + br * a_out * (1.0 - a_in)) / a)
                buf[o + 1] = round((fg * a_in + bg_ * a_out * (1.0 - a_in)) / a)
                buf[o + 2] = round((fb * a_in + bb * a_out * (1.0 - a_in)) / a)
            buf[o + 3] = round(a * 255)
    write_png(path, N, N, buf)


CONF_TEMPLATE = """\
# 由 generate.py 从 noctalia 壁纸取色自动生成, 手改会被覆盖。
# 来源: {source}
# 背景={bg} 文字={on_surface} 选择框={primary} 选中文字={secondary}
[Metadata]
Name=noctalia
Version=1.0
Author=Noctalia Community
Description=Noctalia Material You theme for Fcitx5 (dynamic)
ScaleWithDPI=True

[InputPanel]
NormalColor={secondary}
CandidateLabelColor={secondary}
CandidateCommentColor={secondary}
HighlightColor={secondary}
HighlightBackgroundColor={primary}
HighlightCandidateColor={secondary}
HighlightCandidateLabelColor={secondary}
HighlightCandidateCommentColor={secondary}
FullWidthHighlight=True
PageButtonAlignment=Last Candidate
BlurMask=mask.png
EnableBlur=True

[InputPanel/Background]
Image=panel.png

[InputPanel/Background/Margin]
Left=16
Right=16
Top=16
Bottom=16

[InputPanel/Highlight]
Image=highlight.png

[InputPanel/Highlight/Margin]
Left=10
Right=10
Top=10
Bottom=10

[InputPanel/ContentMargin]
Left=6
Right=6
Top=6
Bottom=6

[InputPanel/TextMargin]
Left=12
Right=12
Top=8
Bottom=8

[Menu]
NormalColor={secondary}
HighlightColor={secondary}
HighlightCandidateColor={secondary}
Spacing=4

[Menu/Background]
Image=menu_panel.png

[Menu/Background/Margin]
Left=10
Right=10
Top=10
Bottom=10

[Menu/Highlight]
Image=highlight.png

[Menu/Highlight/Margin]
Left=8
Right=8
Top=8
Bottom=8

[Menu/Separator]
Color={outline}

[Menu/ContentMargin]
Left=2
Right=2
Top=2
Bottom=2

[Menu/TextMargin]
Left=8
Right=8
Top=4
Bottom=4
"""


def main():
    try:
        pal = load_palette()
        colors = derive(pal)
    except (OSError, ValueError) as e:
        print(f"generate.py: 读取调色板失败: {e}", file=sys.stderr)
        return 1

    gen_rounded(os.path.join(THEME_DIR, "panel.png"), colors["bg"], 10)
    gen_rounded(os.path.join(THEME_DIR, "highlight.png"), colors["primary"], 8)
    gen_bordered(
        os.path.join(THEME_DIR, "menu_panel.png"),
        colors["menu_border"],
        colors["bg"],
        10,
        2,
    )
    conf = CONF_TEMPLATE.format(source=KITTY_THEME, **colors)
    with open(os.path.join(THEME_DIR, "theme.conf"), "w", encoding="utf-8") as f:
        f.write(conf)

    print(
        f"generate.py: bg={colors['bg']} highlight={colors['primary']} "
        f"text={colors['on_surface']} selected_text={colors['secondary']}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
