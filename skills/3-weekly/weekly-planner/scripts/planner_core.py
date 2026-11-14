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

from __future__ import annotations

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
            if 4 <= ovr_val <= 400:
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
            if all(1 <= axis <= 100 for axis in (p, s, a, e)):
                total = p + s + a + e
                return total, f"*[PRS: {total} ({p}/{s}/{a}/{e})]*"
        except (ValueError, TypeError):
            pass

    return None, ""


def ledger_repo_id(conn) -> int:
    """Select the requested repository rather than mixing rows in a shared ledger."""
    selected = conn.execute("SELECT value FROM settings WHERE key = 'repo_slug'").fetchone()
    if selected is None:
        raise ValueError("Native ledger has no selected repository")
    row = conn.execute("SELECT id FROM repos WHERE slug = ?", (selected[0],)).fetchone()
    if row is None:
        raise ValueError(f"No native ledger repository matches {selected[0]}")
    return row[0]


def get_release_milestones(repo_root: Path, gh_repo: str | None = None) -> dict:
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
            repo_id = ledger_repo_id(conn)

            # Use the canonical draft/active, dated-first order for this repository.
            releases = cur.execute(
                "SELECT id, version, codename, status, target_date, exit_criterion, description, milestone "
                "FROM releases WHERE repo_id = ? AND status IN ('draft', 'active') "
                "ORDER BY target_date IS NULL, target_date ASC, version ASC",
                (repo_id,),
            ).fetchall()
            rel_row = releases[0] if releases else None
            labels = [f"{r['version']} {r['codename']} ({r['status']}; target={r['target_date'] or 'undated'})" for r in releases]
            next_release = labels[0] if labels else None
            upcoming = labels[1:]

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
                WHERE m.repo_id = ? AND m.status IN ('planned', 'running')
                ORDER BY m.id ASC
            """, (repo_id,)).fetchall()
            for mr in marathon_rows:
                active_marathons.append(dict(mr))

            # 4. Active Jog Queue (Serial Build Queue)
            jog_rows = cur.execute("""
                SELECT gh_number, position, status, attempt_count
                FROM jog_queue
                WHERE repo_id = ? AND status IN ('pending', 'running')
                ORDER BY position ASC
                LIMIT 10
            """, (repo_id,)).fetchall()
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
        "--json", "number,title,url,labels,assignees,body,updatedAt"
    ]
    if gh_repo:
        cmd.extend(["-R", gh_repo])
    out = run_cmd(cmd, cwd=repo_root, check=True)
    raw_issues = json.loads(out)
    if not isinstance(raw_issues, list):
        raise ValueError("GitHub open-issue intake must return a list")
    if len(raw_issues) >= limit:
        raise RuntimeError(f"Open-issue intake reached limit={limit}; completeness is unknown")
    return {iss["number"]: iss for iss in raw_issues}


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
        # `labels` is read only by the GH-1184 Stalled & stale section (hold/parked); every other
        # consumer ignores extra keys.
        "--json", "number,title,author,headRefName,baseRefName,mergeable,reviewDecision,reviews,reviewRequests,updatedAt,statusCheckRollup,files,body,isDraft,labels,url"
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
    Classify PRs by readiness, explicit holds, and prerequisites.
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

        if re.search(r"(?:^\s*HOLD\b|\[HOLD\])", title, re.IGNORECASE):
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

        # Classify explicit evidence-only purpose, not an implementation's validation note.
        evidence_purpose = re.search(
            r"(?im)^\s*(?:this (?:pr|draft) is an? )?evidence carrier(?: for| only|[.:])",
            body,
        ) or re.search(
            r"(?i)^(?:docs(?:\([^)]*\))?:\s*)?(?:retain|preserve|record)\b.*"
            r"(?:qualification|reconciliation) receipts?", title,
        )
        if evidence_purpose:
            is_evidence_carrier = True
            hold_reason = hold_reason or "Explicit evidence-only purpose"

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
        elif is_draft and decision == "APPROVED" and mergeable == "MERGEABLE" and ci in {"SUCCESS", "NONE"}:
            phase_ready_pending_undraft.append(pr_with_ci)
        else:
            phase_in_review.append(pr_with_ci)

    # Admit only PRs whose open prerequisites are already in the landing sequence.
    # A held, conflicting or cyclic prerequisite must never become a "Land" action.
    pending = {p["number"]: p for p in phase_ready}
    sorted_ready = []
    ready_numbers = set()
    while pending:
        newly_ready = [n for n in pending if pr_dependencies[n] <= ready_numbers]
        if not newly_ready:
            break
        for num in newly_ready:
            sorted_ready.append(pending.pop(num))
            ready_numbers.add(num)
    for p in list(pending.values()) + list(phase_ready_pending_undraft):
        unmet = sorted(pr_dependencies[p["number"]] - ready_numbers)
        if unmet:
            p["blocked_by_unmerged"] = unmet
            phase_in_review.append(p)
            if p in phase_ready_pending_undraft:
                phase_ready_pending_undraft.remove(p)

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

    # 4. Duplicate task check: use the same disposition as merge sequencing.
    evidence_numbers = {
        p["number"] for p in detect_merge_sequence(open_prs)["evidence_carriers_or_held"]
        if p.get("is_evidence_carrier")
    }
    seen_issues: dict[str, list[int]] = {}
    for pr in open_prs:
        title = pr.get("title", "")
        pr_num = pr.get("number")
        if pr_num is None:
            continue
        # Skip evidence carriers, receipts, and doc PRs from implementation duplication flags
        body = pr.get("body") or ""
        combined = f"{title} {body}".lower()
        if pr.get("is_evidence_carrier") or pr_num in evidence_numbers:
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
    - Grounded Assignment: Maps explicit GitHub assignees to known teammates; --team-issue
      supplies domain descriptions. Unmapped tasks remain in sorted triage queue.
    """
    temp_dir = ensure_temp_dir(repo_root)
    intake_mode = "fallback_scratch"
    roadmap_items = []
    active_candidates = []
    deferred_items = []
    unassigned_items = []

    open_issues = get_open_issues(repo_root, gh_repo)
    release_milestones = get_release_milestones(repo_root, gh_repo)

    dialed_in_set = set(release_milestones.get("manifest_summary", {}).get("dialed_in_numbers", []))
    target_release_ver = release_milestones.get("target_release", {}).get("version")

    teammates: dict[str, dict] = {
        "Noel": {"domain": "Orchestration/Gate", "tasks": []},
        "Jose": {"domain": "Data/Pipeline", "tasks": []},
        "Matthew": {"domain": "NexMail/Calendar", "tasks": []},
    }

    releases_cli = repo_root / "utils" / "py" / "releases_app.py"
    releases_db = repo_root / "releases.db"

    raw_items = None
    if not fallback_mode and releases_db.exists():
        try:
            import sqlite3
            conn = sqlite3.connect(f"file:{releases_db}?mode=ro", uri=True)  # SQLITE-GATEWAY-OK: read-only releases.db ledger inspection (GH-1043/GH-777)
            try:
                conn.row_factory = sqlite3.Row
                repo_id = ledger_repo_id(conn)
                rows = conn.execute("""
                    SELECT gh_number, title, section, position, status_marker, issue_url,
                           rating_pri, rating_sev, rating_appeal, rating_effort, rating_ovr,
                           risk, complexity, effort, status_label, raw_text
                    FROM roadmap_items WHERE repo_id = ? ORDER BY section, position
                """, (repo_id,)).fetchall()
                raw_items = [dict(r) for r in rows]
            finally:
                conn.close()
        except Exception as e:
            print(f"[WARN] Direct releases.db roadmap intake failed ({e}); falling back to CLI.", file=sys.stderr)

    if raw_items is None and not fallback_mode and releases_cli.exists():
        out = run_cmd(["python3", str(releases_cli), "roadmap", "list", "--json"], cwd=repo_root)
        raw_items = json.loads(out)
        if not isinstance(raw_items, list):
            raise ValueError("Native roadmap CLI must return a list")
        required = {"is_selected_repo", "rating_pri", "rating_sev", "rating_appeal",
                    "rating_effort", "rating_ovr", "risk"}
        if any(not isinstance(row, dict) or not required.issubset(row)
               or not isinstance(row["is_selected_repo"], bool) for row in raw_items):
            raise ValueError("Native roadmap CLI lacks repository/rating metadata; update the owning repo's releases CLI first")
        raw_items = [row for row in raw_items if row["is_selected_repo"]]
    elif raw_items is None and not fallback_mode and releases_db.exists():
        raise RuntimeError("Native roadmap is unavailable; repair its source or explicitly select --fallback")

    native_loaded = raw_items is not None
    if native_loaded:
        intake_mode = "native_prs"
    else:
        raw_items = [
            {"gh_number": iss["number"], "title": iss.get("title"),
             "section": "Open Issues Intake", "raw_text": ""}
            for iss in open_issues.values()
        ]

    # Apply the same eligibility, live grounding, ratings and risk rules to every source.
    for source_item in raw_items:
        item = dict(source_item)
        section = (item.get("section") or "").lower()
        marker = (item.get("status_marker") or "").strip()
        if section in {"completed", "done", "shipped"} or marker in {"✅", "[DONE]", "shipped"}:
            continue
        combined = f"{item.get('title') or ''} {item.get('raw_text') or ''}".lower()
        if any(word in combined for word in ("superseded", "retired", "do not implement")):
            continue
        try:
            gh_num = int(item.get("gh_number"))
        except (ValueError, TypeError):
            continue
        if gh_num not in open_issues:
            continue
        issue_url = item.get("issue_url") or ""
        if gh_repo and issue_url and not issue_url.lower().startswith(f"https://github.com/{gh_repo}/issues/".lower()):
            continue
        item["gh_number"] = gh_num
        live = open_issues[gh_num]
        if issue_url and live.get("url") and issue_url.rstrip("/").lower() != live["url"].rstrip("/").lower():
            continue
        item["live_assignees"] = [a["login"] for a in live.get("assignees", []) if isinstance(a, dict) and a.get("login")]
        item["live_labels"] = [a["name"] for a in live.get("labels", []) if isinstance(a, dict) and a.get("name")]
        item["updated_at"] = live.get("updatedAt")
        item["prs_score"], item["prs_badge"] = compute_prs_score(item)
        try:
            item["is_high_risk_gate"] = int(item.get("risk") or 0) >= 4
        except (ValueError, TypeError):
            item["is_high_risk_gate"] = False
        if item["is_high_risk_gate"]:
            item["risk_gate_badge"] = f"*[GATE: risk {item['risk']}]*"
        item["is_release_build"] = gh_num in dialed_in_set
        item["release_build_version"] = target_release_ver
        item["is_deferred"] = (
            section.startswith("deferred") or marker.startswith("⏸")
            or (item.get("title") or "").lower().startswith("deferred:")
            or ("deferred" in combined and "vision" in combined)
        )
        roadmap_items.append(item)

    if not native_loaded:
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
        if item.get("is_deferred"):
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
                -(x["position"] if x.get("position") is not None else 999),
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
            deps = f"; waiting on prerequisite PRs {p['blocked_by_unmerged']}" if p.get("blocked_by_unmerged") else ""
            lines.append(f"- **PR #{p.get('number')}**: {p.get('title')} — Review: `{p.get('reviewDecision') or 'PENDING'}`, CI: `{p.get('ci_status')}`{deps}")
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


# ── Stalled & stale (GH-1184) ──────────────────────────────────────────────────────────────────
#
# A read-only report of what the operator started and left hanging: GitHub items idle N days plus
# THIS device's unpushed/uncommitted/orphaned branches and open session notes. Held work (the engine's
# Phase 5 holds and evidence carriers, hold/parked labels, an explicit owner-decision line) is listed
# separately and never called stalled. Every external read is wrapped so a failure or a capped list
# shows up as a coverage gap, never as "nothing stalled". The only GitHub write is one comment per
# device per day on the team weekly issue, found again by a hidden marker and edited in place.
# The ledger is never opened here (GH-777 ratchet, #1182).

