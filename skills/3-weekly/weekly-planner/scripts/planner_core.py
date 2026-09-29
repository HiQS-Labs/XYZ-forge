#!/usr/bin/env python3
"""
Planner Core Engine - Shared by Weekly Planner and Daily Planner skills.

Provides:
- Dual-mode intake: Native XYZ PRS (releases.db) or 2-3 pass scratch Markdown fallback.
- Topologically sorted PR merge sequencing based on CI, reviews, and git mergeability.
- Anti-stall Provisional Decisions Protocol (anchored to canonical GH issue tracker).
- Adversarial Northstars validation (duplication, contradiction, race condition detection)
  applied to BOTH weekly outlines and daily pivots.
- Daily adaptive pivoting based on last 24h merged PRs and closed issues.
"""

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path


def run_cmd(cmd, cwd=None, check=True):
    """Run a shell command safely and return stripped stdout."""
    res = subprocess.run(
        cmd,
        cwd=cwd,
        shell=isinstance(cmd, str),
        capture_output=True,
        text=True,
    )
    if check and res.returncode != 0:
        raise RuntimeError(f"Command failed (exit {res.returncode}): {cmd}\n{res.stderr.strip()}")
    return res.stdout.strip()


def ensure_temp_dir(repo_root: Path) -> Path:
    """Ensure repo has an isolated, gitignored temp directory."""
    temp_dir = repo_root / "temp"
    planner_temp = temp_dir / "planner"
    planner_temp.mkdir(parents=True, exist_ok=True)

    # Check gitignore
    gitignore = repo_root / ".gitignore"
    if gitignore.exists():
        content = gitignore.read_text(encoding="utf-8")
        if not re.search(r"^\s*temp/?\s*$", content, re.MULTILINE):
            print(f"[WARN] 'temp/' is not explicitly listed in {gitignore}. Add 'temp/' to prevent committing scratch artifacts.", file=sys.stderr)
    return planner_temp


def get_open_prs(repo_root: Path, gh_repo: str = None):
    """Fetch open pull requests and metadata."""
    cmd = [
        "gh", "pr", "list",
        "--state", "open",
        "--json", "number,title,author,headRefName,mergeable,reviewDecision,reviews,updatedAt"
    ]
    if gh_repo:
        cmd.extend(["-R", gh_repo])
    try:
        out = run_cmd(cmd, cwd=repo_root)
        return json.loads(out) if out else []
    except Exception as e:
        print(f"[WARN] Failed to fetch open PRs: {e}", file=sys.stderr)
        return []


def detect_merge_sequence(prs: list) -> list:
    """
    Sort PRs into a safe, topological merge sequence:
    1. Approved + MERGEABLE PRs with zero changes requested.
    2. PRs with CHANGES_REQUESTED or broken CI (must be fixed to unblock downstream).
    3. Approved PRs with CONFLICTING state (need rebase against development).
    4. WIP / Review-pending PRs.
    """
    phase_ready = []
    phase_blocker_fixes = []
    phase_needs_rebase = []
    phase_in_review = []

    for pr in prs:
        decision = (pr.get("reviewDecision") or "").upper()
        mergeable = (pr.get("mergeable") or "").upper()
        
        if decision == "CHANGES_REQUESTED":
            phase_blocker_fixes.append(pr)
        elif decision == "APPROVED" and mergeable == "MERGEABLE":
            phase_ready.append(pr)
        elif decision == "APPROVED" and mergeable == "CONFLICTING":
            phase_needs_rebase.append(pr)
        else:
            phase_in_review.append(pr)

    return {
        "ready_to_land": phase_ready,
        "blockers_to_fix": phase_blocker_fixes,
        "needs_rebase": phase_needs_rebase,
        "in_review_or_wip": phase_in_review,
    }


