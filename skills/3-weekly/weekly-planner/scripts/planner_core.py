#!/usr/bin/env python3
"""
Planner Core Engine - Shared by Weekly Planner and Daily Planner skills.

Provides:
- Dual-mode intake: Native XYZ PRS (releases.db / releases_app.py) or 2-3 pass scratch Markdown fallback.
- Topological PR merge sequencing based on CI statusCheckRollup, reviews, git mergeability, and branch/issue dependencies.
- Anti-stall Provisional Decisions Protocol (anchored to canonical GH issue tracker).
- Adversarial Northstars validation (duplication, shared-file collisions, backfill/reconciler race conditions)
  applied to BOTH weekly outlines and daily pivots.
- Daily adaptive pivoting based on time-bounded merged PRs and closed issues (last 24-36h).
- Consistent multi-format output (both .json and .md) and robust baseline lookup.
"""

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone, timedelta
from pathlib import Path


def run_cmd(cmd: list[str] | str, cwd: Path | None = None, check: bool = True) -> str:
    """Run a shell command safely and return stripped stdout."""
    res = subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
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
        if not re.search(r"^\s*/?temp/?\s*$", content, re.MULTILINE):
            print(f"[WARN] 'temp/' is not explicitly listed in {gitignore}. Add 'temp/' to prevent committing scratch artifacts.", file=sys.stderr)
    return planner_temp


def compute_prs_score(item: dict) -> tuple[int | None, str]:
    """
    Compute composite PRS score (4-400) and human-readable rating badge.
    Formula:
    - If rating_ovr is set (4-400), operator override takes precedence.
    - Else if all 4 axes (pri, sev, appeal, effort) are present (1-100 each), sum them.
    - Returns (score, formatted_token_string).
    """
    ovr = item.get("rating_ovr")
    if ovr is not None:
        try:
            ovr_val = int(ovr)
            return ovr_val, f"*[PRS: {ovr_val} (ovr)]*"
        except (ValueError, TypeError):
            pass

    pri = item.get("rating_pri")
    sev = item.get("rating_sev")
    appeal = item.get("rating_appeal")
    effort = item.get("rating_effort")

    if pri is not None and sev is not None and appeal is not None and effort is not None:
        try:
            p, s, a, e = int(pri), int(sev), int(appeal), int(effort)
            total = p + s + a + e
            return total, f"*[PRS: {total} ({p}/{s}/{a}/{e})]*"
        except (ValueError, TypeError):
            pass

    return None, ""


def get_release_milestones(repo_root: Path) -> dict:
    """
    Fetch comprehensive release milestones, build burndown, exit criterion,
    active marathons, and jog queue from releases.db and releases_app.py next.
    """
    releases_cli = repo_root / "utils" / "py" / "releases_app.py"
    releases_db_file = repo_root / "releases.db"

    next_release = None
    upcoming = []
    raw_next = ""

    if releases_cli.exists():
        try:
            raw_next = run_cmd(["python3", str(releases_cli), "next"], cwd=repo_root, check=False)
            lines = [line.strip() for line in raw_next.splitlines() if line.strip()]
            for line in lines:
                if line.startswith("NEXT:"):
                    next_release = line[len("NEXT:"):].strip()
                elif line.startswith("then:"):
                    upcoming.append(line[len("then:"):].strip())
        except Exception as e:
            print(f"[WARN] Failed to query releases_app.py next: {e}", file=sys.stderr)

    target_release_info = {}
    manifest_summary = {}
    active_marathons = []
    active_jog_queue = []

    if releases_db_file.exists():
        try:
            import sqlite3
            conn = sqlite3.connect(f"file:{releases_db_file}?mode=ro", uri=True)  # SQLITE-GATEWAY-OK: read-only releases.db ledger inspection (GH-1043/GH-777)
            conn.row_factory = sqlite3.Row
            cur = conn.cursor()

            # 1. Target Release metadata
            target_ver = None
            if next_release:
                m = re.match(r"^(\d+\.\d+\.\d+)", next_release)
                if m:
                    target_ver = m.group(1)

            if target_ver:
                rel_row = cur.execute(
                    "SELECT id, version, codename, status, target_date, exit_criterion, description, milestone FROM releases WHERE version = ?",
                    (target_ver,)
                ).fetchone()
            else:
                rel_row = cur.execute(
                    "SELECT id, version, codename, status, target_date, exit_criterion, description, milestone FROM releases WHERE status != 'shipped' "
                    "ORDER BY CASE WHEN status = 'active' THEN 0 ELSE 1 END, target_date ASC, id ASC LIMIT 1"
                ).fetchone()

            if rel_row:
                target_release_info = dict(rel_row)
                rel_id = rel_row["id"]

                # 2. Manifest Items (Release Build Items)
                manifest_rows = cur.execute("""
                    SELECT m.state, ir.url, ir.temp_id, m.dial_reason
                    FROM manifest_items m
                    JOIN issue_refs ir ON m.issue_ref_id = ir.id
                    WHERE m.release_id = ?
                """, (rel_id,)).fetchall()

                shipped_issues = []
                dialed_in_issues = []
                cut_issues = []

                for m_row in manifest_rows:
                    state = m_row["state"]
                    url = m_row["url"] or ""
                    m_iss = re.search(r"/issues/(\d+)", url)
                    iss_num = int(m_iss.group(1)) if m_iss else None

                    item_dict = {
                        "state": state,
                        "issue_number": iss_num,
                        "url": url,
                        "temp_id": m_row["temp_id"],
                        "dial_reason": m_row["dial_reason"],
                    }
                    if state == "shipped":
                        shipped_issues.append(item_dict)
                    elif state == "dialed_in":
                        dialed_in_issues.append(item_dict)
                    elif state == "cut":
                        cut_issues.append(item_dict)

                total_active = len(shipped_issues) + len(dialed_in_issues)
                burndown_pct = round((len(shipped_issues) / total_active) * 100, 1) if total_active > 0 else 0.0

                manifest_summary = {
                    "total_items": len(manifest_rows),
                    "shipped_count": len(shipped_issues),
                    "dialed_in_count": len(dialed_in_issues),
                    "cut_count": len(cut_issues),
                    "burndown_pct": burndown_pct,
                    "shipped_issues": shipped_issues,
                    "dialed_in_issues": dialed_in_issues,
                    "dialed_in_numbers": [i["issue_number"] for i in dialed_in_issues if i["issue_number"] is not None],
                    "cut_issues": cut_issues,
                }

            # 3. Active Marathons
            marathon_rows = cur.execute("""
                SELECT m.id, m.status, ir.url, m.created_at
                FROM marathons m
                JOIN issue_refs ir ON m.tracking_ref_id = ir.id
                WHERE m.status IN ('planned', 'running')
                ORDER BY m.id ASC
            """).fetchall()
            for mr in marathon_rows:
                active_marathons.append(dict(mr))

            # 4. Active Jog Queue (Serial Build Queue)
            jog_rows = cur.execute("""
                SELECT gh_number, position, status, attempt_count
                FROM jog_queue
                WHERE status IN ('pending', 'running')
                ORDER BY position ASC
                LIMIT 10
            """).fetchall()
            for jr in jog_rows:
                active_jog_queue.append(dict(jr))

            conn.close()
        except Exception as e:
            print(f"[WARN] Failed to query releases.db for milestones: {e}", file=sys.stderr)

    overdue_note = ""
    target_date_str = target_release_info.get("target_date")
    if not target_date_str and next_release:
        match = re.search(r"target=(\d{4}-\d{2}-\d{2})", next_release)
        if match:
            target_date_str = match.group(1)

    if target_date_str:
        try:
            target_dt = datetime.strptime(target_date_str, "%Y-%m-%d").date()
            today = datetime.now(timezone.utc).date()
            if target_dt < today:
                days_overdue = (today - target_dt).days
                overdue_note = f" ({days_overdue} days overdue)"
            elif target_dt > today:
                days_remaining = (target_dt - today).days
                overdue_note = f" ({days_remaining} days remaining)"
            else:
                overdue_note = " (due today)"
        except Exception:
            pass

    return {
        "next_release": next_release,
        "overdue_note": overdue_note,
        "upcoming_releases": upcoming,
        "target_release": target_release_info,
        "manifest_summary": manifest_summary,
        "active_marathons": active_marathons,
        "active_jog_queue": active_jog_queue,
        "raw": raw_next,
    }


