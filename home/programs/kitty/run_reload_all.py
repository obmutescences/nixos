#!/usr/bin/env python3
"""整合 run_reload_kitty.sh 的全部同步逻辑为单个纯 stdlib 脚本。

覆盖的场景 (按 run_reload_kitty.sh 原顺序):
  1. NiriAnimationSwitcher   轮换 niri 窗口动画 (config.kdl 末尾的 include)
  2. NiriColorSyncer         把 kitty 主题 color2 同步到 mix.kdl / noctalia.kdl
  3. OmpThemeSyncer          把 .pi 的 vars 原样同步到 .omp 主题 JSON
  4. Fcitx5ThemeGenerator    按 kitty 主题重生成 fcitx5 主题 (PNG + theme.conf)
  5. LookThemeSyncer         把 color2/color4 同步到 Look 配置并静默重启

颜色源变更: 原脚本从 noctalia.kdl 的 active-color 取色; 现改为读取
~/.config/kitty/themes/noctalia.conf 的 color2 (与 fcitx5/look 同源)。

颜色同步方式变更: 旧脚本用全文件 sed 无差别替换, 相同 key 的 `color "..."`
在不同块里会被同一种规则命中。现在改为按「上级/上上级块路径」精确匹配:
每条规则 = (祖先块路径, key, 替换值种类), 只替换命中块里的那一条。

用法:
    python3 run_reload_all.py                        # 按序执行全部场景
    python3 run_reload_all.py --anim                 # 只轮换动画
    python3 run_reload_all.py --color                # 只同步 niri 颜色
    python3 run_reload_all.py --omp                  # 只同步 .pi -> .omp
    python3 run_reload_all.py --fcitx5               # 只重建 fcitx5 主题
    python3 run_reload_all.py --look [--no-restart]  # 只同步 Look (可选不重启)
"""

import argparse
import colorsys
import json
import math
import re
import struct
import subprocess
import sys
import time
import zlib
from pathlib import Path

# ======================================================================
# 共享: kitty 主题解析 + 颜色数学 (纯 stdlib)
# ======================================================================


class KittyTheme:
    """解析 kitty 主题 ~/.config/kitty/themes/noctalia.conf。"""

    DEFAULT_PATH = Path.home() / ".config/kitty/themes/noctalia.conf"

    def __init__(self, path=None):
        self.path = Path(path or self.DEFAULT_PATH).expanduser()
        self._kv = self._parse()

    def _parse(self):
        kv = {}
        if self.path.exists():
            for line in self.path.read_text(encoding="utf-8").splitlines():
                m = re.match(r"^([A-Za-z0-9_]+)\s+(#[0-9A-Fa-f]{6})\b", line.strip())
                if m:
                    kv.setdefault(m.group(1), m.group(2))
        return kv

    def exists(self):
        return self.path.exists()

    def color(self, n):
        """取 colorN, 如 color2。"""
        return self._kv.get(f"color{n}")

    def get(self, key, default=None):
        return self._kv.get(key, default)


class ColorMath:
    """颜色转换工具 (colorsys)。"""

    @staticmethod
    def hexv(h):
        return (int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16))

    @staticmethod
    def hex_to_rgb01(hex_color):
        h = hex_color.lstrip("#")
        return tuple(round(int(h[i : i + 2], 16) / 255, 3) for i in (0, 2, 4))

    @staticmethod
    def darken(rgb, factor):
        return tuple(round(v * factor, 3) for v in rgb)

    @staticmethod
    def hex_to_hls(hex_color):
        r, g, b = ColorMath.hexv(hex_color)
        return colorsys.rgb_to_hls(r / 255, g / 255, b / 255)

    @staticmethod
    def from_hls(h, l, s):
        r, g, b = colorsys.hls_to_rgb(h, l, s)
        return f"#{round(r * 255):02X}{round(g * 255):02X}{round(b * 255):02X}"

    @staticmethod
    def clamp_l(hex_color, lo, hi):
        """保持色相/饱和度, 把亮度钳制到 [lo, hi]。"""
        h, l, s = ColorMath.hex_to_hls(hex_color)
        return ColorMath.from_hls(h, min(max(l, lo), hi), s)

    @staticmethod
    def hsla(hex_color, lightness, alpha):
        """run_reload_kitty.sh 的取色算法: 饱和度 +0.2, 指定亮度/透明度。"""
        h, _, s = ColorMath.hex_to_hls(hex_color)
        s += 0.2
        return f"hsla({h * 360:.0f}, {s * 100:.0f}%, {lightness}%, {alpha})"


