import argparse
import asyncio
import logging
import os
import subprocess
import sys
import time
from collections.abc import Iterable
from dataclasses import dataclass
from typing import Any

from dbus_next import Variant
from dbus_next.aio import MessageBus
from dbus_next.constants import MessageType
from dbus_next.errors import DBusError
from dbus_next.message import Message

logger = logging.getLogger("wechat-tray")


def setup_logging(log_file: str | None, debug: bool) -> None:
    """Configure logging to write to *log_file* and stderr.

    When *log_file* is ``None``, file logging is skipped (messages still go
    to stderr so interactive runs see them).
    """
    level = logging.DEBUG if debug else logging.INFO
    logger.setLevel(level)

    fmt = logging.Formatter(
        "%(asctime)s  %(levelname)-8s  %(message)s", datefmt="%Y-%m-%d %H:%M:%S"
    )

    # Always log to stderr so interactive runs are unchanged.
    stderr_handler = logging.StreamHandler(sys.stderr)
    stderr_handler.setLevel(level)
    stderr_handler.setFormatter(fmt)
    logger.addHandler(stderr_handler)

    if log_file:
        try:
            os.makedirs(os.path.dirname(log_file), exist_ok=True)
            file_handler = logging.FileHandler(log_file, encoding="utf-8")
            file_handler.setLevel(level)
            file_handler.setFormatter(fmt)
            logger.addHandler(file_handler)
        except OSError as exc:
            logger.warning("Cannot open log file %r: %s", log_file, exc)


WATCHER_BUS = "org.kde.StatusNotifierWatcher"
WATCHER_PATH = "/StatusNotifierWatcher"
WATCHER_IFACE = "org.kde.StatusNotifierWatcher"
SNI_IFACE = "org.kde.StatusNotifierItem"
PROPERTIES_IFACE = "org.freedesktop.DBus.Properties"
NOTIFICATIONS_BUS = "org.freedesktop.Notifications"
NOTIFICATIONS_PATH = "/org/freedesktop/Notifications"
NOTIFICATIONS_IFACE = "org.freedesktop.Notifications"

ATTENTION_PROPERTIES = {
    "Status",
    "AttentionIconName",
    "AttentionIconPixmap",
    "AttentionMovieName",
    "OverlayIconName",
    "OverlayIconPixmap",
}


ICON_PROPERTIES = {
    "IconName",
    "IconPixmap",
    "ToolTip",
    "Title",
}


def get_session_bus_address() -> str | None:
    """Resolve the D-Bus session bus address.

    Tries the standard environment variable first, then falls back to the
    systemd user bus socket (the default on NixOS and modern distros).  This
    avoids the library's built-in fallback which requires ``DISPLAY`` — an
    X11-ism that is typically absent under Wayland compositors like niri.
    """
    # 1. Explicit env var (set by most terminal sessions and login managers)
    addr = os.environ.get("DBUS_SESSION_BUS_ADDRESS")
    if addr:
        return addr

    # 2. systemd user bus socket (standard on NixOS / modern systemd distros)
    xdg_runtime = os.environ.get("XDG_RUNTIME_DIR")
    if xdg_runtime:
        socket_path = os.path.join(xdg_runtime, "bus")
        if os.path.exists(socket_path):
            return f"unix:path={socket_path}"

    # 3. Fallback by UID (another common location)
    uid = os.getuid()
    socket_path = f"/run/user/{uid}/bus"
    if os.path.exists(socket_path):
        return f"unix:path={socket_path}"

    # 4. Let the library try its own resolution (requires DISPLAY — will
    #    likely fail under pure Wayland, but it's the last resort).
    return None


@dataclass
class SniItem:
    raw: str
    bus_name: str
    path: str
    item_id: str = ""
    title: str = ""
    status: str = ""
    tooltip_text: str = ""

    @property
    def identity_text(self) -> str:
        return " ".join(
            text
            for text in (
                self.raw,
                self.bus_name,
                self.path,
                self.item_id,
                self.title,
                self.tooltip_text,
            )
            if text
        ).lower()


