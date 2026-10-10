#!/usr/bin/env python3
"""整合 run_reload_kitty.sh 的全部同步逻辑为单个纯 stdlib 脚本。

覆盖的场景 (按 run_reload_kitty.sh 原顺序):
  1. NiriAnimationSwitcher   轮换 niri 窗口动画 (config.kdl 末尾的 include)
  2. NiriColorSyncer         把 prime 同步到 mix.kdl / noctalia.kdl
  3. OmpThemeSyncer          按 palette.json 的 Material You 角色重写 .omp 主题 vars
  4. KittyThemeSyncer        按 palette.json 重算 kitty theme.conf (含目录色)
  5. Fcitx5ThemeGenerator    按 iNiR 配色重生成 fcitx5 主题 (PNG + theme.conf)
  6. LookThemeSyncer         把 prime/second 同步到 Look 配置并 reload-config 热重载

颜色源: iNiR 生成物 ~/.local/state/quickshell/user/generated/iris-surface.json
的 roles (回退 palette.json; 环境变量 IRIS_PRIME / IRIS_SECOND 可覆盖)。
可由 ~/.config/kitty/iris_watch.py 在壁纸/配色变化时自动触发, 也可手动运行。

颜色同步方式变更: 旧脚本用全文件 sed 无差别替换, 相同 key 的 `color "..."`
在不同块里会被同一种规则命中。现在改为按「上级/上上级块路径」精确匹配:
每条规则 = (祖先块路径, key, 替换值种类), 只替换命中块里的那一条。

用法:
    python3 iris_reload_all.py                       # 按序执行全部场景
    python3 iris_reload_all.py --anim                # 只轮换动画
    python3 iris_reload_all.py --color               # 只同步 niri 颜色
    python3 iris_reload_all.py --omp                 # 只按 palette.json 重建 .omp 主题 vars
    python3 iris_reload_all.py --kitty               # 只按 palette.json 重算 kitty theme.conf
    python3 iris_reload_all.py --fcitx5              # 只重建 fcitx5 主题
    python3 iris_reload_all.py --look [--no-restart] # 只同步 Look (可选不 reload)
"""

import argparse
import colorsys
import json
import math
import os
import re
import struct
import subprocess
import sys
import time
import zlib
from pathlib import Path

# ======================================================================
# 共享: iNiR 配色读取 + 颜色数学 (纯 stdlib)
# ======================================================================


class IrisTheme:
    """iNiR 配色源 (prime/second), 保持旧 KittyTheme 的接口 (color(n) / get(key))。

    读取优先级: 环境变量 IRIS_PRIME / IRIS_SECOND (iris_watch.py 触发时注入)
                -> iris-surface.json 与 palette.json 中较新的那份
                -> 缺省兜底色。
    槽位映射: prime -> color2 / active_border_color (主色), second -> color4,
              foreground -> roles.onSurface, color8 -> roles.outline。
    """

    SURFACE = Path.home() / ".local/state/quickshell/user/generated/iris-surface.json"
    PALETTE = Path.home() / ".local/state/quickshell/user/generated/palette.json"

    def __init__(self):
        surface, palette = self.SURFACE, self.PALETTE

        surface_data, palette_data = {}, {}
        if surface.exists():
            try:
                surface_data = json.loads(surface.read_text(encoding="utf-8"))
            except (OSError, ValueError):
                surface_data = {}
        if palette.exists():
            try:
                palette_data = json.loads(palette.read_text(encoding="utf-8"))
            except (OSError, ValueError):
                palette_data = {}

        files = [p for p in (surface, palette) if p.exists()]
        newest = max(files, key=lambda p: p.stat().st_mtime) if files else surface
        self.path = newest

        roles = surface_data.get("roles") or {}
        if newest == palette:
            prime = palette_data.get("primary")
            second = palette_data.get("on_secondary_container")
        else:
            prime = roles.get("primary") or palette_data.get("primary")
            second = roles.get("on_secondary_container") or palette_data.get(
                "on_secondary_container"
            )

        # 环境变量可覆盖 (由 iris_watch.py 注入, 或手动指定)
        prime = os.environ.get("IRIS_PRIME") or prime
        second = os.environ.get("IRIS_SECOND") or second

        self._kv = {
            "color2": prime,  # 旧「active」槽位 -> prime
            "active_border_color": prime,
            "color4": second,  # 旧高亮槽位 -> second
            "foreground": roles.get("onSurface") or "#f3f0ea",
            "color8": roles.get("outline") or "#99a0a2",
        }

    def exists(self):
        return bool(self._kv.get("color2") or self._kv.get("color4"))

    def color(self, n):
        """取 colorN (2=prime, 4=second)。"""
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
    def hsla(hex_color, lightness, alpha):
        """run_reload_kitty.sh 的取色算法: 饱和度 +0.2 (封顶 100%), 指定亮度/透明度。"""
        h, _, s = ColorMath.hex_to_hls(hex_color)
        s = min(1.0, s + 0.2)
        return f"hsla({h * 360:.0f}, {s * 100:.0f}%, {lightness}%, {alpha})"


