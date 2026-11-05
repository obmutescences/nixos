#!/usr/bin/env python3
"""Refresh terminal and desktop themes from Pleamar's wallpaper palette.

Pleamar writes its palette to:
    ~/.config/pleamar-shell/palette.json

The primary/secondary roles are used for the cursor, selection, borders,
tabs, URL colour and the blue/magenta ANSI slots.  Other ANSI slots keep
conventional red/green/yellow/cyan colours so terminal semantics survive.

Run manually:
    pleamar_reload_all.py              # refresh Kitty, omp, fcitx5, Look, niri, templates
    pleamar_reload_all.py --kitty      # one target only
    pleamar_reload_all.py --templates  # btop, fastfetch, Telegram, GTK, KDE, Qt
    pleamar_reload_all.py --btop       # one template only (also --fastfetch/--gtk/--kde/--qt)
    pleamar_reload_all.py --all        # explicit all targets
    pleamar_reload_all.py --print      # show the two leading colours
"""

from __future__ import annotations

import argparse
import colorsys
import json
import math
import os
import re
import shutil
import struct
import subprocess
import sys
import zlib
from pathlib import Path

PALETTE = Path.home() / ".config/pleamar-shell/palette.json"
THEME = Path.home() / ".config/kitty/theme.conf"
OMP_THEME = Path.home() / ".omp/agent/themes/noctalia.json"
LOOK_CONFIG = Path.home() / ".look/config"
FCITX_THEME_DIR = Path.home() / ".local/share/fcitx5/themes/noctalia"
NIRI_MIX = Path.home() / ".config/niri/mix.kdl"
NIRI_NOCTALIA = Path.home() / ".config/niri/noctalia.kdl"
TELEGRAM_TEMPLATE = (
    Path.home() / ".local/state/noctalia/community-templates/telegram/telegram.tdesktop-theme"
)
TELEGRAM_THEME = Path.home() / ".config/telegram-desktop/themes/noctalia.tdesktop-theme"
NOCTALIA_COMMUNITY = Path.home() / ".local/state/noctalia/community-templates"
BTOP_THEME = Path.home() / ".config/btop/themes/noctalia.theme"
FASTFETCH_CONF = Path.home() / ".config/fastfetch/config.jsonc"
FASTFETCH_THEME = Path.home() / ".config/fastfetch/themes/noctalia.jsonc"
GTK3_THEME = Path.home() / ".config/gtk-3.0/noctalia.css"
GTK4_THEME = Path.home() / ".config/gtk-4.0/noctalia.css"
KDE_SCHEME = Path.home() / ".local/share/color-schemes/noctalia.colors"
QT6_THEME = Path.home() / ".config/qt6ct/colors/noctalia.conf"
QT5_THEME = Path.home() / ".config/qt5ct/colors/noctalia.conf"
HEX_RE = re.compile(r"^#[0-9a-fA-F]{6}$")
PLACEHOLDER_RE = re.compile(r"\{\{colors\.([a-z_0-9]+)\.default\.(hex|rgb_csv)\}\}")

# ANSI slots whose exact hues matter for shell/tool semantics.  Pleamar's
# palette does not define them, so use readable defaults unless a future
# palette provides explicit roles.
GREEN = "#78d39a"
YELLOW = "#e7c26b"
CYAN = "#64d2d2"


def log(message: str) -> None:
    print(f"[pleamar-theme] {message}", flush=True)


def as_hex(value) -> str | None:
    if not isinstance(value, str):
        return None
    value = value.strip()
    if len(value) == 4 and value.startswith("#"):
        value = "#" + "".join(ch * 2 for ch in value[1:])
    return value.lower() if HEX_RE.fullmatch(value) else None


def rgb(value: str) -> tuple[float, float, float]:
    return tuple(int(value[i : i + 2], 16) / 255.0 for i in (1, 3, 5))


def hexof(values: tuple[float, float, float]) -> str:
    return "#%02x%02x%02x" % tuple(
        max(0, min(255, round(channel * 255))) for channel in values
    )


def mix(a: str, b: str, amount: float) -> str:
    ar, ag, ab = rgb(a)
    br, bg, bb = rgb(b)
    return hexof(
        (
            ar + (br - ar) * amount,
            ag + (bg - ag) * amount,
            ab + (bb - ab) * amount,
        )
    )


def luminance(value: str) -> float:
    channels = []
    for channel in rgb(value):
        channels.append(
            channel / 12.92
            if channel <= 0.03928
            else ((channel + 0.055) / 1.055) ** 2.4
        )
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