@dataclass
class ItemState:
    status: str = ""
    title: str = ""
    tooltip_text: str = ""
    attention_icon_name: str = ""
    attention_pixmap_count: int = 0

    @property
    def has_attention(self) -> bool:
        return (
            self.status == "NeedsAttention"
            or bool(self.attention_icon_name)
            or self.attention_pixmap_count > 0
        )


def variant_value(value: Any) -> Any:
    return getattr(value, "value", value)


def flatten_text(value: Any) -> Iterable[str]:
    value = variant_value(value)

    if value is None:
        return
    if isinstance(value, str):
        if value:
            yield value
        return
    if isinstance(value, dict):
        for item in value.values():
            yield from flatten_text(item)
        return
    if isinstance(value, (list, tuple)):
        for item in value:
            yield from flatten_text(item)


def compact_text(value: Any) -> str:
    return " ".join(text.strip() for text in flatten_text(value) if text.strip())


def parse_sni_item(raw: str) -> SniItem:
    if "/" not in raw:
        return SniItem(raw=raw, bus_name=raw, path="/StatusNotifierItem")

    bus_name, path_tail = raw.split("/", 1)
    if not bus_name or not path_tail:
        raise ValueError(f"非法 StatusNotifierItem: {raw!r}")

    return SniItem(raw=raw, bus_name=bus_name, path="/" + path_tail)


async def maybe_call(getter: Any, default: Any = "") -> Any:
    if getter is None:
        return default
    try:
        return await getter()
    except (TimeoutError, DBusError, AttributeError):
        return default


async def inspect_sni_item(bus: MessageBus, raw: str) -> SniItem:
    item = parse_sni_item(raw)
    introspection = await bus.introspect(item.bus_name, item.path)
    proxy = bus.get_proxy_object(item.bus_name, item.path, introspection)
    iface = proxy.get_interface(SNI_IFACE)

    item.item_id = str(await maybe_call(getattr(iface, "get_id", None)))
    item.title = str(await maybe_call(getattr(iface, "get_title", None)))
    item.status = str(await maybe_call(getattr(iface, "get_status", None)))
    item.tooltip_text = compact_text(
        await maybe_call(getattr(iface, "get_tool_tip", None))
    )
    return item


async def snapshot_item_state(iface: Any) -> ItemState:
    attention_pixmap = await maybe_call(
        getattr(iface, "get_attention_icon_pixmap", None), []
    )
    return ItemState(
        status=str(await maybe_call(getattr(iface, "get_status", None))),
        title=str(await maybe_call(getattr(iface, "get_title", None))),
        tooltip_text=compact_text(
            await maybe_call(getattr(iface, "get_tool_tip", None))
        ),
        attention_icon_name=str(
            await maybe_call(getattr(iface, "get_attention_icon_name", None))
        ),
        attention_pixmap_count=len(attention_pixmap or []),
    )


def item_score(item: SniItem, keywords: tuple[str, ...]) -> int:
    score = 0
    raw_lower = item.raw.lower()
    id_lower = item.item_id.lower()
    title_lower = item.title.lower()
    tooltip_lower = item.tooltip_text.lower()

    for keyword in keywords:
        keyword = keyword.lower()
        if not keyword:
            continue
        if id_lower == keyword or title_lower == keyword:
            score += 100
        if keyword in id_lower or keyword in title_lower:
            score += 50
        if keyword in tooltip_lower:
            score += 30
        if keyword in raw_lower:
            score += 20

    return score