PALETTE = Path.home() / ".local/state/quickshell/user/generated/palette.json"
_HEX_RE = re.compile(r"#[0-9a-fA-F]{6}")


def load_palette(path=None):
    """读取 Material You palette.json, 返回 dict; 失败返回 None。"""
    path = Path(path or PALETTE).expanduser()
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as e:
        print(f"警告: 读取 {path} 失败: {e}", file=sys.stderr)
        return None
    return data if isinstance(data, dict) else None


def pick_role(palette, roles):
    """按候选顺序取第一个存在的角色色, 规范为小写 #rrggbb; 都不存在返回 None。"""
    for role in roles:
        val = palette.get(role)
        if isinstance(val, str) and _HEX_RE.fullmatch(val):
            return val.lower()
    return None


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
# 场景 2: niri 颜色同步 (prime -> mix.kdl / noctalia.kdl)
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
    """把 prime (旧 color2 槽位) 同步到 niri 的 mix.kdl / noctalia.kdl。"""

    NOCTALIA_KDL = Path.home() / ".config/niri/noctalia.kdl"
    MIX_KDL = Path.home() / ".config/niri/mix.kdl"
    DEFAULT_COLOR = "#161a22e6"

    HSLA_LIGHTNESS = 30  # 主色亮度 (%)
    HSLA_ALPHA = 0.65
    B_HSLA_LIGHTNESS = 10  # 背景色亮度 (%)
    B_HSLA_ALPHA = 0.65

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

        active = self.theme.color(2)  # 主色 prime (旧 color2 槽位)
        if not active:
            print("警告: 未读到 prime 颜色, 跳过 niri 颜色同步", file=sys.stderr)
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
# 场景 3: palette.json -> .omp 主题 vars 同步
# ======================================================================


class OmpThemeSyncer:
    """从 iNiR palette.json 读取 Material You 角色色, 按语义映射到 .omp 主题的 vars。

    palette.json 的键是 Material You 角色名 (primary/secondary/tertiary/...)。
    这里用 ROLE_MAP 把 omp 主题的每个 vars key 关联到一组候选角色 (首选在前),
    取第一个存在的角色色; 只重写顶层 'vars' 区块, 其余字段 (colors 引用等) 字节不变,
    dst 中已有但 ROLE_MAP 未覆盖的 var 保留原值。
    """

    PALETTE = Path.home() / ".local/state/quickshell/user/generated/palette.json"
    DST = Path.home() / ".omp/agent/themes/noctalia.json"

    # omp vars key -> palette 角色候选 (按优先级, 首选在前)
    # 语义依据: tert 在 colors 里当作 success, err 当作 error, errorCont 当作 toolErrorBg。

    def __init__(self, palette=None, dst=None):
        self.palette = Path(palette or self.PALETTE).expanduser()
        self.dst = Path(dst or self.DST).expanduser()
        self.ROLE_MAP = {
            "bg": ("surface", "background"),
            "bgAlt": ("surface_container", "surface_container_high"),
            "bgAlt2": ("surface_container_low", "surface_container"),
            "fg": ("on_surface", "on_background"),
            "fgMuted": ("on_surface_variant", "outline"),
            "accent": ("primary", "tertiary"),
            "accentAlt": ("tertiary", "primary"),
            "tert": ("success", "tertiary"),
            "err": ("error", "error_fill"),
            "outline": ("outline", "outline_variant"),
            "outlineVar": ("outline_variant", "outline"),
            "primaryCont": ("primary_container", "surface_container_highest"),
            "errorCont": ("error_container", "primary_container"),
            "surfaceLow": ("surface_container_lowest", "surface_dim"),
            "surfaceLowest": ("surface_dim", "surface_container_lowest"),
            "primaryFixed": ("primary_fixed", "primary_fixed_dim"),
            "secondaryFixedDim": ("secondary_fixed_dim", "secondary_fixed"),
        }

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

    def _load_palette(self):
        return load_palette(self.palette)

    def _build_vars(self, existing, palette):
        """保留 dst 现有 var 顺序, 覆盖 ROLE_MAP 命中的值。"""
        out = {}
        for key, old in existing.items():
            roles = self.ROLE_MAP.get(key)
            new = pick_role(palette, roles) if roles else None
            out[key] = new if new else old
        return out

    def sync(self):
        if not self.palette.exists() or not self.dst.exists():
            print(
                f"警告: {self.palette} 或 {self.dst} 不存在, 跳过 .omp 主题同步",
                file=sys.stderr,
            )
            return False

        palette = self._load_palette()
        if palette is None:
            return False

        dst_text = self.dst.read_text(encoding="utf-8")
        d_start, d_end = self._vars_span(dst_text)
        existing = json.loads(dst_text[d_start:d_end])
        if not isinstance(existing, dict):
            print("警告: .omp 主题 vars 不是对象, 跳过", file=sys.stderr)
            return False

        new_vars = self._build_vars(existing, palette)
        body = json.dumps(new_vars, indent=8, ensure_ascii=False)
        body = body.replace("\n}", "\n    }")  # 与现有 4 空格收尾对齐
        self.dst.write_text(
            dst_text[:d_start] + body + dst_text[d_end:], encoding="utf-8"
        )

        updated = sum(1 for k, v in new_vars.items() if v != existing.get(k))
        print(
            f".omp 主题 vars 已按 {self.palette.name} 重建 "
            f"({updated}/{len(new_vars)} 项更新)"
        )
        return True