STALLED_MARKER_RE = re.compile(r"<!-- planner-stalled:([a-z0-9._-]+):(\d{4}-\d{2}-\d{2}) -->")
INTEGRATION_BRANCHES = {"development", "main", "master"}
LOCAL_ROWS_SHOWN = 10          # per checkout in the rendered section; the JSON keeps every row
HOLD_LABELS = {"hold", "parked"}
IN_PROGRESS_LABELS = {"in progress", "in-progress", "🚧"}
OWNER_HOLD_RE = re.compile(r"(?im)^\s*(?:owner decision|decision)\s*:\s*hold\b")
# A status line, not a word: `- **Resolved 2026-09-29:**`, `Promoted: #123`, `Closed:` — the keyword must be
# followed by a colon within a short span, so prose like "Closed-loop review remains open" is not a status.
RESOLVED_NOTE_RE = re.compile(r"(?im)^\s*-?\s*\**\s*(?:resolved|promoted|closed)\b[^:\n]{0,24}:")
HOLD_DISCLOSURE = (
    "holds recognised: engine title/body phrases (HOLD, leave unmerged, not an authorized merge, "
    "prerequisites required/live-pilot, review authority limit, evidence carrier), labels hold/parked, "
    "body line 'owner decision: hold'; comment-only holds are NOT detected"
)
AGE_DISCLOSURE = ("ages are GitHub update age (updatedAt): label/metadata churn and bot comments count "
                  "as activity, so a human stall after such activity can be missed")
LOCAL_DISCLOSURE = ("'ahead' counts come from cached tracking refs (as of last fetch; this scan never "
                    "fetches); merged/closed matches are by branch NAME only and are unverified")


def _parse_gh_time(value) -> datetime | None:
    if not value or not isinstance(value, str):
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def _age_days(value, now: datetime) -> float | None:
    ts = _parse_gh_time(value) if isinstance(value, str) else value
    if ts is None:
        return None
    if ts.tzinfo is None:
        ts = ts.replace(tzinfo=timezone.utc)
    return (now - ts).total_seconds() / 86400.0


def normalize_device_id(raw: str | None) -> str:
    """device_config, git-pulse and `hostname -s` disagree on case and `.local`; the comment marker
    must not (noels-Mac-Studio.local / noels-mac-studio / noels-Mac-Studio -> noels-mac-studio)."""
    name = (raw or "").strip().lower()
    name = re.sub(r"\.local$", "", name)
    name = re.sub(r"[^a-z0-9._-]+", "-", name).strip("-.")
    return name or "unknown-device"


def resolve_device_id(repo_root: Path, explicit: str | None) -> str:
    if explicit:
        return normalize_device_id(explicit)
    for candidate in (repo_root / "utils" / "py", repo_root / ".xyz" / "utils" / "py"):
        if (candidate / "device_config.py").is_file():
            sys.path.insert(0, str(candidate))
            try:
                from device_config import resolve_device_setting  # noqa: E402
                return normalize_device_id(str(resolve_device_setting("device_id", "XYZ_DEVICE_ID")))
            except Exception:
                break
    import platform
    return normalize_device_id(platform.node())


def _coverage(source: str, status: str, detail: str = "", count: int | None = None) -> dict:
    entry = {"source": source, "status": status}
    if detail:
        entry["detail"] = detail[:300]
    if count is not None:
        entry["count"] = count
    return entry


def _gh_json(cmd: list[str], cwd: Path, source: str, coverage: list, limit: int | None = None):
    """Run a gh command for the stalled scan; a failure or a capped list is a coverage entry, and the
    caller keeps going with what it has (never a crash, never a silent empty list)."""
    try:
        out = run_cmd(cmd, cwd=cwd, check=True)
        data = json.loads(out) if out else []
    except Exception as exc:  # noqa: BLE001 - every failure must become a visible gap
        coverage.append(_coverage(source, "failed", str(exc).splitlines()[-1] if str(exc) else repr(exc)))
        return None
    count = len(data) if isinstance(data, (list, dict)) else None
    if limit is not None and isinstance(data, list) and len(data) >= limit:
        coverage.append(_coverage(source, "truncated", f"{len(data)} rows returned at limit {limit}", count))
    else:
        coverage.append(_coverage(source, "ok", count=count))
    return data


def resolve_gh_slug(repo_root: Path, gh_repo: str | None) -> str | None:
    if gh_repo:
        return gh_repo
    try:
        return run_cmd(["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"], cwd=repo_root) or None
    except Exception:
        return None


def _origin_slug(path: Path) -> tuple[str | None, str]:
    """(slug, how) for a checkout's origin. A local-path origin (a clone of a clone) is followed ONE
    hop; anything deeper is reported unresolved rather than guessed."""
    def origin_of(p: Path) -> str:
        try:
            return run_cmd(["git", "-C", str(p), "remote", "get-url", "origin"], check=True)
        except Exception:
            return ""

    def slug_of(url: str) -> str | None:
        m = re.search(r"[:/]([^/:]+/[^/]+?)(?:\.git)?/?$", url.strip())
        return m.group(1).lower() if m and not url.startswith(("/", ".", "~")) else None

    url = origin_of(path)
    if not url:
        return None, "no origin"
    slug = slug_of(url)
    if slug:
        return slug, "origin"
    local = Path(os.path.expanduser(url))
    if local.is_dir():
        hop = origin_of(local)
        slug = slug_of(hop) if hop else None
        if slug:
            return slug, "origin via one local hop"
        return None, f"origin is a local path whose own origin is {hop or 'missing'}"
    return None, f"unparseable origin {url[:80]}"


def discover_local_roots(repo_root: Path, roots: list[str], target_slug: str | None, coverage: list) -> list[Path]:
    """Expand --local-roots (globs allowed) to checkouts of the target repo. Foreign repos are skipped
    silently; a checkout whose origin cannot be resolved is a visible gap."""
    import glob as _glob
    candidates: list[Path] = []
    for raw in roots:
        for hit in sorted(_glob.glob(os.path.expanduser(raw))) or []:
            p = Path(hit)
            if (p / ".git").exists():
                candidates.append(p.resolve())
    seen, selected = set(), []
    for p in candidates:
        if p in seen:
            continue
        seen.add(p)
        if p == repo_root.resolve():
            selected.append(p)
            continue
        slug, how = _origin_slug(p)
        if slug is None:
            coverage.append(_coverage(f"local root {p.name}", "skipped", f"origin unresolved: {how}"))
        elif target_slug and slug == target_slug.lower():
            selected.append(p)
    return selected


def _extract_issue_numbers(text: str | None) -> list[int]:
    if not text:
        return []
    found: list[int] = []
    for m in re.finditer(r"(?:(?<![A-Za-z0-9])#(\d+)\b|\b(?:GH-|gh-?)(\d+)\b)", str(text)):
        val = int(m.group(1) or m.group(2))
        if val not in found:
            found.append(val)
    return found


def _resolve_tick_bin(checkout_path: Path) -> Path | None:
    engine_root = Path(__file__).resolve().parents[4]
    for cand in (
        checkout_path / "bin" / "tick",
        checkout_path / ".xyz" / "bin" / "tick",
        engine_root / "bin" / "tick",
    ):
        if cand.is_file() and os.access(cand, os.X_OK):
            return cand
    return None


def scan_local_checkout(path: Path, pr_heads: dict[str, list[dict]], now: datetime, device: str,
                        coverage: list) -> list[dict]:
    """Read-only: one for-each-ref, one status, worktree list --porcelain, and optional read-only tick claims
    per checkout. No fetch, prune, claim, ping or write of any kind.
    `--no-optional-locks` keeps `status` from refreshing the index (git-status(1), BACKGROUND REFRESH)."""
    rows: list[dict] = []
    label = path.name
    branch_dates: dict[str, str] = {}
    try:
        refs = run_cmd(["git", "-C", str(path), "for-each-ref", "refs/heads",
                        "--format=%(refname:short)%00%(upstream:short)%00%(upstream:track)%00%(committerdate:iso8601-strict)"])
    except Exception as exc:
        coverage.append(_coverage(f"local root {label}", "failed", str(exc).splitlines()[-1]))
        return rows
    for line in refs.splitlines():
        parts = line.split("\x00")
        if len(parts) != 4:
            continue
        branch, upstream, track, cdate = parts
        age = _age_days(cdate, now)
        last = cdate[:10] if cdate else "unknown"
        branch_dates[branch] = last
        ahead = re.search(r"ahead (\d+)", track or "")
        iss_nums = _extract_issue_numbers(branch) or _extract_issue_numbers(label)
        # Integration branches are promotion PR heads (development -> main); a name match there is
        # never a retirement hint, and a local `development` is tracked by every clone anyway.
        matches = [] if branch in INTEGRATION_BRANCHES else pr_heads.get(branch, [])
        closed = [m for m in matches if str(m.get("state", "")).upper() in {"MERGED", "CLOSED"}]
        if closed and not any(str(m.get("state", "")).upper() == "OPEN" for m in matches):
            m = closed[0]
            rows.append({"kind": "branch", "ref": f"{label}:{branch}", "path": str(path), "device": device,
                         "last_activity": last, "issue_numbers": iss_nums,
                         "reason": f"PR #{m.get('number')} is {str(m.get('state')).lower()} (name match, unverified)"
                                   + (f"; local ahead {ahead.group(1)} as of last fetch" if ahead else ""),
                         "next_action": "retire? name match — verify with /merge-cleanup"})
        elif not upstream and branch not in INTEGRATION_BRANCHES:
            rows.append({"kind": "branch", "ref": f"{label}:{branch}", "path": str(path), "device": device,
                         "last_activity": last, "issue_numbers": iss_nums,
                         "reason": "no upstream (never pushed)",
                         "next_action": "inspect; push or open PR"})
        elif ahead:
            rows.append({"kind": "branch", "ref": f"{label}:{branch}", "path": str(path), "device": device,
                         "last_activity": last, "issue_numbers": iss_nums,
                         "reason": f"ahead {ahead.group(1)} of {upstream} (as of last fetch)",
                         "next_action": "inspect; push or open PR"})
        _ = age
    try:
        porcelain = run_cmd(["git", "-C", str(path), "--no-optional-locks", "status", "--porcelain"])
    except Exception as exc:
        coverage.append(_coverage(f"local root {label} status", "failed", str(exc).splitlines()[-1]))
        return rows
    dirty = [l for l in porcelain.splitlines() if l.strip()]
    if dirty:
        rows.append({"kind": "worktree", "ref": label, "path": str(path), "device": device,
                     "last_activity": now.date().isoformat(),
                     "issue_numbers": _extract_issue_numbers(label),
                     "reason": f"{len(dirty)} uncommitted change(s)",
                     "next_action": "commit or stash"})

    # GH-1459: Enumerate checked-out linked worktrees (read-only) so clean tracked worktrees still
    # surface their checked-out issue branch for checkout calibration.
    try:
        wt_out = run_cmd(["git", "-C", str(path), "worktree", "list", "--porcelain"])
        cur_wt_path = ""
        cur_wt_branch = ""
        for wt_line in (wt_out.splitlines() + [""]):
            if not wt_line.strip():
                if cur_wt_path and cur_wt_branch and cur_wt_branch not in INTEGRATION_BRANCHES:
                    wt_nums = _extract_issue_numbers(cur_wt_branch) or _extract_issue_numbers(Path(cur_wt_path).name)
                    wt_label = Path(cur_wt_path).name
                    rows.append({
                        "kind": "worktree_branch",
                        "ref": f"{wt_label}:{cur_wt_branch}",
                        "path": cur_wt_path,
                        "checkout": str(path),
                        "device": device,
                        "last_activity": branch_dates.get(cur_wt_branch, now.date().isoformat()),
                        "issue_numbers": wt_nums,
                        "reason": f"checked out worktree on {cur_wt_branch}",
                        "next_action": "active local checkout",
                    })
                cur_wt_path = ""
                cur_wt_branch = ""
            elif wt_line.startswith("worktree "):
                cur_wt_path = wt_line[len("worktree "):].strip()
            elif wt_line.startswith("branch refs/heads/"):
                cur_wt_branch = wt_line[len("branch refs/heads/"):].strip()
    except Exception as exc:
        coverage.append(_coverage(f"local root {label} worktrees", "failed", str(exc).splitlines()[-1]))

    # GH-1459: Read active .tick claims via canonical `tick claims --json` only (target root pinned,
    # zero STATE.md writes, and no parallel Python event-folding interpreter).
    if (path / ".tick").is_dir():
        tick_bin = _resolve_tick_bin(path)
        if tick_bin is None:
            coverage.append(_coverage(f"tick claims {label}", "unavailable", "tick binary not found"))
        else:
            env = dict(os.environ)
            env["TICK_REPO_ROOT"] = str(path)
            proc = subprocess.run(
                [str(tick_bin), "claims", "--json"],
                cwd=path,
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )
            if proc.returncode != 0:
                detail = (proc.stderr or proc.stdout or f"exit {proc.returncode}").strip().splitlines()[-1]
                coverage.append(_coverage(f"tick claims {label}", "failed", detail))
            else:
                try:
                    raw_claims = json.loads(proc.stdout.strip() or "{}")
                    claims_data = raw_claims.get("claimed") if isinstance(raw_claims, dict) else raw_claims
                    if not isinstance(claims_data, list):
                        raise ValueError("tick claims --json did not return a claimed list")
                    for c_item in claims_data:
                        if not isinstance(c_item, dict):
                            continue
                        task_id = str(c_item.get("task") or c_item.get("id") or "")
                        agent_id = str(c_item.get("agent") or c_item.get("owner") or "unknown")
                        c_paths = c_item.get("paths") or []
                        iss_nums = _extract_issue_numbers(task_id)
                        for cp in c_paths if isinstance(c_paths, list) else [c_paths]:
                            for n_val in _extract_issue_numbers(str(cp)):
                                if n_val not in iss_nums:
                                    iss_nums.append(n_val)
                        rows.append({
                            "kind": "tick_claim",
                            "ref": f"{label}:tick:{task_id}",
                            "path": str(path),
                            "checkout": str(path),
                            "device": device,
                            "agent": agent_id,
                            "last_activity": str(c_item.get("ts") or now.date().isoformat())[:10],
                            "issue_numbers": iss_nums,
                            "reason": f"tick claim by {agent_id} on {task_id}",
                            "next_action": "active tick claim",
                        })
                    coverage.append(_coverage(f"tick claims {label}", "ok", count=len(claims_data)))
                except Exception as exc:
                    coverage.append(_coverage(f"tick claims {label}", "failed", str(exc).splitlines()[-1]))

    coverage.append(_coverage(f"local root {label}", "ok", count=len(rows)))
    return rows


