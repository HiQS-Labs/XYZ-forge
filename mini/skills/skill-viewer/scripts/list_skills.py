#!/usr/bin/env python3
"""list_skills.py — print every skill in this repo with its name and description. (XYZ mini)

Reads the frontmatter of skills/*/SKILL.md (relative to the repo toplevel, or --root) and prints a
table plus a trailing "N skills" line. Nothing is hardcoded: the count is whatever is on disk.
The frontmatter reader is a copy of skills-army-hq's `skill_info` loop (XYZ-forge,
skills/skills-army-hq/scripts/intake.py) with its helpers inlined — stdlib only, no PyYAML.

Usage: list_skills.py [--root DIR] [--json]
Exit:  0 ok · 1 a SKILL.md is missing/invalid frontmatter · 2 no skills found
"""
import argparse
import glob
import json
import os
import re
import subprocess
import sys


class SkillError(Exception):
    pass


def frontmatter_fields(text, where):
    if not (text.startswith("---\n") and "\n---" in text[4:]):
        raise SkillError(f"missing frontmatter: {where}")
    header = text[4:].split("\n---", 1)[0]
    fields = {}
    lines = header.splitlines()
    for i, line in enumerate(lines):
        match = re.match(r"^(name|description):\s*(.*)$", line)
        if not match:
            continue
        key, value = match.groups()
        if key in fields:
            raise SkillError(f"duplicate {key}: {where}")
        if value in ("|", "|-", "|+", ">", ">-", ">+"):
            block = []
            for following in lines[i + 1:]:
                if following and not following[0].isspace():
                    break
                block.append(following.strip())
            value = " ".join(block).strip()
        elif value.startswith('"'):
            try:
                value = json.loads(value)
            except ValueError as exc:
                raise SkillError(f"invalid quoted {key}: {where}") from exc
        elif value.startswith("'"):
            if not value.endswith("'"):
                raise SkillError(f"unclosed {key}: {where}")
            value = value[1:-1].replace("''", "'")
        fields[key] = value
    name = fields.get("name")
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", name):
        raise SkillError(f"missing or invalid name: {where}")
    desc = fields.get("description")
    if not isinstance(desc, str) or not desc.strip():
        raise SkillError(f"missing description: {where}")
    return name, desc.strip()


def repo_root():
    # Resolve from THIS FILE's location, never from the caller's CWD — otherwise running the viewer
    # from inside some other git repo would silently list that repo's (empty) skills/ instead.
    here = os.path.dirname(os.path.abspath(__file__))
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=here, capture_output=True, text=True, check=True).stdout
        return out.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        # fallback: this file lives at <root>/skills/skill-viewer/scripts/
        return os.path.abspath(os.path.join(here, "..", "..", ".."))


def main(argv=None):
    ap = argparse.ArgumentParser(description="List skills and their descriptions.")
    ap.add_argument("--root", default=None, help="repo root (default: git toplevel)")
    ap.add_argument("--json", action="store_true")
    a = ap.parse_args(argv)
    root = a.root or repo_root()
    paths = sorted(glob.glob(os.path.join(root, "skills", "*", "SKILL.md")))
    rows, errors = [], []
    for p in paths:
        folder = os.path.basename(os.path.dirname(p))
        try:
            with open(p, encoding="utf-8") as fh:
                name, desc = frontmatter_fields(fh.read(), p)
            if name != folder:
                raise SkillError(f"folder/name mismatch: {folder} != {name}")
            rows.append({"name": name, "description": desc, "path": os.path.relpath(p, root)})
        except (SkillError, OSError) as e:
            errors.append(str(e))
    if a.json:
        print(json.dumps({"root": root, "skills": rows, "errors": errors}, indent=2))
    else:
        width = max([len(r["name"]) for r in rows] + [5])
        for r in rows:
            d = r["description"]
            if len(d) > 100:
                d = d[:97] + "..."
            print(f"{r['name']:<{width}}  {d}")
        for e in errors:
            print(f"ERROR  {e}", file=sys.stderr)
        print(f"{len(rows)} skills")
    if errors:
        return 1
    if not rows:
        print("no skills found under skills/*/SKILL.md", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
