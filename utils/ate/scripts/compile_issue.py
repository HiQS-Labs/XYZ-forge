#!/usr/bin/env python3
"""
Compile error_log.jsonl into one GitHub issue: a single unified checklist of
every finding from the run, ranked by severity (critical first).

Issue title defaults to "ATE - [test-name] yyyy-mm-dd" (override with --title).

Requires the `gh` CLI, already authenticated (`gh auth status`).

Usage:
  python3 compile_issue.py --log error_log.jsonl --repo owner/repo --test-name aider-flag-fuzz
  python3 compile_issue.py --log error_log.jsonl --repo owner/repo --dry-run
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from collections import defaultdict
from datetime import date
from pathlib import Path

SEVERITY_ORDER = ["critical", "high", "medium", "low", "none", "unknown"]

# #142: the terminal states a caller can branch on. Before this contract, main() returned None
# on EVERY path — a run whose `gh issue create` failed outright exited 0, indistinguishable from
# "filed it" and from "nothing to file", so no wrapper, CI job, or supervising agent could tell a
# multi-hour run's final step had failed. Documented in utils/ate/SKILL.md ("Exit codes").
EXIT_FILED = 0       # issue created, or --dry-run body rendered
EXIT_NO_RECORDS = 3  # log empty — nothing to file, not an error, but a distinct observable
EXIT_GH_FAILED = 1   # gh issue create failed; issue_body.md is preserved for manual filing


def load_records(log_path: Path) -> list[dict]:
    records = []
    for line in log_path.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return records


def group_by_severity(records: list[dict]) -> dict:
    groups = defaultdict(lambda: defaultdict(list))
    for r in records:
        c = r.get("classification") or {}
        # #141 Phase 2: the clean-pass skip keys on the TOP-LEVEL status, which both producers
        # emit. fuzz-loop records no longer carry a nested classification.status — it was a pure
        # alias of the top-level field (the third alias GH-141's review counted), and stripping
        # it here without this change would have turned every clean record into an
        # unknown-severity finding.
        if r.get("status") == "pass" and c.get("severity") in (None, "none"):
            continue  # clean pass, no need to report
        # A pass the classifier graded severe (run_variations' Gemma path) stays a finding.
        sev = c.get("severity", "unknown")
        # signature = category + first ~60 chars of likely_cause, so near-duplicate
        # failures collapse into one bucket instead of one row per iteration
        sig = f"{c.get('category', 'uncategorized')} :: {(c.get('likely_cause') or '')[:60]}"
        groups[sev][sig].append(r)
    return groups


def build_body(groups: dict, total: int, test_name: str) -> str:
    lines = [
        f"Automated ATE (Automated Testing Environment) rollup — test run: `{test_name}`.",
        f"Total variations logged: {total}. Findings below are a unified list, ranked "
        "by severity (critical first).",
        "",
    ]
    for sev in SEVERITY_ORDER:
        buckets = groups.get(sev)
        if not buckets:
            continue
        lines.append(f"## {sev.upper()} ({sum(len(v) for v in buckets.values())} instances)")
        lines.append("")
        for sig, instances in sorted(buckets.items(), key=lambda kv: -len(kv[1])):
            example = instances[0]
            lines.append(f"- [ ] **{sig}** — seen {len(instances)}x")
            lines.append(f"  - example command: `{example.get('command', '')}`")
            lines.append(f"  - example variation: `{json.dumps(example.get('variation', {}))}`")
            stderr_lines = (example.get("stderr") or "").strip().splitlines()
            if stderr_lines:
                lines.append(f"  - stderr tail: `{stderr_lines[-1][:200]}`")
        lines.append("")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--log", required=True)
    ap.add_argument("--repo", required=True, help="owner/repo for `gh issue create --repo`")
    ap.add_argument("--test-name", default="variation-test",
                     help="short slug identifying this test run; used in the default "
                          "title 'ATE - [test-name] yyyy-mm-dd'")
    ap.add_argument("--title", default=None,
                     help="override the default 'ATE - [test-name] yyyy-mm-dd' title")
    ap.add_argument("--label", action="append", default=None,
                    help="repeatable; defaults to the neutral 'bug' if omitted. The Aider "
                         "preset opts back into 'aider-pipeline' explicitly (#141 Phase 5: "
                         "generalized soaks must not file Aider-labelled issues)")
    ap.add_argument("--dry-run", action="store_true", help="print the issue body, don't call gh")
    args = ap.parse_args()
    labels = args.label or ["bug"]  # #141 Phase 5: neutral default; Aider presets pass aider-pipeline explicitly
    title = args.title or f"ATE - [{args.test_name}] {date.today().isoformat()}"

    records = load_records(Path(args.log))
    if not records:
        print("No records found in log — nothing to file.")
        return EXIT_NO_RECORDS

    groups = group_by_severity(records)
    body = build_body(groups, len(records), args.test_name)

    if args.dry_run:
        print(f"[title] {title}\n")
        print(body)
        return EXIT_FILED

    body_path = Path("issue_body.md")
    body_path.write_text(body)

    cmd = [
        "gh", "issue", "create",
        "--repo", args.repo,
        "--title", title,
        "--body-file", str(body_path),
    ]
    for label in labels:
        cmd += ["--label", label]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        print(f"Issue created: {result.stdout.strip()}")
        body_path.unlink()
        return EXIT_FILED
    print(f"gh issue create failed:\n{result.stderr}")
    print(f"Issue body was written to {body_path} — you can file it manually.")
    return EXIT_GH_FAILED


if __name__ == "__main__":
    sys.exit(main())