def scan_notes(repo_root: Path, now: datetime, notes_days: int, device: str, coverage: list) -> list[dict]:
    """Open session notes touched in the window: dated PARKED/YYYY-MM-DD-*.md not marked resolved, and
    relay threads whose STATUS is not Approved/Closed. Path, mtime and status only — never contents,
    and a note's `check`/`close` fields are never executed."""
    rows: list[dict] = []
    cutoff = now - timedelta(days=notes_days)

    # "Touched in the window" means the last COMMIT touching the file, or an uncommitted change —
    # never the filesystem mtime, which a fresh clone sets to the clone time for every file.
    touched: dict[str, str] = {}
    try:
        log = run_cmd(["git", "-C", str(repo_root), "log", f"--since={cutoff.isoformat()}", "--format=%cI",
                       "--name-only", "--", "PARKED", "relay-system"])
        stamp = ""
        for line in log.splitlines():
            if not line.strip():
                continue
            if re.match(r"\d{4}-\d{2}-\d{2}T", line):
                stamp = line.strip()
            else:
                touched.setdefault(line.strip(), stamp)
        porcelain = run_cmd(["git", "-C", str(repo_root), "--no-optional-locks", "status", "--porcelain", "--",
                             "PARKED", "relay-system"])
        # run_cmd strips stdout, so the first porcelain line has lost its leading status space:
        # split on whitespace once (status token, path) instead of slicing a fixed column.
        for line in porcelain.splitlines():
            parts = line.strip().split(None, 1)
            if len(parts) == 2:
                path = parts[1].split(" -> ")[-1].strip().strip('"')
                touched[path] = now.isoformat()
    except Exception as exc:
        coverage.append(_coverage("note history", "failed", str(exc).splitlines()[-1] if str(exc) else repr(exc)))

    def last_touch(f: Path) -> datetime | None:
        rel = str(f.relative_to(repo_root))
        return _parse_gh_time(touched.get(rel)) if rel in touched else None

    parked = repo_root / "PARKED"
    if parked.is_dir():
        seen = 0
        for f in sorted(parked.glob("*.md")):
            if not re.match(r"\d{4}-\d{2}-\d{2}-", f.name):
                continue   # README.md / PARKED.md are folder metadata, not notes
            mtime = last_touch(f)
            if mtime is None or mtime < cutoff:
                continue
            seen += 1
            try:
                text = f.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            if RESOLVED_NOTE_RE.search(text):
                continue
            rows.append({"kind": "note", "ref": f"PARKED/{f.name}", "path": str(f), "checkout": str(repo_root),
                         "device": device, "last_activity": mtime.date().isoformat(),
                         "reason": "parked note, not marked resolved",
                         "next_action": "resolve, promote to an issue, or mark Resolved:"})
        coverage.append(_coverage("PARKED notes", "ok", f"{seen} touched in window", count=len([r for r in rows if r["kind"] == "note"])))
    else:
        coverage.append(_coverage("PARKED notes", "absent"))
    relay_root = repo_root / "relay-system"
    if relay_root.is_dir():
        open_threads = 0
        for f in sorted(relay_root.glob("*/*.md")):
            mtime = last_touch(f)
            if mtime is None or mtime < cutoff:
                continue
            status = ""
            try:
                with open(f, encoding="utf-8", errors="replace") as fh:
                    for line in fh:
                        m = re.match(r"^[`*]*STATUS[`*]*:[`*]*\s*(.*)", line)   # poll.relay_field's grammar
                        if m:
                            status = m.group(1).strip("`* \t\n")
                            break
            except OSError:
                continue
            if status.lower() in {"approved", "closed"}:
                continue
            open_threads += 1
            rows.append({"kind": "relay", "ref": str(f.relative_to(repo_root)), "path": str(f),
                         "checkout": str(repo_root), "device": device, "last_activity": mtime.date().isoformat(),
                         "reason": f"relay thread STATUS: {status or 'unknown'}",
                         "next_action": "take or close the pending turn"})
        coverage.append(_coverage("relay threads", "ok", count=open_threads))
    else:
        coverage.append(_coverage("relay threads", "absent"))
    return rows


def _labels(item: dict) -> set[str]:
    return {str(l.get("name", "")).lower() for l in (item.get("labels") or []) if isinstance(l, dict)}


def collect_stalled_stale(prs: list[dict], issues: dict[int, dict] | None, sequence: dict, operator: str | None,
                          now: datetime, stale_days: int, draft_stale_days: int, device: str,
                          local_rows: list[dict], coverage: list, prior_reports: dict[str, str],
                          date_local: str | None = None) -> dict:
    """Pure over its inputs. Held is decided before Stalled and wins. `date_local` is the device's
    calendar date the comment markers use; device freshness is judged against it, not against UTC."""
    held_numbers = {p.get("number") for p in sequence.get("evidence_carriers_or_held", [])}
    hold_reasons = {p.get("number"): p.get("hold_reason") or ("evidence carrier" if p.get("is_evidence_carrier") else "held")
                    for p in sequence.get("evidence_carriers_or_held", [])}
    stalled: list[dict] = []
    held: list[dict] = []

    for pr in prs:
        n = pr.get("number")
        age = _age_days(pr.get("updatedAt"), now)
        ref, url = f"PR #{n}", pr.get("url") or ""
        last = (pr.get("updatedAt") or "")[:10]
        labels = _labels(pr)
        reason = None
        if n in held_numbers:
            reason = hold_reasons.get(n) or "held (engine)"
        elif labels & HOLD_LABELS:
            reason = f"label {sorted(labels & HOLD_LABELS)[0]}"
        elif OWNER_HOLD_RE.search(pr.get("body") or ""):
            reason = "owner decision: hold (body)"
        if reason:
            held.append({"kind": "pr", "ref": ref, "url": url, "device": "github", "last_activity": last,
                         "reason": reason, "next_action": "none (intentional hold)"})
            continue
        if age is None:
            continue
        if pr.get("isDraft") and age >= draft_stale_days:
            stalled.append({"kind": "pr", "ref": ref, "url": url, "device": "github", "last_activity": last,
                            "reason": f"draft idle {age:.0f}d (>= {draft_stale_days})",
                            "next_action": "resume or close"})
        elif not pr.get("isDraft") and age >= stale_days:
            mergeable = str(pr.get("mergeable") or "")
            stalled.append({"kind": "pr", "ref": ref, "url": url, "device": "github", "last_activity": last,
                            "reason": f"idle {age:.0f}d (>= {stale_days}); review {pr.get('reviewDecision') or 'none'}",
                            "next_action": "rebase" if mergeable == "CONFLICTING" else "resume or close"})

    for n, iss in sorted((issues or {}).items()):
        labels = _labels(iss)
        assignees = {str(a.get("login", "")).lower() for a in (iss.get("assignees") or []) if isinstance(a, dict)}
        mine = bool(operator) and operator.lower() in assignees
        in_progress = bool(labels & IN_PROGRESS_LABELS)
        ref, url, last = f"issue #{n}", iss.get("url") or "", (iss.get("updatedAt") or "")[:10]
        if labels & HOLD_LABELS or OWNER_HOLD_RE.search(iss.get("body") or ""):
            if mine or in_progress:
                held.append({"kind": "issue", "ref": ref, "url": url, "device": "github", "last_activity": last,
                             "reason": "label hold/parked" if labels & HOLD_LABELS else "owner decision: hold (body)",
                             "next_action": "none (intentional hold)"})
            continue
        if not (mine or in_progress):
            continue
        age = _age_days(iss.get("updatedAt"), now)
        if age is not None and age >= stale_days:
            stalled.append({"kind": "issue", "ref": ref, "url": url, "device": "github", "last_activity": last,
                            "reason": f"{'assigned' if mine else 'in progress'}, idle {age:.0f}d (>= {stale_days})",
                            "next_action": "resume or route to the weekly issue"})

    today = date_local or now.date().isoformat()
    devices = []
    for dev, last_date in sorted(prior_reports.items()):
        if dev == device:
            devices.append({"device": dev, "last_report": today, "status": "today"})   # this run IS its report
        else:
            devices.append({"device": dev, "last_report": last_date,
                            "status": "today" if last_date == today else f"no report since {last_date}"})
    if device not in prior_reports:
        devices.append({"device": device, "last_report": today, "status": "today"})

    return {
        "generated_at": now.isoformat(), "device": device,
        "thresholds": {"stale_days": stale_days, "draft_stale_days": draft_stale_days},
        "stalled": stalled, "held": held, "local": local_rows,
        "coverage": coverage,
        "disclosures": [HOLD_DISCLOSURE, AGE_DISCLOSURE, LOCAL_DISCLOSURE],
        "devices": devices,
    }


def format_stalled_markdown(section: dict, title: str, date_local: str) -> str:
    """Render one Stalled & stale section (used for the daily MD, the stalled MD and the comment)."""
    gaps = [c for c in section.get("coverage", []) if c.get("status") not in {"ok"}]
    lines = [title, "",
             f"- **Device:** `{section.get('device')}` · **Date:** {date_local} · **Generated:** {section.get('generated_at')}",
             f"- **Thresholds:** stale ≥ {section['thresholds']['stale_days']}d, drafts ≥ {section['thresholds']['draft_stale_days']}d",
             "", "**Coverage**", ""]
    for c in section.get("coverage", []):
        extra = f" — {c.get('detail')}" if c.get("detail") else ""
        cnt = f" ({c.get('count')})" if c.get("count") is not None else ""
        lines.append(f"- `{c.get('status')}` {c.get('source')}{cnt}{extra}")
    for d in section.get("devices", []):
        lines.append(f"- device `{d['device']}`: {d['status']}")
    for note in section.get("disclosures", []):
        lines.append(f"- _{note}_")
    lines += ["", "**Stalled**", ""]
    if section.get("stalled"):
        for r in section["stalled"]:
            link = f"[{r['ref']}]({r['url']})" if r.get("url") else r["ref"]
            lines.append(f"- {link} — last activity {r['last_activity']} — {r['reason']} → _{r['next_action']}_")
    elif gaps:
        lines.append("- *No stalled items observed — coverage incomplete (see gaps above).*")
    else:
        lines.append("- *No stalled GitHub items.*")
    lines += ["", f"**Local — {section.get('device')}**", ""]
    if section.get("local"):
        # Newest first, at most LOCAL_ROWS_SHOWN per checkout so one orphan-heavy clone cannot flood
        # the comment; the JSON keeps every row.
        # One bucket per CHECKOUT: branch/worktree rows by their checkout path, note/relay rows by the
        # checkout that owns the file (`checkout`), so no single clone renders more than LOCAL_ROWS_SHOWN.
        per_checkout: dict[str, list[dict]] = {}
        for r in section["local"]:
            key = r.get("checkout") or r.get("path") or r["ref"]
            per_checkout.setdefault(key, []).append(r)
        for key, rows in per_checkout.items():
            rows.sort(key=lambda r: (r.get("last_activity", ""), r.get("ref", "")), reverse=True)
            for r in rows[:LOCAL_ROWS_SHOWN]:
                lines.append(f"- `{r['ref']}` — {r['last_activity']} — {r['reason']} → _{r['next_action']}_")
            if len(rows) > LOCAL_ROWS_SHOWN:
                lines.append(f"- `{Path(key).name}` … +{len(rows) - LOCAL_ROWS_SHOWN} more row(s) in the JSON")
    else:
        lines.append("- *Nothing unpushed, uncommitted or orphaned observed on this device (subject to coverage).*")
    lines += ["", "**Held (intentional, not stalled)**", ""]
    if section.get("held"):
        for r in section["held"]:
            link = f"[{r['ref']}]({r['url']})" if r.get("url") else r["ref"]
            lines.append(f"- {link} — last activity {r['last_activity']} — {r['reason']} → _{r['next_action']}_")
    else:
        lines.append("- *None.*")
    lines.append("")
    return "\n".join(lines)


