#!/usr/bin/env python3
"""model_catalog.py (GH-450) — the vendored Model-catalog pin: read it, verify it, re-render it.

What this closes. `relay-automation/openrouter-model-aliases.yml` used to be a hand-appended table
(GH-120): add a line, add a test assertion, hope the other consumer of the same fact (AEGIS-Sleuth)
gets the same correction. HiQS-Labs/Model-catalog is now the pin of record for model aliases, and
this repo consumes it the decided way (Model-catalog PROJECT.md Phase 1 — do not re-litigate):

  * `relay-automation/model-catalog/catalog.json` is a BYTE-IDENTICAL vendored copy of the
    catalog at one git tag;
  * `relay-automation/model-catalog/catalog.pin.json` records that tag and the sha256 of the
    copy (plus the renderer's), so CI can see the copy<->upstream edge no drift check can;
  * `relay-automation/model-catalog/render_openrouter.py` is the catalog repo's own renderer,
    vendored at a pinned commit, because the drift check must run on a hosted runner with no
    sibling checkout;
  * `relay-automation/openrouter-model-aliases.yml` is GENERATED from the vendored copy by that
    renderer. `resolve-model-alias.sh` is untouched: it still reads the legacy `alias: slug`
    lines, and nothing in Bash parses JSON (GH-551 adjacency).

Adding a model is therefore two PRs: a row in Model-catalog (tagged), then a sync PR here
(`pin --tag`, `render`, `check`). A hand-appended YAML line is exactly what `check` turns red.

CLI:
    python3 utils/py/model_catalog.py check   [--root DIR]   pin sha256s + YAML drift; exit 1 on any
    python3 utils/py/model_catalog.py render  [--root DIR]   rewrite the YAML from the vendored copy
    python3 utils/py/model_catalog.py version [--root DIR]   print the vendored catalog's version
    python3 utils/py/model_catalog.py pin --tag vX.Y.Z --tag-commit SHA [--renderer-commit SHA]
                                                              rewrite the pin record from the files
                                                              on disk (the sync-PR step)

Library: `catalog_version(root)` never raises and returns None when the copy is missing or
unreadable — telemetry must never fail a turn because a data file did (GH-346 Phase 0 lesson).
"""

import argparse
import hashlib
import json
import os
import subprocess
import sys
from typing import Any, Dict, List, Optional

CATALOG_DIR_REL = os.path.join("relay-automation", "model-catalog")
CATALOG_REL = os.path.join(CATALOG_DIR_REL, "catalog.json")
PIN_REL = os.path.join(CATALOG_DIR_REL, "catalog.pin.json")
RENDERER_REL = os.path.join(CATALOG_DIR_REL, "render_openrouter.py")
YAML_REL = os.path.join("relay-automation", "openrouter-model-aliases.yml")

UPSTREAM_REPO = "HiQS-Labs/Model-catalog"

# The renderer is a small pure-Python script over a 60-row file; anything near this is a hang.
RENDER_TIMEOUT_S = 30


def default_root() -> str:
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def catalog_path(root: str) -> str:
    return os.path.join(root, CATALOG_REL)


def pin_path(root: str) -> str:
    return os.path.join(root, PIN_REL)


def renderer_path(root: str) -> str:
    return os.path.join(root, RENDERER_REL)


def yaml_path(root: str) -> str:
    return os.path.join(root, YAML_REL)


