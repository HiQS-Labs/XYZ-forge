#!/usr/bin/env python3
"""
vscode-color — give a git repo a stable, distinct VS Code background tint.

Two modes:
  Deterministic (default): SHA-256-hash the repo's GitHub slug (owner/name) into a
    hue, then emit a subtle dark-theme palette. Same repo -> same color, every
    session; different repos -> different colors.
  Manual override (--hue / --sat / --lightness): build a specific palette instead of
    the hash. Stamps a "// vscode-repo-tint": "manual" marker at the top of the file,
    and deterministic mode then REFUSES to overwrite that repo unless --force is given.

The palette tints seven surfaces so the window reads as one coherent color, and is
merged into <repo>/.vscode/settings.json under workbench.colorCustomizations,
preserving any other keys already in the file.

Usage:
    vscode-color.py                          # deterministic tint for the cwd's repo
    vscode-color.py --print                  # preview slug + hex, write nothing
    vscode-color.py --light                  # light-theme-tuned variant
    vscode-color.py --hue 240 --sat 0.12     # manual: near-neutral grey, blue tinge
    vscode-color.py --force                  # let the hash overwrite a manual repo
    vscode-color.py --repo /path/to/repo     # target a repo other than the cwd
"""
import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

MARKER_KEY = "// vscode-repo-tint"

# The seven tinted surfaces, derived from three lightness anchors:
#   bg      = editor / active tab background
#   darker  = sidebar / activity bar / panel (slightly recessed)
#   accent  = title bar / status bar (lighter, so chrome reads as a band)
COLOR_KEYS = (
    "editor.background",
    "sideBar.background",
    "activityBar.background",
    "panel.background",
    "tab.activeBackground",
    "titleBar.activeBackground",
    "statusBar.background",
)


def run_git(args, cwd):
    return subprocess.check_output(
        ["git", *args], cwd=str(cwd), text=True, stderr=subprocess.DEVNULL
    ).strip()


def repo_root(start):
    return Path(run_git(["rev-parse", "--show-toplevel"], start))


def repo_slug(root):
    """owner/name from the origin remote, lowercased, .git stripped.

    Falls back to the toplevel folder name (prefixed 'local/') when there is no
    origin remote, so an un-pushed repo still gets a stable, distinct color.
    """
    try:
        url = run_git(["remote", "get-url", "origin"], root)
    except subprocess.CalledProcessError:
        return "local/" + root.name.lower()
    slug = url
    if slug.startswith("git@"):                 # git@github.com:owner/repo.git
        slug = slug.split(":", 1)[1]
    elif "://" in slug:                          # https://github.com/owner/repo.git
        slug = slug.split("://", 1)[1].split("/", 1)[1]
    if slug.endswith(".git"):
        slug = slug[:-4]
    return slug.strip("/").lower()


