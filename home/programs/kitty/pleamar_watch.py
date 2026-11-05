#!/usr/bin/env python3
"""Watch Pleamar's palette file and refresh Kitty, omp, fcitx5, Look, Telegram and niri.

Watched file:
    ~/.config/pleamar-shell/palette.json

The target is pleamar_reload_all.py, which reads primary/secondary from that
file and refreshes the Kitty, omp, fcitx5, Look, Telegram and niri themes.  A change is debounced briefly
so Pleamar can finish writing the file before Kitty is reloaded.

Usage:
    pleamar_watch.py              # run in the foreground
    pleamar_watch.py --once       # apply the current palette and exit
    pleamar_watch.py --print      # print primary/secondary and exit
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

PALETTE = Path.home() / ".config/pleamar-shell/palette.json"
TARGET = Path(__file__).with_name("pleamar_reload_all.py")
TARGET_ARGS = ["--all"]
POLL_SECONDS = 0.5
SETTLE_SECONDS = 0.35


def log(message: str) -> None:
    print(time.strftime("[%Y-%m-%d %H:%M:%S]"), "[pleamar-watch]", message, flush=True)


def mtime_ns(path: Path) -> int:
    try:
        return path.stat().st_mtime_ns
    except OSError:
        return 0


def read_colors(path: Path) -> tuple[str | None, str | None]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return None, None
    if not isinstance(data, dict):
        return None, None
    return data.get("primary"), data.get("secondary")


def run_target(target: Path, target_args: list[str]) -> int:
    if target.suffix == ".py":
        command = [sys.executable, str(target), *target_args]
    else:
        command = [str(target), *target_args]
    log("执行: " + " ".join(command))
    try:
        result = subprocess.run(command, check=False)
    except OSError as exc:
        log(f"目标执行失败: {exc}")
        return 1
    log(f"目标退出码: {result.returncode}")
    return result.returncode


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Pleamar wallpaper colour watcher")
    parser.add_argument("--palette", type=Path, default=PALETTE)
    parser.add_argument("--target", type=Path, default=TARGET)
    parser.add_argument(
        "--args",
        default=" ".join(TARGET_ARGS),
        help="arguments passed to the target (default: --all)",
    )
    parser.add_argument("--once", action="store_true", help="apply once and exit")
    parser.add_argument(
        "--print", dest="print_only", action="store_true", help="print current primary/secondary"
    )
    args = parser.parse_args(argv)

    palette = args.palette.expanduser()
    target = args.target.expanduser()
    target_args = args.args.split()

    if args.print_only:
        primary, secondary = read_colors(palette)
        print(f"primary={primary} secondary={secondary} source={palette}")
        return 0 if primary else 1

    if not palette.exists():
        log(f"等待 {palette} 出现")

    if args.once:
        return run_target(target, target_args)

    # Apply the palette already on disk at startup.  Kitty may have started
    # before this service, so theme.conf and the running instances both need
    # to catch up.
    if palette.exists():
        run_target(target, target_args)

    log(f"监听: {palette}")
    last = mtime_ns(palette)
    while True:
        time.sleep(POLL_SECONDS)
        current = mtime_ns(palette)
        if current == last:
            continue
        log("检测到 palette.json 变化")
        time.sleep(SETTLE_SECONDS)
        last = mtime_ns(palette)
        run_target(target, target_args)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        raise SystemExit(0)
