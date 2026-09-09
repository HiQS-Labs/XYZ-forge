from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "web" / "flightdeck" / "design-tokens.json"
OUTPUT = ROOT / "web" / "flightdeck" / "tokens.css"


def _variables(values: dict[str, str], prefix: str = "") -> str:
    return "\n".join(f"  --{prefix}{name}: {value};" for name, value in values.items())


def render(source: Path = SOURCE) -> str:
    data = json.loads(source.read_text(encoding="utf-8"))
    required = {"schema_version", "fonts", "scale", "breakpoints", "dark", "light"}
    if set(data) != required or data["schema_version"] != 1:
        raise ValueError("token schema must contain exactly the v1 token families")
    for family in required - {"schema_version"}:
        if not isinstance(data[family], dict) or not data[family]:
            raise ValueError(f"token family {family} must be a non-empty object")
        if any(not isinstance(name, str) or not isinstance(value, str) or not value.strip() for name, value in data[family].items()):
            raise ValueError(f"token family {family} contains an invalid scalar")
    if set(data["dark"]) != set(data["light"]):
        raise ValueError("light and dark semantic token keys must match")
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    dark = _variables(data["dark"], "color-")
    light = _variables(data["light"], "color-")
    shared = _variables(data["fonts"], "font-") + "\n" + _variables(data["scale"])
    compact = data["breakpoints"]["compact"]
    wide = data["breakpoints"]["wide"]
    return f"""/* generated from design-tokens.json sha256:{digest}; do not edit */
:root {{
{shared}
{dark}
  color-scheme: dark;
}}
:root[data-theme="light"] {{
{light}
  color-scheme: light;
}}
@media (prefers-color-scheme: light) {{
  :root:not([data-theme="dark"]) {{
{light}
    color-scheme: light;
  }}
}}
@media (max-width: {compact}) {{
  :root {{ --card-width: var(--compact-card-width); --focus-card-width: var(--compact-card-width); --card-min-height: var(--compact-card-min-height); }}
  .topbar {{ align-items: flex-start; padding: var(--space-4); }}
  .countdown {{ display: none; }}
  .controls {{ flex-wrap: wrap; justify-content: flex-end; }}
  .repo-grid {{ grid-template-columns: 1fr; padding: 0 var(--space-4) var(--space-4); }}
  .source-strip {{ padding-left: var(--space-4); }}
  .repo-card {{ min-height: auto; padding: var(--space-4); }}
}}
@media (min-width: {wide}) {{
  :root {{ --card-width: var(--wide-card-width); }}
}}
@media (prefers-reduced-motion: reduce) {{
  :root {{ --motion-fast: 0ms; --motion-normal: 0ms; }}
}}
"""


def audit_css(css: str) -> list[str]:
    findings: list[str] = []
    if re.search(r"#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(", css):
        findings.append("raw color literal")
    typography = re.findall(r"font-(?:family|size)\s*:\s*([^;}]+)", css)
    if any(not value.strip().startswith("var(") for value in typography):
        findings.append("raw typography literal")
    return findings


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Generate Flightdeck CSS tokens")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args(argv)
    rendered = render()
    app_css = ROOT.joinpath("web", "flightdeck", "app.css").read_text(encoding="utf-8")
    findings = audit_css(app_css)
    if findings:
        print("token audit failed: " + ", ".join(findings))
        return 1
    if args.check:
        if not OUTPUT.is_file() or OUTPUT.read_text(encoding="utf-8") != rendered:
            print("tokens.css is stale; run python3 -m src.flightdeck.tokens")
            return 1
        return 0
    OUTPUT.write_text(rendered, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