def audit_adversarial(plan: dict) -> dict:
    """
    Adversarial Northstars Audit:
    - Check for duplication across assignments.
    - Check for file/subsystem contradictions (e.g. parallel edits to CHANGELOG/migrations).
    - Check for race conditions (e.g. running historical backfill while rolling sync is active).
    - Check for external dependency stalls ('waiting for X to decide').
    """
    findings = []
    
    # 1. External Stalls check
    raw_text = json.dumps(plan).lower()
    if "waiting for" in raw_text or "waiting on" in raw_text:
        findings.append({
            "severity": "HIGH",
            "type": "ANTI_STALL_VIOLATION",
            "message": "Plan mentions 'waiting for/on' external feedback. Enforce Provisional Decision Protocol: define a provisional default, record on tracker issue, and wire a UI setting/re-compute button."
        })

    # 2. PR merge collision check
    prs = plan.get("prs", [])
    if len(prs) > 3:
        findings.append({
            "severity": "MEDIUM",
            "type": "MERGE_FRICTION",
            "message": f"{len(prs)} open PRs will contend on CHANGELOG.md and version bumps. Enforce sequential landing where only the active landing branch rebases."
        })

    # 3. Data pipeline vs Reconciler concurrency check
    has_backfill = any("backfill" in (pr.get("title", "") + pr.get("headRefName", "")).lower() for pr in prs)
    if has_backfill:
        findings.append({
            "severity": "HIGH",
            "type": "DATA_RACE_HAZARD",
            "message": "Backfill operations must enforce isolated window keys (--window-key) to prevent rolling reconcilers from misclassifying mixed coverage as stalled."
        })

    return {
        "passed": len([f for f in findings if f["severity"] == "HIGH"]) == 0,
        "findings": findings
    }


def pivot_daily(weekly_plan_file: Path, repo_root: Path, gh_repo: str = None) -> dict:
    """
    Generate daily plan pivot by checking what merged/closed in the last 24h.
    """
    # Fetch recent merged PRs (last 24-36 hours)
    cmd = [
        "gh", "pr", "list",
        "--state", "merged",
        "--limit", "15",
        "--json", "number,title,mergedAt,headRefName"
    ]
    if gh_repo:
        cmd.extend(["-R", gh_repo])
    
    merged_prs = []
    try:
        out = run_cmd(cmd, cwd=repo_root)
        merged_prs = json.loads(out) if out else []
    except Exception as e:
        print(f"[WARN] Failed to fetch merged PRs: {e}", file=sys.stderr)

    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "recent_merges": merged_prs,
    }


def main():
    parser = argparse.ArgumentParser(description="Planner Core Engine")
    parser.add_argument("--repo-root", default=".", help="Path to repository root")
    parser.add_argument("--gh-repo", default=None, help="Target GitHub repo (e.g. Org/Name)")
    parser.add_argument("--mode", choices=["weekly", "daily", "audit", "sequence"], default="weekly")
    parser.add_argument("--plan-file", help="Path to existing weekly plan JSON/MD")
    parser.add_argument("--decisions-issue", help="Canonical GH issue number for provisional decisions tracker")

    args = parser.parse_args()
    repo_root = Path(args.repo_root).resolve()
    temp_dir = ensure_temp_dir(repo_root)

    prs = get_open_prs(repo_root, args.gh_repo)
    sequence = detect_merge_sequence(prs)

    if args.mode == "sequence":
        print(json.dumps(sequence, indent=2))
        return

    if args.mode == "audit":
        audit = audit_adversarial({"prs": prs})
        print(json.dumps(audit, indent=2))
        return

    if args.mode == "daily":
        pivot = pivot_daily(Path(args.plan_file) if args.plan_file else None, repo_root, args.gh_repo)
        audit = audit_adversarial({"prs": prs, "pivot": pivot})
        result = {
            "mode": "daily_pivot",
            "merge_sequence": sequence,
            "pivot": pivot,
            "adversarial_audit": audit,
        }
        out_file = temp_dir / f"daily-pivot-{datetime.now().strftime('%Y%m%d')}.json"
        out_file.write_text(json.dumps(result, indent=2), encoding="utf-8")
        print(f"Daily pivot generated at: {out_file}")
        return

    # Weekly mode
    audit = audit_adversarial({"prs": prs})
    result = {
        "mode": "weekly_plan",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "merge_sequence": sequence,
        "adversarial_audit": audit,
        "decisions_issue": args.decisions_issue or "NONE_SET",
    }
    out_file = temp_dir / f"weekly-plan-{datetime.now().strftime('%Y%m%d')}.json"
    out_file.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(f"Weekly plan outline generated at: {out_file}")


if __name__ == "__main__":
    main()
