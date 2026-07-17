#!/usr/bin/env python3
"""Validate the working-doc / skill / scripts trinity for a repo-local skill."""

from __future__ import annotations

import argparse
import os
from pathlib import Path


REQUIRED_FRONTMATTER_KEYS = [
    "title:",
    "status:",
    "created:",
    "updated:",
    "owner:",
    "goal:",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skill-dir", required=True, type=Path)
    parser.add_argument("--working-doc", required=True, type=Path)
    return parser.parse_args()


def require(errors: list[str], condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def infer_repo_root(skill_dir: Path, working_doc: Path) -> Path:
    common = os.path.commonpath([str(skill_dir.resolve()), str(working_doc.resolve())])
    return Path(common)


def main() -> int:
    args = parse_args()
    errors: list[str] = []

    skill_dir = args.skill_dir
    working_doc = args.working_doc
    repo_root = infer_repo_root(skill_dir, working_doc)
    relative_working_doc = working_doc.resolve().relative_to(repo_root.resolve()).as_posix()
    local_project = skill_dir / "PROJECT.md"
    skill_doc = skill_dir / "SKILL.md"
    scripts = sorted((skill_dir / "scripts").glob("*.py"))

    require(errors, working_doc.exists(), f"missing working doc: {working_doc}")
    require(errors, local_project.exists(), f"missing local PROJECT.md: {local_project}")
    require(errors, skill_doc.exists(), f"missing SKILL.md: {skill_doc}")
    require(errors, len(scripts) >= 2, f"expected at least 2 python helpers in {(skill_dir / 'scripts')}")

    if working_doc.exists():
        doc_text = working_doc.read_text(encoding="utf-8")
        require(errors, doc_text.startswith("---\n"), "working doc missing YAML frontmatter")
        for key in REQUIRED_FRONTMATTER_KEYS:
            require(errors, key in doc_text, f"working doc missing frontmatter key: {key.rstrip(':')}")
        require(errors, "## Status" in doc_text, "working doc missing ## Status section")
        require(
            errors,
            "| What was just completed | What's next |" in doc_text,
            "working doc missing exact PDDA status table header",
        )

    if local_project.exists():
        project_text = local_project.read_text(encoding="utf-8")
        require(
            errors,
            working_doc.as_posix() in project_text or relative_working_doc in project_text,
            "local PROJECT.md does not point at the canonical working doc",
        )

    if skill_doc.exists():
        skill_text = skill_doc.read_text(encoding="utf-8")
        require(errors, skill_text.startswith("---\n"), "SKILL.md missing frontmatter")
        require(errors, "name:" in skill_text, "SKILL.md missing name in frontmatter")
        require(errors, "description:" in skill_text, "SKILL.md missing description in frontmatter")

    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1

    print("OK: trinity scaffold is structurally aligned")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