def read_stalled_comments(repo_root: Path, slug: str, issue_num: int, coverage: list) -> tuple[list[dict] | None, dict[str, str]]:
    """List the weekly issue's comments once: returns (comments or None on failure, {device: latest date})."""
    out = _gh_json(["gh", "api", "--paginate", "--slurp", f"repos/{slug}/issues/{issue_num}/comments?per_page=100"],
                   repo_root, "weekly issue comments", coverage)
    if out is None:
        return None, {}
    comments: list[dict] = []
    for entry in out if isinstance(out, list) else []:
        if isinstance(entry, list):
            comments.extend(c for c in entry if isinstance(c, dict))
        elif isinstance(entry, dict):
            comments.append(entry)
    prior: dict[str, str] = {}
    for c in comments:
        for dev, day in STALLED_MARKER_RE.findall(str(c.get("body", ""))):
            if day > prior.get(dev, ""):
                prior[dev] = day
    return comments, prior


def sync_stalled_comment(repo_root: Path, slug: str, issue_num: int, comments: list[dict], device: str,
                         date_local: str, body_md: str) -> tuple[bool, str]:
    """Edit this device's comment for today if it exists (marker match), else create it. Pattern copied
    from utils/py/marathon_drive.py:332-362,1696-1722 (importing that module is heavy)."""
    marker = f"<!-- planner-stalled:{device}:{date_local} -->"
    body = f"{marker}\n{body_md}"
    comment_id = ""
    for c in comments:
        if marker in str(c.get("body", "")):
            comment_id = str(c.get("id", ""))
            break
    payload = json.dumps({"body": body})
    import tempfile
    fd, path = tempfile.mkstemp(prefix="planner-stalled-", suffix=".json")
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write(payload)
    try:
        if comment_id:
            run_cmd(["gh", "api", "--method", "PATCH", f"repos/{slug}/issues/comments/{comment_id}", "--input", path], cwd=repo_root)
            return True, f"edited comment {comment_id}"
        run_cmd(["gh", "api", "--method", "POST", f"repos/{slug}/issues/{issue_num}/comments", "--input", path], cwd=repo_root)
        return True, "created comment"
    except Exception as exc:
        return False, str(exc).splitlines()[-1] if str(exc) else repr(exc)
    finally:
        try:
            os.unlink(path)
        except OSError:
            pass


def run_stalled_scan(repo_root: Path, gh_repo: str | None, prs: list[dict], sequence: dict, args, now: datetime,
                     prs_error: str | None = None) -> tuple[dict, dict]:
    """Collect everything for the section. Returns (section, context) where context carries what the
    comment step needs (slug, comments, date_local, device)."""
    coverage: list[dict] = []
    slug = resolve_gh_slug(repo_root, gh_repo)
    if not slug:
        coverage.append(_coverage("repo slug", "failed", "gh repo view failed and --gh-repo not given"))
    device = resolve_device_id(repo_root, args.device_id)
    date_local = datetime.now().date().isoformat()
    if prs_error:
        coverage.append(_coverage("open PRs", "failed", prs_error))
    else:
        coverage.append(_coverage("open PRs", "truncated" if len(prs) >= 300 else "ok", count=len(prs)))
    issues = None
    try:
        issues = get_open_issues(repo_root, gh_repo)
        coverage.append(_coverage("open issues", "ok", count=len(issues)))
    except Exception as exc:
        coverage.append(_coverage("open issues", "failed", str(exc).splitlines()[-1] if str(exc) else repr(exc)))
    operator = args.operator
    if not operator:
        try:
            operator = run_cmd(["gh", "api", "user", "-q", ".login"], cwd=repo_root) or None
            coverage.append(_coverage("operator login", "ok", operator or ""))
        except Exception as exc:
            coverage.append(_coverage("operator login", "failed", str(exc).splitlines()[-1]))
    all_prs = _gh_json(["gh", "pr", "list", "--state", "all", "--limit", "500", "--json", "number,headRefName,state"]
                       + (["-R", gh_repo] if gh_repo else []), repo_root, "PR heads (all states)", coverage, limit=500)
    pr_heads: dict[str, list[dict]] = {}
    for p in all_prs or []:
        pr_heads.setdefault(str(p.get("headRefName")), []).append(p)
    roots = list(args.local_roots or [str(repo_root), "~/marathon-clones/*"])
    local_rows: list[dict] = []
    for path in discover_local_roots(repo_root, roots, slug, coverage):
        local_rows.extend(scan_local_checkout(path, pr_heads, now, device, coverage))
    local_rows.extend(scan_notes(repo_root, now, args.stale_days, device, coverage))
    comments, prior = None, {}
    if args.team_issue and slug:
        comments, prior = read_stalled_comments(repo_root, slug, args.team_issue, coverage)
    section = collect_stalled_stale(prs, issues, sequence, operator, now, args.stale_days, args.draft_stale_days,
                                    device, local_rows, coverage, prior, date_local)
    return section, {"slug": slug, "comments": comments, "date_local": date_local, "device": device}


def publish_stalled_comment(repo_root: Path, section: dict, ctx: dict, team_issue: int) -> int:
    """Post or edit this device's comment. Returns 0, or 3 when the listing or the write failed
    (a failed listing never falls through to a blind POST)."""
    if not ctx.get("slug"):
        print("[ERROR] stalled comment: repo slug unresolved; pass --gh-repo", file=sys.stderr)
        return 3
    if ctx.get("comments") is None:
        print("[ERROR] stalled comment: could not list the weekly issue's comments; not posting blind", file=sys.stderr)
        return 3
    title = f"### Stalled & stale — {ctx['device']} — {ctx['date_local']}"
    body = format_stalled_markdown(section, title, ctx["date_local"])
    ok, what = sync_stalled_comment(repo_root, ctx["slug"], team_issue, ctx["comments"], ctx["device"], ctx["date_local"], body)
    print(f"stalled comment on #{team_issue}: {what}" if ok else f"[ERROR] stalled comment on #{team_issue}: {what}",
          file=sys.stdout if ok else sys.stderr)
    return 0 if ok else 3


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

    section = pivot_data.get("stalled_stale")
    if section:
        lines.append("")
        lines.append(format_stalled_markdown(section, "## 5. Stalled & stale", pivot_data.get("date_local") or date_str))
    lines.append("")
    return "\n".join(lines)



# ---------------------------------------------------------------------------
# GH-1459: Daily Work Ledger GH Issue, Carryover, Checkout Calibration & Repo Modes
# ---------------------------------------------------------------------------

LEDGER_TITLE_RE = re.compile(r"^Daily Work Ledger — (\d{4}-\d{2}-\d{2})$")
LEDGER_MARKER_LINE_RE = re.compile(
    r"^<!--\s*daily-ledger:([A-Za-z0-9._-]+):([A-Za-z0-9._-]+):(\d{4}-\d{2}-\d{2})(?:\s+started:(\S+))?\s*-->$"
)


def resolve_ledger_date(tz_name: str | None = None) -> tuple[str, str]:
    """Return (YYYY-MM-DD, resolved_tz) in the shared ledger timezone (default America/Los_Angeles)."""
    tz_raw = (tz_name or os.environ.get("XYZ_LEDGER_TZ") or "America/Los_Angeles").strip()
    try:
        from zoneinfo import ZoneInfo
        tz_obj = ZoneInfo(tz_raw)
        return datetime.now(tz_obj).strftime("%Y-%m-%d"), tz_raw
    except Exception:
        return datetime.now(timezone.utc).strftime("%Y-%m-%d"), "UTC"


def _read_device_config_key(repo_root: Path, key: str, env_name: str | None = None):
    for candidate in (repo_root / "utils" / "py", repo_root / ".xyz" / "utils" / "py"):
        if (candidate / "device_config.py").is_file():
            sys.path.insert(0, str(candidate))
            try:
                from device_config import resolve_device_setting  # noqa: E402
                val = resolve_device_setting(key, env_name or "")
                if val is not None and str(val).strip():
                    return val
            except Exception:
                break
    cfg_file = Path(os.environ.get("XYZ_DEVICE_CONFIG") or os.path.expanduser("~/.xyz/device_config.json"))
    if cfg_file.is_file():
        try:
            data = json.loads(cfg_file.read_text(encoding="utf-8"))
            if isinstance(data, dict) and key in data:
                return data[key]
        except Exception:
            pass
    return None


def resolve_repo_mode(repo_root: Path, explicit_mode: str | None = None) -> tuple[str, str]:
    """Precedence: --repo-mode CLI > XYZ_DAILY_LEDGER_MODE env > device_config.json daily_ledger_mode > auto."""
    valid = {"forge", "vendored", "gh-only"}
    if explicit_mode and explicit_mode != "auto" and explicit_mode in valid:
        return explicit_mode, "cli --repo-mode"
    env_mode = (os.environ.get("XYZ_DAILY_LEDGER_MODE") or "").strip().lower()
    if env_mode in valid:
        return env_mode, "env XYZ_DAILY_LEDGER_MODE"
    cfg_mode = _read_device_config_key(repo_root, "daily_ledger_mode", "XYZ_DAILY_LEDGER_MODE")
    if isinstance(cfg_mode, str) and cfg_mode.strip().lower() in valid:
        return cfg_mode.strip().lower(), "device_config daily_ledger_mode"
    if (repo_root / "releases.db").is_file() and (repo_root / "utils" / "hq" / "hq.sh").is_file():
        return "forge", "auto (releases.db + utils/hq/hq.sh)"
    if (repo_root / ".xyz").is_dir():
        return "vendored", "auto (.xyz/ directory)"
    return "gh-only", "auto (github + git fallback)"


def resolve_trusted_bots(repo_root: Path) -> set[str]:
    bots: set[str] = set()
    raw_env = os.environ.get("XYZ_DAILY_LEDGER_TRUSTED_BOTS") or ""
    for part in raw_env.split(","):
        if part.strip():
            bots.add(part.strip().lower())
    cfg_val = _read_device_config_key(repo_root, "daily_ledger_trusted_bots", "XYZ_DAILY_LEDGER_TRUSTED_BOTS")
    if isinstance(cfg_val, list):
        for item in cfg_val:
            if str(item).strip():
                bots.add(str(item).strip().lower())
    elif isinstance(cfg_val, str):
        for part in cfg_val.split(","):
            if part.strip():
                bots.add(part.strip().lower())
    return bots


def _flatten_gh_pages(raw) -> list[dict]:
    items: list[dict] = []
    for entry in raw if isinstance(raw, list) else []:
        if isinstance(entry, list):
            items.extend(x for x in entry if isinstance(x, dict))
        elif isinstance(entry, dict):
            items.append(entry)
    return items