# ======================================================================
# 场景 4: palette.json -> kitty theme.conf 同步
# ======================================================================


class KittyThemeSyncer:
    """把 palette.json 的 Material You 角色色同步到 kitty 的 theme.conf。

    ii 壁纸主题系统生成的 theme.conf 各次变化很小, 且 ANSI 16 色 / 目录色不跟随主色。
    这里只替换文件中已存在的配置项 (保留 ii 的注释与排版), 按 palette 角色重算:
      基本色 (background/foreground/cursor/selection) <- surface / on_surface 系
      边框与 URL <- primary
      Tab 栏 <- primary / surface 系
      16 色: 目录色 color4/color12 <- primary (跟随主色), 红槽 <- error(_fill),
             绿槽 <- success, 黄槽 <- tertiary_fixed, 青槽 <- tertiary, 灰槽 <- outline 系。
    """

    CONF = Path.home() / ".config/kitty/theme.conf"

    # `key  value` 行 (value 后可跟行尾注释), 保留 key 与 value 之间的对齐空白
    _LINE_RE = re.compile(r"^(\s*)([A-Za-z_]\w*)(\s+)(\S+)(\s*(?:#.*)?)$")

    # ii 生成 theme.conf 与本脚本存在竞态: ii 通常在 palette.json 之后约 1s 才写 theme.conf。
    # 处理: 先等 ii 写完 (theme.conf mtime 晚于 palette.json) 再写入, 写后再守护一小段时间
    # 防止 ii 补写覆盖, 最后 SIGUSR1 让 kitty 重读配置 (否则磁盘正确但界面仍是 ii 的旧色)。
    II_WAIT_SECONDS = 6.0  # 等 ii 写完 theme.conf 的最长时间
    SETTLE_SECONDS = 1.0  # theme.conf 静默多久视为写完
    GUARD_SECONDS = 3.0  # 写后守护窗口: 期间被 ii 覆盖就重写
    POLL_SECONDS = 0.25

    def __init__(self, palette=None, conf=None):
        self.palette = Path(palette or PALETTE).expanduser()
        self.conf = Path(conf or self.CONF).expanduser()
        # kitty 配置项 -> palette 角色候选 (按优先级, 首选在前)
        self.ROLE_MAP = {
            # 基本色
            "background": ("surface", "background"),
            "foreground": ("on_surface", "on_background"),
            "selection_background": ("surface_container_highest", "primary_container"),
            "selection_foreground": ("on_surface", "on_background"),
            "cursor": ("on_surface", "on_background"),
            "cursor_text_color": ("surface", "background"),
            "url_color": ("primary", "tertiary"),
            # 边框
            "active_border_color": ("primary", "tertiary"),
            "inactive_border_color": ("surface_container_high", "outline_variant"),
            "bell_border_color": ("error_fill", "error"),
            # Tab 栏
            "active_tab_foreground": ("on_primary", "on_surface"),
            "active_tab_background": ("primary", "tertiary"),
            "inactive_tab_foreground": ("on_surface_variant", "outline"),
            "inactive_tab_background": ("surface_container", "surface_container_low"),
            "tab_bar_background": ("surface_container_lowest", "surface_dim"),
            # 16 色 (普通): color4 是目录色, 跟随主色
            "color0": ("surface_dim", "surface_container_lowest"),
            "color1": ("error_fill", "error"),
            "color2": ("success", "tertiary"),
            "color3": ("tertiary_fixed", "tertiary_fixed_dim"),
            "color4": ("primary", "tertiary"),
            "color5": ("secondary", "secondary_fixed"),
            "color6": ("tertiary", "success"),
            "color7": ("on_surface_variant", "outline"),
            # 16 色 (明亮)
            "color8": ("outline_variant", "surface_container_highest"),
            "color9": ("error", "error_fill"),
            "color10": ("tertiary", "success"),
            "color11": ("tertiary_fixed_dim", "tertiary_fixed"),
            "color12": ("primary_fixed", "primary"),
            "color13": ("secondary_fixed", "secondary_fixed_dim"),
            "color14": ("primary_fixed_dim", "primary_fixed"),
            "color15": ("on_surface", "on_background"),
        }

    def build_colors(self, palette):
        """kitty key -> 颜色, 只保留能取到角色的项。"""
        colors = {}
        for key, roles in self.ROLE_MAP.items():
            val = pick_role(palette, roles)
            if val:
                colors[key] = val
        return colors

    def _rewrite(self, text, colors):
        out, hits = [], 0
        for line in text.splitlines(keepends=True):
            m = self._LINE_RE.match(line)
            if m and m.group(2) in colors:
                out.append(
                    f"{m.group(1)}{m.group(2)}{m.group(3)}"
                    f"{colors[m.group(2)]}{m.group(5)}"
                )
                hits += 1
            else:
                out.append(line)
        return "".join(out), hits

    def _wait_for_ii(self):
        """等 ii 写完 theme.conf: 其 mtime 晚于 palette.json 且静默 SETTLE_SECONDS。

        最多等 II_WAIT_SECONDS, 超时则照常写入 (不无限阻塞)。
        """
        try:
            palette_mtime = self.palette.stat().st_mtime
        except OSError:
            return
        deadline = time.time() + self.II_WAIT_SECONDS
        while time.time() < deadline:
            try:
                conf_mtime = self.conf.stat().st_mtime
            except OSError:
                time.sleep(self.POLL_SECONDS)
                continue
            if (
                conf_mtime > palette_mtime
                and time.time() - conf_mtime >= self.SETTLE_SECONDS
            ):
                return
            time.sleep(self.POLL_SECONDS)

    def _guard(self, expected):
        """写后守护 GUARD_SECONDS: ii 若覆盖 theme.conf, 立即重写回我们的颜色。"""
        deadline = time.time() + self.GUARD_SECONDS
        rewrites = 0
        while time.time() < deadline:
            time.sleep(self.POLL_SECONDS)
            try:
                cur = self.conf.read_text(encoding="utf-8")
            except OSError:
                continue
            if cur != expected:
                self.conf.write_text(expected, encoding="utf-8")
                rewrites += 1
        return rewrites

    @staticmethod
    def _reload_kitty():
        """让运行中的 kitty 重读配置 (SIGUSR1), 与 ii applycolor.sh 的做法一致。"""
        try:
            subprocess.run(
                ["pkill", "-USR1", "-x", "kitty"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            )
        except OSError:
            pass

    def sync(self):
        if not self.palette.exists() or not self.conf.exists():
            print(
                f"警告: {self.palette} 或 {self.conf} 不存在, 跳过 kitty 主题同步",
                file=sys.stderr,
            )
            return False

        palette = load_palette(self.palette)
        if palette is None:
            return False

        colors = self.build_colors(palette)
        if not colors:
            print(
                "警告: palette 未匹配到任何角色, 跳过 kitty 主题同步", file=sys.stderr
            )
            return False

        # 1) 等 ii 先写完, 否则我们的写入会被 ii 后续覆盖
        self._wait_for_ii()
        # 2) 写入我们的颜色
        text = self.conf.read_text(encoding="utf-8")
        expected, hits = self._rewrite(text, colors)
        self.conf.write_text(expected, encoding="utf-8")
        # 3) 守护窗口: ii 若补写覆盖, 立即重写
        rewrites = self._guard(expected)
        # 4) 让 kitty 重读配置, 否则磁盘已改但界面仍是 ii 的旧色
        self._reload_kitty()

        msg = (
            f"kitty: theme.conf 已按 {self.palette.name} 重算 "
            f"({hits} 项, 目录色 color4={colors.get('color4')})"
        )
        if rewrites:
            msg += f", 守护期内被 ii 覆盖 {rewrites} 次已重写"
        print(msg)
        return True


# ======================================================================
# 场景 5: fcitx5 主题重生成 (generate.py 逻辑内联)
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
    BG_LIGHTNESS = 0.20  # 面板背景亮度 (与选择框同色相饱和度, 压低亮度)
    HL_BG_LIGHTNESS = 0.16  # 选中区域背景亮度: 与面板同色相/饱和度, 但压得更暗

    CONF_TEMPLATE = """\
# 由 iris_reload_all.py 从 iNiR 配色自动生成, 手改会被覆盖。
# 来源: {source}
# 背景={bg} 文字={on_surface} 选择框={highlight_bg} 选中文字={secondary}
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
HighlightBackgroundColor={highlight_bg}
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
        # 选中区域背景: 与面板背景同色相/饱和度, 只把亮度压到更低
        highlight_bg = ColorMath.from_hls(h, self.HL_BG_LIGHTNESS, s)
        return {
            "bg": bg,
            "on_surface": pal["foreground"],
            "highlight_bg": highlight_bg,
            "outline": pal["color8"] or accent,
            "secondary": pal["color4"] or pal["foreground"],
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
        self.gen_rounded(self.theme_dir / "highlight.png", colors["highlight_bg"], 8)
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
            f"fcitx5: bg={colors['bg']} highlight_bg={colors['highlight_bg']} "
            f"text={colors['secondary']}"
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
# 场景 6: Look 主题同步 (sync_look_theme.py 逻辑内联)
# ======================================================================


class LookThemeSyncer:
    """把 prime/second (旧 color2/color4 槽位) 同步到 Look 配置, 并 lookapp reload-config 热重载。"""

    LOOK_CONFIG = Path.home() / ".look/config"
    TINT_DARKEN = 0.2  # 背景压暗系数: 1.0 = color2 原色, 越小越暗

    def __init__(self, theme, config_path=None, restart=True):
        self.theme = theme
        self.config_path = Path(config_path or self.LOOK_CONFIG).expanduser()
        self.restart = restart

    def update_config(self):
        color2 = self.theme.color(2)
        color4 = self.theme.color(4)
        if not color2 or not color4:
            print("未读到 prime/second 颜色", file=sys.stderr)
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

    def reload(self):
        """官方热重载: lookapp reload-config 让运行中的 Look 重读配置, 不弹窗不重启。"""
        try:
            proc = subprocess.run(
                ["lookapp", "reload-config"],
                capture_output=True,
                text=True,
                check=False,
            )
        except OSError as e:
            print(f"警告: 无法执行 lookapp reload-config: {e}", file=sys.stderr)
            return

        output = (proc.stdout or "") + (proc.stderr or "")
        if "not running" in output:
            # Look 未在运行: 配置已落盘, 官方提示下次启动生效; 这里直接拉起以立即应用
            subprocess.Popen(
                ["setsid", "lookapp"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            print("look 未在运行, 已后台启动 lookapp (新配置随即生效)")
            return
        if proc.returncode != 0:
            print(
                f"警告: lookapp reload-config 退出码 {proc.returncode}",
                file=sys.stderr,
            )
            return
        print("look 配置已热重载 (lookapp reload-config)")

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
        "--omp", action="store_true", help="按 palette.json 重建 .omp 主题 vars"
    )
    parser.add_argument(
        "--kitty", action="store_true", help="按 palette.json 重算 kitty theme.conf"
    )
    parser.add_argument(
        "--fcitx5", action="store_true", help="只重建 fcitx5 noctalia 主题"
    )
    parser.add_argument("--look", action="store_true", help="只同步 Look 主题")
    parser.add_argument(
        "--no-restart", action="store_true", help="Look 只改配置不调用 reload-config"
    )
    args = parser.parse_args(argv)

    flags = (args.anim, args.color, args.omp, args.kitty, args.fcitx5, args.look)
    run_all = not any(flags)

    if args.anim or run_all:
        NiriAnimationSwitcher().switch()

    # 配色读到后供后续场景共用 (自动触发时 iris_watch.py 已做防抖, 无需再等)
    theme = IrisTheme()
    if not theme.exists():
        print(
            f"警告: 未读到 iNiR 配色 (检查 {theme.SURFACE} 或先切一次壁纸)",
            file=sys.stderr,
        )

    if args.color or run_all:
        NiriColorSyncer(theme).sync()

    if args.omp or run_all:
        OmpThemeSyncer().sync()

    if args.kitty or run_all:
        KittyThemeSyncer().sync()

    if args.fcitx5 or run_all:
        gen = Fcitx5ThemeGenerator(theme)
        if gen.generate():
            gen.reload()

    # if args.look or run_all:
    #     LookThemeSyncer(theme, restart=not args.no_restart).run()

    return 0


if __name__ == "__main__":
    sys.exit(main())