# ======================================================================
# 场景 1: niri 窗口动画轮换
# ======================================================================


class NiriAnimationSwitcher:
    """轮换 niri 窗口动画: 备份 config.kdl -> 删除旧 include -> 末尾追加新 include。"""

    CONFIG_FILE = Path.home() / ".config/niri/config.kdl"
    INDEX_FILE = Path.home() / ".config/niri/current_animation_index"

    def __init__(self, config_file=None, index_file=None, animations=None):
        self.config_file = Path(config_file or self.CONFIG_FILE).expanduser()
        self.index_file = Path(index_file or self.INDEX_FILE).expanduser()
        # self.animations = list(animations or self.ANIMATIONS)
        self.animations = [
            'include "./animations_config/ribbons.kdl"',
            'include "./animations_config/glass.kdl"',
            'include "./animations_config/blackhole.kdl"',
            'include "./animations_config/pixel-drift.kdl"',
            'include "./animations_config/liquid-flow.kdl"',
            'include "./animations_config/quantum-ripple.kdl"',
            'include "./animations_config/burn-ashes.kdl"',
            'include "./animations_config/roll-drop.kdl"',
            'include "./animations_config/glitch.kdl"',
            'include "./animations_config/smoke.kdl"',
            'include "./animations_config/throw.kdl"',
            'include "./animations_config/withstar.kdl"',
            'include "./animations_config/fold-window.kdl"',
            'include "./animations_config/dither-glitch.kdl"',
            'include "./animations_config/incinerate.kdl"',
        ]

    def _next_index(self):
        """读索引 +1, 越界回 0; 索引文件不存在则从 0 开始。"""
        idx = 0
        if self.index_file.exists():
            try:
                idx = int(self.index_file.read_text().strip())
            except ValueError:
                idx = 0
            idx += 1
            if idx >= len(self.animations):
                idx = 0
        return idx

    def switch(self):
        """轮换到下一个动画, 返回 include 行; 失败返回 None。"""
        if not self.config_file.exists():
            print(f"警告: 找不到 {self.config_file}", file=sys.stderr)
            return None
        if not self.animations:
            print("警告: 动画列表为空", file=sys.stderr)
            return None

        idx = self._next_index()
        line = self.animations[idx]

        # 2. 删除所有含 animations_config 的行 (sed '/animations_config/d')
        kept = [
            ln
            for ln in self.config_file.read_text(encoding="utf-8").splitlines(
                keepends=True
            )
            if "animations_config" not in ln
        ]
        # 3. 末尾追加新 include
        if kept and not kept[-1].endswith("\n"):
            kept[-1] += "\n"
        kept.append(line + "\n")
        self.config_file.write_text("".join(kept), encoding="utf-8")
        # 4. 保存新索引
        self.index_file.write_text(f"{idx}\n", encoding="utf-8")

        print(f"niri 动画: index={idx} -> {line}")
        return line


# ======================================================================
# 场景 2: niri 颜色同步 (kitty 主题 color2 -> mix.kdl / noctalia.kdl)
#         按上级/上上级块路径精确匹配替换
# ======================================================================