def get_open_issues(repo_root: Path, gh_repo: str | None = None, limit: int = 500) -> dict[int, dict]:
    """Fetch all open issues from GitHub with metadata to ground planning in live state."""
    cmd = [
        "gh", "issue", "list",
        "--state", "open",
        "--limit", str(limit),
        "--json", "number,title,labels,assignees,body,updatedAt"
    ]
    if gh_repo:
        cmd.extend(["-R", gh_repo])
    try:
        out = run_cmd(cmd, cwd=repo_root, check=True)
        raw_issues = json.loads(out) if out else []
        return {iss["number"]: iss for iss in raw_issues if "number" in iss}
    except Exception as e:
        print(f"[WARN] Failed to fetch live open issues via gh issue list: {e}", file=sys.stderr)
        return {}


def eval_ci_status(pr: dict) -> str:
    """
    Evaluate statusCheckRollup for a PR.
    Returns: 'FAILURE', 'PENDING', 'SUCCESS', or 'NONE'.
    """
    rollup = pr.get("statusCheckRollup") or []
    if not rollup:
        return "NONE"

    has_pending = False
    has_success = False

    for item in rollup:
        typename = item.get("__typename", "")
        if typename == "CheckRun":
            conclusion = (item.get("conclusion") or "").upper()
            status = (item.get("status") or "").upper()
            if conclusion in {"FAILURE", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED", "STARTUP_FAILURE"}:
                return "FAILURE"
            if status in {"IN_PROGRESS", "QUEUED", "WAITING", "PENDING", "REQUESTED"} or (status != "COMPLETED" and not conclusion):
                has_pending = True
            elif conclusion in {"SUCCESS", "NEUTRAL", "SKIPPED"}:
                has_success = True
        elif typename == "StatusContext":
            state = (item.get("state") or "").upper()
            if state in {"FAILURE", "ERROR"}:
                return "FAILURE"
            if state in {"PENDING", "EXPECTED"}:
                has_pending = True
            elif state == "SUCCESS":
                has_success = True
        else:
            state_val = (item.get("state") or item.get("conclusion") or "").upper()
            status_val = (item.get("status") or "").upper()
            if state_val in {"FAILURE", "ERROR", "TIMED_OUT", "CANCELLED"}:
                return "FAILURE"
            if state_val in {"PENDING", "EXPECTED"} or status_val in {"IN_PROGRESS", "QUEUED", "WAITING", "PENDING"}:
                has_pending = True
            elif state_val in {"SUCCESS", "NEUTRAL", "SKIPPED"}:
                has_success = True

    if has_pending:
        return "PENDING"
    if has_success:
        return "SUCCESS"
    return "NONE"


def get_open_prs(repo_root: Path, gh_repo: str | None = None, limit: int = 300) -> list[dict]:
    """Fetch open pull requests and metadata, propagating failures."""
    cmd = [
        "gh", "pr", "list",
        "--state", "open",
        "--limit", str(limit),
        "--json", "number,title,author,headRefName,baseRefName,mergeable,reviewDecision,reviews,updatedAt,statusCheckRollup,files,body,isDraft"
    ]
    if gh_repo:
        cmd.extend(["-R", gh_repo])

    out = run_cmd(cmd, cwd=repo_root, check=True)
    prs = json.loads(out) if out else []
    if len(prs) >= limit:
        print(f"[WARN] Fetched {len(prs)} open PRs (limit={limit}); result may be truncated.", file=sys.stderr)
    return prs


def detect_merge_sequence(prs: list[dict]) -> dict:
    """
    Classify PRs into 4 status groups and compute a topological merge sequence:
    1. Phase 1: ready_to_land — Approved, MERGEABLE, passing or neutral CI, and unblocked.
    2. Phase 2: blockers_to_fix — CHANGES_REQUESTED or broken CI (must be fixed to unblock downstream).
    3. Phase 3: needs_rebase — CONFLICTING state (requires rebase against base branch).
    4. Phase 4: in_review_or_wip — Review-pending, CI-pending, or draft PRs.

    Topological dependency resolution considers:
    - Base branch dependencies (where PR A's baseRefName is PR B's headRefName).
    - In-body references (Depends on #<id>, Stacked on #<id>).
    """
    head_to_pr = {pr.get("headRefName"): pr.get("number") for pr in prs if pr.get("headRefName")}
    pr_by_number = {pr.get("number"): pr for pr in prs if pr.get("number")}

    # Build direct dependencies
    pr_dependencies: dict[int, set[int]] = {}
    for pr in prs:
        num = pr.get("number")
        deps: set[int] = set()
        # 1. Branch stacking
        base = pr.get("baseRefName")
        if base and base in head_to_pr and head_to_pr[base] != num:
            dep_num = head_to_pr[base]
            if dep_num:
                deps.add(dep_num)
        # 2. Body dependencies
        body = pr.get("body") or ""
        for match in re.finditer(r"(?i)(?:depends\s+on|stacked\s+on|prerequisite:?)\s+#(\d+)", body):
            dep_num = int(match.group(1))
            if dep_num in pr_by_number and dep_num != num:
                deps.add(dep_num)
        pr_dependencies[num] = deps

    phase_ready = []
    phase_ready_pending_undraft = []
    phase_blocker_fixes = []
    phase_needs_rebase = []
    phase_held_or_evidence = []
    phase_in_review = []

    for pr in prs:
        decision = (pr.get("reviewDecision") or "").upper()
        mergeable = (pr.get("mergeable") or "").upper()
        is_draft = bool(pr.get("isDraft"))
        ci = eval_ci_status(pr)
        title = pr.get("title") or ""
        body = pr.get("body") or ""
        combined_text = f"{title} {body}".lower()

        # Detect explicit holds or evidence carrier status
        is_held = False
        hold_reason = ""
        is_evidence_carrier = False

        if re.search(r"\bhold\b", title, re.IGNORECASE):
            is_held = True
            hold_reason = "Explicit HOLD in title"
        elif re.search(r"leave (?:this draft )?unmerged|leave unmerged", combined_text):
            is_held = True
            is_evidence_carrier = True
            hold_reason = "Evidence carrier (leave unmerged)"
        elif re.search(r"not an (?:additional )?authorized merge", combined_text):
            is_held = True
            is_evidence_carrier = True
            hold_reason = "Evidence retention (not an authorized merge)"
        elif re.search(r"prerequisites? required|live-pilot", combined_text):
            is_held = True
            hold_reason = "Prerequisites required"
        elif re.search(r"review authority limit|fail/escalated", combined_text):
            is_held = True
            hold_reason = "Review authority limit / unresolved escalation"

        if re.search(r"qualification receipts?|reconciliation receipts?|evidence carrier", combined_text):
            is_evidence_carrier = True

        pr_with_ci = dict(pr)
        pr_with_ci["ci_status"] = ci
        pr_with_ci["is_held"] = is_held
        pr_with_ci["hold_reason"] = hold_reason
        pr_with_ci["is_evidence_carrier"] = is_evidence_carrier
        pr_with_ci["dependencies"] = sorted(list(pr_dependencies.get(pr.get("number"), set())))

        if is_held or is_evidence_carrier:
            phase_held_or_evidence.append(pr_with_ci)
        elif decision == "CHANGES_REQUESTED" or ci == "FAILURE":
            phase_blocker_fixes.append(pr_with_ci)
        elif mergeable == "CONFLICTING":
            phase_needs_rebase.append(pr_with_ci)
        elif decision == "APPROVED" and mergeable == "MERGEABLE" and ci in {"SUCCESS", "NONE"} and not is_draft:
            phase_ready.append(pr_with_ci)
        elif is_draft and mergeable == "MERGEABLE" and ci in {"SUCCESS", "NONE"}:
            phase_ready_pending_undraft.append(pr_with_ci)
        else:
            phase_in_review.append(pr_with_ci)

    # Topologically sort phase_ready:
    # A PR in ready_to_land should only land after any prerequisite PRs it depends on.
    ready_numbers = {p["number"] for p in phase_ready}
    sorted_ready = []
    visited: set[int] = set()
    visiting: set[int] = set()

    def visit(num: int):
        if num in visiting:
            # Cycle detected, break cycle
            return
        if num in visited:
            return
        visiting.add(num)
        for dep in pr_dependencies.get(num, set()):
            if dep in ready_numbers:
                visit(dep)
        visiting.remove(num)
        visited.add(num)
        p = pr_by_number.get(num)
        if p and p["number"] in ready_numbers:
            pr_data = next((x for x in phase_ready if x["number"] == num), p)
            sorted_ready.append(pr_data)

    for p in phase_ready:
        if p["number"] not in visited:
            visit(p["number"])

    # Any ready PR whose dependencies are not ready is marked as blocked
    for p in sorted_ready:
        unmet_deps = [d for d in pr_dependencies.get(p["number"], set()) if d not in ready_numbers]
        p["blocked_by_unmerged"] = unmet_deps

    return {
        "status_phases": {
            "ready_to_land": sorted_ready,
            "ready_pending_undraft": phase_ready_pending_undraft,
            "blockers_to_fix": phase_blocker_fixes,
            "needs_rebase": phase_needs_rebase,
            "evidence_carriers_or_held": phase_held_or_evidence,
            "in_review_or_wip": phase_in_review,
        },
        "topological_merge_sequence": sorted_ready,
        # Backward-compatible aliases at root
        "ready_to_land": sorted_ready,
        "ready_pending_undraft": phase_ready_pending_undraft,
        "blockers_to_fix": phase_blocker_fixes,
        "needs_rebase": phase_needs_rebase,
        "evidence_carriers_or_held": phase_held_or_evidence,
        "in_review_or_wip": phase_in_review,
    }


def audit_adversarial(plan: dict, prs: list[dict] | None = None) -> dict:
    """
    Adversarial Northstars Audit:
    - Check for external dependency stalls ('waiting for X to decide').
    - Check for actual file collisions across open PRs / plan tasks (especially CHANGELOG.md, schema, configs).
    - Check for data pipeline vs reconciler concurrency hazards (backfill overlapping active reconciler).
    - Check for duplicate tasks / PRs targeting identical fixes.
    """
    findings = []
    open_prs = prs if prs is not None else plan.get("prs", [])

    # 1. External Stalls check
    # Check plan task items, blockers, and PR titles (ignoring mentions of the anti-stall rule itself)
    task_items = plan.get("tasks") or plan.get("roadmap_items") or plan.get("raw_tasks") or []
    stall_targets = []
    for t in task_items:
        t_str = str(t)
        if any(neg in t_str.lower() for neg in ["never write", "forbids", "protocol", "anti-stall", "rule:"]):
            continue
        if re.search(r"\bwaiting\s+(?:for|on)\b", t_str, re.IGNORECASE):
            stall_targets.append(t_str[:80])

    for pr in open_prs:
        title = pr.get("title", "")
        if re.search(r"\bwaiting\s+(?:for|on)\s+(?:stakeholder|client|decision|pm|legal|review|elan|sam|marketing)\b", title, re.IGNORECASE):
            stall_targets.append(f"PR #{pr.get('number')}: {title}")

    if stall_targets:
        findings.append({
            "severity": "HIGH",
            "type": "ANTI_STALL_VIOLATION",
            "message": f"Plan/tasks mention waiting on external feedback: {'; '.join(stall_targets)}. Enforce Provisional Decision Protocol: define a provisional default, record on tracker issue, and wire a UI setting/re-compute button."
        })

    # 2. File Collision & Merge Friction check (based on real changed files)
    file_to_prs: dict[str, list[int]] = {}
    for pr in open_prs:
        pr_num = pr.get("number")
        files = pr.get("files") or []
        for f in files:
            path = f.get("path") if isinstance(f, dict) else str(f)
            if path and pr_num is not None:
                file_to_prs.setdefault(path, []).append(pr_num)

    colliding_files = {path: nums for path, nums in file_to_prs.items() if len(nums) > 1}
    if colliding_files:
        sample_collisions = [f"{path} (PRs: {nums})" for path, nums in list(colliding_files.items())[:5]]
        findings.append({
            "severity": "MEDIUM",
            "type": "MERGE_FRICTION",
            "message": f"Detected {len(colliding_files)} overlapping file(s) across active PRs: {'; '.join(sample_collisions)}. Enforce sequential landing order to prevent merge conflicts."
        })

    # 3. Data pipeline vs Reconciler concurrency check (backfill overlapping reconciler/sync)
    backfill_items = []
    reconciler_items = []

    # Check PRs
    for pr in open_prs:
        title_ref = (pr.get("title", "") + " " + pr.get("headRefName", "")).lower()
        if "backfill" in title_ref:
            backfill_items.append(f"PR #{pr.get('number')}: {pr.get('title')}")
        if any(k in title_ref for k in ["reconcil", "rolling", "stream", "realtime", "sync"]):
            reconciler_items.append(f"PR #{pr.get('number')}: {pr.get('title')}")

    # Check Plan tasks if present
    plan_tasks = plan.get("tasks") or plan.get("roadmap_items") or []
    for t in plan_tasks:
        t_text = str(t).lower()
        if "backfill" in t_text:
            backfill_items.append(str(t)[:60])
        if any(k in t_text for k in ["reconcil", "rolling", "stream", "sync"]):
            reconciler_items.append(str(t)[:60])

    if backfill_items and reconciler_items:
        findings.append({
            "severity": "HIGH",
            "type": "DATA_RACE_HAZARD",
            "message": f"Concurrent backfill ({len(backfill_items)} item(s)) and reconciler ({len(reconciler_items)} item(s)) operations detected. Backfill operations must enforce isolated window keys (--window-key) or run in separate execution windows."
        })

    # 4. Duplicate task check
    seen_issues: dict[str, list[int]] = {}
    for pr in open_prs:
        title = pr.get("title", "")
        pr_num = pr.get("number")
        if pr_num is None:
            continue
        # Skip evidence carriers, receipts, and doc PRs from implementation duplication flags
        body = pr.get("body") or ""
        combined = f"{title} {body}".lower()
        if pr.get("is_evidence_carrier") or any(k in combined for k in ["leave this draft unmerged", "leave unmerged", "qualification receipts", "evidence carrier"]):
            continue
        if title.lower().startswith("docs("):
            continue

        for match in re.finditer(r"(?i)(?:fixes|closes|resolves|gh-|#)(\d+)", title):
            issue_id = match.group(1)
            seen_issues.setdefault(issue_id, []).append(pr_num)
    duplicates = {iss: nums for iss, nums in seen_issues.items() if len(nums) > 1}
    if duplicates:
        dup_summary = [f"Issue #{iss} claimed by PRs: {nums}" for iss, nums in duplicates.items()]
        findings.append({
            "severity": "MEDIUM",
            "type": "TASK_DUPLICATION",
            "message": f"Multiple implementation PRs targeting identical issue/task: {'; '.join(dup_summary)}."
        })

    return {
        "passed": len([f for f in findings if f["severity"] == "HIGH"]) == 0,
        "findings": findings
    }


def fetch_recent_merges(repo_root: Path, gh_repo: str | None = None, hours: int = 36) -> list[dict]:
    """Fetch PRs merged in the last N hours (filtered by mergedAt)."""
    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
    cutoff_date = cutoff.strftime("%Y-%m-%d")
    cmd = [
        "gh", "pr", "list",
        "--state", "merged",
        "--search", f"merged:>={cutoff_date}",
        "--limit", "200",
        "--json", "number,title,mergedAt,headRefName,baseRefName,author,files"
    ]
    if gh_repo:
        cmd.extend(["-R", gh_repo])

    out = run_cmd(cmd, cwd=repo_root, check=True)
    raw_prs = json.loads(out) if out else []

    filtered = []
    for pr in raw_prs:
        merged_str = pr.get("mergedAt")
        if not merged_str:
            continue
        try:
            merged_dt = datetime.fromisoformat(merged_str.replace("Z", "+00:00"))
            if merged_dt >= cutoff:
                filtered.append(pr)
        except ValueError:
            filtered.append(pr)

    filtered.sort(key=lambda x: x.get("mergedAt", ""), reverse=True)
    return filtered


def fetch_recent_closed_issues(repo_root: Path, gh_repo: str | None = None, hours: int = 36) -> list[dict]:
    """Fetch issues closed in the last N hours (filtered by closedAt)."""
    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
    cutoff_date = cutoff.strftime("%Y-%m-%d")
    cmd = [
        "gh", "issue", "list",
        "--state", "closed",
        "--search", f"closed:>={cutoff_date}",
        "--limit", "200",
        "--json", "number,title,closedAt,state,author,labels,assignees"
    ]
    if gh_repo:
        cmd.extend(["-R", gh_repo])

    out = run_cmd(cmd, cwd=repo_root, check=True)
    raw_issues = json.loads(out) if out else []

    filtered = []
    for issue in raw_issues:
        closed_str = issue.get("closedAt")
        if not closed_str:
            continue
        try:
            closed_dt = datetime.fromisoformat(closed_str.replace("Z", "+00:00"))
            if closed_dt >= cutoff:
                filtered.append(issue)
        except ValueError:
            filtered.append(issue)

    filtered.sort(key=lambda x: x.get("closedAt", ""), reverse=True)
    return filtered


def find_latest_weekly_plan(temp_dir: Path) -> Path | None:
    """Find the most recent weekly plan file (.json or .md) in temp/planner/."""
    candidates = []
    patterns = ["weekly-plan-*.json", "WEEKLY-PLAN-*.json", "weekly-plan-*.md", "WEEKLY-PLAN-*.md"]
    for pat in patterns:
        candidates.extend(temp_dir.glob(pat))

    if not candidates:
        return None

    # Sort by mtime descending
    candidates.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return candidates[0]


def load_weekly_plan(plan_file: Path) -> dict:
    """Load and validate an existing weekly plan JSON or Markdown outline."""
    if not plan_file.exists():
        raise FileNotFoundError(f"Weekly plan file does not exist: {plan_file}")

    content = plan_file.read_text(encoding="utf-8").strip()
    if not content:
        raise ValueError(f"Weekly plan file is empty: {plan_file}")

    if plan_file.suffix.lower() == ".json":
        data = json.loads(content)
        if not isinstance(data, dict):
            raise ValueError(f"Invalid JSON weekly plan structure in {plan_file}")
        return data

    # Parse Markdown plan
    tasks = []
    for line in content.splitlines():
        line_clean = line.strip()
        if line_clean.startswith(("- [ ]", "- [x]", "* [ ]", "* [x]", "- **GH-", "- #")):
            tasks.append(line_clean)

    return {
        "mode": "weekly_plan_md",
        "file_path": str(plan_file),
        "raw_tasks": tasks,
        "content_length": len(content),
    }


def pivot_daily(weekly_plan_file: Path | None, repo_root: Path, gh_repo: str | None = None, hours: int = 36) -> dict:
    """
    Generate daily plan pivot:
    1. Validates and loads weekly baseline plan (fails if missing).
    2. Ingests merged PRs and closed issues in the last N hours.
    3. Reconciles baseline items against closures.
    4. Identifies accomplished items and updates queue.
    """
    temp_dir = ensure_temp_dir(repo_root)

    resolved_plan_file = weekly_plan_file
    if not resolved_plan_file:
        resolved_plan_file = find_latest_weekly_plan(temp_dir)

    if not resolved_plan_file or not resolved_plan_file.exists():
        raise FileNotFoundError(
            "No active weekly plan baseline found in temp/planner/. "
            "Please run /weekly-planner first to establish the baseline before generating a daily pivot."
        )

    baseline_plan = load_weekly_plan(resolved_plan_file)

    # Ingest closures
    recent_merges = fetch_recent_merges(repo_root, gh_repo, hours=hours)
    recent_closed_issues = fetch_recent_closed_issues(repo_root, gh_repo, hours=hours)

    merged_numbers = {pr["number"] for pr in recent_merges}
    closed_numbers = {issue["number"] for issue in recent_closed_issues}
    all_closed_refs = merged_numbers.union(closed_numbers)

    # Reconcile baseline items
    baseline_items = baseline_plan.get("tasks") or baseline_plan.get("roadmap_items") or baseline_plan.get("raw_tasks") or []
    completed_items = []
    active_items = []

    for item in baseline_items:
        item_str = str(item)
        match = re.search(r"(?:GH-|#)(\d+)", item_str)
        if match and int(match.group(1)) in all_closed_refs:
            completed_items.append({"item": item, "status": "DONE", "closed_via": "PR_OR_ISSUE"})
        else:
            active_items.append({"item": item, "status": "PENDING"})

    return {
        "baseline_file": str(resolved_plan_file),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "interval_hours": hours,
        "accomplished_yesterday": {
            "merged_prs": recent_merges,
            "closed_issues": recent_closed_issues,
        },
        "completed_items": completed_items,
        "active_items": active_items,
    }


def ingest_weekly_intake(repo_root: Path, gh_repo: str | None = None, team_issue: int | None = None, fallback_mode: bool = False) -> dict:
    """
    Ingest weekly signals:
    - Grounding: Validates open issues against live GitHub state (drops closed/retired/foreign issues).
    - Release Milestone Anchor: Ingests next unshipped release, exit criterion, manifest build burndown,
      active marathons, and jog queue from releases.db and releases_app.py next.
    - Mode A (Native XYZ): Query PRS 4-axis ratings (pri, sev, appeal, effort, ovr, risk) directly from
      releases.db roadmap_items (or releases_app.py fallback).
    - Mode B (Fallback): Query open GitHub issues and generate pass1-intake.md and pass2-sharpened.md.
    - Prioritization: Sorts tasks by (is_release_build, prs_score) descending so dialed-in release builds
      and high-value/cheap tasks advance first.
    - Grounded Assignment: Assigns issues based on explicit GitHub assignees or --team-issue;
      leaves unassigned tasks in sorted triage queue.
    """
    temp_dir = ensure_temp_dir(repo_root)
    intake_mode = "fallback_scratch"
    roadmap_items = []
    active_candidates = []
    deferred_items = []
    unassigned_items = []

    open_issues = get_open_issues(repo_root, gh_repo)
    release_milestones = get_release_milestones(repo_root)

    dialed_in_set = set(release_milestones.get("manifest_summary", {}).get("dialed_in_numbers", []))
    target_release_ver = release_milestones.get("target_release", {}).get("version")

    teammates: dict[str, dict] = {
        "Noel": {"domain": "Orchestration/Gate", "tasks": []},
        "Jose": {"domain": "Data/Pipeline", "tasks": []},
        "Matthew": {"domain": "NexMail/Calendar", "tasks": []},
    }

    releases_cli = repo_root / "utils" / "py" / "releases_app.py"
    releases_db = repo_root / "releases.db"

    if not fallback_mode and releases_db.exists():
        try:
            import sqlite3
            conn = sqlite3.connect(f"file:{releases_db}?mode=ro", uri=True)  # SQLITE-GATEWAY-OK: read-only releases.db ledger inspection (GH-1043/GH-777)
            conn.row_factory = sqlite3.Row
            cur = conn.cursor()
            rows = cur.execute("""
                SELECT gh_number, title, section, position, status_marker,
                       rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr,
                       risk, complexity, effort, status_label, raw_text
                FROM roadmap_items
                ORDER BY section, position
            """).fetchall()
            raw_items = [dict(r) for r in rows]
            conn.close()
            intake_mode = "native_prs"

            for item in raw_items:
                section = (item.get("section") or "").lower()
                if section in {"completed", "done", "shipped"}:
                    continue
                status_marker = (item.get("status_marker") or "").strip()
                if status_marker in {"✅", "[DONE]", "shipped"}:
                    continue

                raw_title = item.get("title") or ""
                raw_text = item.get("raw_text") or ""
                combined = f"{raw_title} {raw_text}".lower()

                # Filter out superseded or retired items
                if any(t in combined for t in ["superseded", "retired", "do not implement"]):
                    continue
                if "deferred" in combined and "vision" in combined:
                    continue

                gh_num_raw = item.get("gh_number")
                if not gh_num_raw:
                    continue
                try:
                    gh_num = int(gh_num_raw)
                except (ValueError, TypeError):
                    continue

                # Grounding check: Issue must actually be open in GitHub!
                if open_issues and gh_num not in open_issues:
                    continue

                # Enrich with live assignees and labels from GitHub
                if gh_num in open_issues:
                    live_iss = open_issues[gh_num]
                    item["live_assignees"] = [a.get("login") for a in live_iss.get("assignees", []) if isinstance(a, dict)]
                    item["live_labels"] = [lbl.get("name") for lbl in live_iss.get("labels", []) if isinstance(lbl, dict)]
                    item["updated_at"] = live_iss.get("updatedAt")

                # PRS score calculation
                score, prs_badge = compute_prs_score(item)
                item["prs_score"] = score
                item["prs_badge"] = prs_badge

                # Risk gate check (risk >= 4 acts as human gate, not summed)
                risk_val = item.get("risk")
                if risk_val is not None:
                    try:
                        if int(risk_val) >= 4:
                            item["is_high_risk_gate"] = True
                            item["risk_gate_badge"] = f"*[GATE: risk {risk_val}]*"
                    except (ValueError, TypeError):
                        pass

                # Dialed-in release build association
                if gh_num in dialed_in_set:
                    item["is_release_build"] = True
                    item["release_build_version"] = target_release_ver

                roadmap_items.append(item)
        except Exception as e:
            print(f"[WARN] Direct releases.db roadmap intake failed ({e}); falling back to CLI.", file=sys.stderr)

    if not roadmap_items and not fallback_mode and releases_cli.exists():
        try:
            cmd = ["python3", str(releases_cli), "roadmap", "list", "--json"]
            out = run_cmd(cmd, cwd=repo_root, check=True)
            if out:
                raw_items = json.loads(out)
                intake_mode = "native_prs"
                for item in raw_items:
                    section = (item.get("section") or "").lower()
                    if section in {"completed", "done", "shipped"}:
                        continue
                    status_marker = (item.get("status_marker") or "").strip()
                    if status_marker in {"✅", "[DONE]", "shipped"}:
                        continue

                    raw_title = item.get("title") or ""
                    raw_text = item.get("raw_text") or ""
                    combined = f"{raw_title} {raw_text}".lower()

                    if any(t in combined for t in ["superseded", "retired", "do not implement"]):
                        continue
                    if "deferred" in combined and "vision" in combined:
                        continue

                    gh_num_raw = item.get("gh_number")
                    if not gh_num_raw:
                        continue
                    try:
                        gh_num = int(gh_num_raw)
                    except ValueError:
                        continue

                    if open_issues and gh_num not in open_issues:
                        continue

                    if gh_num in open_issues:
                        live_iss = open_issues[gh_num]
                        item["live_assignees"] = [a.get("login") for a in live_iss.get("assignees", []) if isinstance(a, dict)]
                        item["live_labels"] = [lbl.get("name") for lbl in live_iss.get("labels", []) if isinstance(lbl, dict)]
                        item["updated_at"] = live_iss.get("updatedAt")

                    if gh_num in dialed_in_set:
                        item["is_release_build"] = True
                        item["release_build_version"] = target_release_ver

                    roadmap_items.append(item)
        except (subprocess.SubprocessError, json.JSONDecodeError, OSError, RuntimeError) as e:
            print(f"[WARN] Native CLI intake failed ({e}); falling back to GitHub issues intake.", file=sys.stderr)

    if not roadmap_items:
        intake_mode = "fallback_scratch"
        raw_issues = list(open_issues.values()) if open_issues else []
        if not raw_issues:
            cmd = [
                "gh", "issue", "list",
                "--state", "open",
                "--limit", "100",
                "--json", "number,title,labels,assignees,body,updatedAt"
            ]
            if gh_repo:
                cmd.extend(["-R", gh_repo])
            out = run_cmd(cmd, cwd=repo_root, check=True)
            raw_issues = json.loads(out) if out else []

        roadmap_items = [
            {
                "gh_number": iss.get("number"),
                "title": iss.get("title"),
                "labels": [lbl.get("name") for lbl in iss.get("labels", []) if isinstance(lbl, dict)],
                "assignees": [a.get("login") for a in iss.get("assignees", []) if isinstance(a, dict)],
                "live_assignees": [a.get("login") for a in iss.get("assignees", []) if isinstance(a, dict)],
                "section": "Open Issues Intake",
                "updated_at": iss.get("updatedAt"),
                "is_release_build": iss.get("number") in dialed_in_set,
                "release_build_version": target_release_ver,
            }
            for iss in raw_issues
        ]

        # Generate pass1-intake.md and pass2-sharpened.md in temp/planner/
        pass1_file = temp_dir / "pass1-intake.md"
        pass1_lines = ["# Pass 1: Unfiltered Task Intake\n"]
        for item in roadmap_items:
            pass1_lines.append(f"- #{item.get('gh_number')} {item.get('title')}")
        pass1_file.write_text("\n".join(pass1_lines) + "\n", encoding="utf-8")

        pass2_file = temp_dir / "pass2-sharpened.md"
        pass2_lines = ["# Pass 2: Sharpened & Prioritized Tasks\n"]
        for item in roadmap_items[:20]:
            pass2_lines.append(f"- [ ] **GH-{item.get('gh_number')}**: {item.get('title')}")
        pass2_file.write_text("\n".join(pass2_lines) + "\n", encoding="utf-8")

    # Ingest team weekly issue if provided
    if team_issue:
        try:
            cmd = ["gh", "issue", "view", str(team_issue), "--json", "body,assignees,title"]
            if gh_repo:
                cmd.extend(["-R", gh_repo])
            out = run_cmd(cmd, cwd=repo_root, check=True)
            issue_data = json.loads(out)
            body = issue_data.get("body", "")
            for line in body.splitlines():
                match = re.search(r"([A-Z][a-z]+)\s*(?:->|:|-)\s*([A-Za-z0-9_ /-]+)", line)
                if match:
                    name, domain = match.group(1), match.group(2).strip()
                    teammates[name] = {"domain": domain, "tasks": []}
        except (subprocess.SubprocessError, json.JSONDecodeError, OSError, RuntimeError) as e:
            print(f"[WARN] Failed to parse team issue #{team_issue}: {e}", file=sys.stderr)

    # Ground task assignments in explicit GitHub assignees or explicit issue mapping
    login_to_member = {
        "noelsaw1": "Noel",
        "noel": "Noel",
        "jose": "Jose",
        "matthew": "Matthew",
    }

    for item in roadmap_items:
        title = item.get("title") or ""
        if title.lower().startswith("deferred:"):
            deferred_items.append(item)
            continue

        assigned = False
        live_assignees = item.get("live_assignees") or item.get("assignees") or []
        for login in live_assignees:
            member = login_to_member.get(login.lower())
            if member and member in teammates:
                teammates[member]["tasks"].append(item)
                item["assignment_source"] = f"GitHub assignee (@{login})"
                assigned = True
                break

        if not assigned:
            unassigned_items.append(item)
        active_candidates.append(item)

    def sort_plan_tasks(tasks: list[dict]) -> list[dict]:
        """
        Prioritize tasks:
        1. Dialed-in release build tasks first.
        2. Highest composite PRS score descending.
        3. Original ledger position ascending (tie-breaker).
        """
        return sorted(
            tasks,
            key=lambda x: (
                1 if x.get("is_release_build") else 0,
                x.get("prs_score") if x.get("prs_score") is not None else -1,
                -(x.get("position") or 999),
            ),
            reverse=True,
        )

    for member in teammates:
        teammates[member]["tasks"] = sort_plan_tasks(teammates[member]["tasks"])
    unassigned_items = sort_plan_tasks(unassigned_items)
    active_candidates = sort_plan_tasks(active_candidates)

    return {
        "intake_mode": intake_mode,
        "roadmap_items": active_candidates,
        "deferred_items": deferred_items,
        "unassigned_items": unassigned_items,
        "teammate_assignments": teammates,
        "release_milestones": release_milestones,
    }


def format_weekly_markdown(date_str: str, plan_data: dict) -> str:
    """Format weekly plan as a clean, complete Markdown document."""
    seq = plan_data.get("merge_sequence", {})
    phases = seq.get("status_phases", {})
    ready = phases.get("ready_to_land", [])
    ready_undraft = phases.get("ready_pending_undraft", [])
    blockers = phases.get("blockers_to_fix", [])
    rebase = phases.get("needs_rebase", [])
    in_review = phases.get("in_review_or_wip", [])
    held_or_evidence = phases.get("evidence_carriers_or_held", [])

    audit = plan_data.get("adversarial_audit", {})
    teammates = plan_data.get("teammate_assignments", {})
    unassigned = plan_data.get("unassigned_items", [])
    deferred = plan_data.get("deferred_items", [])
    release_info = plan_data.get("release_milestones", {})
    decisions_issue = plan_data.get("decisions_issue", "NONE_SET")

    # Compute 7-day planning window
    try:
        start_dt = datetime.strptime(date_str, "%Y-%m-%d")
        end_dt = start_dt + timedelta(days=6)
        window_str = f"{start_dt.strftime('%b %d')} – {end_dt.strftime('%b %d, %Y')} (America/Los_Angeles)"
    except Exception:
        window_str = date_str

    lines = [
        f"# Weekly Plan Outline — {date_str}",
        "",
        f"- **Planning Window:** {window_str}",
        f"- **Generated:** {plan_data.get('timestamp')}",
        f"- **Intake Mode:** {plan_data.get('intake_mode')}",
        f"- **Provisional Decisions Register:** Issue #{decisions_issue}" if decisions_issue != "NONE_SET" else "- **Provisional Decisions Register:** None configured",
        "",
        "## 0. Release Milestone Context & Active Targets",
        ""
    ]

    next_rel = release_info.get("next_release")
    overdue_note = release_info.get("overdue_note", "")
    upcoming = release_info.get("upcoming_releases", [])

    target_rel = release_info.get("target_release", {})
    manifest = release_info.get("manifest_summary", {})
    marathons = release_info.get("active_marathons", [])
    jog_q = release_info.get("active_jog_queue", [])

    if next_rel or target_rel:
        rel_title = next_rel if next_rel else f"{target_rel.get('version')} {target_rel.get('codename')} ({target_rel.get('status')})"
        lines.append(f"- **Target Release:** `{rel_title}`{overdue_note}")
        exit_crit = target_rel.get("exit_criterion")
        if exit_crit:
            clean_exit = exit_crit.strip().replace("\n", " ")
            if len(clean_exit) > 200:
                clean_exit = clean_exit[:197] + "..."
            lines.append(f"- **Release Exit Criterion:** {clean_exit}")

        if manifest and manifest.get("total_items", 0) > 0:
            shipped = manifest.get("shipped_count", 0)
            dialed = manifest.get("dialed_in_count", 0)
            pct = manifest.get("burndown_pct", 0.0)
            lines.append(f"- **Release Build Burndown:** {shipped} shipped, {dialed} dialed-in ({pct}% complete)")
            dialed_nums = manifest.get("dialed_in_numbers", [])
            if dialed_nums:
                dialed_str = ", ".join(f"#{num}" for num in dialed_nums)
                lines.append(f"- **Dialed-in Build Tasks:** {dialed_str}")

        if upcoming:
            lines.append("- **Subsequent Milestones:**")
            for u in upcoming:
                lines.append(f"  - `{u}`")

        if marathons:
            lines.append("- **Active Marathons:**")
            for m in marathons:
                lines.append(f"  - Marathon #{m.get('id')} (`{m.get('status')}`): {m.get('url')}")

        if jog_q:
            lines.append("- **Active Jog Build Queue:**")
            for j in jog_q:
                lines.append(f"  - Pos {j.get('position')}: GH-{j.get('gh_number')} (status: `{j.get('status')}`)")
    else:
        lines.append("- *No release targets detected from releases_app.py next or releases.db.*")

    lines.extend([
        "",
        "## 1. Immediate P0 Blockers",
        ""
    ])

    if blockers:
        for p in blockers:
            lines.append(f"- **PR #{p.get('number')}** ({p.get('author', {}).get('login', 'unknown')}): {p.get('title')} — CI: `{p.get('ci_status', 'UNKNOWN')}` | Review: `{p.get('reviewDecision', 'NONE')}`")
    else:
        lines.append("- *No open PR blockers detected.*")

    lines.extend([
        "",
        "## 2. PR Merge Sequence (Topologically Ordered)",
        ""
    ])

    if ready:
        lines.append("### Phase 1: Ready to Land")
        for p in ready:
            deps_note = f" (depends on PR #{p['dependencies']})" if p.get("dependencies") else ""
            lines.append(f"1. **PR #{p.get('number')}**: {p.get('title')}{deps_note} — `MERGEABLE`, CI: `{p.get('ci_status')}`")
        lines.append("")
    else:
        lines.append("### Phase 1: Ready to Land")
        lines.append("- *No PRs currently ready to land.*")
        lines.append("")

    if ready_undraft:
        lines.append("### Phase 2: Ready Pending Undraft")
        for p in ready_undraft:
            lines.append(f"- **PR #{p.get('number')}**: {p.get('title')} — `DRAFT`, CI: `{p.get('ci_status')}` (ready to undraft upon operator check)")
        lines.append("")

    if rebase:
        lines.append("### Phase 3: Needs Rebase")
        for p in rebase:
            lines.append(f"- **PR #{p.get('number')}**: {p.get('title')} — `CONFLICTING` against base")
        lines.append("")

    if in_review:
        lines.append("### Phase 4: In Review / WIP")
        for p in in_review:
            lines.append(f"- **PR #{p.get('number')}**: {p.get('title')} — Review: `{p.get('reviewDecision') or 'PENDING'}`, CI: `{p.get('ci_status')}`")
        lines.append("")

    if held_or_evidence:
        lines.append("### Phase 5: Held Drafts & Evidence Carriers (Do Not Merge Directly)")
        for p in held_or_evidence:
            reason = p.get("hold_reason") or "Held / Evidence retention"
            lines.append(f"- **PR #{p.get('number')}**: {p.get('title')} — Status: `{reason}`")
        lines.append("")

    def format_task_item(t: dict) -> str:
        gh_num = t.get("gh_number") or t.get("number")
        title = t.get("title") or ""
        badges = []
        if t.get("is_release_build"):
            ver = t.get("release_build_version")
            badges.append(f"*[Release Build: {ver}]*" if ver else "*[Release Build]*")
        if t.get("prs_badge"):
            badges.append(t["prs_badge"])
        if t.get("risk_gate_badge"):
            badges.append(t["risk_gate_badge"])
        if t.get("assignment_source"):
            badges.append(f"*[{t['assignment_source']}]*")
        badge_str = (" " + " ".join(badges)) if badges else ""
        return f"- [ ] **GH-{gh_num}**: {title}{badge_str}"

    lines.extend([
        "## 3. Teammate Focus & Action Outlines",
        ""
    ])

    for member, data in teammates.items():
        domain = data.get("domain", "General")
        tasks = data.get("tasks", [])
        lines.append(f"### {member} ({domain})")
        if tasks:
            for t in tasks:
                lines.append(format_task_item(t))
        else:
            lines.append("- *No scheduled tasks assigned.*")
        lines.append("")

    if unassigned:
        lines.append("### Unassigned / Triage Queue")
        for t in unassigned[:10]:
            lines.append(format_task_item(t))
        if len(unassigned) > 10:
            lines.append(f"- *... and {len(unassigned) - 10} more unassigned items in roadmap ledger.*")
        lines.append("")

    if deferred:
        lines.append("### Deferred / Parked Intake")
        for t in deferred[:10]:
            lines.append(format_task_item(t))
        lines.append("")

    lines.extend([
        "## 4. Adversarial Northstars Audit",
        ""
    ])

    findings = audit.get("findings", [])
    if findings:
        for f in findings:
            lines.append(f"- **[{f.get('severity')}] {f.get('type')}**: {f.get('message')}")
    else:
        lines.append("- **PASS:** Zero contradictions, file collisions, concurrency hazards, or external stalls detected.")

    lines.append("")
    return "\n".join(lines)


def format_daily_markdown(date_str: str, pivot_data: dict) -> str:
    """Format daily pivot as a clean, complete Markdown document."""
    pivot = pivot_data.get("pivot", {})
    seq = pivot_data.get("merge_sequence", {})
    phases = seq.get("status_phases", {})
    ready = phases.get("ready_to_land", [])
    blockers = phases.get("blockers_to_fix", [])
    audit = pivot_data.get("adversarial_audit", {})
    yesterday = pivot.get("accomplished_yesterday", {})
    merged_prs = yesterday.get("merged_prs", [])
    closed_issues = yesterday.get("closed_issues", [])

    lines = [
        f"# Daily Plan Pivot — {date_str}",
        "",
        f"- **Baseline Weekly Plan:** `{pivot.get('baseline_file')}`",
        f"- **Timestamp:** {pivot.get('timestamp')}",
        "",
        "## 1. Accomplished Yesterday",
        "",
        "### Merged Pull Requests (Last 24–36h)",
    ]

    if merged_prs:
        for pr in merged_prs:
            lines.append(f"- **PR #{pr.get('number')}** ({pr.get('author', {}).get('login', 'unknown')}): {pr.get('title')} (`{pr.get('mergedAt')}`)")
    else:
        lines.append("- *No pull requests merged in this interval.*")

    lines.extend([
        "",
        "### Closed Issues (Last 24–36h)",
    ])

    if closed_issues:
        for iss in closed_issues:
            lines.append(f"- **Issue #{iss.get('number')}**: {iss.get('title')} (`{iss.get('closedAt')}`)")
    else:
        lines.append("- *No issues closed in this interval.*")

    lines.extend([
        "",
        "## 2. Today's Immediate P0 Blocker",
        ""
    ])

    if blockers:
        top_blocker = blockers[0]
        lines.append(f"**P0 BLOCKER:** Clear PR #{top_blocker.get('number')} ({top_blocker.get('title')}) — CI: `{top_blocker.get('ci_status')}`")
    elif ready:
        lines.append(f"**P0 ACTION:** Land PR #{ready[0].get('number')} ({ready[0].get('title')})")
    else:
        lines.append("- *No active blockers. Proceed with assigned queue.*")

    lines.extend([
        "",
        "## 3. Active PR Merge Sequence",
        ""
    ])

    if ready:
        for p in ready:
            lines.append(f"1. **PR #{p.get('number')}**: {p.get('title')} (CI: `{p.get('ci_status')}`)")
    else:
        lines.append("- *No PRs currently ready to land.*")

    lines.extend([
        "",
        "## 4. Adversarial Audit Findings",
        ""
    ])

    findings = audit.get("findings", [])
    if findings:
        for f in findings:
            lines.append(f"- **[{f.get('severity')}] {f.get('type')}**: {f.get('message')}")
    else:
        lines.append("- **PASS:** Zero contradictions or data race hazards detected for today's execution.")

    lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Planner Core Engine")
    parser.add_argument("--repo-root", default=".", help="Path to repository root")
    parser.add_argument("--gh-repo", default=None, help="Target GitHub repo (e.g. Org/Name)")
    parser.add_argument("--mode", choices=["weekly", "daily", "audit", "sequence", "intake"], default="weekly")
    parser.add_argument("--plan-file", help="Path to existing weekly plan JSON/MD")
    parser.add_argument("--decisions-issue", help="Canonical GH issue number for provisional decisions tracker")
    parser.add_argument("--team-issue", "--issue", dest="team_issue", type=int, help="Team weekly issue number for focus assignments")
    parser.add_argument("--hours", type=int, default=36, help="Lookback interval in hours for daily mode")
    parser.add_argument("--fallback", action="store_true", help="Force scratch markdown fallback intake")

    args = parser.parse_args()
    repo_root = Path(args.repo_root).resolve()
    if not repo_root.is_dir():
        print(f"[ERROR] repo root not found: {repo_root}", file=sys.stderr)
        sys.exit(2)
    temp_dir = ensure_temp_dir(repo_root)

    prs = get_open_prs(repo_root, args.gh_repo)
    sequence = detect_merge_sequence(prs)

    if args.mode == "sequence":
        print(json.dumps(sequence, indent=2))
        return

    if args.mode == "audit":
        audit = audit_adversarial({"prs": prs}, prs=prs)
        print(json.dumps(audit, indent=2))
        return

    now_utc = datetime.now(timezone.utc)
    date_str = now_utc.strftime("%Y-%m-%d")

    if args.mode == "daily":
        plan_file_arg = Path(args.plan_file) if args.plan_file else None
        pivot = pivot_daily(plan_file_arg, repo_root, args.gh_repo, hours=args.hours)
        audit = audit_adversarial({"prs": prs, "pivot": pivot}, prs=prs)
        result = {
            "mode": "daily_pivot",
            "date": date_str,
            "merge_sequence": sequence,
            "pivot": pivot,
            "adversarial_audit": audit,
        }
        out_json = temp_dir / f"daily-pivot-{date_str}.json"
        out_json.write_text(json.dumps(result, indent=2), encoding="utf-8")
        out_md = temp_dir / f"DAILY-PIVOT-{date_str}.md"
        out_md.write_text(format_daily_markdown(date_str, result), encoding="utf-8")
        print(f"Daily pivot generated at:\n  - JSON: {out_json}\n  - Markdown: {out_md}")
        return

    # Weekly mode
    intake = ingest_weekly_intake(repo_root, args.gh_repo, team_issue=args.team_issue, fallback_mode=args.fallback)
    plan_payload = {
        "prs": prs,
        "roadmap_items": intake.get("roadmap_items", []),
        "teammates": intake.get("teammate_assignments", {}),
    }
    audit = audit_adversarial(plan_payload, prs=prs)
    result = {
        "mode": "weekly_plan",
        "date": date_str,
        "timestamp": now_utc.isoformat(),
        "intake_mode": intake.get("intake_mode"),
        "release_milestones": intake.get("release_milestones", {}),
        "merge_sequence": sequence,
        "adversarial_audit": audit,
        "teammate_assignments": intake.get("teammate_assignments", {}),
        "unassigned_items": intake.get("unassigned_items", []),
        "deferred_items": intake.get("deferred_items", []),
        "decisions_issue": args.decisions_issue or "NONE_SET",
        "tasks": intake.get("roadmap_items", []),
    }
    out_json = temp_dir / f"weekly-plan-{date_str}.json"
    out_json.write_text(json.dumps(result, indent=2), encoding="utf-8")
    out_md = temp_dir / f"WEEKLY-PLAN-{date_str}.md"
    out_md.write_text(format_weekly_markdown(date_str, result), encoding="utf-8")
    print(f"Weekly plan outline generated at:\n  - JSON: {out_json}\n  - Markdown: {out_md}")


if __name__ == "__main__":
    main()
