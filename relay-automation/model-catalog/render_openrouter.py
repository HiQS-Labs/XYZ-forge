#!/usr/bin/env python3
"""Render the OpenRouter alias YAML (XYZ-forge relay-automation/openrouter-model-aliases.yml)
from data/catalog.json.

Deterministic order (PROJECT.md schema rules — XYZ's resolver is file-order-wins within tiers):
squash-length of `match` descending, then lexicographic. Output goes to stdout; redirect it over
the vendored copy in XYZ-forge and the drift check demands byte equality.
"""
import json
import re
import sys
from pathlib import Path


def squash(s: str) -> str:
    return re.sub(r"[^a-z0-9]", "", s.lower())


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    catalog_path = root / "data" / "catalog.json"
    argv = sys.argv[1:]
    if "--catalog" in argv:
        # Drift-check mode (XYZ #450): render from a vendored copy instead of this repo's data/.
        catalog_path = Path(argv[argv.index("--catalog") + 1])
    elif argv:
        catalog_path = Path(argv[0])
    catalog = json.loads(catalog_path.read_text())
    rows = [r for r in catalog["aliases"] if r["target"] == "openrouter"]
    rows.sort(key=lambda r: (-len(squash(r["match"])), r["match"]))
    lines = [
        f"# GENERATED from HiQS-Labs/Model-catalog v{catalog['version']} — edit the catalog, not this file.",
        "# Legacy format (GH-120): `alias: canonical-slug`, consumed by resolve-model-alias.sh.",
        "# Regenerate with Model-catalog's scripts/render_openrouter.py --catalog <vendored catalog.json>",
        "#   (run from anywhere; see Model-catalog PROJECT.md Phase 1 for the drift-check recipe).",
    ]
    for r in rows:
        lines.append(f"{r['match']}: {r['replace']}")
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