class KdlColorRewriter:
    """按「块路径 + key」精确匹配, 只替换命中的 `key "value"` 行。

    规则格式: (祖先块路径, key, 替换值种类)
      祖先块路径: 从最近的块开始写, 越精确写越长。
          ("overview",)              -> overview 块内 (父级)
          ("window-picker", "label") -> window-picker > label 块内 (上上级)
          ("shadow",)                -> 任意 shadow 块内 (模糊匹配父级)
      替换值种类: 由 values 字典定义, 默认 active / hsla / b_hsla,
          可在 NiriColorSyncer._build_values 里扩展自定义种类。

    因此相同 key (如 color) 在不同块里可以用不同的替换值。
    """

    def __init__(self, rules, values):
        self.rules = rules  # [(祖先块路径 tuple, key str, 替换值种类 str)]
        self.values = values  # {种类: 实际颜色字符串}

    @staticmethod
    def _stack_matches(stack, ancestors):
        """ancestors 与当前块栈顶做后缀匹配 (ancestors 为空则任意位置)。"""
        if not ancestors:
            return True
        if len(stack) < len(ancestors):
            return False
        return tuple(stack[-len(ancestors) :]) == tuple(ancestors)

    def rewrite(self, text):
        stack, out = [], []
        for line in text.splitlines(keepends=True):
            stripped = line.strip()
            if not stripped or stripped.startswith("//"):
                out.append(line)
                continue

            opened = None
            m = re.match(r"^([A-Za-z0-9_-]+)\s*\{", stripped)
            if m:
                opened = m.group(1)
                stack.append(opened)

            prop = re.match(r'^([A-Za-z0-9_-]+)\s+"[^"]*"', stripped)
            if prop:
                key = prop.group(1)
                for ancestors, rule_key, spec in self.rules:
                    if key == rule_key and self._stack_matches(stack, ancestors):
                        repl = self.values[spec]
                        # 保留行首缩进, 只替换 key 与引号内的值
                        out.append(
                            re.sub(
                                rf'^(\s*)({re.escape(key)})\s+"[^"]*"',
                                rf'\1\2 "{repl}"',
                                line,
                                count=1,
                            )
                        )
                        break
                else:
                    out.append(line)
            else:
                out.append(line)

            # 块结束: 统计 '}' 数量 (同行开块则少弹一个)
            closes = stripped.count("}")
            if closes:
                for _ in range(closes - (1 if opened else 0)):
                    if stack:
                        stack.pop()
        return "".join(out)


