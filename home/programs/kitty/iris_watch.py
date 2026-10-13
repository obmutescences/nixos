#!/usr/bin/env python3
"""监听 iNiR 壁纸配色的变化, 并执行 iris_reload_all.py 做主题同步。

监听 (每秒轮询 mtime):
  ~/.local/state/quickshell/user/generated/iris-surface.json   # iRiS 解出的配色, 壁纸变化后约 0.5s 写入
  ~/.local/state/quickshell/user/generated/colors.json         # Material 调色板, 生成链完成后写入

检测到变化后等 SETTLE_SECONDS 让整条生成链写完, 然后:
  - prime 从较新的 iris-surface.json / palette.json 提取, second 取壁纸的第二显色
    (iris-washi.json 的 highlights.wallpaper, 与 highlight 设置无关)
  - 注入环境变量 IRIS_PRIME / IRIS_SECOND / IRIS_SURFACE / IRIS_GENERATED
  - 执行目标脚本 (默认 ~/.config/kitty/iris_reload_all.py)

用法:
  iris_watch.py                       # 常驻监听 (默认目标/参数见下方常量)
  iris_watch.py --print               # 只打印当前 prime/second 后退出
  iris_watch.py --args ""             # 空字符串 = 不加参数 (即含 --anim 的全场景)
  iris_watch.py --args "--color"      # 自定义传给目标脚本的参数
"""

import argparse
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

GENERATED = Path.home() / ".local/state/quickshell/user/generated"
WATCHED = (GENERATED / "iris-surface.json", GENERATED / "colors.json")
DEFAULT_TARGET = Path.home() / ".config/kitty/iris_reload_all.py"
DEFAULT_ARGS = "--color --omp --kitty --fcitx5 --look"  # 默认不跑 --anim (动画轮换)
POLL_SECONDS = 1.0
SETTLE_SECONDS = 2.5
_HEX_RE = re.compile(r"#[0-9a-fA-F]{6}")


def log(msg):
    print(time.strftime("[%Y-%m-%d %H:%M:%S]"), "[iris-watch]", msg, flush=True)


def mtime_ns(path):
    try:
        return path.stat().st_mtime_ns
    except OSError:
        return 0


def second_from_wallpaper(generated=None):
    """壁纸的第二显色 (小写 #rrggbb), 与 iris.appearance.highlight 的设置无关。

    先用求解器按当前纸张算好的 iris-washi.json -> schemes.<mode>.highlights.wallpaper
    (highlight=accent 时它仍是壁纸的第二色, palette.json / roles 的 tertiary 则不是);
    退回生成器记录的 iris-seeds.json.secondary; 都取不到返回 None。
    """
    gen = Path(generated or GENERATED).expanduser()
    mode = "dark"
    try:
        mode = (
            json.loads((gen / "theme-meta.json").read_text(encoding="utf-8")).get(
                "mode"
            )
            or "dark"
        )
    except (OSError, ValueError):
        pass
    try:
        schemes = (
            json.loads((gen / "iris-washi.json").read_text(encoding="utf-8")).get(
                "schemes"
            )
            or {}
        )
        for key in (mode, "dark"):
            val = ((schemes.get(key) or {}).get("highlights") or {}).get("wallpaper")
            if isinstance(val, str) and _HEX_RE.fullmatch(val.strip()):
                return val.strip().lower()
    except (OSError, ValueError):
        pass
    try:
        val = json.loads((gen / "iris-seeds.json").read_text(encoding="utf-8")).get(
            "secondary"
        )
        if isinstance(val, str) and _HEX_RE.fullmatch(val.strip()):
            return val.strip().lower()
    except (OSError, ValueError):
        pass
    return None


def read_colors():
    """返回 (prime, second, 来源文件名)。prime 取 iris-surface.json / palette.json 里较新的那份;
    second 取壁纸的第二显色 (second_from_wallpaper), 取不到才退回那份里的 secondary。"""
    surface = GENERATED / "iris-surface.json"
    palette = GENERATED / "palette.json"
    files = [p for p in (surface, palette) if p.exists()]
    newest = max(files, key=lambda p: p.stat().st_mtime) if files else surface

    prime = second = None
    roles = {}
    try:
        roles = json.loads(surface.read_text(encoding="utf-8")).get("roles") or {}
    except (OSError, ValueError):
        pass
    if newest == palette:
        try:
            data = json.loads(palette.read_text(encoding="utf-8"))
            prime, second = data.get("primary"), data.get("secondary")
        except (OSError, ValueError):
            pass
    prime = prime or roles.get("primary")
    second = second or roles.get("secondary")
    if not prime or not second:
        try:
            data = json.loads(palette.read_text(encoding="utf-8"))
            prime = prime or data.get("primary")
            second = second or data.get("secondary")
        except (OSError, ValueError):
            pass
    second = (
        second_from_wallpaper() or second
    )  # 壁纸的第二显色优先 (与 highlight 设置无关)
    return prime, second, newest.name


def main():
    parser = argparse.ArgumentParser(description="iNiR 配色变化监听器")
    parser.add_argument(
        "--target", default=str(DEFAULT_TARGET), help="变化时要执行的脚本"
    )
    parser.add_argument("--args", default=DEFAULT_ARGS, help="传给目标脚本的参数")
    parser.add_argument(
        "--print",
        dest="print_now",
        action="store_true",
        help="打印当前 prime/second 后退出",
    )
    args = parser.parse_args()

    if args.print_now:
        prime, second, source = read_colors()
        print(f"prime={prime} second={second} (来源: {source})")
        return 0 if (prime and second) else 1

    target_args = args.args.split()
    log("监听: " + ", ".join(str(p) for p in WATCHED))
    log("触发目标: %s %s" % (args.target, " ".join(target_args)))
    last = {p: mtime_ns(p) for p in WATCHED}

    while True:
        time.sleep(POLL_SECONDS)
        current = {p: mtime_ns(p) for p in WATCHED}
        changed = [p for p in WATCHED if current[p] != last[p]]
        if not changed:
            continue
        log(
            "检测到变化: %s; 等 %.1fs 后执行"
            % (", ".join(p.name for p in changed), SETTLE_SECONDS)
        )
        time.sleep(SETTLE_SECONDS)
        last = {p: mtime_ns(p) for p in WATCHED}

        prime, second, source = read_colors()
        env = dict(os.environ)
        env["IRIS_SURFACE"] = str(GENERATED / "iris-surface.json")
        env["IRIS_GENERATED"] = str(GENERATED)
        if prime:
            env["IRIS_PRIME"] = prime
        if second:
            env["IRIS_SECOND"] = second

        cmd = (
            [sys.executable, args.target]
            if args.target.endswith(".py")
            else [args.target]
        ) + target_args
        log(
            "执行: %s (prime=%s, second=%s, 来源=%s)"
            % (args.target, prime, second, source)
        )
        try:
            proc = subprocess.run(cmd, env=env)
            log("目标退出码: %d" % proc.returncode)
        except OSError as exc:
            log("目标执行失败: %s" % exc)


if __name__ == "__main__":
    raise SystemExit(main())