class WechatTrayNotifier:
    def __init__(self, bus: MessageBus, args: argparse.Namespace) -> None:
        self.bus = bus
        self.args = args
        self.keywords = tuple(keyword.lower() for keyword in args.keywords)

        self.item: SniItem | None = None
        self.item_iface: Any | None = None
        self.props_iface: Any | None = None

        self.armed = True
        self.last_event_at = 0.0
        self.last_notify_at = 0.0
        self.event_lock = asyncio.Lock()
        self.rearm_task: asyncio.Task[None] | None = None

    async def start(self) -> None:
        await self.bind_watcher()
        await self.bind_existing_wechat_item()

    async def bind_watcher(self) -> None:
        introspection = await self.bus.introspect(WATCHER_BUS, WATCHER_PATH)
        watcher = self.bus.get_proxy_object(WATCHER_BUS, WATCHER_PATH, introspection)
        watcher_iface = watcher.get_interface(WATCHER_IFACE)

        watcher_iface.on_status_notifier_item_registered(
            lambda raw: asyncio.create_task(self.on_item_registered(raw))
        )
        watcher_iface.on_status_notifier_item_unregistered(self.on_item_unregistered)

        self.watcher_iface = watcher_iface

    async def registered_items(self) -> list[str]:
        items = await self.watcher_iface.get_registered_status_notifier_items()
        return list(items or [])

    async def bind_existing_wechat_item(self) -> None:
        deadline = (
            None
            if self.args.wait_item_timeout < 0
            else time.monotonic() + self.args.wait_item_timeout
        )
        poll_interval = 10.0  # seconds between checks

        while True:
            items = await self.registered_items()
            match = await self.find_wechat_item(items)
            if match is not None:
                await self.bind_item(match)
                return

            # Exit immediately in --once mode or when timeout is exactly 0.
            if self.args.once or self.args.wait_item_timeout == 0:
                logger.error("未找到微信托盘项。当前托盘项如下：")
                await print_registered_items(self.bus, items, self.keywords)
                logger.error("确认微信已启动且托盘可见，或用 --keywords/--item 指定。")
                raise SystemExit(1)

            # Check deadline when a finite timeout is set.
            if deadline is not None:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    logger.error(
                        "已等待 %.0f 秒仍未找到微信托盘项，退出。",
                        self.args.wait_item_timeout,
                    )
                    await print_registered_items(self.bus, items, self.keywords)
                    raise SystemExit(1)
                wait = min(poll_interval, remaining)
            else:
                wait = poll_interval

            if deadline is None:
                logger.info(
                    "未找到微信托盘项，%d 秒后重试 …",
                    int(wait),
                )
            else:
                logger.info(
                    "未找到微信托盘项，%d 秒后重试 …（剩余 %.0f 秒）",
                    int(wait),
                    remaining,
                )
            await asyncio.sleep(wait)

    async def find_wechat_item(self, items: list[str]) -> SniItem | None:
        if self.args.item:
            return await inspect_sni_item(self.bus, self.args.item)

        candidates: list[tuple[int, SniItem]] = []
        for raw in items:
            try:
                item = await inspect_sni_item(self.bus, raw)
            except Exception as exc:
                logger.debug("跳过无法读取的托盘项 %r: %s", raw, exc)
                continue

            score = item_score(item, self.keywords)
            if score > 0:
                candidates.append((score, item))

        if not candidates:
            return None

        candidates.sort(key=lambda candidate: candidate[0], reverse=True)
        return candidates[0][1]

    async def bind_item(self, item: SniItem) -> None:
        self.item = item
        introspection = await self.bus.introspect(item.bus_name, item.path)
        proxy = self.bus.get_proxy_object(item.bus_name, item.path, introspection)
        self.item_iface = proxy.get_interface(SNI_IFACE)
        self.props_iface = proxy.get_interface(PROPERTIES_IFACE)

        self.item_iface.on_new_status(
            lambda status: asyncio.create_task(self.on_status_signal(status))
        )
        self.item_iface.on_new_attention_icon(
            lambda: asyncio.create_task(self.on_attention_event("NewAttentionIcon"))
        )
        self.item_iface.on_new_icon(
            lambda: asyncio.create_task(self.on_attention_event("NewIcon"))
        )
        self.item_iface.on_new_tool_tip(
            lambda: asyncio.create_task(self.on_attention_event("NewToolTip"))
        )
        self.props_iface.on_properties_changed(
            lambda interface, changed, invalidated: asyncio.create_task(
                self.on_properties_changed(interface, changed, invalidated)
            )
        )

        state = await snapshot_item_state(self.item_iface)
        logger.info("已定位微信托盘: %s", item.raw)
        print(f"已定位微信托盘: {item.raw}")
        print(
            "当前状态: "
            f"id={item.item_id!r}, title={state.title or item.title!r}, "
            f"status={state.status!r}, tooltip={state.tooltip_text or item.tooltip_text!r}"
        )
        print("开始监听微信托盘消息，Ctrl+C 退出。")
        logger.info("开始监听微信托盘消息")

    async def on_item_registered(self, raw: str) -> None:
        if self.item is not None:
            return

        try:
            item = await inspect_sni_item(self.bus, raw)
        except Exception as exc:
            logger.debug("新托盘项无法读取 %r: %s", raw, exc)
            return

        if item_score(item, self.keywords) <= 0:
            return

        print(f"检测到微信托盘重新注册: {raw}")
        logger.info("检测到微信托盘重新注册: %s", raw)
        await self.bind_item(item)

    def on_item_unregistered(self, raw: str) -> None:
        if self.item is None:
            return
        if raw not in {self.item.raw, self.item.bus_name}:
            return

        print(f"微信托盘已注销: {raw}")
        logger.info("微信托盘已注销: %s", raw)
        self.item = None
        self.item_iface = None
        self.props_iface = None
        self.armed = True

    async def on_status_signal(self, status: str) -> None:
        await self.on_attention_event(f"NewStatus:{status}")

    async def on_properties_changed(
        self, interface: str, changed: dict[str, Any], invalidated: list[str]
    ) -> None:
        if interface != SNI_IFACE:
            return

        changed_keys = set(changed)
        invalidated_keys = set(invalidated or [])
        interesting_keys = changed_keys | invalidated_keys

        if not interesting_keys & (ATTENTION_PROPERTIES | ICON_PROPERTIES):
            return

        if interesting_keys & ATTENTION_PROPERTIES:
            source = "PropertiesChanged:" + ",".join(sorted(interesting_keys))
            await self.on_attention_event(source)
            return

        if self.args.icon_change_is_message and interesting_keys & ICON_PROPERTIES:
            source = "PropertiesChanged:" + ",".join(sorted(interesting_keys))
            await self.on_attention_event(source)

    async def on_attention_event(self, source: str) -> None:
        if self.item_iface is None:
            return
        if source == "NewIcon" and not self.args.icon_change_is_message:
            return

        async with self.event_lock:
            now = time.monotonic()
            previous_event_at = self.last_event_at
            self.last_event_at = now

            state = await snapshot_item_state(self.item_iface)
            source_is_icon = source == "NewIcon" or any(
                prop in source for prop in ICON_PROPERTIES
            )
            source_is_attention = (
                "NewAttentionIcon" in source
                or "NewStatus:NeedsAttention" in source
                or any(prop in source for prop in ATTENTION_PROPERTIES)
            )
            event_means_attention = (
                state.has_attention
                or source_is_attention
                or (self.args.icon_change_is_message and source_is_icon)
            )

            logger.debug(
                "event=%r, status=%r, attention_icon=%r, attention_pixmaps=%s, armed=%s",
                source,
                state.status,
                state.attention_icon_name,
                state.attention_pixmap_count,
                self.armed,
            )

            if not event_means_attention:
                self.armed = True
                return

            event_gap = now - previous_event_at if previous_event_at else 999999.0
            quiet_gap_rearmed = event_gap >= self.args.clear_after
            debounce_passed = now - self.last_notify_at >= self.args.debounce
            repeat_due = (
                self.args.repeat_after > 0
                and now - self.last_notify_at >= self.args.repeat_after
            )

            if self.armed or quiet_gap_rearmed or repeat_due:
                if debounce_passed:
                    await self.send_notification(
                        state, repeated=not (self.armed or quiet_gap_rearmed)
                    )
                    self.last_notify_at = now
                self.armed = False

            self.schedule_rearm()

    def schedule_rearm(self) -> None:
        if self.rearm_task is not None:
            self.rearm_task.cancel()

        self.rearm_task = asyncio.create_task(self.rearm_after_idle(self.last_event_at))

    async def rearm_after_idle(self, event_at: float) -> None:
        try:
            await asyncio.sleep(self.args.clear_after)
        except asyncio.CancelledError:
            return

        if self.last_event_at == event_at:
            self.armed = True
            logger.debug("托盘闪烁事件已静止，已重新准备接收下一次消息")

    async def send_notification(self, state: ItemState, repeated: bool) -> None:
        title = self.args.title
        message = self.args.repeat_message if repeated else self.args.message
        if self.args.show_tooltip and state.tooltip_text:
            message = state.tooltip_text

        try:
            await self.send_dbus_notification(title, message)
        except Exception as exc:
            logger.warning("DBus 通知失败，尝试 notify-send 兜底: %s", exc)
            self.send_notify_send(title, message)

        print(f"已发送通知: {title} - {message}")
        logger.info("已发送通知: %s - %s", title, message)

    async def send_dbus_notification(self, title: str, message: str) -> None:
        urgency = {
            "low": 0,
            "normal": 1,
            "critical": 2,
        }[self.args.urgency]

        reply = await self.bus.call(
            Message(
                destination=NOTIFICATIONS_BUS,
                path=NOTIFICATIONS_PATH,
                interface=NOTIFICATIONS_IFACE,
                member="Notify",
                signature="susssasa{sv}i",
                body=[
                    "WeChat",
                    0,
                    "wechat",
                    title,
                    message,
                    [],
                    {"urgency": Variant("y", urgency)},
                    self.args.timeout,
                ],
            )
        )

        if reply.message_type == MessageType.ERROR:
            raise DBusError._from_message(reply)

    def send_notify_send(self, title: str, message: str) -> None:
        cmd = [
            "notify-send",
            "-a",
            "WeChat",
            "-i",
            "wechat",
            "-u",
            self.args.urgency,
            "-t",
            str(self.args.timeout),
            title,
            message,
        ]
        try:
            subprocess.run(cmd, check=False)
        except FileNotFoundError:
            logger.error("找不到 notify-send，无法发送兜底通知。")