class NiriColorSyncer:
    """把 kitty 主题 color2 同步到 niri 的 mix.kdl / noctalia.kdl。"""

    NOCTALIA_KDL = Path.home() / ".config/niri/noctalia.kdl"
    MIX_KDL = Path.home() / ".config/niri/mix.kdl"
    DEFAULT_COLOR = "#161a22e6"

    HSLA_LIGHTNESS = 30  # 主色亮度 (%)
    HSLA_ALPHA = 1.0
    B_HSLA_LIGHTNESS = 10  # 背景色亮度 (%)
    B_HSLA_ALPHA = 0.1

    LABEL_LIGHTNESS = 10

    def __init__(self, theme, noctalia_kdl=None, mix_kdl=None):
        self.theme = theme
        self.noctalia_kdl = Path(noctalia_kdl or self.NOCTALIA_KDL).expanduser()
        self.mix_kdl = Path(mix_kdl or self.MIX_KDL).expanduser()

    def _get_mix_file_rules(
        self,
    ) -> list[tuple[tuple[str], str, str] | tuple[tuple[str, str], str, str]]:
        return [
            # layout > shadow 的投影主色
            (("layout", "shadow"), "color", "active"),
            # window-rule > shadow 的失焦色
            (("window-rule", "shadow"), "inactive-color", "hsla"),
            # window-picker > label 里的三处
            (("window-picker", "label"), "text-color", "active"),
            (("window-picker", "label"), "background-color", "label_hsla"),
            (("window-picker", "label"), "border-color", "active"),
            # window-picker > backdrop 的桌面背景主色 (与 layout>shadow 的 color 同名, 规则不同)
            # window-picker > selection 的高亮/悬停
            (("window-picker", "selection"), "focused-color", "color4"),
            (("window-picker", "selection"), "hover-color", "color4"),
            # overview 的背景色 (更暗)
            (("overview",), "backdrop-color", "b_hsla"),
        ]

    def _get_noctalia_file_rules(self) -> list[tuple[tuple[str, str], str, str]]:
        return [
            (("layout", "focus-ring"), "active-color", "hsla"),
            (("layout", "focus-ring"), "inactive-color", "hsla"),
            (("layout", "border"), "active-color", "hsla"),
            (("layout", "border"), "inactive-color", "hsla"),
            (("layout", "tab-indicator"), "active-color", "hsla"),
            (("layout", "tab-indicator"), "inactive-color", "hsla"),
            (("recent-windows", "highlight"), "active-color", "hsla"),
        ]

    def _build_values(self, active):
        """替换值种类 -> 实际字符串。可在此追加自定义种类。"""
        hsla = (
            ColorMath.hsla(active, self.HSLA_LIGHTNESS, self.HSLA_ALPHA)
            or active
            or self.DEFAULT_COLOR
        )
        b_hsla = (
            ColorMath.hsla(active, self.B_HSLA_LIGHTNESS, self.B_HSLA_ALPHA)
            or active
            or self.DEFAULT_COLOR
        )
        label_hsla = (
            ColorMath.hsla(active, self.LABEL_LIGHTNESS, self.HSLA_ALPHA)
            or active
            or self.DEFAULT_COLOR
        )
        color4 = self.theme.color(4) or active or self.DEFAULT_COLOR
        return {
            "active": active,  # color2 原色
            "color4": color4,  # color4 原色
            "hsla": hsla,  # 压暗主色 (亮度 30%)
            "b_hsla": b_hsla,  # 更暗背景色 (亮度 10%, 低透明度)
            "label_hsla": label_hsla,
        }

    @staticmethod
    def _rewrite(path, rules, values):
        text = path.read_text(encoding="utf-8")
        path.write_text(KdlColorRewriter(rules, values).rewrite(text), encoding="utf-8")

    def sync(self):
        if not self.noctalia_kdl.exists() or not self.mix_kdl.exists():
            print("警告: mix.kdl 或 noctalia.kdl 不存在, 跳过颜色同步", file=sys.stderr)
            return False

        active = self.theme.color(2)  # 新取色源: kitty 主题 color2
        if not active:
            print("警告: kitty 主题中未找到 color2, 跳过颜色同步", file=sys.stderr)
            return False

        values = self._build_values(active)
        self._rewrite(self.mix_kdl, self._get_mix_file_rules(), values)
        self._rewrite(self.noctalia_kdl, self._get_noctalia_file_rules(), values)

        print(
            f"niri 颜色: color2 {active} -> mix.kdl / noctalia.kdl "
            f"(hsla={values['hsla']}, b_hsla={values['b_hsla']})"
        )
        return True


# ======================================================================
# 场景 3: .pi -> .omp 主题 vars 同步
# ======================================================================


class OmpThemeSyncer:
    """把 .pi 的 vars 原文同步到 .omp, 其余字段字节不变。"""

    SRC = Path.home() / ".pi/agent/themes/noctalia.json"
    DST = Path.home() / ".omp/agent/themes/noctalia.json"

    def __init__(self, src=None, dst=None):
        self.src = Path(src or self.SRC).expanduser()
        self.dst = Path(dst or self.DST).expanduser()

    @staticmethod
    def _vars_span(text):
        """返回顶层 'vars' 值的原始 (start, end) 区间。"""
        key = text.index('"vars"')
        colon = text.index(":", key)
        start = colon + 1
        while start < len(text) and text[start] in " \t\r\n":
            start += 1
        _, end = json.JSONDecoder().raw_decode(text, start)
        return start, end

    def sync(self):
        if not self.src.exists() or not self.dst.exists():
            print("警告: .pi 或 .omp 主题 JSON 不存在, 跳过 vars 同步", file=sys.stderr)
            return False

        src_text = self.src.read_text(encoding="utf-8")
        dst_text = self.dst.read_text(encoding="utf-8")
        s_start, s_end = self._vars_span(src_text)
        d_start, d_end = self._vars_span(dst_text)
        self.dst.write_text(
            dst_text[:d_start] + src_text[s_start:s_end] + dst_text[d_end:],
            encoding="utf-8",
        )
        print("noctalia.json vars 已同步到 ~/.omp/agent/themes/")
        return True


