#!/usr/bin/env python3
"""Scaffold the working-doc / skill / scripts trinity for a repo-local skill."""

from __future__ import annotations

import argparse
import os
from pathlib import Path

from render_working_doc import render_doc


SKILL_TEMPLATE = """---
name: {skill_name}
description: >-
  Describe when `{skill_name}` should trigger, what it owns, and how its
  bundled scripts support deterministic work.
---

# {skill_name}

Replace this starter text with:

1. a short "when to use it" section
2. a short "when not to use it" section
3. the smallest workflow that can drive the task
4. pointers to bundled scripts or references
"""


POINTER_TEMPLATE = """# {skill_name} project pointer

Canonical working doc path: `{working_doc}`

Canonical working doc: [../../{working_doc}](../../{working_doc})

Keep active execution state in the working doc. Use this local file only as a pointer.
"""

VALIDATE_HELPER_TEMPLATE = """#!/usr/bin/env python3
\"\"\"Starter validation hook for {skill_name}.\"\"\"


def main() -> int:
    print("TODO: implement validation for {skill_name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
"""


TASK_HELPER_TEMPLATE = """#!/usr/bin/env python3
\"\"\"Starter deterministic helper for {skill_name}.\"\"\"


def main() -> int:
    print("TODO: implement a deterministic helper for {skill_name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skill-dir", required=True, type=Path)
    parser.add_argument("--working-doc", required=True, type=Path)
    parser.add_argument("--title", required=True)
    parser.add_argument("--owner", required=True)
    parser.add_argument("--goal", required=True)
    parser.add_argument("--repo-root", type=Path)
    parser.add_argument("--force", action="store_true")
    return parser.parse_args()


def write_if_needed(path: Path, content: str, force: bool) -> str:
    if path.exists() and not force:
        return f"kept  {path}"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    return f"wrote {path}"


def infer_repo_root(skill_dir: Path, working_doc: Path, explicit: Path | None) -> Path:
    if explicit is not None:
        return explicit
    common = os.path.commonpath([str(skill_dir.resolve()), str(working_doc.resolve())])
    return Path(common)


def repo_relative(path: Path, repo_root: Path) -> str:
    try:
        return path.resolve().relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def main() -> int:
    args = parse_args()
    skill_dir = args.skill_dir
    skill_name = skill_dir.name
    repo_root = infer_repo_root(skill_dir, args.working_doc, args.repo_root)
    relative_working_doc = repo_relative(args.working_doc, repo_root)
    skill_dir.mkdir(parents=True, exist_ok=True)
    scripts_dir = skill_dir / "scripts"
    scripts_dir.mkdir(exist_ok=True)

    results = []
    if not args.working_doc.exists() or args.force:
        working_doc = render_doc(
            skill_dir=skill_dir,
            output=args.working_doc,
            repo_root=repo_root,
            title=args.title,
            owner=args.owner,
            goal=args.goal,
            just_completed="Created the first PDDA-compliant working doc for this skill.",
            next_step="Build or refine the skill scaffold and validate the helper scripts.",
            phases=["Working doc contract", "Skill contract", "Deterministic helpers"],
        )
        args.working_doc.parent.mkdir(parents=True, exist_ok=True)
        args.working_doc.write_text(working_doc, encoding="utf-8")
        results.append(f"wrote {args.working_doc}")
    else:
        results.append(f"kept  {args.working_doc}")

    results.append(
        write_if_needed(
            skill_dir / "PROJECT.md",
            POINTER_TEMPLATE.format(skill_name=skill_name, working_doc=relative_working_doc),
            args.force,
        )
    )
    results.append(
        write_if_needed(
            skill_dir / "SKILL.md",
            SKILL_TEMPLATE.format(skill_name=skill_name),
            args.force,
        )
    )
    results.append(
        write_if_needed(
            scripts_dir / "validate_skill.py",
            VALIDATE_HELPER_TEMPLATE.format(skill_name=skill_name),
            args.force,
        )
    )
    results.append(
        write_if_needed(
            scripts_dir / "task_helper.py",
            TASK_HELPER_TEMPLATE.format(skill_name=skill_name),
            args.force,
        )
    )

    for line in results:
        print(line)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
