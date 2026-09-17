#!/usr/bin/env python3
"""GH-660 — detect vendored-skill drift against this repo's canonical skills/.

A vendored skill collection (e.g. a Deployed Skills tree symlinked into agent
homes) drifts silently: someone hand-patches the vendored copy, or canonical
gains hardening the vendor never receives (the GH-592 resume recipe the express
collection lacked). This check names every vendored SKILL.md that differs from
its canonical source, so the operator re-vendors instead of hand-patching.

Advisory boundaries, stated: only names present in BOTH trees are compared —
a vendored extra is reported as `unrecognized` (informational, never a failure:
collections legitimately vendor skills this repo does not own), and a canonical
skill absent from the collection is not the collection's defect. Exit codes:
0 clean · 1 drift detected · 2 usage.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

EXIT_OK, EXIT_DRIFT, EXIT_USAGE = 0, 1, 2


def _digest(path: Path) -> str:
    # GH-663 finding 3: normalize CRLF before hashing — a vendor that differs
    # only in line endings is content-identical for a Markdown loader, and
    # flagging it would be a false positive.
    return hashlib.sha256(path.read_bytes().replace(b"\r\n", b"\n")).hexdigest()


def scan(canonical: Path, collection: Path) -> dict:
    result = {"drifted": [], "ok": [], "unrecognized": []}
    for skill_md in sorted(canonical.glob("*/SKILL.md")):
        name = skill_md.parent.name
        vendored = collection / name / "SKILL.md"
        if not vendored.is_file():
            continue  # canonical skill the collection doesn't vendor: not its defect
        entry = {"skill": name,
                 "canonical_sha256": _digest(skill_md),
                 "vendored_sha256": _digest(vendored)}
        if entry["canonical_sha256"] != entry["vendored_sha256"]:
            entry["canonical_path"] = str(skill_md)
            entry["vendored_path"] = str(vendored)
            result["drifted"].append(entry)
        else:
            result["ok"].append(entry)
    for vendored_md in sorted(collection.glob("*/SKILL.md")):
        name = vendored_md.parent.name
        if not (canonical / name / "SKILL.md").is_file():
            result["unrecognized"].append({"skill": name,
                                           "vendored_path": str(vendored_md)})
    return result


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--canonical", required=True,
                        help="this repo's root (skills/ is appended) OR its "
                             "skills/ directory directly — both accepted")
    parser.add_argument("--collection", required=True,
                        help="vendored collection directory to check")
    parser.add_argument("--json", action="store_true", dest="as_json",
                        help="machine-readable report on stdout")
    args = parser.parse_args(argv)

    canonical, collection = Path(args.canonical), Path(args.collection)
    skills_dir = canonical / "skills" if (canonical / "skills").is_dir() else canonical
    if not skills_dir.is_dir() or not collection.is_dir():
        parser.print_usage(sys.stderr)
        return EXIT_USAGE
    result = scan(skills_dir, collection)
    if args.as_json:
        print(json.dumps(result, indent=2))
    else:
        for entry in result["drifted"]:
            print(f"DRIFTED  {entry['skill']}: vendored {entry['vendored_path']} "
                  f"!= canonical {entry['canonical_path']}")
        for entry in result["unrecognized"]:
            print(f"UNRECOGNIZED  {entry['skill']}: {entry['vendored_path']} "
                  f"(no canonical skills/{entry['skill']})")
        print(f"{len(result['ok'])} ok, {len(result['drifted'])} drifted, "
              f"{len(result['unrecognized'])} unrecognized")
    return EXIT_DRIFT if result["drifted"] else EXIT_OK


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
