#!/usr/bin/env python3
"""Export installed skill-file inventories for Claude, Codex, and Antigravity."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
from pathlib import Path


ENVIRONMENT_DEFAULTS = {
    "claude": Path("~/.claude/skills"),
    "codex": Path("~/.codex/skills"),
    "antigravity": Path("~/.gemini/antigravity/skills"),
    "antigravity_local": Path("~/.gemini/antigravity-cli/skills"),
}


def infer_repo_root() -> Path:
    return Path(__file__).resolve().parents[3]


def default_output_dir() -> Path:
    return infer_repo_root() / "temp" / "skills-sync-trinity"


def timestamp_label() -> str:
    return dt.datetime.now(dt.UTC).strftime("%Y%m%dT%H%M%SZ")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=default_output_dir())
    parser.add_argument("--label", default=timestamp_label())
    parser.add_argument("--claude-root", type=Path, default=ENVIRONMENT_DEFAULTS["claude"])
    parser.add_argument("--codex-root", type=Path, default=ENVIRONMENT_DEFAULTS["codex"])
    parser.add_argument("--antigravity-root", type=Path, default=ENVIRONMENT_DEFAULTS["antigravity"])
    parser.add_argument("--antigravity-local-root", type=Path, default=ENVIRONMENT_DEFAULTS["antigravity_local"])
    return parser.parse_args()


def sorted_walk(root: Path) -> tuple[list[str], list[str]]:
    files: list[str] = []
    skill_dirs: list[str] = []

    for current, dirnames, filenames in os.walk(root, topdown=True, followlinks=True):
        dirnames.sort()
        filenames.sort()
        current_path = Path(current)
        current_rel = current_path.relative_to(root).as_posix()

        if "SKILL.md" in filenames:
            skill_dirs.append("." if current_rel == "." else current_rel)

        for filename in filenames:
            rel_path = (current_path / filename).relative_to(root).as_posix()
            files.append(rel_path)

    return files, sorted(set(skill_dirs))


def describe_root_entry(path: Path, root: Path) -> dict[str, object]:
    return {
        "name": path.name,
        "relative_path": path.relative_to(root).as_posix(),
        "absolute_path": str(path),
        "resolved_path": str(path.expanduser().resolve(strict=False)),
        "exists": path.exists(),
        "is_symlink": path.is_symlink(),
        "is_dir": path.is_dir(),
    }


def assign_files_to_skills(
    all_files: list[str],
    skill_dirs: list[str],
) -> tuple[dict[str, list[str]], list[str]]:
    assignments = {skill_dir: [] for skill_dir in skill_dirs}
    orphans: list[str] = []
    ordered_prefixes = sorted(skill_dirs, key=lambda item: (-len(item), item))

    for rel_path in all_files:
        matched = None
        for prefix in ordered_prefixes:
            prefix_with_sep = f"{prefix}/"
            if rel_path.startswith(prefix_with_sep):
                matched = prefix
                break
        if matched is None:
            orphans.append(rel_path)
        else:
            assignments[matched].append(rel_path)

    return assignments, orphans


def collect_environment(name: str, root: Path) -> dict[str, object]:
    expanded_root = root.expanduser()
    resolved_root = expanded_root.resolve(strict=False)

    if not expanded_root.exists():
        return {
            "name": name,
            "configured_root": str(root),
            "root": str(expanded_root),
            "resolved_root": str(resolved_root),
            "status": "missing",
            "skill_count": 0,
            "file_count": 0,
            "skills": [],
            "all_files": [],
            "orphan_files": [],
            "unresolved_root_entries": [],
        }

    if not expanded_root.is_dir():
        return {
            "name": name,
            "configured_root": str(root),
            "root": str(expanded_root),
            "resolved_root": str(resolved_root),
            "status": "not_directory",
            "skill_count": 0,
            "file_count": 0,
            "skills": [],
            "all_files": [],
            "orphan_files": [],
            "unresolved_root_entries": [],
        }

    all_files, skill_dirs = sorted_walk(expanded_root)
    assignments, orphans = assign_files_to_skills(all_files, skill_dirs)
    covered_top_level = {skill_dir.split("/", 1)[0] for skill_dir in skill_dirs}
    unresolved_root_entries = [
        describe_root_entry(path, expanded_root)
        for path in sorted(expanded_root.iterdir(), key=lambda item: item.name)
        if path.name not in covered_top_level
    ]

    skills = []
    for skill_dir in skill_dirs:
        skill_path = expanded_root / skill_dir
        skills.append(
            {
                "name": skill_path.name,
                "relative_path": skill_dir,
                "absolute_path": str(skill_path),
                "resolved_path": str(skill_path.resolve(strict=False)),
                "is_symlink": skill_path.is_symlink(),
                "file_count": len(assignments[skill_dir]),
                "files": assignments[skill_dir],
            }
        )

    return {
        "name": name,
        "configured_root": str(root),
        "root": str(expanded_root),
        "resolved_root": str(resolved_root),
        "status": "present",
        "skill_count": len(skills),
        "file_count": len(all_files),
        "skills": skills,
        "all_files": all_files,
        "orphan_files": orphans,
        "unresolved_root_entries": unresolved_root_entries,
    }


def render_readme(report: dict[str, object]) -> str:
    lines = [
        "# Skills sync trinity inventory",
        "",
        f"Generated at: `{report['generated_at']}`",
        f"Bundle path: `{report['bundle_dir']}`",
        "",
        "| Environment | Status | Root | Skills | Files | Orphans |",
        "|---|---|---|---:|---:|---:|",
    ]

    for env in report["environments"]:
        lines.append(
            "| {name} | {status} | `{root}` | {skill_count} | {file_count} | {orphans} |".format(
                name=env["name"],
                status=env["status"],
                root=env["root"],
                skill_count=env["skill_count"],
                file_count=env["file_count"],
                orphans=len(env["orphan_files"]),
            )
        )

    for env in report["environments"]:
        lines.extend(
            [
                "",
                f"## {env['name']}",
                "",
                f"- Root: `{env['root']}`",
                f"- Status: `{env['status']}`",
                f"- Skill count: `{env['skill_count']}`",
                f"- File count: `{env['file_count']}`",
                f"- File listing: `{env['name']}-files.txt`",
            ]
        )

        if env["status"] != "present":
            continue

        lines.extend(
            [
                "",
                "| Skill | Installed path | Resolved path | Files | Symlink |",
                "|---|---|---|---:|---|",
            ]
        )
        for skill in env["skills"]:
            lines.append(
                "| {name} | `{relative_path}` | `{resolved_path}` | {file_count} | {is_symlink} |".format(
                    **skill
                )
            )

        if env["orphan_files"]:
            lines.extend(["", "Unassigned files:"])
            for orphan in env["orphan_files"]:
                lines.append(f"- `{orphan}`")

        if env["unresolved_root_entries"]:
            lines.extend(["", "Root entries without a discovered `SKILL.md`:"])
            for entry in env["unresolved_root_entries"]:
                lines.append(
                    "- `{relative_path}` -> `{resolved_path}`".format(
                        **entry
                    )
                )

    lines.append("")
    return "\n".join(lines)


def write_outputs(bundle_dir: Path, report: dict[str, object]) -> list[Path]:
    bundle_dir.mkdir(parents=True, exist_ok=True)
    outputs: list[Path] = []

    inventory_json = bundle_dir / "inventory.json"
    inventory_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    outputs.append(inventory_json)

    readme = bundle_dir / "README.md"
    readme.write_text(render_readme(report), encoding="utf-8")
    outputs.append(readme)

    for env in report["environments"]:
        env_file = bundle_dir / f"{env['name']}-files.txt"
        body = "\n".join(env["all_files"]) + ("\n" if env["all_files"] else "")
        if env["status"] != "present":
            body = f"# status: {env['status']}\n"
        env_file.write_text(body, encoding="utf-8")
        outputs.append(env_file)

    return outputs


def main() -> int:
    args = parse_args()
    bundle_dir = args.output_dir / args.label
    environments = [
        collect_environment("claude", args.claude_root),
        collect_environment("codex", args.codex_root),
        collect_environment("antigravity", args.antigravity_root),
        collect_environment("antigravity-local", args.antigravity_local_root),
    ]
    report = {
        "generated_at": dt.datetime.now(dt.UTC).isoformat().replace("+00:00", "Z"),
        "bundle_dir": str(bundle_dir),
        "repo_root": str(infer_repo_root()),
        "environments": environments,
    }

    for output in write_outputs(bundle_dir, report):
        print(f"wrote {output}")
    print(f"bundle {bundle_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
