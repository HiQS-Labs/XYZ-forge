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
        "--json", "number,title,author,headRefName,baseRefName,mergeable,reviewDecision,reviews,updatedAt,statusCheckRollup,files,body,isDraft,labels,url"
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


def scan_local_checkout(path: Path, pr_heads: dict[str, list[dict]], now: datetime, device: str,
                        coverage: list) -> list[dict]:
    """Read-only: one for-each-ref and one status per checkout. No fetch, prune or write of any kind.
    `--no-optional-locks` keeps `status` from refreshing the index (git-status(1), BACKGROUND REFRESH)."""
    rows: list[dict] = []
    label = path.name
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
        ahead = re.search(r"ahead (\d+)", track or "")
        # Integration branches are promotion PR heads (development -> main); a name match there is
        # never a retirement hint, and a local `development` is tracked by every clone anyway.
        matches = [] if branch in INTEGRATION_BRANCHES else pr_heads.get(branch, [])
        closed = [m for m in matches if str(m.get("state", "")).upper() in {"MERGED", "CLOSED"}]
        if closed and not any(str(m.get("state", "")).upper() == "OPEN" for m in matches):
            m = closed[0]
            rows.append({"kind": "branch", "ref": f"{label}:{branch}", "path": str(path), "device": device,
                         "last_activity": last,
                         "reason": f"PR #{m.get('number')} is {str(m.get('state')).lower()} (name match, unverified)"
                                   + (f"; local ahead {ahead.group(1)} as of last fetch" if ahead else ""),
                         "next_action": "retire? name match — verify with /merge-cleanup"})
        elif not upstream and branch not in INTEGRATION_BRANCHES:
            rows.append({"kind": "branch", "ref": f"{label}:{branch}", "path": str(path), "device": device,
                         "last_activity": last, "reason": "no upstream (never pushed)",
                         "next_action": "inspect; push or delete"})
        elif ahead:
            rows.append({"kind": "branch", "ref": f"{label}:{branch}", "path": str(path), "device": device,
                         "last_activity": last, "reason": f"ahead {ahead.group(1)} of {upstream} (as of last fetch)",
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
                     "last_activity": now.date().isoformat(), "reason": f"{len(dirty)} uncommitted change(s)",
                     "next_action": "commit or stash"})
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
            rows.append({"kind": "note", "ref": f"PARKED/{f.name}", "path": str(f), "device": device,
                         "last_activity": mtime.date().isoformat(), "reason": "parked note, not marked resolved",
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
            rows.append({"kind": "relay", "ref": str(f.relative_to(repo_root)), "path": str(f), "device": device,
                         "last_activity": mtime.date().isoformat(),
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
        devices.append({"device": dev, "last_report": last_date,
                        "status": "today" if (dev == device or last_date == today) else f"no report since {last_date}"})
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
        # Branch/worktree rows group by checkout; note rows (one path each) group by their kind so a
        # pile of PARKED files or relay threads is capped the same way.
        group_names = {"note": "PARKED notes", "relay": "relay threads"}
        per_group: dict[str, list[dict]] = {}
        for r in section["local"]:
            key = (r.get("path") or r["ref"]) if r.get("kind") in {"branch", "worktree"} else group_names.get(r.get("kind"), "notes")
            per_group.setdefault(key, []).append(r)
        for key, rows in per_group.items():
            rows.sort(key=lambda r: (r.get("last_activity", ""), r.get("ref", "")), reverse=True)
            for r in rows[:LOCAL_ROWS_SHOWN]:
                lines.append(f"- `{r['ref']}` — {r['last_activity']} — {r['reason']} → _{r['next_action']}_")
            if len(rows) > LOCAL_ROWS_SHOWN:
                label = key if key in group_names.values() else rows[0]["ref"].split(":")[0]
                lines.append(f"- `{label}` … +{len(rows) - LOCAL_ROWS_SHOWN} more row(s) in the JSON")
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


def main():
    parser = argparse.ArgumentParser(description="Planner Core Engine")
    parser.add_argument("--repo-root", default=".", help="Path to repository root")
    parser.add_argument("--gh-repo", default=None, help="Target GitHub repo (e.g. Org/Name)")
    parser.add_argument("--mode", choices=["weekly", "daily", "audit", "sequence", "intake", "stalled"], default="weekly")
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
        if args.mode not in {"stalled", "daily"}:
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
