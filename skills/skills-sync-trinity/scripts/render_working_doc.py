#!/usr/bin/env python3
"""Render a PDDA-compliant working doc for a repo-local skill."""

from __future__ import annotations

import argparse
import datetime as dt
from pathlib import Path


DEFAULT_PHASES = [
    "Working doc contract",
    "Skill contract",
    "Deterministic helpers",
]


def repo_relative(path: Path, repo_root: Path) -> str:
    try:
        return path.resolve().relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        return path.as_posix()


def render_doc(
    *,
    skill_dir: Path,
    output: Path,
    repo_root: Path,
    title: str,
    owner: str,
    goal: str,
    just_completed: str,
    next_step: str,
    phases: list[str],
) -> str:
    today = dt.date.today().isoformat()
    related = [
        repo_relative(skill_dir / "PROJECT.md", repo_root),
        repo_relative(skill_dir / "SKILL.md", repo_root),
    ]
    scripts_dir = skill_dir / "scripts"
    if scripts_dir.exists():
        for script in sorted(scripts_dir.glob("*.py")):
            related.append(repo_relative(script, repo_root))

    toc_lines = [
        f"- [Phase {idx} - {phase}](#phase-{idx}---{phase.lower().replace(' ', '-')})"
        for idx, phase in enumerate(phases, start=1)
    ]

    sections = []
    for idx, phase in enumerate(phases, start=1):
        sections.append(
            f"""## Phase {idx} - {phase}

### Checklist

- [ ] Define the deliverables for {phase.lower()}.
- [ ] Implement the changes owned by this phase.
- [ ] Record any decisions or findings back into this doc before closing the phase.

### QA checklist - Phase {idx}

- [ ] Output for this phase is present in the repo.
- [ ] Validation steps for this phase are named explicitly.
"""
        )

    body = "\n".join(sections).rstrip()
    related_yaml = "\n".join(f"  - {item}" for item in related)
    toc = "\n".join(toc_lines)

    return f"""---
title: {title}
status: Active
created: {today}
updated: {today}
owner: {owner}
doc_type: project
effort: 2
complexity: 2
risk: 1
phases: {len(phases)}
related:
{related_yaml}
goal: >
  {goal}
roadmap_exempt: true
---

# {title}

## Status

| What was just completed | What's next |
|---|---|
| {just_completed} | {next_step} |

## Table of contents

{toc}

{body}
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--skill-dir", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--repo-root", type=Path, default=Path.cwd())
    parser.add_argument("--title", required=True)
    parser.add_argument("--owner", required=True)
    parser.add_argument("--goal", required=True)
    parser.add_argument(
        "--just-completed",
        default="Created the first PDDA-compliant working doc for this skill.",
    )
    parser.add_argument(
        "--next-step",
        default="Build or refine the skill scaffold and validate the helper scripts.",
    )
    parser.add_argument("--phase", action="append", dest="phases")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    phases = args.phases or list(DEFAULT_PHASES)
    rendered = render_doc(
        skill_dir=args.skill_dir,
        output=args.output,
        repo_root=args.repo_root,
        title=args.title,
        owner=args.owner,
        goal=args.goal,
        just_completed=args.just_completed,
        next_step=args.next_step,
        phases=phases,
    )
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered, encoding="utf-8")
    print(f"wrote {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