def sha256_file(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def load_catalog(root: str) -> Dict[str, Any]:
    with open(catalog_path(root), "r", encoding="utf-8") as f:
        return json.load(f)


def load_pin(root: str) -> Dict[str, Any]:
    with open(pin_path(root), "r", encoding="utf-8") as f:
        return json.load(f)


def catalog_version(root: Optional[str] = None) -> Optional[str]:
    """The vendored catalog's `version` field, or None. Never raises."""
    try:
        v = load_catalog(root or default_root()).get("version")
        return str(v) if v else None
    except Exception:
        return None


def render_yaml(root: str) -> bytes:
    """Render the YAML from the vendored copy with the vendored renderer, as bytes."""
    r = subprocess.run(
        [sys.executable or "python3", renderer_path(root), "--catalog", catalog_path(root)],
        capture_output=True,
        check=False,
        timeout=RENDER_TIMEOUT_S,
    )
    if r.returncode != 0:
        raise RuntimeError(
            f"renderer exited {r.returncode}: {r.stderr.decode('utf-8', 'replace').strip()[-300:]}"
        )
    return r.stdout


def check_pin(root: str) -> List[str]:
    """Every way the vendored copy can disagree with its pin record, as human-readable problems."""
    problems: List[str] = []
    for rel in (CATALOG_REL, PIN_REL, RENDERER_REL, YAML_REL):
        if not os.path.isfile(os.path.join(root, rel)):
            problems.append(f"missing: {rel}")
    if problems:
        return problems

    try:
        pin = load_pin(root)
    except Exception as e:  # noqa: BLE001 — every parse failure is one named problem
        return [f"{PIN_REL}: unreadable ({e})"]
    try:
        catalog = load_catalog(root)
    except Exception as e:  # noqa: BLE001
        return [f"{CATALOG_REL}: unreadable ({e})"]

    for key in ("repo", "tag", "tag_commit", "version", "catalog_sha256",
                "renderer_sha256", "renderer_commit"):
        if not pin.get(key):
            problems.append(f"{PIN_REL}: missing field {key!r}")
    if problems:
        return problems

    got = sha256_file(catalog_path(root))
    if got != pin["catalog_sha256"]:
        problems.append(
            f"catalog sha256 mismatch: {CATALOG_REL} is {got[:12]}…, pin record says "
            f"{pin['catalog_sha256'][:12]}… ({pin['repo']} {pin['tag']}) — the vendored copy is "
            f"not byte-identical to the pinned tag; re-vendor from the tag or re-pin deliberately"
        )
    got = sha256_file(renderer_path(root))
    if got != pin["renderer_sha256"]:
        problems.append(
            f"renderer sha256 mismatch: {RENDERER_REL} is {got[:12]}…, pin record says "
            f"{pin['renderer_sha256'][:12]}… — the vendored renderer drifted from the pinned commit"
        )
    if str(catalog.get("version")) != str(pin["version"]):
        problems.append(
            f"version mismatch: {CATALOG_REL} says {catalog.get('version')!r}, pin record says "
            f"{pin['version']!r}"
        )
    return problems


def check_drift(root: str) -> List[str]:
    """The committed YAML must be byte-identical to a fresh render of the vendored copy."""
    try:
        fresh = render_yaml(root)
    except Exception as e:  # noqa: BLE001
        return [f"render failed: {e}"]
    with open(yaml_path(root), "rb") as f:
        committed = f.read()
    if fresh == committed:
        return []
    fresh_lines = fresh.decode("utf-8", "replace").splitlines()
    committed_lines = committed.decode("utf-8", "replace").splitlines()
    only_committed = [line for line in committed_lines if line not in fresh_lines]
    only_fresh = [line for line in fresh_lines if line not in committed_lines]
    detail = []
    if only_committed:
        detail.append("committed-only: " + "; ".join(only_committed[:3]))
    if only_fresh:
        detail.append("render-only: " + "; ".join(only_fresh[:3]))
    return [
        (
            f"drift: {YAML_REL} is not byte-identical to a render of {CATALOG_REL} "
            f"({' | '.join(detail) or 'byte-level difference'}) — this file is GENERATED; change the "
            f"catalog and run `python3 utils/py/model_catalog.py render`, never hand-edit the YAML"
        )
    ]


def check(root: str) -> List[str]:
    """Pin problems AND drift problems, together: a flipped row in the vendored copy is both a
    sha mismatch and a render that no longer matches the committed YAML, and the operator should
    see both edges in one run rather than fix one and discover the other."""
    problems = check_pin(root)
    if any(pr.startswith("missing: ") or "unreadable" in pr for pr in problems):
        return problems
    return problems + check_drift(root)


def write_pin(root: str, tag: str, tag_commit: str, renderer_commit: Optional[str],
              vendored_on: Optional[str], expect_sha256: Optional[str] = None) -> Dict[str, Any]:
    catalog = load_catalog(root)
    existing: Dict[str, Any] = {}
    if os.path.isfile(pin_path(root)):
        try:
            existing = load_pin(root)
        except Exception:  # noqa: BLE001 — a corrupt pin is simply rewritten
            existing = {}
    # A pin is never self-certifying (mirrors AEGIS-Sleuth's sync rule, PR #180 review): moving to
    # a NEW tag records whatever bytes are on disk as "the tag" unless the operator supplies the
    # hash from the Model-catalog release. Re-pinning the SAME tag verifies against the old record.
    catalog_sha = sha256_file(catalog_path(root))
    expected = expect_sha256 or (existing.get("catalog_sha256") if existing.get("tag") == tag else None)
    if not expected:
        raise SystemExit(
            f"model-catalog pin: moving to {tag} needs --expect-sha256 <hex> (the catalog sha256 from "
            f"the {UPSTREAM_REPO} release) — a pin must not certify whatever bytes happen to be on disk"
        )
    if catalog_sha != expected:
        raise SystemExit(
            f"model-catalog pin: {CATALOG_REL} sha256 {catalog_sha[:12]}… != expected "
            f"{expected[:12]}… for {tag} — re-vendor from the tag before pinning"
        )
    # Provenance guard (PR #456 review): if the on-disk renderer changed since the last pin and no
    # --renderer-commit names where it came from, refuse. Otherwise the record would carry the OLD
    # commit beside the NEW file's sha256 — `check` stays green (file vs recorded sha) while
    # `renderer_source` points at content that cannot match it.
    renderer_sha = sha256_file(renderer_path(root))
    if (not renderer_commit and existing.get("renderer_sha256")
            and existing["renderer_sha256"] != renderer_sha):
        raise SystemExit(
            f"model-catalog pin: {RENDERER_REL} changed since the last pin "
            f"({existing['renderer_sha256'][:12]}… -> {renderer_sha[:12]}…) but no --renderer-commit "
            f"was given — pass the Model-catalog commit the new renderer was vendored from"
        )
    # The renderer's provenance is resolved ONCE and used for both fields; a record with no
    # renderer commit at all (first pin without --renderer-commit) is refused rather than written
    # with a `/None/` source URL that check_pin would then accept.
    resolved_renderer_commit = renderer_commit or existing.get("renderer_commit")
    if not resolved_renderer_commit:
        raise SystemExit(
            f"model-catalog pin: no renderer provenance — pass --renderer-commit <sha> (the "
            f"{UPSTREAM_REPO} commit {RENDERER_REL} was vendored from)"
        )
    pin = {
        "repo": UPSTREAM_REPO,
        "tag": tag,
        "tag_commit": tag_commit,
        "version": str(catalog.get("version")),
        "updated": catalog.get("updated"),
        "catalog_sha256": catalog_sha,
        "catalog_source": f"https://raw.githubusercontent.com/{UPSTREAM_REPO}/{tag}/data/catalog.json",
        "renderer_commit": resolved_renderer_commit,
        "renderer_sha256": renderer_sha,
        "renderer_source": f"https://github.com/{UPSTREAM_REPO}/blob/"
                           f"{resolved_renderer_commit}/scripts/render_openrouter.py",
        "vendored_on": vendored_on or existing.get("vendored_on"),
        "_comment": (
            "GH-450: pin record for the vendored Model-catalog copy. Verified by "
            "`python3 utils/py/model_catalog.py check` (test/gh450-model-catalog-pin.sh). "
            "Rewrite with `model_catalog.py pin --tag ... --tag-commit ...` in a sync PR; never by hand."
        ),
    }
    with open(pin_path(root), "w", encoding="utf-8") as f:
        json.dump(pin, f, indent=2)
        f.write("\n")
    return pin


def main(argv: List[str]) -> int:
    p = argparse.ArgumentParser(description="vendored Model-catalog pin: check / render / version / pin")
    sub = p.add_subparsers(dest="cmd", required=True)
    for name in ("check", "render", "version"):
        sp = sub.add_parser(name)
        sp.add_argument("--root", default=default_root())
    sp = sub.add_parser("pin")
    sp.add_argument("--root", default=default_root())
    sp.add_argument("--tag", required=True)
    sp.add_argument("--tag-commit", required=True)
    sp.add_argument("--renderer-commit", default=None)
    sp.add_argument("--vendored-on", default=None)
    sp.add_argument("--expect-sha256", default=None,
                    help="catalog sha256 from the Model-catalog release; required when moving to a new tag")
    args = p.parse_args(argv)
    root = os.path.abspath(args.root)

    if args.cmd == "version":
        v = catalog_version(root)
        if not v:
            print(f"model-catalog: no readable version in {CATALOG_REL}", file=sys.stderr)
            return 1
        print(v)
        return 0

    if args.cmd == "render":
        out = render_yaml(root)
        with open(yaml_path(root), "wb") as f:
            f.write(out)
        print(f"model-catalog: rendered {YAML_REL} from {CATALOG_REL} (v{catalog_version(root)})")
        return 0

    if args.cmd == "pin":
        pin = write_pin(root, args.tag, args.tag_commit, args.renderer_commit, args.vendored_on,
                        expect_sha256=args.expect_sha256)
        print(f"model-catalog: pinned {pin['repo']} {pin['tag']} (v{pin['version']}, "
              f"catalog {pin['catalog_sha256'][:12]}…) -> {PIN_REL}")
        return 0

    problems = check(root)
    if problems:
        for pr in problems:
            print(f"model-catalog check: FAIL — {pr}", file=sys.stderr)
        return 1
    pin = load_pin(root)
    print(f"model-catalog check: OK — {pin['repo']} {pin['tag']} (v{pin['version']}); "
          f"{YAML_REL} matches a fresh render")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