def find_or_create_daily_ledger_issue(
    repo_root: Path,
    slug: str | None,
    date_local: str,
    ledger_issue_arg: int | None,
    create_if_missing: bool,
    operator: str | None,
    auth_login: str | None,
    allow_delegate: bool,
    trusted_bots: set[str],
    coverage: list[dict],
    warnings: list[str],
) -> dict:
    """Resolve today's canonical Daily Work Ledger issue (min(number)) and most recent prior workday's ledger.
    Unconditionally paginates when the 100-row search page is full so >100 historical ledgers, mixed-page
    duplicate spikes (1 today + 100 yesterday), and backfilled dates never lose completeness."""
    state = {
        "today_ledger": None,
        "today_duplicates": [],
        "previous_ledger": None,
        "previous_duplicates": [],
        "created_issue": False,
        "auth_refused": None,
    }
    if not slug:
        coverage.append(_coverage("ledger discovery", "failed", "repo slug unresolved"))
        return state

    by_number: dict[int, dict] = {}
    discovery_status = "ok"
    discovery_detail = ""

    # Optional explicit --ledger-issue override
    override_issue = None
    if ledger_issue_arg:
        try:
            out = run_cmd(
                ["gh", "issue", "view", str(ledger_issue_arg), "-R", slug,
                 "--json", "number,title,state,url,body,createdAt,author"],
                cwd=repo_root, check=True
            )
            override_issue = json.loads(out) if out else None
            if isinstance(override_issue, dict) and override_issue.get("number"):
                by_number[int(override_issue["number"])] = override_issue
        except Exception as exc:
            discovery_status = "failed"
            discovery_detail = f"--ledger-issue {ledger_issue_arg} lookup failed: {str(exc).splitlines()[-1]}"

    # 1. Exact-date lookup for today's ledger
    today_search = f'"Daily Work Ledger — {date_local}" in:title sort:created-asc'
    try:
        out_today = run_cmd(
            ["gh", "issue", "list", "-R", slug, "--search", today_search,
             "--state", "all", "--limit", "100",
             "--json", "number,title,state,url,body,createdAt,author"],
            cwd=repo_root, check=True,
        )
        raw_today = json.loads(out_today) if out_today else []
        if not isinstance(raw_today, list):
            raise ValueError("today ledger search did not return a list")
        for iss in raw_today:
            if isinstance(iss, dict) and iss.get("number"):
                by_number[int(iss["number"])] = iss
        today_capped = len(raw_today) >= 100
    except Exception as exc:
        today_capped = False
        discovery_status = "failed"
        discovery_detail = str(exc).splitlines()[-1] if str(exc) else repr(exc)

    # 2. Descending history lookup for prior workday (and any additional ledgers)
    hist_search = '"Daily Work Ledger — " in:title sort:created-desc'
    hist_capped = False
    if discovery_status == "ok":
        try:
            out_hist = run_cmd(
                ["gh", "issue", "list", "-R", slug, "--search", hist_search,
                 "--state", "all", "--limit", "100",
                 "--json", "number,title,state,url,body,createdAt,author"],
                cwd=repo_root, check=True,
            )
            raw_hist = json.loads(out_hist) if out_hist else []
            if not isinstance(raw_hist, list):
                raise ValueError("history ledger search did not return a list")
            for iss in raw_hist:
                if isinstance(iss, dict) and iss.get("number"):
                    by_number[int(iss["number"])] = iss
            hist_capped = len(raw_hist) >= 100
        except Exception as exc:
            discovery_status = "failed"
            discovery_detail = str(exc).splitlines()[-1] if str(exc) else repr(exc)

    # 3. Unconditional full pagination when either 100-row page is full
    if discovery_status == "ok" and (today_capped or hist_capped):
        try:
            out_all = run_cmd(
                ["gh", "api", "--paginate", "--slurp", f"repos/{slug}/issues?state=all&per_page=100"],
                cwd=repo_root, check=True,
            )
            raw_all = _flatten_gh_pages(json.loads(out_all) if out_all else [])
            if not raw_all:
                discovery_status = "truncated"
                discovery_detail = "100-row cap reached and paginated fallback returned no issues"
            else:
                for iss in raw_all:
                    if isinstance(iss, dict) and iss.get("number") and "pull_request" not in iss:
                        num = int(iss["number"])
                        by_number[num] = {
                            "number": num,
                            "title": iss.get("title") or "",
                            "state": str(iss.get("state") or "").upper(),
                            "url": iss.get("html_url") or iss.get("url") or "",
                            "body": iss.get("body") or "",
                            "createdAt": iss.get("created_at") or iss.get("createdAt") or "",
                            "author": iss.get("user") or iss.get("author") or {},
                        }
        except Exception as exc:
            discovery_status = "truncated"
            discovery_detail = f"100-row cap reached and pagination failed: {str(exc).splitlines()[-1]}"

    def _partition_ledgers(issues_map: dict[int, dict]) -> tuple[list[dict], str | None, list[dict]]:
        by_date: dict[str, list[dict]] = {}
        for iss in issues_map.values():
            title = str(iss.get("title") or "").strip()
            m = LEDGER_TITLE_RE.match(title)
            if not m:
                continue
            d_str = m.group(1)
            cp = dict(iss)
            cp["ledger_date"] = d_str
            by_date.setdefault(d_str, []).append(cp)
        for d_key in by_date:
            by_date[d_key].sort(key=lambda x: int(x["number"]))
        t_list = list(by_date.get(date_local, []))
        prior_dates = sorted(d for d in by_date if d < date_local)
        p_date = prior_dates[-1] if prior_dates else None
        p_list = list(by_date.get(p_date, [])) if p_date else []
        return t_list, p_date, p_list

    today_list, prev_date, prev_list = _partition_ledgers(by_number)
    if override_issue and override_issue not in today_list:
        cp_ov = dict(override_issue)
        cp_ov["ledger_date"] = date_local
        today_list.insert(0, cp_ov)

    # Create today's ledger issue only when --publish-ledger is set, discovery is 'ok', and none exists
    if not today_list and create_if_missing:
        if discovery_status != "ok":
            warnings.append(
                f"Refused to create Daily Work Ledger issue for {date_local}: discovery status is {discovery_status} ({discovery_detail})"
            )
        else:
            auth_ok = bool(auth_login) and (
                (bool(operator) and operator.lower() == auth_login.lower())
                or (allow_delegate and auth_login.lower() in trusted_bots)
            )
            if not auth_ok:
                state["auth_refused"] = (
                    f"refused issue creation: operator '{operator}' does not match authenticated user '{auth_login or 'unresolved'}'"
                )
            else:
                init_body = (
                    f"# Daily Work Ledger — {date_local}\n\n"
                    f"Shared daily coordination ledger for `{slug}` ({date_local}).\n"
                    f"Operators post and update their calibrated daily work block via `/daily-planner` (`planner_core.py --mode ledger --publish-ledger`).\n"
                )
                try:
                    run_cmd(
                        ["gh", "issue", "create", "-R", slug,
                         "--title", f"Daily Work Ledger — {date_local}",
                         "--body", init_body],
                        cwd=repo_root, check=True,
                    )
                    state["created_issue"] = True
                    # Re-run exact-date discovery immediately to reconcile concurrent creation via min(number)
                    out_re = run_cmd(
                        ["gh", "issue", "list", "-R", slug, "--search", today_search,
                         "--state", "all", "--limit", "100",
                         "--json", "number,title,state,url,body,createdAt,author"],
                        cwd=repo_root, check=True,
                    )
                    for iss in json.loads(out_re) if out_re else []:
                        if isinstance(iss, dict) and iss.get("number"):
                            by_number[int(iss["number"])] = iss
                    today_list, prev_date, prev_list = _partition_ledgers(by_number)
                except Exception as exc:
                    discovery_status = "failed"
                    discovery_detail = f"issue create/reconcile failed: {str(exc).splitlines()[-1]}"

    if today_list:
        state["today_ledger"] = today_list[0]
        state["today_duplicates"] = today_list
        if len(today_list) > 1:
            dup_nums = ", ".join(f"#{x['number']}" for x in today_list[1:])
            warnings.append(
                f"Multiple ledger issues found for {date_local}; canonical is #{today_list[0]['number']} (min(number)), reading comments across duplicates ({dup_nums})."
            )
    if prev_list:
        state["previous_ledger"] = prev_list[0]
        state["previous_duplicates"] = prev_list
        if len(prev_list) > 1:
            dup_nums = ", ".join(f"#{x['number']}" for x in prev_list[1:])
            warnings.append(
                f"Multiple prior ledger issues found for {prev_date}; canonical is #{prev_list[0]['number']} (min(number)), reading comments across duplicates ({dup_nums})."
            )

    coverage.append(
        _coverage(
            "ledger discovery",
            discovery_status,
            discovery_detail or (f"today=#{state['today_ledger']['number'] if state['today_ledger'] else 'none'}, prev=#{state['previous_ledger']['number'] if state['previous_ledger'] else 'none'}"),
            count=len(today_list) + len(prev_list),
        )
    )
    return state


def read_ledger_comments(repo_root: Path, slug: str | None, issues: list[dict], source_label: str,
                         coverage: list[dict]) -> list[dict] | None:
    if not issues:
        coverage.append(_coverage(source_label, "skipped", "no ledger issue to read", count=0))
        return []
    if not slug:
        coverage.append(_coverage(source_label, "failed", "repo slug unresolved"))
        return None
    merged: list[dict] = []
    for iss in issues:
        num = iss.get("number")
        try:
            out = run_cmd(
                ["gh", "api", "--paginate", "--slurp", f"repos/{slug}/issues/{num}/comments?per_page=100"],
                cwd=repo_root, check=True,
            )
            pages = _flatten_gh_pages(json.loads(out) if out else [])
            for c in pages:
                cp = dict(c)
                cp["_ledger_issue_number"] = num
                merged.append(cp)
        except Exception as exc:
            coverage.append(_coverage(source_label, "failed", str(exc).splitlines()[-1] if str(exc) else repr(exc)))
            return None
    coverage.append(_coverage(source_label, "ok", count=len(merged)))
    return merged


def _extract_active_claim_refs(body: str) -> tuple[list[int], list[int]]:
    """Extract issue numbers and PR numbers from a ledger comment body, ignoring the 'Completed Since Prior Ledger' section."""
    active_lines: list[str] = []
    in_completed = False
    for line in body.splitlines():
        stripped = line.strip()
        if re.match(r"^#{1,4}\s+.*completed\s+since", stripped, re.IGNORECASE):
            in_completed = True
            continue
        if in_completed and re.match(r"^#{1,4}\s+", stripped):
            in_completed = False
        if not in_completed:
            active_lines.append(line)
    active_text = "\n".join(active_lines)
    pr_nums: list[int] = []
    for m in re.finditer(r"\bPR\s*#?(\d+)\b", active_text, re.IGNORECASE):
        val = int(m.group(1))
        if val not in pr_nums:
            pr_nums.append(val)
    # Remove `PR #N` substrings before scanning issue `#N` / `GH-N` so `PR #55` is not double-counted as issue `#55`
    scrubbed = re.sub(r"\bPR\s*#?\d+\b", "", active_text, flags=re.IGNORECASE)
    iss_nums = _extract_issue_numbers(scrubbed)
    return iss_nums, pr_nums


def parse_ledger_comment(
    comment: dict,
    expected_date: str,
    allow_delegate: bool,
    trusted_bots: set[str],
    warnings: list[str],
) -> dict | None:
    """First-line marker parser + ingestion authorship verifier (LESSONS-LEARNED.md:154 & Codex P1 guard)."""
    body = str(comment.get("body") or "")
    non_empty = [ln.strip() for ln in body.splitlines() if ln.strip()]
    if not non_empty:
        return None
    m = LEDGER_MARKER_LINE_RE.match(non_empty[0])
    if not m:
        return None
    marker_op, marker_dev, marker_date, started_raw = m.group(1), m.group(2), m.group(3), m.group(4)
    if marker_date != expected_date:
        warnings.append(
            f"Ignored comment #{comment.get('id')} marker date {marker_date} != expected ledger date {expected_date}"
        )
        return None
    user_obj = comment.get("user") or comment.get("author") or {}
    author_login = str(user_obj.get("login") or "").strip()
    verified = bool(author_login) and (
        author_login.lower() == marker_op.lower()
        or (allow_delegate and author_login.lower() in trusted_bots)
    )
    iss_nums, pr_nums = _extract_active_claim_refs(body)
    created_at = str(comment.get("created_at") or comment.get("createdAt") or "")
    started_ts = started_raw or created_at
    if not verified:
        warnings.append(
            f"Rejected forged/unverified ledger marker for operator '{marker_op}' authored by '{author_login or 'unknown'}' (comment #{comment.get('id')})"
        )
    return {
        "comment_id": comment.get("id"),
        "ledger_issue_number": comment.get("_ledger_issue_number"),
        "operator": marker_op,
        "device": normalize_device_id(marker_dev),
        "date": marker_date,
        "started": started_ts,
        "created_at": created_at,
        "author_login": author_login,
        "verified": verified,
        "provenance": "verified-ledger-claim" if verified else "unverified-forged-marker",
        "issue_numbers": iss_nums,
        "pr_numbers": pr_nums,
        "body": body,
    }