def hsl_to_hex(h, s, l):
    c = (1 - abs(2 * l - 1)) * s
    x = c * (1 - abs((h / 60) % 2 - 1))
    m = l - c / 2
    r, g, b = {
        0: (c, x, 0), 1: (x, c, 0), 2: (0, c, x),
        3: (0, x, c), 4: (x, 0, c), 5: (c, 0, x),
    }[int(h // 60) % 6]
    return "#{:02x}{:02x}{:02x}".format(
        round((r + m) * 255), round((g + m) * 255), round((b + m) * 255)
    )


def palette(hue, sat, bg_l, accent_l):
    bg = hsl_to_hex(hue, sat, bg_l)
    darker = hsl_to_hex(hue, sat, max(bg_l - 0.03, 0.0))
    accent = hsl_to_hex(hue, sat, accent_l)
    return {
        "editor.background": bg,
        "sideBar.background": darker,
        "activityBar.background": darker,
        "panel.background": darker,
        "tab.activeBackground": bg,
        "titleBar.activeBackground": accent,
        "statusBar.background": accent,
    }


def hash_hsl(slug, light):
    digest = hashlib.sha256(slug.encode()).digest()
    hue = digest[0] / 255 * 360
    sat = 0.30 + (digest[1] / 255) * 0.20       # 0.30-0.50: distinct, not garish
    bg_l, accent_l = (0.94, 0.78) if light else (0.13, 0.22)
    return hue, sat, bg_l, accent_l


def load_settings(path):
    """Read existing settings.json, tolerating JSONC (// comments, trailing commas).

    Returns (data, ok). On an unparseable file ok is False and data is {} so the
    caller can refuse to clobber rather than silently overwrite hand-edited config.
    """
    if not path.exists():
        return {}, True
    raw = path.read_text()
    if not raw.strip():
        return {}, True
    try:
        return json.loads(raw), True
    except json.JSONDecodeError:
        pass
    stripped = re.sub(r"/\*.*?\*/", "", raw, flags=re.S)
    stripped = re.sub(r"(^|\s)//[^\n]*", r"\1", stripped)
    stripped = re.sub(r",(\s*[}\]])", r"\1", stripped)
    try:
        return json.loads(stripped), True
    except json.JSONDecodeError:
        return {}, False


def main():
    p = argparse.ArgumentParser(add_help=True, description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--repo", help="target repo path (default: cwd's git toplevel)")
    p.add_argument("--print", dest="preview", action="store_true",
                   help="print slug + colors, write nothing")
    p.add_argument("--light", action="store_true", help="light-theme-tuned variant")
    p.add_argument("--force", action="store_true",
                   help="let deterministic mode overwrite a manually-tinted repo")
    # Manual-override knobs. Supplying any of these switches to manual mode.
    p.add_argument("--hue", type=float, help="manual hue 0-360")
    p.add_argument("--sat", type=float, help="manual saturation 0-1 (default 0.12)")
    p.add_argument("--lightness", type=float, help="manual editor lightness 0-1")
    p.add_argument("--accent-lightness", type=float,
                   help="manual title/status bar lightness 0-1")
    args = p.parse_args()

    manual = any(v is not None for v in
                 (args.hue, args.sat, args.lightness, args.accent_lightness))

    start = Path(args.repo).resolve() if args.repo else Path.cwd()
    try:
        root = repo_root(start)
    except subprocess.CalledProcessError:
        print(f"vscode-color: {start} is not inside a git repo", file=sys.stderr)
        return 2

    slug = repo_slug(root)

    if manual:
        bg_l = args.lightness if args.lightness is not None else (0.94 if args.light else 0.13)
        if args.accent_lightness is not None:
            accent_l = args.accent_lightness
        elif args.light:
            accent_l = max(bg_l - 0.16, 0.0)
        else:
            accent_l = min(bg_l + 0.09, 1.0)
        hue = args.hue if args.hue is not None else 0.0
        sat = args.sat if args.sat is not None else 0.12
        colors = palette(hue, sat, bg_l, accent_l)
    else:
        colors = palette(*hash_hsl(slug, args.light))

    label = "manual" if manual else "hash"
    if args.preview:
        print(f"{slug}  [{label}]")
        print(json.dumps(colors, indent=2))
        return 0

    settings_path = root / ".vscode" / "settings.json"
    data, ok = load_settings(settings_path)
    if not ok:
        print(f"vscode-color: {settings_path} exists but is not valid JSON/JSONC; "
              f"refusing to overwrite. Fix or remove it, then re-run.", file=sys.stderr)
        return 4

    # Refuse to clobber a hand-picked color with the hash, unless forced.
    if not manual and data.get(MARKER_KEY) == "manual" and not args.force:
        print(f"vscode-color: {slug} is manually tinted (marker present); "
              f"deterministic mode will not overwrite it. Re-run with --force to "
              f"replace it with the hash color.", file=sys.stderr)
        return 3

    if manual:
        data[MARKER_KEY] = "manual"
    elif args.force:
        data.pop(MARKER_KEY, None)              # forced hash clears the manual stamp

    data["workbench.colorCustomizations"] = colors
    settings_path.parent.mkdir(parents=True, exist_ok=True)
    settings_path.write_text(json.dumps(data, indent=2) + "\n")
    print(f"{slug}  [{label}] -> {colors['editor.background']}  ({settings_path})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