async def print_registered_items(
    bus: MessageBus, items: list[str], keywords: tuple[str, ...] = ()
) -> None:
    for raw in items:
        try:
            item = await inspect_sni_item(bus, raw)
            score = item_score(item, keywords) if keywords else 0
            marker = " *" if score > 0 else ""
            print(
                f"{marker} {item.raw}\n"
                f"    bus={item.bus_name}, path={item.path}, id={item.item_id!r}, "
                f"title={item.title!r}, status={item.status!r}, tooltip={item.tooltip_text!r}"
            )
        except Exception as exc:
            print(f"  {raw}\n    无法读取: {exc}")


async def connect_bus(
    bus_address: str | None = None,
    max_wait: float = 30.0,
) -> MessageBus:
    """Connect to the D-Bus session bus, retrying with backoff on failure.

    Under compositor startup the session bus may not be ready immediately.
    """
    retry_at = 0.5
    last_exc: Exception | None = None

    while True:
        try:
            bus = await MessageBus(bus_address=bus_address).connect()
            return bus
        except Exception as exc:
            last_exc = exc
            if retry_at > max_wait:
                break
            logger.warning(
                "D-Bus connection failed (%s), retrying in %.1fs …",
                exc,
                retry_at,
            )
            await asyncio.sleep(retry_at)
            retry_at = min(retry_at * 2, max_wait)

    raise RuntimeError(
        f"Could not connect to D-Bus session bus after {max_wait:.0f}s"
    ) from last_exc