def fetch_pr_review_threads(repo_root: Path, slug: str | None, pr_numbers: list[int],
                            coverage: list[dict]) -> dict[int, dict]:
    """Bounded GraphQL lookup of reviewThreads(first:100){pageInfo{hasNextPage} nodes{isResolved isOutdated}}."""
    if not pr_numbers:
        coverage.append(_coverage("PR review threads", "skipped", "no operator open PRs", count=0))
        return {}
    if not slug or "/" not in slug:
        coverage.append(_coverage("PR review threads", "failed", "repo slug unresolved"))
        return {}
    owner, name = slug.split("/", 1)
    fields = []
    for n in pr_numbers:
        fields.append(
            f"pr_{int(n)}: pullRequest(number: {int(n)}) {{ reviewThreads(first: 100) {{ pageInfo {{ hasNextPage }} nodes {{ isResolved isOutdated }} }} }}"
        )
    query = f"query($owner: String!, $name: String!) {{ repository(owner: $owner, name: $name) {{ {' '.join(fields)} }} }}"
    try:
        out = run_cmd(
            ["gh", "api", "graphql", "-f", f"query={query}", "-F", f"owner={owner}", "-F", f"name={name}"],
            cwd=repo_root, check=True,
        )
        payload = json.loads(out) if out else {}
        repo_node = (payload.get("data") or {}).get("repository")
        if not isinstance(repo_node, dict):
            raise ValueError("GraphQL repository node missing")
        result: dict[int, dict] = {}
        any_truncated = False
        for n in pr_numbers:
            pr_node = repo_node.get(f"pr_{int(n)}") or {}
            rt = pr_node.get("reviewThreads") or {}
            has_next = bool((rt.get("pageInfo") or {}).get("hasNextPage"))
            if has_next:
                any_truncated = True
            nodes = rt.get("nodes") or []
            unresolved = sum(1 for nd in nodes if isinstance(nd, dict) and not nd.get("isResolved", False))
            result[int(n)] = {"unresolved_count": unresolved, "truncated": has_next}
        coverage.append(
            _coverage(
                "PR review threads",
                "truncated" if any_truncated else "ok",
                "one or more PRs hit reviewThreads(first:100) cap" if any_truncated else "",
                count=len(pr_numbers),
            )
        )
        return result
    except Exception as exc:
        coverage.append(_coverage("PR review threads", "failed", str(exc).splitlines()[-1] if str(exc) else repr(exc)))
        return {}


import tempfile

def sync_daily_ledger_comment(
    repo_root: Path,
    slug: str,
    issue_num: int,
    existing_comments: list[dict],
    operator: str,
    device: str,
    date_local: str,
    auth_login: str | None,
    allow_delegate: bool,
    trusted_bots: set[str],
    body_md: str,
    now_iso: str,
) -> tuple[bool, str, dict]:
    """Idempotent per-(operator, device, date_local) comment sync with strict POST & PATCH authorship verification
    and preserved `started:<ISO-8601>` timestamp."""
    if not auth_login:
        return False, "authenticated GitHub login unresolved; refusing to publish", {"action": "refused", "reason": "no_auth_login"}

    norm_dev = normalize_device_id(device)
    matched_comment = None
    matched_started = None
    for c in existing_comments:
        if c.get("_ledger_issue_number") and int(c["_ledger_issue_number"]) != int(issue_num):
            continue
        c_body = str(c.get("body") or "")
        non_empty = [ln.strip() for ln in c_body.splitlines() if ln.strip()]
        if not non_empty:
            continue
        m = LEDGER_MARKER_LINE_RE.match(non_empty[0])
        if not m:
            continue
        m_op, m_dev, m_date, m_started = m.group(1), normalize_device_id(m.group(2)), m.group(3), m.group(4)
        if m_op.lower() == operator.lower() and m_dev == norm_dev and m_date == date_local:
            matched_comment = c
            matched_started = m_started or str(c.get("created_at") or c.get("createdAt") or now_iso)
            break

    if matched_comment is not None:
        c_user = matched_comment.get("user") or matched_comment.get("author") or {}
        c_author = str(c_user.get("login") or "").strip()
        if c_author.lower() != auth_login.lower() or operator.lower() != auth_login.lower():
            return (
                False,
                f"refused PATCH on comment #{matched_comment.get('id')}: comment author '{c_author}' / operator '{operator}' mismatch with authenticated user '{auth_login}'",
                {"action": "refused", "reason": "auth_mismatch_patch", "comment_id": matched_comment.get("id")},
            )
        started_ts = matched_started or now_iso
        marker = f"<!-- daily-ledger:{operator}:{norm_dev}:{date_local} started:{started_ts} -->"
        full_body = f"{marker}\n{body_md}"
        comment_id = str(matched_comment.get("id"))
        fd, tmp_path = tempfile.mkstemp(prefix="daily-ledger-", suffix=".json")
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(json.dumps({"body": full_body}))
        try:
            run_cmd(["gh", "api", "--method", "PATCH", f"repos/{slug}/issues/comments/{comment_id}", "--input", tmp_path], cwd=repo_root)
            return True, f"patched comment {comment_id} (preserved started:{started_ts})", {
                "action": "patched", "comment_id": comment_id, "started": started_ts, "created_count": 0, "patched_count": 1
            }
        except Exception as exc:
            return False, str(exc).splitlines()[-1] if str(exc) else repr(exc), {"action": "failed"}
        finally:
            try:
                os.unlink(tmp_path)
            except OSError:
                pass

    # POST path
    post_ok = operator.lower() == auth_login.lower() or (allow_delegate and auth_login.lower() in trusted_bots)
    if not post_ok:
        return (
            False,
            f"refused POST: operator '{operator}' does not match authenticated user '{auth_login}'",
            {"action": "refused", "reason": "auth_mismatch_post"},
        )
    started_ts = now_iso
    marker = f"<!-- daily-ledger:{operator}:{norm_dev}:{date_local} started:{started_ts} -->"
    full_body = f"{marker}\n{body_md}"
    fd, tmp_path = tempfile.mkstemp(prefix="daily-ledger-", suffix=".json")
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write(json.dumps({"body": full_body}))
    try:
        run_cmd(["gh", "api", "--method", "POST", f"repos/{slug}/issues/{issue_num}/comments", "--input", tmp_path], cwd=repo_root)
        return True, f"created comment on #{issue_num} (started:{started_ts})", {
            "action": "created", "issue_number": issue_num, "started": started_ts, "created_count": 1, "patched_count": 0
        }
    except Exception as exc:
        return False, str(exc).splitlines()[-1] if str(exc) else repr(exc), {"action": "failed"}
    finally:
        try:
            os.unlink(tmp_path)
        except OSError:
            pass


