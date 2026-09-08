"""把 kitty themes/noctalia.conf 的颜色同步到 Look (~/.look/config)。

- color2 -> ui_tint_*  (Look 面板背景色，经 TINT_DARKEN 压暗)
- color4 -> ui_font_*  (Look 字体颜色)

Look 不支持后台重载配置（D-Bus 只有 Toggle，config 不监听文件），
所以默认改完会重启 lookapp 让新配置生效；加 --no-restart 可跳过。

重启是"隐藏式"的：Look 启动即弹窗（tauri.conf visible:true 编译死），
脚本在 D-Bus 名字一注册就立刻 Toggle 隐藏，抢在窗口首帧前，不打断工作。
"""

import re
import subprocess
import sys
import time
from pathlib import Path

KITTY_THEME = Path.home() / ".config/kitty/themes/noctalia.conf"
LOOK_CONFIG = Path.home() / ".look/config"

# 背景暗化系数：1.0 = color2 原色，越小越暗（RGB 同比例缩放，色相不变）。
# 觉得背景偏亮就往小调，比如 0.6；偏暗就往大调，比如 0.85。
TINT_DARKEN = 0.4


def parse_colors(path: Path) -> dict:
    colors = {}
    for line in path.read_text().splitlines():
        m = re.match(r"^color(\d+)\s+(#[0-9a-fA-F]{6})", line.strip())
        if m:
            colors[int(m.group(1))] = m.group(2)
    return colors


def hex_to_rgb01(hex_color: str) -> tuple:
    h = hex_color.lstrip("#")
    return tuple(round(int(h[i : i + 2], 16) / 255, 3) for i in (0, 2, 4))


def darken(rgb: tuple, factor: float) -> tuple:
    return tuple(round(v * factor, 3) for v in rgb)


def update_config(colors: dict) -> bool:
    if 2 not in colors or 4 not in colors:
        print("noctalia.conf 缺少 color2/color4", file=sys.stderr)
        return False

    bg = darken(hex_to_rgb01(colors[2]), TINT_DARKEN)
    fg = hex_to_rgb01(colors[4])

    # 关键：非 custom 主题时，内置主题预设会覆盖 tint/font 值，
    # 必须把 ui_theme 设为 custom 修改才会生效。
    updates = {
        "ui_theme": "custom",
        "ui_tint_red": bg[0],
        "ui_tint_green": bg[1],
        "ui_tint_blue": bg[2],
        "ui_font_red": fg[0],
        "ui_font_green": fg[1],
        "ui_font_blue": fg[2],
    }

    text = LOOK_CONFIG.read_text() if LOOK_CONFIG.exists() else ""
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

    LOOK_CONFIG.write_text("\n".join(lines) + "\n")
    print(
        f"look: bg=color2 {colors[2]} * {TINT_DARKEN} -> tint=({bg[0]},{bg[1]},{bg[2]}) "
        f"font=color4 {colors[4]} -> ({fg[0]},{fg[1]},{fg[2]})"
    )
    return True


def dbus_ping() -> bool:
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
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode
        == 0
    )


def reload_look():
    subprocess.run(["killall", "lookapp"], check=False)
    time.sleep(0.8)  # 等 D-Bus 名字 com.look.Desktop 释放
    subprocess.Popen(
        ["setsid", "lookapp"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
    )
    # 名字一注册就 Toggle 隐藏，抢在首帧前 -> 无闪烁重启
    up = False
    for _ in range(100):  # 最多等 5s
        if dbus_ping():
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
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        print("look 已重启并隐藏（不打断工作）")
    else:
        print("警告: lookapp 未在 5s 内注册 D-Bus", file=sys.stderr)


def main():
    if not KITTY_THEME.exists():
        print(f"找不到主题文件: {KITTY_THEME}", file=sys.stderr)
        return 1
    colors = parse_colors(KITTY_THEME)
    if update_config(colors) and "--no-restart" not in sys.argv:
        reload_look()
    return 0


if __name__ == "__main__":
    sys.exit(main())