def contrast(a: str, b: str) -> float:
    la, lb = luminance(a), luminance(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def best_text(background: str) -> str:
    dark, light = "#10161a", "#f5f7f5"
    return dark if contrast(dark, background) >= contrast(light, background) else light


def role(palette: dict, *keys: str) -> str | None:
    for key in keys:
        value = as_hex(palette.get(key))
        if value:
            return value
    return None


def build_theme(palette: dict) -> dict[str, str]:
    primary = role(palette, "primary", "aqua", "mint")
    if not primary:
        raise ValueError("palette.json has no primary/aqua colour")

    secondary = role(palette, "secondary", "azure", "tertiary") or primary
    tertiary = role(palette, "tertiary", "secondary") or secondary
    background = (
        role(palette, "surface", "background", "tint", "panel", "deep") or "#10161a"
    )
    foreground = role(palette, "on_surface", "ink", "onSurface") or best_text(
        background
    )
    faint = role(palette, "faint", "on_surface_variant", "onSurfaceVariant") or mix(
        foreground, background, 0.36
    )
    outline = role(palette, "outline") or mix(background, foreground, 0.40)
    surface_variant = role(palette, "surface_variant", "surfaceVariant") or mix(
        background, foreground, 0.12
    )
    error = role(palette, "error", "alert") or "#e76a6a"
    on_primary = role(palette, "on_primary", "onPrimary") or best_text(primary)
    on_secondary = role(palette, "on_secondary", "onSecondary") or best_text(secondary)
    on_tertiary = role(palette, "on_tertiary", "onTertiary") or best_text(tertiary)
    green = role(palette, "success", "green") or GREEN
    yellow = role(palette, "warning", "yellow") or YELLOW
    cyan = role(palette, "info", "cyan") or CYAN

    def bright(color: str) -> str:
        return mix(color, foreground, 0.22)

    return {
        # Base surface
        "foreground": foreground,
        "background": background,
        "selection_foreground": on_primary,
        "selection_background": primary,
        # Cursor
        "cursor": primary,
        "cursor_text_color": on_primary,
        # URLs and borders
        "url_color": secondary,
        "active_border_color": primary,
        "inactive_border_color": outline,
        "bell_border_color": error,
        # Tab bar
        "active_tab_foreground": on_primary,
        "active_tab_background": primary,
        "inactive_tab_foreground": faint,
        "inactive_tab_background": surface_variant,
        "tab_bar_background": background,
        # Marks (Kitty keyboard selection)
        "mark1_foreground": on_primary,
        "mark1_background": primary,
        "mark2_foreground": on_secondary,
        "mark2_background": secondary,
        "mark3_foreground": on_tertiary,
        "mark3_background": tertiary,
        # ANSI normal
        "color0": background,
        "color1": error,
        "color2": green,
        "color3": yellow,
        "color4": primary,
        "color5": secondary,
        "color6": cyan,
        "color7": faint,
        # ANSI bright
        "color8": outline,
        "color9": bright(error),
        "color10": bright(green),
        "color11": bright(yellow),
        "color12": bright(primary),
        "color13": bright(secondary),
        "color14": bright(cyan),
        "color15": foreground,
    }


def render(colors: dict[str, str], palette_path: Path) -> str:
    lines = [
        "# Generated by pleamar-shell from palette.json",
        f"# Source: {palette_path}",
        "# Do not edit manually; the watcher overwrites this file.",
        "",
        "# The basic colors",
    ]
    keys = [
        "foreground",
        "background",
        "selection_foreground",
        "selection_background",
        "",
        "# Cursor colors",
        "cursor",
        "cursor_text_color",
        "",
        "# URL underline color when hovering with mouse",
        "url_color",
        "",
        "# Kitty window border colors",
        "active_border_color",
        "inactive_border_color",
        "bell_border_color",
        "",
        "# Tab bar colors",
        "active_tab_foreground",
        "active_tab_background",
        "inactive_tab_foreground",
        "inactive_tab_background",
        "tab_bar_background",
        "",
        "# Marks",
        "mark1_foreground",
        "mark1_background",
        "mark2_foreground",
        "mark2_background",
        "mark3_foreground",
        "mark3_background",
        "",
        "# The 16 terminal colors",
        "",
        "# black",
        "color0",
        "color8",
        "",
        "# red",
        "color1",
        "color9",
        "",
        "# green",
        "color2",
        "color10",
        "",
        "# yellow",
        "color3",
        "color11",
        "",
        "# blue",
        "color4",
        "color12",
        "",
        "# magenta",
        "color5",
        "color13",
        "",
        "# cyan",
        "color6",
        "color14",
        "",
        "# white",
        "color7",
        "color15",
    ]
    for key in keys:
        if not key:
            lines.append("")
        elif key.startswith("#"):
            lines.append(key)
        elif key in colors:
            lines.append(f"{key:<24} {colors[key]}")
    lines.append("")
    return "\n".join(lines)


def build_omp_vars(palette: dict, colors: dict[str, str]) -> dict[str, str]:
    """Map Pleamar colours onto the vars used by the omp noctalia theme."""
    background = colors["background"]
    foreground = colors["foreground"]
    primary = colors["color4"]
    secondary = colors["color5"]
    error = colors["color1"]
    tertiary = role(palette, "tertiary", "secondary") or secondary
    faint = colors["color7"]
    outline = colors["inactive_border_color"]
    surface_variant = role(palette, "surface_variant", "surfaceVariant") or mix(
        background, foreground, 0.12
    )
    deep = role(palette, "deep") or mix(background, "#000000", 0.55)

    return {
        "bg": background,
        "bgAlt": surface_variant,
        "bgAlt2": mix(background, foreground, 0.04),
        "fg": foreground,
        "fgMuted": faint,
        "accent": primary,
        "accentAlt": secondary,
        "accentDim": mix(primary, background, 0.52),
        "tert": tertiary,
        "err": error,
        "outline": outline,
        "outlineVar": mix(background, primary, 0.28),
        "primaryCont": mix(background, primary, 0.20),
        "errorCont": mix(background, error, 0.20),
        "surfaceLow": mix(background, deep, 0.50),
        "surfaceLowest": deep,
        "primaryFixed": mix(background, primary, 0.38),
        "secondaryFixedDim": mix(secondary, foreground, 0.52),
    }


def sync_omp(palette: dict, colors: dict[str, str], omp_theme: Path) -> bool:
    if not omp_theme.exists():
        log(f"{omp_theme} not found; skipping omp theme")
        return False
    try:
        data = json.loads(omp_theme.read_text(encoding="utf-8"))
        if not isinstance(data, dict) or not isinstance(data.get("vars"), dict):
            raise ValueError("omp theme has no vars object")
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        log(f"cannot update {omp_theme}: {exc}")
        return False

    existing = data["vars"]
    new_vars = build_omp_vars(palette, colors)
    updated = 0
    for key, value in new_vars.items():
        if existing.get(key) != value:
            existing[key] = value
            updated += 1

    content = json.dumps(data, indent=2, ensure_ascii=False) + "\n"
    try:
        old = omp_theme.read_text(encoding="utf-8")
    except OSError:
        old = ""
    # Always write in place, not via rename: omp watches the active theme
    # file and stops repainting when an editor replaces its inode.  A no-op
    # write also re-attaches the watcher after an earlier atomic replacement.
    omp_theme.write_text(content, encoding="utf-8")
    log(f"{omp_theme} refreshed ({updated if content != old else 0} vars changed)")
    return True



def write_if_changed(path: Path, content: str) -> bool:
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        old = path.read_text(encoding="utf-8")
    except OSError:
        old = ""
    if old == content:
        return False
    path.write_text(content, encoding="utf-8")
    return True


# ---------------------------------------------------------------------------
# Shared Material role expansion for Telegram and other template consumers
# ---------------------------------------------------------------------------


def expanded_roles(palette: dict, colors: dict[str, str]) -> dict[str, str]:
    """Fill the Material roles Pleamar does not write, from its own palette."""
    background = colors["background"]
    foreground = colors["foreground"]
    primary = colors["color4"]
    secondary = colors["color5"]
    error = colors["color1"]
    tertiary = role(palette, "tertiary", "secondary") or secondary
    faint = colors["color7"]
    outline = colors["inactive_border_color"]
    surface_variant = role(palette, "surface_variant", "surfaceVariant") or mix(
        background, foreground, 0.12
    )
    deep = role(palette, "deep") or mix(background, "#000000", 0.55)
    surface = role(palette, "surface", "panel", "background") or background
    primary_container = mix(background, primary, 0.25)
    secondary_container = mix(background, secondary, 0.25)
    tertiary_container = mix(background, tertiary, 0.25)
    error_container = mix(background, error, 0.25)

    out = dict(palette)
    defaults = {
        "background": background,
        "on_background": foreground,
        "surface": surface,
        "surface_variant": surface_variant,
        "surface_dim": mix(background, "#000000", 0.25),
        "surface_container": surface_variant,
        "surface_container_high": mix(surface_variant, foreground, 0.08),
        "surface_container_highest": mix(surface_variant, foreground, 0.16),
        "surface_container_low": mix(background, surface_variant, 0.50),
        "surface_container_lowest": deep,
        "on_surface": foreground,
        "on_surface_variant": faint,
        "outline": outline,
        "outline_variant": mix(background, outline, 0.55),
        "primary": primary,
        "on_primary": colors["selection_foreground"],
        "primary_container": primary_container,
        "on_primary_container": best_text(primary_container),
        "primary_fixed_dim": mix(primary, background, 0.35),
        "secondary": secondary,
        "on_secondary": colors["selection_foreground"],
        "secondary_container": secondary_container,
        "on_secondary_container": best_text(secondary_container),
        "tertiary": tertiary,
        "on_tertiary": best_text(tertiary),
        "tertiary_container": tertiary_container,
        "on_tertiary_container": best_text(tertiary_container),
        "error": error,
        "on_error": best_text(error),
        "error_container": error_container,
        "on_error_container": best_text(error_container),
        "shadow": "#000000",
    }
    for key, value in defaults.items():
        if not as_hex(out.get(key)):
            out[key] = value
    return out


def render_template(template: str, roles: dict[str, str]) -> tuple[str, set[str]]:
    missing: set[str] = set()

    def substitute(match: re.Match) -> str:
        role_name, kind = match.group(1), match.group(2)
        value = as_hex(roles.get(role_name))
        if not value:
            missing.add(role_name)
            return match.group(0)
        body = value[1:]
        if kind == "hex":
            return value
        return ",".join(str(int(body[i : i + 2], 16)) for i in (0, 2, 4))

    return PLACEHOLDER_RE.sub(substitute, template), missing


# ---------------------------------------------------------------------------
# Noctalia template outputs (btop / fastfetch / Telegram / GTK / KDE / Qt)
# ---------------------------------------------------------------------------


def _version_key(path: Path) -> tuple[int, ...]:
    match = re.search(r"-noctalia-(\d+(?:\.\d+)*)", str(path))
    if not match:
        return ()
    return tuple(int(part) for part in match.group(1).split("."))


def _builtin_templates(relative: str) -> list[Path]:
    """Find the newest noctalia template installed in the Nix store."""
    found = list(
        Path("/nix/store").glob(
            f"*-noctalia-*/share/noctalia/assets/templates/{relative}"
        )
    )
    return sorted(found, key=_version_key, reverse=True)


def template_targets() -> list[tuple[str, list[Path], Path, str | None]]:
    """(label, template candidates, output path, post-write action)."""
    return [
        ("btop", _builtin_templates("btop/btop.theme"), BTOP_THEME, "btop"),
        (
            "fastfetch",
            [NOCTALIA_COMMUNITY / "fastfetch/fastfetch-colors.jsonc"],
            FASTFETCH_THEME,
            "fastfetch",
        ),
        ("telegram", [TELEGRAM_TEMPLATE], TELEGRAM_THEME, "telegram"),
        (
            "gtk3",
            _builtin_templates("gtk/gtk3.css"),
            GTK3_THEME,
            "gtk",
        ),
        (
            "gtk4",
            _builtin_templates("gtk/gtk4.css"),
            GTK4_THEME,
            "gtk",
        ),
        ("kde", _builtin_templates("kde/kcolorscheme.colors"), KDE_SCHEME, "kde"),
        ("qt6ct", _builtin_templates("qt/qtct.conf"), QT6_THEME, "qt"),
        ("qt5ct", _builtin_templates("qt/qtct.conf"), QT5_THEME, "qt"),
    ]


def reload_btop() -> bool:
    pkill = shutil.which("pkill")
    if not pkill:
        log("pkill not found; btop theme written but not reloaded")
        return False
    proc = subprocess.run(
        [pkill, "-SIGUSR2", "-x", "btop"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    if proc.returncode == 0:
        log("btop theme reloaded (SIGUSR2)")
        return True
    return False


def _nudge_logo(value: str) -> str:
    """Avoid fastfetch's 16-byte truecolor SGR logo bug."""
    body = value[1:]
    channels = [int(body[index : index + 2], 16) for index in (0, 2, 4)]
    if min(channels) >= 100:
        channels[channels.index(min(channels))] = 99
    return "#%02x%02x%02x" % tuple(channels)


def _merge_json(dst: dict, src: dict) -> int:
    changed = 0
    for key, value in src.items():
        if isinstance(value, dict) and isinstance(dst.get(key), dict):
            changed += _merge_json(dst[key], value)
        elif dst.get(key) != value:
            dst[key] = value
            changed += 1
    return changed


def _apply_fastfetch(theme_path: Path) -> int:
    """Merge the logo/display sections into fastfetch's config.jsonc."""
    try:
        theme = json.loads(theme_path.read_text(encoding="utf-8"))
        config = json.loads(FASTFETCH_CONF.read_text(encoding="utf-8"))
    except OSError as exc:
        log(f"cannot read fastfetch config: {exc}")
        return -1
    except ValueError as exc:
        log(f"fastfetch config is not strict JSON; skipping merge: {exc}")
        return -1
    if not isinstance(theme, dict) or not isinstance(config, dict):
        log("fastfetch theme/config has a non-object root; skipping merge")
        return -1

    patch: dict = {}
    for key in ("logo", "display"):
        value = theme.get(key)
        if isinstance(value, dict):
            patch[key] = json.loads(json.dumps(value))
    logo = patch.get("logo")
    if isinstance(logo, dict):
        colors = logo.get("color")
        if isinstance(colors, dict):
            for key, value in colors.items():
                if isinstance(value, str) and HEX_RE.fullmatch(value):
                    colors[key] = _nudge_logo(value)

    changed = _merge_json(config, patch)
    if changed:
        FASTFETCH_CONF.write_text(
            json.dumps(config, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
    return changed


def _check_gtk_imports() -> list[str]:
    bad = []
    for version in ("gtk-3.0", "gtk-4.0"):
        path = Path.home() / ".config" / version / "gtk.css"
        try:
            text = path.read_text(encoding="utf-8")
        except OSError:
            bad.append(str(path))
            continue
        if "noctalia.css" not in text:
            bad.append(str(path))
    return bad


def _parse_kv(text: str) -> dict[tuple[str, str], str]:
    result: dict[tuple[str, str], str] = {}
    section = ""
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("[") and line.endswith("]"):
            section = line
        elif "=" in line and not line.startswith("#"):
            key, _, value = line.partition("=")
            result[(section, key.strip())] = value.strip()
    return result


KDE_SKIP_SECTIONS = ("[Colors:Header][Inactive]",)


def _kde_stale(scheme_path: Path) -> bool:
    try:
        config = _parse_kv((Path.home() / ".config/kdeglobals").read_text())
        scheme = _parse_kv(scheme_path.read_text())
    except OSError:
        return True
    if config.get(("[General]", "ColorScheme")) != "noctalia":
        return True
    return any(
        config.get(key) not in (None, value)
        for key, value in scheme.items()
        if key[1] != "ColorScheme" and key[0] not in KDE_SKIP_SECTIONS
    )


def _apply_kde(scheme_path: Path) -> str | None:
    """Apply the generated KDE colour scheme when it is not already active."""
    if not shutil.which("plasma-apply-colorscheme"):
        log("plasma-apply-colorscheme not found; KDE scheme written only")
        return None
    if not _kde_stale(scheme_path):
        return None

    kdeglobals = Path.home() / ".config/kdeglobals"
    try:
        text = kdeglobals.read_text(encoding="utf-8")
    except OSError:
        text = ""
    keep = [
        line
        for line in text.splitlines()
        if not line.startswith(("ColorScheme=", "ColorSchemeHash="))
    ]
    kdeglobals.write_text("\n".join(keep).rstrip("\n") + "\n", encoding="utf-8")

    proc = subprocess.run(
        ["plasma-apply-colorscheme", "noctalia"],
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        log(
            "plasma-apply-colorscheme failed: "
            f"{(proc.stderr or proc.stdout).strip()}"
        )
        return None
    return "KDE colour scheme applied"


def sync_templates(
    palette: dict,
    colors: dict[str, str],
    names: set[str] | None = None,
    reload: bool = True,
) -> bool:
    """Render noctalia template products from the Pleamar palette.

    A target is skipped when its template is missing or when a placeholder
    role cannot be resolved, so a half-rendered theme is never written.
    """
    roles = expanded_roles(palette, colors)
    done = 0
    for label, templates, output, action in template_targets():
        if names is not None and label not in names:
            continue
        template = next((path for path in templates if path.exists()), None)
        if template is None:
            log(f"{label} template not found; skipping")
            continue
        try:
            text = template.read_text(encoding="utf-8")
        except OSError as exc:
            log(f"cannot read {label} template: {exc}")
            continue
        rendered, missing = render_template(text, roles)
        if missing:
            log(f"{label} skipped; palette lacks roles: {sorted(missing)}")
            continue

        changed = write_if_changed(output, rendered)
        notes: list[str] = []
        if action == "btop":
            if changed and reload and reload_btop():
                notes.append("reloaded")
        elif action == "fastfetch":
            merged = _apply_fastfetch(output)
            if merged > 0:
                notes.append(f"merged {merged} config keys")
        elif action == "gtk" and changed:
            bad = _check_gtk_imports()
            if bad:
                notes.append("missing import noctalia.css: " + ", ".join(bad))
        elif action == "kde" and reload:
            note = _apply_kde(output)
            if note:
                notes.append(note)
        elif action == "qt" and changed:
            notes.append("restart Qt apps to apply")
        elif action == "telegram" and changed:
            notes.append("reselect the theme in Telegram")

        state = "updated" if changed else "unchanged"
        tail = f" ({', '.join(notes)})" if notes else ""
        log(f"{label}: {state}{tail} -> {output}")
        done += 1
    return done > 0


# ---------------------------------------------------------------------------
# fcitx5 theme
# ---------------------------------------------------------------------------

FCITX_CONF = """# 由 pleamar_reload_all.py 从 Pleamar palette.json 自动生成, 手改会被覆盖。
# 来源: {source}
# 背景={bg} 副色={secondary} 选择框={highlight_bg}
[Metadata]
Name=noctalia
Version=1.0
Author=Noctalia Community
Description=Pleamar Material You theme for Fcitx5 (dynamic)
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


def _hexv(value: str) -> tuple[int, int, int]:
    return int(value[1:3], 16), int(value[3:5], 16), int(value[5:7], 16)


def _from_hls(h: float, lightness: float, saturation: float) -> str:
    r, g, b = colorsys.hls_to_rgb(h, lightness, saturation)
    return "#%02X%02X%02X" % tuple(round(v * 255) for v in (r, g, b))


def _hsla(value: str, lightness: int, alpha: float) -> str:
    h, _, s = colorsys.rgb_to_hls(*rgb(value))
    return f"hsla({h * 360:.0f}, {min(1.0, s + 0.2) * 100:.0f}%, {lightness}%, {alpha})"


def _png_chunk(kind: bytes, data: bytes) -> bytes:
    chunk = struct.pack(">I", len(data)) + kind + data
    return chunk + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)


def _write_png(path: Path, width: int, height: int, rgba: bytearray) -> None:
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        raw += rgba[y * width * 4 : (y + 1) * width * 4]
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + _png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + _png_chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + _png_chunk(b"IEND", b"")
    )


def _rrect_sdf(px: float, py: float, cx: float, cy: float, hw: float, hh: float, r: float) -> float:
    qx = abs(px - cx) - (hw - r)
    qy = abs(py - cy) - (hh - r)
    ax, ay = max(qx, 0.0), max(qy, 0.0)
    return math.hypot(ax, ay) + min(max(qx, qy), 0.0) - r


def _coverage(sdf: float) -> float:
    return min(max(0.5 - sdf, 0.0), 1.0)


def _fcitx_rounded(path: Path, color: str, radius: float) -> None:
    n = 128
    cr, cg, cb = _hexv(color)
    center = (n - 1) / 2.0
    buf = bytearray(n * n * 4)
    for y in range(n):
        for x in range(n):
            alpha = _coverage(_rrect_sdf(x + 0.5, y + 0.5, center, center, center, center, radius))
            at = (y * n + x) * 4
            buf[at], buf[at + 1], buf[at + 2] = cr, cg, cb
            buf[at + 3] = round(alpha * 255)
    _write_png(path, n, n, buf)


def _fcitx_bordered(path: Path, border_color: str, fill_color: str, radius: float, border: float) -> None:
    n = 128
    br, bg_, bb = _hexv(border_color)
    fr, fg, fb = _hexv(fill_color)
    center = (n - 1) / 2.0
    hw_in = center - border
    r_in = radius - border
    buf = bytearray(n * n * 4)
    for y in range(n):
        for x in range(n):
            a_out = _coverage(_rrect_sdf(x + 0.5, y + 0.5, center, center, center, center, radius))
            a_in = _coverage(_rrect_sdf(x + 0.5, y + 0.5, center, center, hw_in, hw_in, r_in))
            a = a_in + a_out * (1.0 - a_in)
            at = (y * n + x) * 4
            if a > 0:
                buf[at] = round((fr * a_in + br * a_out * (1.0 - a_in)) / a)
                buf[at + 1] = round((fg * a_in + bg_ * a_out * (1.0 - a_in)) / a)
                buf[at + 2] = round((fb * a_in + bb * a_out * (1.0 - a_in)) / a)
            buf[at + 3] = round(a * 255)
    _write_png(path, n, n, buf)


def reload_fcitx() -> None:
    # fcitx5 belongs to niri (`spawn-at-startup "fcitx5" ...`).  Do not replace
    # it with a systemd-run transient unit: that takes ownership away from
    # niri and leaves a pleamar-fcitx.service behind.  `-r` asks the running
    # daemon to reread its configuration in place.  The classicui PNG cache
    # may retain the previous panel until fcitx is restarted by its owner.
    remote = shutil.which("fcitx5-remote")
    if not remote:
        log("fcitx5-remote not found; theme written but not reloaded")
        return
    subprocess.run(
        [remote, "-r"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    #  ReloadConfig only rereads the config files.  classicui also keeps the
    #  decoded theme images in memory, so changing panel.png under the same
    #  theme name otherwise waits for the next fcitx start.  Reload that one
    #  addon explicitly, leaving the daemon itself owned by niri.
    for command in (
        ["gdbus", "call", "--session", "--dest", "org.fcitx.Fcitx5",
         "--object-path", "/controller", "--method",
         "org.fcitx.Fcitx.Controller1.ReloadAddonConfig", "classicui"],
        ["busctl", "--user", "call", "org.fcitx.Fcitx5", "/controller",
         "org.fcitx.Fcitx.Controller1", "ReloadAddonConfig", "s", "classicui"],
        ["qdbus", "org.fcitx.Fcitx5", "/controller",
         "org.fcitx.Fcitx.Controller1.ReloadAddonConfig", "classicui"],
    ):
        if shutil.which(command[0]):
            subprocess.run(
                command,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                check=False,
            )
            break
    log("fcitx5 config and classicui theme reload requested (daemon left to niri)")


def sync_fcitx(colors: dict[str, str], palette_path: Path, reload: bool = True) -> bool:
    accent = colors["color4"]
    secondary = colors["color5"]
    outline = colors["inactive_border_color"]
    h, _, s = colorsys.rgb_to_hls(*rgb(accent))
    background = _from_hls(h, 0.20, s)
    highlight = _from_hls(h, 0.16, s)
    theme_dir = FCITX_THEME_DIR
    theme_dir.mkdir(parents=True, exist_ok=True)
    _fcitx_rounded(theme_dir / "panel.png", background, 10)
    _fcitx_rounded(theme_dir / "highlight.png", highlight, 8)
    _fcitx_bordered(theme_dir / "menu_panel.png", accent, background, 10, 2)
    content = FCITX_CONF.format(
        source=palette_path,
        bg=background,
        secondary=secondary.upper(),
        highlight_bg=highlight,
        outline=outline.upper(),
    )
    changed = write_if_changed(theme_dir / "theme.conf", content)
    log(f"fcitx5: {'updated' if changed else 'unchanged'} ({theme_dir})")
    if reload:
        reload_fcitx()
    return True


# ---------------------------------------------------------------------------
# Look launcher theme
# ---------------------------------------------------------------------------


def reload_look() -> None:
    lookapp = shutil.which("lookapp")
    if not lookapp:
        log("lookapp not found; config written but not reloaded")
        return
    proc = subprocess.run(
        [lookapp, "reload-config"], capture_output=True, text=True, check=False
    )
    output = (proc.stdout or "") + (proc.stderr or "")
    if "not running" in output.lower():
        subprocess.Popen(
            [lookapp],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        log("lookapp was not running; started with the new config")
    elif proc.returncode != 0:
        log(f"lookapp reload-config failed ({proc.returncode}): {output.strip()}")
    else:
        log("lookapp reload-config applied")


def sync_look(colors: dict[str, str], reload: bool = True) -> bool:
    path = LOOK_CONFIG
    if not path.exists():
        log(f"Look config not found: {path}")
        return False
    primary = colors["color4"]
    tint = tuple(round(v * 0.2, 3) for v in rgb(primary))
    font = tuple(round(v, 3) for v in rgb(primary))
    updates = {
        "ui_theme": "custom",
        "ui_tint_red": tint[0],
        "ui_tint_green": tint[1],
        "ui_tint_blue": tint[2],
        "ui_font_red": font[0],
        "ui_font_green": font[1],
        "ui_font_blue": font[2],
        "ui_border_red": font[0],
        "ui_border_green": font[1],
        "ui_border_blue": font[2],
    }
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        log(f"cannot read Look config: {exc}")
        return False
    lines: list[str] = []
    seen: set[str] = set()
    for line in text.splitlines():
        if "=" in line and not line.lstrip().startswith("#"):
            key = line.split("=", 1)[0].strip()
            if key in updates:
                lines.append(f"{key}={updates[key]}")
                seen.add(key)
                continue
        lines.append(line)
    for key, value in updates.items():
        if key not in seen:
            lines.append(f"{key}={value}")
    changed = write_if_changed(path, "\n".join(lines) + "\n")
    log(
        f"look: {'updated' if changed else 'unchanged'} "
        f"tint={primary}*0.2, font={primary}"
    )
    if reload:
        reload_look()
    return True


# ---------------------------------------------------------------------------
# niri window colours
# ---------------------------------------------------------------------------


def _kdl_stack_matches(stack: list[str], ancestors: tuple[str, ...]) -> bool:
    if not ancestors:
        return True
    if len(stack) < len(ancestors):
        return False
    return tuple(stack[-len(ancestors) :]) == ancestors


def kdl_rewrite(
    text: str,
    rules: list[tuple[tuple[str, ...], str, str]],
    values: dict[str, str],
) -> str:
    stack: list[str] = []
    out: list[str] = []
    for line in text.splitlines(keepends=True):
        stripped = line.strip()
        if not stripped or stripped.startswith("//"):
            out.append(line)
            continue
        opened = None
        match = re.match(r"^([A-Za-z0-9_-]+)\s*\{", stripped)
        if match:
            opened = match.group(1)
            stack.append(opened)
        prop = re.match(r'^([A-Za-z0-9_-]+)\s+"[^"]*"', stripped)
        if prop:
            key = prop.group(1)
            for ancestors, rule_key, spec in rules:
                if key == rule_key and _kdl_stack_matches(stack, ancestors):
                    out.append(
                        re.sub(
                            rf'^(\s*)({re.escape(key)})\s+"[^"]*"',
                            rf'\1\2 "{values[spec]}"',
                            line,
                            count=1,
                        )
                    )
                    break
            else:
                out.append(line)
        else:
            out.append(line)
        closes = stripped.count("}")
        if closes:
            for _ in range(closes - (1 if opened else 0)):
                if stack:
                    stack.pop()
    return "".join(out)


NIRI_MIX_RULES = [
    (("layout", "shadow"), "color", "active"),
    (("window-rule", "shadow"), "inactive-color", "hsla"),
    (("window-picker", "label"), "text-color", "active"),
    (("window-picker", "label"), "background-color", "label_hsla"),
    (("window-picker", "label"), "border-color", "active"),
    (("window-picker", "card", "info"), "title-color", "active"),
    (("window-picker", "card", "info"), "app-id-color", "secondary_alpha"),
    (("window-picker", "card", "info"), "workspace-color", "secondary_alpha"),
    (("window-picker", "selection"), "focused-color", "secondary"),
    (("window-picker", "selection"), "hover-color", "secondary"),
    (("overview",), "backdrop-color", "b_hsla"),
]
NIRI_NOCTALIA_RULES = [
    (("layout", "focus-ring"), "active-color", "hsla"),
    (("layout", "focus-ring"), "inactive-color", "hsla"),
    (("layout", "border"), "active-color", "hsla"),
    (("layout", "border"), "inactive-color", "hsla"),
    (("layout", "tab-indicator"), "active-color", "hsla"),
    (("layout", "tab-indicator"), "inactive-color", "hsla"),
    (("recent-windows", "highlight"), "active-color", "hsla"),
]


def reload_niri() -> None:
    niri = shutil.which("niri")
    if not niri:
        log("niri not found; colours written but config not reloaded")
        return
    proc = subprocess.run(
        [niri, "msg", "action", "load-config-file"],
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        log(f"niri reload failed: {(proc.stderr or proc.stdout).strip()}")
    else:
        log("niri config reloaded")


def sync_niri(colors: dict[str, str], reload: bool = True) -> bool:
    if not NIRI_MIX.exists() or not NIRI_NOCTALIA.exists():
        log("niri mix.kdl or noctalia.kdl not found; skipping")
        return False
    primary = colors["color4"]
    secondary = colors["color5"]
    values = {
        "active": primary,
        "secondary": secondary,
        "secondary_alpha": f"{secondary}d0",
        "hsla": _hsla(primary, 45, 0.3),
        "b_hsla": _hsla(primary, 10, 0.3),
        "label_hsla": _hsla(primary, 10, 0.3),
    }
    changed = False
    for path, rules in ((NIRI_MIX, NIRI_MIX_RULES), (NIRI_NOCTALIA, NIRI_NOCTALIA_RULES)):
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as exc:
            log(f"cannot read {path}: {exc}")
            continue
        rendered = kdl_rewrite(text, rules, values)
        if write_if_changed(path, rendered):
            changed = True
    log(f"niri: {'updated' if changed else 'unchanged'} (primary={primary})")
    if reload:
        reload_niri()
    return True


def reload_kitty() -> None:
    pkill = shutil.which("pkill")
    if not pkill:
        log("pkill not found; skipping Kitty reload")
        return
    # NixOS wraps Kitty as ".kitty-wrapped"; distro packages may expose it
    # as "kitty".  Signal both names, but never a pattern: kitten helpers
    # also contain the word kitty and must not receive the signal.
    for name in ("kitty", ".kitty-wrapped"):
        subprocess.run(
            [pkill, "-USR1", "-x", name],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )


def write_theme(theme_path: Path, content: str) -> bool:
    theme_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        old = theme_path.read_text(encoding="utf-8")
    except OSError:
        old = ""
    if old == content:
        return False
    temporary = theme_path.with_name(f".{theme_path.name}.tmp")
    temporary.write_text(content, encoding="utf-8")
    os.replace(temporary, theme_path)
    return True


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Sync Kitty colours from Pleamar")
    parser.add_argument("--all", action="store_true", help="refresh every target")
    parser.add_argument("--kitty", action="store_true", help="refresh Kitty")
    parser.add_argument(
        "--omp", action="store_true", help="refresh the omp noctalia theme"
    )
    parser.add_argument("--fcitx5", action="store_true", help="refresh the fcitx5 theme")
    parser.add_argument("--look", action="store_true", help="refresh the Look launcher")
    parser.add_argument(
        "--telegram", action="store_true", help="refresh the Telegram theme file"
    )
    parser.add_argument(
        "--templates",
        action="store_true",
        help="refresh btop/fastfetch/Telegram/GTK/KDE/Qt template outputs",
    )
    parser.add_argument("--btop", action="store_true", help="refresh the btop theme")
    parser.add_argument(
        "--fastfetch", action="store_true", help="refresh the fastfetch theme"
    )
    parser.add_argument(
        "--gtk", action="store_true", help="refresh the GTK3/GTK4 themes"
    )
    parser.add_argument(
        "--kde", action="store_true", help="refresh the KDE colour scheme"
    )
    parser.add_argument("--qt", action="store_true", help="refresh the Qt colour files")
    parser.add_argument("--niri", action="store_true", help="refresh niri window colours")
    parser.add_argument("--palette", type=Path, default=PALETTE)
    parser.add_argument("--theme", type=Path, default=THEME)
    parser.add_argument("--omp-theme", type=Path, default=OMP_THEME)
    parser.add_argument(
        "--print",
        dest="print_only",
        action="store_true",
        help="print primary/secondary",
    )
    parser.add_argument(
        "--no-reload",
        action="store_true",
        help="write theme files without restarting apps",
    )
    args = parser.parse_args(argv)

    palette_path = args.palette.expanduser()
    theme_path = args.theme.expanduser()
    try:
        palette = json.loads(palette_path.read_text(encoding="utf-8"))
        if not isinstance(palette, dict):
            raise ValueError("palette root is not an object")
        colors = build_theme(palette)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"warning: cannot read {palette_path}: {exc}", file=sys.stderr)
        return 1

    if args.print_only:
        print(
            f"primary={colors['color4']} secondary={colors['color5']} "
            f"background={colors['background']}"
        )
        return 0

    requested = any(
        (
            args.kitty,
            args.omp,
            args.fcitx5,
            args.look,
            args.telegram,
            args.templates,
            args.btop,
            args.fastfetch,
            args.gtk,
            args.kde,
            args.qt,
            args.niri,
        )
    )
    all_actions = args.all or not requested
    do_kitty = args.kitty or all_actions
    do_omp = args.omp or all_actions
    do_fcitx = args.fcitx5 or all_actions
    do_look = args.look or all_actions
    do_niri = args.niri or all_actions

    template_names: set[str] = set()
    if args.templates or all_actions:
        template_names = {
            "btop",
            "fastfetch",
            "telegram",
            "gtk3",
            "gtk4",
            "kde",
            "qt6ct",
            "qt5ct",
        }
    else:
        if args.btop:
            template_names.add("btop")
        if args.fastfetch:
            template_names.add("fastfetch")
        if args.telegram:
            template_names.add("telegram")
        if args.gtk:
            template_names.update(("gtk3", "gtk4"))
        if args.kde:
            template_names.add("kde")
        if args.qt:
            template_names.update(("qt6ct", "qt5ct"))

    if do_kitty:
        content = render(colors, palette_path)
        changed = write_theme(theme_path, content)
        if not args.no_reload:
            reload_kitty()
        log(
            f"{theme_path} {'updated' if changed else 'unchanged'} "
            f"(primary={colors['color4']}, secondary={colors['color5']})"
        )
    if do_omp:
        sync_omp(palette, colors, args.omp_theme.expanduser())
    if do_fcitx:
        sync_fcitx(colors, palette_path, reload=not args.no_reload)
    if do_look:
        sync_look(colors, reload=not args.no_reload)
    if template_names:
        sync_templates(palette, colors, template_names, reload=not args.no_reload)
    if do_niri:
        sync_niri(colors, reload=not args.no_reload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