def run_daily_ledger(
    repo_root: Path,
    gh_repo: str | None,
    prs: list[dict],
    sequence: dict,
    args,
    now: datetime,
    prs_error: str | None = None,
) -> tuple[dict, int]:
    """Run the GH-1459 Daily Work Ledger scan and optional --publish-ledger sync."""
    coverage: list[dict] = []
    warnings: list[str] = []
    date_local, resolved_tz = resolve_ledger_date(getattr(args, "ledger_tz", None))
    repo_mode, repo_mode_how = resolve_repo_mode(repo_root, getattr(args, "repo_mode", "auto"))
    device = resolve_device_id(repo_root, args.device_id)
    trusted_bots = resolve_trusted_bots(repo_root)
    allow_delegate = bool(getattr(args, "allow_delegate_comment", False))

    slug = resolve_gh_slug(repo_root, gh_repo)
    if not slug:
        coverage.append(_coverage("repo slug", "failed", "gh repo view failed and --gh-repo not given"))
    else:
        coverage.append(_coverage("repo slug", "ok", slug))

    auth_login = None
    try:
        auth_login = (run_cmd(["gh", "api", "user", "-q", ".login"], cwd=repo_root) or "").strip() or None
        coverage.append(_coverage("authenticated login", "ok", auth_login or ""))
    except Exception as exc:
        coverage.append(_coverage("authenticated login", "failed", str(exc).splitlines()[-1] if str(exc) else repr(exc)))

    operator = (args.operator or auth_login or "").strip() or None
    if not operator:
        coverage.append(_coverage("operator login", "failed", "unresolved (pass --operator or authenticate gh)"))
    else:
        coverage.append(_coverage("operator login", "ok", operator))

    # Open PRs coverage (respecting get_open_prs limit=300)
    if prs_error:
        coverage.append(_coverage("open PRs", "failed", prs_error))
        open_prs_ok = False
    elif len(prs) >= 300:
        coverage.append(_coverage("open PRs", "truncated", f"{len(prs)} rows returned at limit 300", count=len(prs)))
        open_prs_ok = False
    else:
        coverage.append(_coverage("open PRs", "ok", count=len(prs)))
        open_prs_ok = True

    # Open issues coverage
    open_issues: dict[int, dict] | None = None
    open_issues_ok = False
    try:
        open_issues = get_open_issues(repo_root, slug or gh_repo)
        coverage.append(_coverage("open issues", "ok", count=len(open_issues)))
        open_issues_ok = True
    except Exception as exc:
        err_line = str(exc).splitlines()[-1] if str(exc) else repr(exc)
        status_kind = "truncated" if "reached limit=" in err_line else "failed"
        coverage.append(_coverage("open issues", status_kind, err_line))

    # Optional Forge releases.db enrichment (read-only via existing get_release_milestones; GH-777 compliant)
    release_context: dict = {}
    if repo_mode == "forge":
        try:
            release_context = get_release_milestones(repo_root)
            coverage.append(_coverage("releases.db", "ok", f"target={(release_context.get('target_release') or {}).get('version') or 'none'}"))
        except Exception as exc:
            coverage.append(_coverage("releases.db", "failed", str(exc).splitlines()[-1]))
    else:
        coverage.append(_coverage("releases.db", "skipped", f"repo_mode={repo_mode}"))

    # Local checkouts, worktrees, and read-only .tick claims
    all_prs = _gh_json(
        ["gh", "pr", "list", "--state", "all", "--limit", "500", "--json", "number,headRefName,state"]
        + (["-R", slug] if slug else (["-R", gh_repo] if gh_repo else [])),
        repo_root, "PR heads (all states)", coverage, limit=500,
    )
    pr_heads: dict[str, list[dict]] = {}
    for p_item in all_prs or []:
        pr_heads.setdefault(str(p_item.get("headRefName")), []).append(p_item)
    roots = list(args.local_roots or [str(repo_root), "~/marathon-clones/*"])
    local_rows: list[dict] = []
    for path in discover_local_roots(repo_root, roots, slug, coverage):
        local_rows.extend(scan_local_checkout(path, pr_heads, now, device, coverage))

    # Ledger discovery (and optional creation when --publish-ledger is set)
    disc = find_or_create_daily_ledger_issue(
        repo_root=repo_root,
        slug=slug,
        date_local=date_local,
        ledger_issue_arg=getattr(args, "ledger_issue", None),
        create_if_missing=bool(getattr(args, "publish_ledger", False)),
        operator=operator,
        auth_login=auth_login,
        allow_delegate=allow_delegate,
        trusted_bots=trusted_bots,
        coverage=coverage,
        warnings=warnings,
    )
    today_ledger = disc["today_ledger"]
    previous_ledger = disc["previous_ledger"]
    prev_date = previous_ledger.get("ledger_date") if previous_ledger else None

    today_comments = read_ledger_comments(repo_root, slug, disc["today_duplicates"], "today ledger comments", coverage)
    prev_comments = read_ledger_comments(repo_root, slug, disc["previous_duplicates"], "previous ledger comments", coverage)

    # Parse and verify comments on previous_ledger and today_ledger
    parsed_prev: list[dict] = []
    for c in prev_comments or []:
        pc = parse_ledger_comment(c, prev_date or "", allow_delegate, trusted_bots, warnings)
        if pc is not None:
            parsed_prev.append(pc)

    parsed_today: list[dict] = []
    for c in today_comments or []:
        tc = parse_ledger_comment(c, date_local, allow_delegate, trusted_bots, warnings)
        if tc is not None:
            parsed_today.append(tc)

    # 1. Prior-workday carryover for operator across ANY device (verified comments only)
    carryover_open_issues: list[dict] = []
    carryover_open_prs: list[dict] = []
    completed_since_last: list[dict] = []
    unverified_carryover: list[dict] = []
    pr_by_num = {int(p["number"]): p for p in prs if p.get("number")}

    seen_carry_iss: set[int] = set()
    seen_carry_pr: set[int] = set()
    for pc in parsed_prev:
        if not pc["verified"]:
            continue
        if not operator or pc["operator"].lower() != operator.lower():
            continue
        src_dev = pc["device"]
        for inum in pc["issue_numbers"]:
            if inum in seen_carry_iss:
                continue
            seen_carry_iss.add(inum)
            if not open_issues_ok or open_issues is None:
                unverified_carryover.append({"kind": "issue", "number": inum, "from_device": src_dev, "reason": "open_issues coverage incomplete"})
            elif inum in open_issues:
                iss_obj = open_issues[inum]
                carryover_open_issues.append({
                    "number": inum,
                    "title": iss_obj.get("title") or "",
                    "url": iss_obj.get("url") or "",
                    "from_device": src_dev,
                    "from_date": prev_date,
                })
            else:
                completed_since_last.append({"kind": "issue", "number": inum, "from_device": src_dev, "from_date": prev_date, "status": "closed"})
        for pnum in pc["pr_numbers"]:
            if pnum in seen_carry_pr:
                continue
            seen_carry_pr.add(pnum)
            if not open_prs_ok:
                unverified_carryover.append({"kind": "pr", "number": pnum, "from_device": src_dev, "reason": "open_prs coverage incomplete"})
            elif pnum in pr_by_num:
                pr_obj = pr_by_num[pnum]
                carryover_open_prs.append({
                    "number": pnum,
                    "title": pr_obj.get("title") or "",
                    "url": pr_obj.get("url") or "",
                    "from_device": src_dev,
                    "from_date": prev_date,
                })
            else:
                completed_since_last.append({"kind": "pr", "number": pnum, "from_device": src_dev, "from_date": prev_date, "status": "merged_or_closed"})

    # 2. Newly assigned open issues, PRs awaiting review, and PRs needing remediation
    assigned_issues: list[dict] = []
    if operator and open_issues:
        for inum, iss_obj in sorted(open_issues.items()):
            assignees = {str(a.get("login", "")).lower() for a in (iss_obj.get("assignees") or []) if isinstance(a, dict)}
            if operator.lower() in assignees and inum not in seen_carry_iss:
                assigned_issues.append({
                    "number": inum,
                    "title": iss_obj.get("title") or "",
                    "url": iss_obj.get("url") or "",
                    "labels": sorted(_labels(iss_obj)),
                })

    prs_awaiting_review: list[dict] = []
    my_open_pr_nums: list[int] = []
    for pr_obj in prs:
        pnum = int(pr_obj.get("number") or 0)
        author_login = str((pr_obj.get("author") or {}).get("login") or "").strip()
        if operator and author_login.lower() == operator.lower():
            my_open_pr_nums.append(pnum)
        if pr_obj.get("isDraft"):
            continue
        req_list = pr_obj.get("reviewRequests") or []
        matched_req = None
        team_notes: list[str] = []
        for req in req_list:
            if not isinstance(req, dict):
                continue
            r_login = str(req.get("login") or "").strip()
            r_slug = str(req.get("slug") or req.get("name") or "").strip()
            if operator and r_login and r_login.lower() == operator.lower():
                matched_req = f"user:{r_login}"
            elif r_slug and not r_login:
                team_notes.append(f"team:{r_slug}")
        if matched_req or (team_notes and operator):
            if matched_req:
                prs_awaiting_review.append({
                    "number": pnum,
                    "title": pr_obj.get("title") or "",
                    "url": pr_obj.get("url") or "",
                    "author": author_login,
                    "requested_via": matched_req,
                    "team_requests": team_notes,
                })

    thread_map = fetch_pr_review_threads(repo_root, slug, my_open_pr_nums, coverage)
    prs_needing_remediation: list[dict] = []
    for pnum in my_open_pr_nums:
        pr_obj = pr_by_num[pnum]
        ci_st = eval_ci_status(pr_obj)
        rev_dec = str(pr_obj.get("reviewDecision") or "")
        t_info = thread_map.get(pnum) or {}
        unresolved_cnt = int(t_info.get("unresolved_count") or 0)
        reasons: list[str] = []
        if rev_dec == "CHANGES_REQUESTED":
            reasons.append("CHANGES_REQUESTED")
        if ci_st == "FAILURE":
            reasons.append("CI_FAILURE")
        if unresolved_cnt > 0:
            reasons.append(f"UNRESOLVED_THREADS({unresolved_cnt})")
        if reasons:
            prs_needing_remediation.append({
                "number": pnum,
                "title": pr_obj.get("title") or "",
                "url": pr_obj.get("url") or "",
                "ci_status": ci_st,
                "review_decision": rev_dec,
                "unresolved_threads": unresolved_cnt,
                "reasons": reasons,
            })

    # 3. Earliest-Starter & Already Checked Out Calibration (with explicit provenance)
    verified_today = [tc for tc in parsed_today if tc["verified"]]
    verified_today.sort(key=lambda x: (x.get("started") or "9999", int(x.get("comment_id") or 0)))
    earliest_starter = None
    if verified_today:
        es = verified_today[0]
        earliest_starter = {
            "operator": es["operator"],
            "device": es["device"],
            "started": es["started"],
            "comment_id": es["comment_id"],
            "issue_numbers": es["issue_numbers"],
            "pr_numbers": es["pr_numbers"],
        }

    already_checked_out: list[dict] = []
    other_claimed_issues: dict[int, list[dict]] = {}
    other_claimed_prs: dict[int, list[dict]] = {}

    # Source A: verified ledger comments on today's issue
    for tc in verified_today:
        op_name = tc["operator"]
        is_other = not operator or op_name.lower() != operator.lower()
        for inum in tc["issue_numbers"]:
            claim_row = {
                "kind": "issue",
                "number": inum,
                "ref": f"GH-{inum}",
                "owner": op_name,
                "device": tc["device"],
                "started": tc["started"],
                "provenance": "verified-ledger-claim",
            }
            already_checked_out.append(claim_row)
            if is_other:
                other_claimed_issues.setdefault(inum, []).append(claim_row)
        for pnum in tc["pr_numbers"]:
            claim_row = {
                "kind": "pr",
                "number": pnum,
                "ref": f"PR #{pnum}",
                "owner": op_name,
                "device": tc["device"],
                "started": tc["started"],
                "provenance": "verified-ledger-claim",
            }
            already_checked_out.append(claim_row)
            if is_other:
                other_claimed_prs.setdefault(pnum, []).append(claim_row)

    # Source B: live GitHub claims (in-progress labels, assignees, open PR branches)
    for inum, iss_obj in sorted((open_issues or {}).items()):
        labels = _labels(iss_obj)
        assignees = [str(a.get("login") or "") for a in (iss_obj.get("assignees") or []) if isinstance(a, dict) and a.get("login")]
        if (labels & IN_PROGRESS_LABELS) or assignees:
            owner_str = ",".join(assignees) if assignees else "in-progress-label"
            claim_row = {
                "kind": "issue",
                "number": inum,
                "ref": f"GH-{inum}",
                "owner": owner_str,
                "device": "github",
                "started": (iss_obj.get("updatedAt") or "")[:19],
                "provenance": "github-label-or-pr",
            }
            already_checked_out.append(claim_row)
            if assignees and operator and all(a.lower() != operator.lower() for a in assignees):
                other_claimed_issues.setdefault(inum, []).append(claim_row)

    for pr_obj in prs:
        pnum = int(pr_obj.get("number") or 0)
        p_author = str((pr_obj.get("author") or {}).get("login") or "")
        head_ref = str(pr_obj.get("headRefName") or "")
        for inum in _extract_issue_numbers(head_ref) or _extract_issue_numbers(pr_obj.get("title")):
            claim_row = {
                "kind": "issue",
                "number": inum,
                "ref": f"GH-{inum} (via PR #{pnum})",
                "owner": p_author or "pr-author",
                "device": "github",
                "started": (pr_obj.get("updatedAt") or "")[:19],
                "provenance": "github-label-or-pr",
            }
            already_checked_out.append(claim_row)
            if p_author and operator and p_author.lower() != operator.lower():
                other_claimed_issues.setdefault(inum, []).append(claim_row)

    # Source C: local checkouts, linked worktrees, and read-only .tick claims on this device
    for lrow in local_rows:
        for inum in lrow.get("issue_numbers") or []:
            claim_row = {
                "kind": "issue",
                "number": inum,
                "ref": f"GH-{inum} ({lrow.get('ref')})",
                "owner": lrow.get("agent") or operator or device,
                "device": device,
                "started": lrow.get("last_activity") or date_local,
                "provenance": "local-device-only",
                "local_kind": lrow.get("kind"),
            }
            already_checked_out.append(claim_row)
            other_claimed_issues.setdefault(inum, []).append(claim_row)

    # Detect collisions against operator's candidate issues (carryover + assigned + open release builds)
    candidate_issues: list[int] = []
    for item in carryover_open_issues:
        if item["number"] not in candidate_issues:
            candidate_issues.append(item["number"])
    for item in assigned_issues:
        if item["number"] not in candidate_issues:
            candidate_issues.append(item["number"])

    collisions: list[dict] = []
    for inum in candidate_issues:
        claimants = other_claimed_issues.get(inum, [])
        if claimants:
            collisions.append({
                "number": inum,
                "ref": f"GH-{inum}",
                "claimants": claimants,
            })

    ledger_data = {
        "mode": "daily_ledger",
        "date": date_local,
        "timezone": resolved_tz,
        "generated_at": now.isoformat(),
        "repo_slug": slug,
        "repo_mode": repo_mode,
        "repo_mode_source": repo_mode_how,
        "operator": operator,
        "authenticated_login": auth_login,
        "device": device,
        "today_ledger": today_ledger,
        "today_duplicates": [x["number"] for x in disc["today_duplicates"]],
        "previous_ledger": previous_ledger,
        "previous_duplicates": [x["number"] for x in disc["previous_duplicates"]],
        "earliest_starter": earliest_starter,
        "already_checked_out": already_checked_out,
        "collisions": collisions,
        "carryover_open_issues": carryover_open_issues,
        "carryover_open_prs": carryover_open_prs,
        "completed_since_last_ledger": completed_since_last,
        "unverified_carryover": unverified_carryover,
        "assigned_open_issues": assigned_issues,
        "prs_awaiting_review": prs_awaiting_review,
        "prs_needing_remediation": prs_needing_remediation,
        "local_checkout": local_rows,
        "release_context": {
            "target_release": (release_context.get("target_release") if isinstance(release_context, dict) else None),
            "manifest_summary": (release_context.get("manifest_summary") if isinstance(release_context, dict) else None),
        },
        "warnings": warnings,
        "coverage": coverage,
        "publish_receipt": None,
    }

    rc = 0
    if getattr(args, "publish_ledger", False):
        disc_cov = next((c for c in coverage if c["source"] == "ledger discovery"), {})
        tcomm_cov = next((c for c in coverage if c["source"] == "today ledger comments"), {})
        if disc.get("auth_refused"):
            print(f"[ERROR] daily ledger publish refused: {disc['auth_refused']}", file=sys.stderr)
            ledger_data["publish_receipt"] = {"action": "refused", "detail": disc["auth_refused"]}
            return ledger_data, 3
        if disc_cov.get("status") != "ok" or tcomm_cov.get("status") not in {"ok", "skipped"} or today_ledger is None:
            msg = f"coverage incomplete or today ledger unresolved (discovery={disc_cov.get('status')}, comments={tcomm_cov.get('status')}); refusing to publish blind"
            print(f"[ERROR] daily ledger publish: {msg}", file=sys.stderr)
            ledger_data["publish_receipt"] = {"action": "refused", "detail": msg}
            return ledger_data, 3
        comment_md = format_daily_ledger_markdown(ledger_data, for_comment=True)
        ok, what, receipt = sync_daily_ledger_comment(
            repo_root=repo_root,
            slug=slug,
            issue_num=int(today_ledger["number"]),
            existing_comments=today_comments or [],
            operator=operator or "",
            device=device,
            date_local=date_local,
            auth_login=auth_login,
            allow_delegate=allow_delegate,
            trusted_bots=trusted_bots,
            body_md=comment_md,
            now_iso=now.strftime("%Y-%m-%dT%H:%M:%SZ"),
        )
        ledger_data["publish_receipt"] = receipt
        print(f"daily ledger comment on #{today_ledger['number']}: {what}" if ok else f"[ERROR] daily ledger comment on #{today_ledger['number']}: {what}",
              file=sys.stdout if ok else sys.stderr)
        rc = 0 if ok else 3

    return ledger_data, rc