async def list_items(args: argparse.Namespace) -> None:
    bus = await connect_bus(
        bus_address=get_session_bus_address(),
        max_wait=args.connect_timeout,
    )
    introspection = await bus.introspect(WATCHER_BUS, WATCHER_PATH)
    watcher = bus.get_proxy_object(WATCHER_BUS, WATCHER_PATH, introspection)
    watcher_iface = watcher.get_interface(WATCHER_IFACE)
    items = list(await watcher_iface.get_registered_status_notifier_items() or [])
    await print_registered_items(bus, items, tuple(args.keywords))
    bus.disconnect()


async def main() -> None:
    args = parse_args()
    setup_logging(args.log_file, args.debug)

    if args.list:
        await list_items(args)
        return

    bus = await connect_bus(
        bus_address=get_session_bus_address(),
        max_wait=args.connect_timeout,
    )
    notifier = WechatTrayNotifier(bus, args)
    await notifier.start()

    if args.once:
        bus.disconnect()
        return

    await asyncio.Event().wait()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="监听微信 StatusNotifierItem 托盘闪烁，并用 notify-send 发送桌面通知。"
    )
    parser.add_argument(
        "--keywords",
        nargs="+",
        default=["wechat", "微信"],
        help="用于识别微信托盘项的关键词，默认: wechat 微信",
    )
    parser.add_argument(
        "--item",
        help="手动指定托盘项，例如 org.kde.StatusNotifierItem-1316221-1/StatusNotifierItem",
    )
    parser.add_argument("--list", action="store_true", help="列出当前所有托盘项后退出")
    parser.add_argument(
        "--once", action="store_true", help="定位微信托盘项并打印当前状态后退出"
    )
    parser.add_argument(
        "--wait-item-timeout",
        type=float,
        default=-1.0,
        help="启动时等待微信托盘项出现的最大秒数；-1 表示无限等待，0 表示立即退出，默认 -1",
    )
    parser.add_argument("--debug", action="store_true", help="打印收到的托盘事件和状态")
    parser.add_argument(
        "--connect-timeout",
        type=float,
        default=30.0,
        help="D-Bus 连接重试最长时间（秒），默认 30",
    )
    parser.add_argument(
        "--log-file",
        default=None,
        help="日志文件路径，默认不写入文件（仅输出到 stderr）；启动时建议指定以诊断问题",
    )
    parser.add_argument(
        "--debounce",
        type=float,
        default=3.0,
        help="两次 notify-send 之间的最小间隔秒数，默认 3",
    )
    parser.add_argument(
        "--clear-after",
        type=float,
        default=8.0,
        help="托盘事件静止多少秒后重新准备接收下一次消息，默认 8",
    )
    parser.add_argument(
        "--repeat-after",
        type=float,
        default=60.0,
        help="消息未清除且托盘持续闪烁时，最多每多少秒重复提醒一次；设为 0 禁用，默认 60",
    )
    parser.add_argument(
        "--no-icon-change",
        dest="icon_change_is_message",
        action="store_false",
        help="不把微信 IconPixmap/NewIcon 变化当作消息事件，只监听明确的 Attention/Status",
    )
    parser.set_defaults(icon_change_is_message=True)
    parser.add_argument("--title", default="微信新消息", help="通知标题")
    parser.add_argument("--message", default="请查看微信", help="首次通知正文")
    parser.add_argument(
        "--repeat-message", default="微信仍有未读消息", help="重复提醒正文"
    )
    parser.add_argument(
        "--show-tooltip", action="store_true", help="通知正文优先使用托盘 tooltip"
    )
    parser.add_argument(
        "--timeout", type=int, default=5000, help="通知显示毫秒数，默认 5000"
    )
    parser.add_argument(
        "--urgency",
        choices=("low", "normal", "critical"),
        default="critical",
        help="notify-send urgency，默认 normal",
    )
    return parser.parse_args()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n监听已停止")
    except SystemExit:
        raise
    except Exception:
        logger.exception("Fatal error")
        raise