# ======================================================================
# 场景 4: fcitx5 主题重生成 (generate.py 逻辑内联)
# ======================================================================


def rrect_sdf(px, py, cx, cy, hw, hh, r):
    qx = abs(px - cx) - (hw - r)
    qy = abs(py - cy) - (hh - r)
    ax, ay = max(qx, 0.0), max(qy, 0.0)
    return math.hypot(ax, ay) + min(max(qx, qy), 0.0) - r


def coverage(sdf):
    return min(max(0.5 - sdf, 0.0), 1.0)


class Fcitx5ThemeGenerator:
    """按 kitty 主题重生成 fcitx5 noctalia 主题 (panel/highlight/menu_panel PNG + theme.conf)。"""

    THEME_DIR = Path.home() / ".local/share/fcitx5/themes/noctalia"
    N = 128  # 9-patch 源图边长
    BG_LIGHTNESS = 0.25  # 背景亮度 (与选择框同色相饱和度, 压低亮度)
    HL_LIGHTNESS = (0.62, 0.85)  # 选择框亮度区间

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

    def __init__(self, theme, theme_dir=None):
        self.theme = theme
        self.theme_dir = Path(theme_dir or self.THEME_DIR).expanduser()

    def derive(self):
        # 与原版 generate.py 的 load_palette 一致: 值统一大写 (PNG/theme.conf 字节级一致)
        pal = {}
        for k in (
            "active_border_color",
            "foreground",
            "active_tab_foreground",
            "color8",
            "color4",
        ):
            v = self.theme.get(k)
            pal[k] = v.upper() if v else v
        required = ["active_border_color", "foreground"]
        missing = [k for k in required if not pal[k]]
        if missing:
            raise ValueError(f"{self.theme.path} 缺少关键颜色: {missing}")

        accent = (
            pal["active_border_color"] or (self.theme.color(2) or "").upper() or None
        )
        h, _, s = ColorMath.hex_to_hls(accent)
        bg = ColorMath.from_hls(h, self.BG_LIGHTNESS, s)
        highlight = ColorMath.clamp_l(accent, *self.HL_LIGHTNESS)
        return {
            "bg": bg,
            "on_surface": pal["foreground"],
            "primary": highlight,
            "on_primary": pal["active_tab_foreground"] or bg,
            "outline": pal["color8"] or accent,
            "secondary": pal["color4"] or highlight,
            "menu_border": accent,
        }

    def write_png(self, path, w, h, rgba):
        def chunk(typ, data):
            c = struct.pack(">I", len(data)) + typ + data
            return c + struct.pack(">I", zlib.crc32(typ + data) & 0xFFFFFFFF)

        raw = bytearray()
        for y in range(h):
            raw.append(0)
            raw += rgba[y * w * 4 : (y + 1) * w * 4]
        ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
        path.write_bytes(
            b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", ihdr)
            + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
            + chunk(b"IEND", b"")
        )

    def gen_rounded(self, path, color, radius):
        cr, cg, cb = ColorMath.hexv(color)
        c = (self.N - 1) / 2.0
        buf = bytearray(self.N * self.N * 4)
        for y in range(self.N):
            for x in range(self.N):
                a = coverage(rrect_sdf(x + 0.5, y + 0.5, c, c, c, c, radius))
                o = (y * self.N + x) * 4
                buf[o], buf[o + 1], buf[o + 2] = cr, cg, cb
                buf[o + 3] = round(a * 255)
        self.write_png(path, self.N, self.N, buf)

    def gen_bordered(self, path, border_color, fill_color, radius, border):
        br, bg_, bb = ColorMath.hexv(border_color)
        fr, fg, fb = ColorMath.hexv(fill_color)
        c = (self.N - 1) / 2.0
        hw_in = c - border
        r_in = radius - border
        buf = bytearray(self.N * self.N * 4)
        for y in range(self.N):
            for x in range(self.N):
                a_out = coverage(rrect_sdf(x + 0.5, y + 0.5, c, c, c, c, radius))
                a_in = coverage(rrect_sdf(x + 0.5, y + 0.5, c, c, hw_in, hw_in, r_in))
                a = a_in + a_out * (1.0 - a_in)
                o = (y * self.N + x) * 4
                if a > 0:
                    buf[o] = round((fr * a_in + br * a_out * (1.0 - a_in)) / a)
                    buf[o + 1] = round((fg * a_in + bg_ * a_out * (1.0 - a_in)) / a)
                    buf[o + 2] = round((fb * a_in + bb * a_out * (1.0 - a_in)) / a)
                buf[o + 3] = round(a * 255)
        self.write_png(path, self.N, self.N, buf)

    def generate(self):
        try:
            colors = self.derive()
        except (OSError, ValueError) as e:
            print(f"fcitx5: 读取调色板失败: {e}", file=sys.stderr)
            return False

        self.theme_dir.mkdir(parents=True, exist_ok=True)
        self.gen_rounded(self.theme_dir / "panel.png", colors["bg"], 10)
        self.gen_rounded(self.theme_dir / "highlight.png", colors["primary"], 8)
        self.gen_bordered(
            self.theme_dir / "menu_panel.png",
            colors["menu_border"],
            colors["bg"],
            10,
            2,
        )
        conf = self.CONF_TEMPLATE.format(source=self.theme.path, **colors)
        (self.theme_dir / "theme.conf").write_text(conf, encoding="utf-8")

        print(
            f"fcitx5: bg={colors['bg']} highlight={colors['primary']} "
            f"text={colors['on_surface']} selected_text={colors['secondary']}"
        )
        return True

    def reload(self):
        # fcitx5 -r 重启后新进程会在前台常驻, run() 会一直等 -> 卡住脚本。
        # 后台脱离启动 (新会话 + 丢弃 IO), 不等它退出。
        subprocess.Popen(
            ["fcitx5", "-r"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        print("fcitx5 -r 已触发 (后台)")


# ======================================================================
# 场景 5: Look 主题同步 (sync_look_theme.py 逻辑内联)
# ======================================================================


class LookThemeSyncer:
    """把 kitty 主题 color2/color4 同步到 Look 配置, 并静默重启 lookapp。"""

    LOOK_CONFIG = Path.home() / ".look/config"
    TINT_DARKEN = 0.4  # 背景压暗系数: 1.0 = color2 原色, 越小越暗

    def __init__(self, theme, config_path=None, restart=True):
        self.theme = theme
        self.config_path = Path(config_path or self.LOOK_CONFIG).expanduser()
        self.restart = restart

    def update_config(self):
        color2 = self.theme.color(2)
        color4 = self.theme.color(4)
        if not color2 or not color4:
            print("noctalia.conf 缺少 color2/color4", file=sys.stderr)
            return False

        bg = ColorMath.darken(ColorMath.hex_to_rgb01(color2), self.TINT_DARKEN)
        fg = ColorMath.hex_to_rgb01(color4)
        # 非 custom 主题时内置预设会覆盖 tint/font, 必须把 ui_theme 设为 custom
        updates = {
            "ui_theme": "custom",
            "ui_tint_red": bg[0],
            "ui_tint_green": bg[1],
            "ui_tint_blue": bg[2],
            "ui_font_red": fg[0],
            "ui_font_green": fg[1],
            "ui_font_blue": fg[2],
        }

        text = (
            self.config_path.read_text(encoding="utf-8")
            if self.config_path.exists()
            else ""
        )
        lines, seen = [], set()
        for line in text.splitlines():
            if "=" in line and not line.lstrip().startswith("#"):
                key = line.split("=", 1)[0].strip()
                if key in updates:
                    lines.append(f"{key}={updates[key]}")
                    seen.add(key)
                    continue
            lines.append(line)
        for key, val in updates.items():
            if key not in seen:
                lines.append(f"{key}={val}")
        self.config_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

        print(
            f"look: bg=color2 {color2} * {self.TINT_DARKEN} -> tint=({bg[0]},{bg[1]},{bg[2]}) "
            f"font=color4 {color4} -> ({fg[0]},{fg[1]},{fg[2]})"
        )
        return True

    def _dbus_ping(self):
        return (
            subprocess.run(
                [
                    "gdbus",
                    "call",
                    "--session",
                    "--dest",
                    "com.look.Desktop",
                    "--object-path",
                    "/com/look/Desktop",
                    "--method",
                    "org.freedesktop.DBus.Peer.Ping",
                ],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            ).returncode
            == 0
        )

    def reload(self):
        """隐藏式重启 lookapp: D-Bus 名字一注册就立刻 Toggle 隐藏, 不打断工作。"""
        subprocess.run(["killall", "lookapp"], check=False)
        time.sleep(0.8)  # 等 D-Bus 名字 com.look.Desktop 释放
        subprocess.Popen(
            ["setsid", "lookapp"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        up = False
        for _ in range(100):  # 最多等 5s
            if self._dbus_ping():
                up = True
                break
            time.sleep(0.05)
        if up:
            subprocess.run(
                [
                    "gdbus",
                    "call",
                    "--session",
                    "--dest",
                    "com.look.Desktop",
                    "--object-path",
                    "/com/look/Desktop",
                    "--method",
                    "com.look.Desktop.Toggle",
                ],
                check=False,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            print("look 已重启并隐藏（不打断工作）")
        else:
            print("警告: lookapp 未在 5s 内注册 D-Bus", file=sys.stderr)

    def run(self):
        if self.update_config() and self.restart:
            self.reload()
        return True


# ======================================================================
# 入口
# ======================================================================


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="run_reload_all",
        description="整合 run_reload_kitty.sh 的全部同步逻辑 (纯 stdlib)",
    )
    parser.add_argument("--anim", action="store_true", help="只轮换 niri 窗口动画")
    parser.add_argument(
        "--color", action="store_true", help="只同步 niri 颜色 (mix.kdl/noctalia.kdl)"
    )
    parser.add_argument(
        "--omp", action="store_true", help="只同步 .pi -> .omp 主题 vars"
    )
    parser.add_argument(
        "--fcitx5", action="store_true", help="只重建 fcitx5 noctalia 主题"
    )
    parser.add_argument("--look", action="store_true", help="只同步 Look 主题")
    parser.add_argument("--no-restart", action="store_true", help="Look 只改配置不重启")
    args = parser.parse_args(argv)

    flags = (args.anim, args.color, args.omp, args.fcitx5, args.look)
    run_all = not any(flags)

    if args.anim or run_all:
        NiriAnimationSwitcher().switch()

    # 原脚本在取色前 sleep 1 等 noctalia 写完主题文件; 主题读完供后续场景共用
    if run_all or args.color:
        time.sleep(1)
    theme = KittyTheme()
    if not theme.exists():
        print(f"警告: 找不到主题文件 {theme.path}", file=sys.stderr)

    if args.color or run_all:
        NiriColorSyncer(theme).sync()

    if args.omp or run_all:
        OmpThemeSyncer().sync()

    if args.fcitx5 or run_all:
        gen = Fcitx5ThemeGenerator(theme)
        if gen.generate():
            gen.reload()

    if args.look or run_all:
        LookThemeSyncer(theme, restart=not args.no_restart).run()

    return 0


if __name__ == "__main__":
    sys.exit(main())