def format_daily_ledger_markdown(ledger: dict, for_comment: bool = False) -> str:
    """Render the Daily Work Ledger report (both full local MD and per-operator GitHub issue comment)."""
    date_str = ledger.get("date") or ""
    op = ledger.get("operator") or "unassigned"
    dev = ledger.get("device") or "unknown-device"
    rmode = ledger.get("repo_mode") or "gh-only"
    t_iss = ledger.get("today_ledger")
    p_iss = ledger.get("previous_ledger")
    es = ledger.get("earliest_starter")

    heading = f"### Daily Work Ledger — `{op}` (`{dev}`) — {date_str}" if for_comment else f"# Daily Work Ledger — {date_str}"
    lines = [
        heading,
        "",
        f"- **Operator:** `{op}` · **Device:** `{dev}` · **Repo Mode:** `{rmode}` ({ledger.get('repo_mode_source')})",
        f"- **Today's Ledger Issue:** " + (f"[#{t_iss['number']}]({t_iss.get('url') or ''}) (`{t_iss.get('title')}`)" if t_iss else "*Not created yet (run with `--publish-ledger`)*"),
        f"- **Prior Workday Ledger:** " + (f"[#{p_iss['number']}]({p_iss.get('url') or ''}) (`{p_iss.get('ledger_date')}`)" if p_iss else "*None found*"),
        f"- **Earliest Starter Today:** " + (f"`{es['operator']}` on `{es['device']}` at `{es['started']}`" if es else "*No verified starter comment recorded yet*"),
        "",
        "## 1. Coverage & Verification Gate",
        "",
    ]
    for c in ledger.get("coverage", []):
        extra = f" — {c.get('detail')}" if c.get("detail") else ""
        cnt = f" ({c.get('count')})" if c.get("count") is not None else ""
        lines.append(f"- `{c.get('status')}` **{c.get('source')}**{cnt}{extra}")
    for w in ledger.get("warnings", []):
        lines.append(f"- ⚠️ **Warning:** {w}")

    lines.extend(["", "## 2. Already Checked Out / Earliest-Starter Calibration", ""])
    checked = ledger.get("already_checked_out") or []
    if checked:
        for row in checked:
            lines.append(
                f"- **{row.get('ref')}** — owner `{row.get('owner')}` (`{row.get('device')}`) · started `{row.get('started')}` · provenance `{row.get('provenance')}`"
            )
    else:
        lines.append("- *No active checkouts observed across today's ledger comments, GitHub labels/PRs, or local checkouts.*")

    collisions = ledger.get("collisions") or []
    if collisions:
        lines.append("")
        lines.append("### ⚠️ Checkout Collisions Detected")
        for col in collisions:
            owners = ", ".join(f"{c['owner']} ({c['provenance']})" for c in col.get("claimants", []))
            lines.append(f"- **COLLISION on {col['ref']}**: claimed/checked out by {owners}")

    lines.extend(["", "## 3. Carryover from Prior Workday", ""])
    c_iss = ledger.get("carryover_open_issues") or []
    c_prs = ledger.get("carryover_open_prs") or []
    if c_iss or c_prs:
        for item in c_iss:
            lines.append(f"- **GH-{item['number']}**: {item.get('title')} (carried from `{item.get('from_device')}` on `{item.get('from_date')}`)")
        for item in c_prs:
            lines.append(f"- **PR #{item['number']}**: {item.get('title')} (carried from `{item.get('from_device')}` on `{item.get('from_date')}`)")
    else:
        lines.append("- *No open carryover items from prior workday.*")

    comp = ledger.get("completed_since_last_ledger") or []
    if comp:
        lines.extend(["", "### Completed Since Prior Ledger", ""])
        for item in comp:
            prefix = "GH-" if item.get("kind") == "issue" else "PR #"
            lines.append(f"- ~~{prefix}{item['number']}~~ (`{item.get('status')}` since `{item.get('from_date')}`)")

    lines.extend(["", "## 4. PR Reviews & Comment Remediations", ""])
    revs = ledger.get("prs_awaiting_review") or []
    rems = ledger.get("prs_needing_remediation") or []
    if revs:
        lines.append("### PRs Awaiting Your Review")
        for r in revs:
            lines.append(f"- **PR #{r['number']}** by `{r.get('author')}`: {r.get('title')} (`{r.get('requested_via')}`)")
    else:
        lines.append("- *No open PRs currently requesting your review.*")
    if rems:
        lines.append("")
        lines.append("### Your Open PRs Needing Remediation")
        for rm in rems:
            lines.append(f"- **PR #{rm['number']}**: {rm.get('title')} — `{', '.join(rm.get('reasons') or [])}`")
    else:
        lines.append("- *No open PRs authored by you with failing CI, changes requested, or unresolved review threads.*")

    lines.extend(["", "## 5. Newly Assigned Open Issues", ""])
    ass = ledger.get("assigned_open_issues") or []
    if ass:
        for a in ass:
            lines.append(f"- **GH-{a['number']}**: {a.get('title')}")
    else:
        lines.append("- *No additional open issues assigned to you.*")

    lines.append("")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Planner Core Engine")
    parser.add_argument("--repo-root", default=".", help="Path to repository root")
    parser.add_argument("--gh-repo", default=None, help="Target GitHub repo (e.g. Org/Name)")
    parser.add_argument("--mode", choices=["weekly", "daily", "audit", "sequence", "intake", "stalled", "ledger"], default="weekly")
    parser.add_argument("--plan-file", help="Path to existing weekly plan JSON/MD")
    parser.add_argument("--decisions-issue", help="Canonical GH issue number for provisional decisions tracker")
    parser.add_argument("--team-issue", "--issue", dest="team_issue", type=int,
                        help="Team weekly issue number for focus assignments; in daily/stalled mode also the "
                             "target of the per-device Stalled & stale comment (GH-1184)")
    parser.add_argument("--hours", type=int, default=36, help="Lookback interval in hours for daily mode")
    parser.add_argument("--fallback", action="store_true", help="Force scratch markdown fallback intake")
    # GH-1184 Stalled & stale (daily section + headless `--mode stalled`)
    parser.add_argument("--stale-days", type=int, default=3, help="PRs / in-progress issues idle this many days are stalled")
    parser.add_argument("--draft-stale-days", type=int, default=7, help="draft PRs idle this many days are stalled")
    parser.add_argument("--local-roots", action="append",
                        help="checkout path or glob to scan read-only (repeatable; default: --repo-root and ~/marathon-clones/*)")
    parser.add_argument("--device-id", help="device id for the comment marker (default: device_config device_id, normalized)")
    parser.add_argument("--operator", help="GitHub login whose assigned issues count as 'mine' (default: gh api user)")
    # GH-1459 Daily Work Ledger & repo-mode support
    parser.add_argument("--repo-mode", choices=["auto", "forge", "vendored", "gh-only"], default="auto",
                        help="Repository operating mode (precedence: --repo-mode > XYZ_DAILY_LEDGER_MODE > device_config > auto)")
    parser.add_argument("--publish-ledger", action="store_true",
                        help="Create today's Daily Work Ledger GH issue if missing and POST/PATCH this operator+device comment")
    parser.add_argument("--ledger-issue", type=int, help="Explicit GitHub issue number override for today's Daily Work Ledger")
    parser.add_argument("--ledger-tz", help="IANA timezone for shared Daily Work Ledger date boundary (default: America/Los_Angeles)")
    parser.add_argument("--allow-delegate-comment", action="store_true",
                        help="Allow trusted delegate bot (in XYZ_DAILY_LEDGER_TRUSTED_BOTS / daily_ledger_trusted_bots) to POST ledger comments")

    args = parser.parse_args()
    if args.stale_days < 1 or args.draft_stale_days < 1:
        print("[ERROR] --stale-days/--draft-stale-days must be >= 1", file=sys.stderr)
        sys.exit(2)
    repo_root = Path(args.repo_root).resolve()
    if not repo_root.is_dir():
        print(f"[ERROR] repo root not found: {repo_root}", file=sys.stderr)
        sys.exit(2)
    temp_dir = ensure_temp_dir(repo_root)

    # The stalled scan must still produce its report when the PR lookup fails (the failure becomes a
    # coverage gap, GH-1184 AC4); every other mode keeps today's fail-closed behaviour.
    prs_error = None
    try:
        prs = get_open_prs(repo_root, args.gh_repo)
    except Exception as exc:
        if args.mode not in {"stalled", "daily", "ledger"}:
            raise
        prs, prs_error = [], (str(exc).splitlines()[-1] if str(exc) else repr(exc))
        print(f"[WARN] open PR lookup failed; continuing with a coverage gap: {prs_error}", file=sys.stderr)
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

    if args.mode == "ledger":
        ledger_data, rc = run_daily_ledger(repo_root, args.gh_repo, prs, sequence, args, now_utc, prs_error)
        l_date = ledger_data.get("date") or date_str
        out_json = temp_dir / f"daily-ledger-{l_date}.json"
        out_json.write_text(json.dumps(ledger_data, indent=2), encoding="utf-8")
        out_md = temp_dir / f"DAILY-LEDGER-{l_date}.md"
        out_md.write_text(format_daily_ledger_markdown(ledger_data, for_comment=False), encoding="utf-8")
        gaps = sum(1 for c in ledger_data["coverage"] if c.get("status") not in {"ok", "skipped"})
        print(f"daily ledger ({ledger_data['repo_mode']}): {len(ledger_data['carryover_open_issues']) + len(ledger_data['carryover_open_prs'])} carryover, "
              f"{len(ledger_data['assigned_open_issues'])} assigned, {len(ledger_data['prs_awaiting_review'])} reviews, "
              f"{len(ledger_data['prs_needing_remediation'])} remediations, {len(ledger_data['collisions'])} collision(s), "
              f"{gaps} coverage gap(s) → {out_md}")
        sys.exit(rc)

    if args.mode == "stalled":
        # Headless GH-1184 entry point for the #1168 scheduler: only the read-only scan and, with
        # --team-issue, this device's comment. Never pivot_daily (no weekly baseline needed).
        section, ctx = run_stalled_scan(repo_root, args.gh_repo, prs, sequence, args, now_utc, prs_error)
        result = {"mode": "stalled", "date": date_str, "date_local": ctx["date_local"], "stalled_stale": section}
        out_json = temp_dir / f"stalled-{date_str}.json"
        out_json.write_text(json.dumps(result, indent=2), encoding="utf-8")
        out_md = temp_dir / f"STALLED-{date_str}.md"
        out_md.write_text(format_stalled_markdown(section, f"# Stalled & stale — {ctx['device']} — {ctx['date_local']}",
                                                  ctx["date_local"]), encoding="utf-8")
        gaps = sum(1 for c in section["coverage"] if c.get("status") != "ok")
        print(f"stalled scan: {len(section['stalled'])} stalled, {len(section['held'])} held, "
              f"{len(section['local'])} local, {gaps} coverage gap(s) → {out_md}")
        rc = publish_stalled_comment(repo_root, section, ctx, args.team_issue) if args.team_issue else 0
        sys.exit(rc)

    if args.mode == "daily":
        plan_file_arg = Path(args.plan_file) if args.plan_file else None
        pivot = pivot_daily(plan_file_arg, repo_root, args.gh_repo, hours=args.hours)
        audit = audit_adversarial({"prs": prs, "pivot": pivot}, prs=prs)
        section, ctx = run_stalled_scan(repo_root, args.gh_repo, prs, sequence, args, now_utc, prs_error)
        result = {
            "mode": "daily_pivot",
            "date": date_str,
            "date_local": ctx["date_local"],
            "merge_sequence": sequence,
            "pivot": pivot,
            "adversarial_audit": audit,
            "stalled_stale": section,
        }
        out_json = temp_dir / f"daily-pivot-{date_str}.json"
        out_json.write_text(json.dumps(result, indent=2), encoding="utf-8")
        out_md = temp_dir / f"DAILY-PIVOT-{date_str}.md"
        out_md.write_text(format_daily_markdown(date_str, result), encoding="utf-8")
        print(f"Daily pivot generated at:\n  - JSON: {out_json}\n  - Markdown: {out_md}")
        if args.team_issue:
            sys.exit(publish_stalled_comment(repo_root, section, ctx, args.team_issue))
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
