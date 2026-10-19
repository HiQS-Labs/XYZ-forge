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

# Byte identity of this entry point; verification is separate from execution approval.
PLANNER_SOURCE_SHA256 = __import__("hashlib").sha256(Path(__file__).read_bytes()).hexdigest()
WEEKLY_IO_TIMEOUT_SECONDS = 60


def load_issue_intake():
    """Locate harness code without importing planner main or creating scratch."""
    import importlib.util
    override = os.environ.get("XYZ_HARNESS") or os.environ.get("XYZ_REPO_ROOT")
    if override and not (Path(override) / "relay-automation/relay-drive.sh").is_file():
        raise RuntimeError("explicit harness is unavailable or incomplete")
    here = Path(__file__).resolve()
    bundled = here.parents[4]
    module_file = bundled / "skills/3-weekly/weekly-planner/scripts/issue_intake.py"
    if not all(path.is_file() for path in (module_file, bundled / "utils/py/releases_app.py",
                                          bundled / "utils/hq/hq-lib.sh",
                                          bundled / "relay-automation/relay-drive.sh")):
        candidates = []
        if override:
            candidates.append(Path(override) / "skills/1-hourly/relay-xyz/find-harness.sh")
        candidates.append(here.parents[3] / "1-hourly/relay-xyz/find-harness.sh")
        for directory in (".codex/skills", ".agents/skills", ".claude/skills", ".gemini/config/skills",
                          ".gemini/antigravity/skills", ".gemini/antigravity-cli/skills", ".zcode/skills"):
            candidates.append(Path.home() / directory / "relay-xyz/find-harness.sh")
        locator = next((path for path in candidates if path.is_file()), None)
        if locator is None:
            raise RuntimeError("harness locator not found; set XYZ_HARNESS")
        harness = Path(run_cmd(["bash", str(locator), "--root", "--quiet"]))
        module_file = harness / "skills/3-weekly/weekly-planner/scripts/issue_intake.py"
        if not module_file.is_file():
            raise RuntimeError("selected harness lacks issue_intake.py; update harness")
    spec = importlib.util.spec_from_file_location("issue_intake", module_file)
    module = importlib.util.module_from_spec(spec)
    data = module_file.read_bytes()
    exec(compile(data, str(module_file), "exec"), module.__dict__)
    module.loaded_sha256 = __import__("hashlib").sha256(data).hexdigest()
    return module


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


def resolve_gh_repo(repo_root: Path) -> str | None:
    """Resolve GitHub owner/repo from git remote or gh CLI."""
    try:
        out = run_cmd(["git", "config", "--get", "remote.origin.url"], cwd=repo_root, check=False)
        if out:
            m = re.search(r"github\.com[:/]([\w.-]+/[\w.-]+?)(?:\.git)?$", out.strip())
            if m:
                return m.group(1)
    except Exception:
        pass
    try:
        out = run_cmd(["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"], cwd=repo_root, check=False)
        if out and "/" in out.strip():
            return out.strip()
    except Exception:
        pass
    return None


def ingest_weekly_intake(repo_root: Path, gh_repo: str | None = None, team_issue: int | None = None, fallback_mode: bool = False, since: str | None = None) -> dict:
    """
    Ingest weekly signals:
    - Grounding: Validates open issues against live GitHub state (drops closed/retired/foreign issues).
    - Release Milestone Anchor: Ingests next unshipped release, exit criterion, manifest build burndown,
      active marathons, and jog queue from releases.db and releases_app.py next.
    - Mode A (Native XYZ): Query PRS 4-axis ratings (pri, sev, appeal, effort, ovr, risk) directly from
      releases.db roadmap_items (or releases_app.py fallback).
    - Mode B (Fallback): Query open GitHub issues and generate pass1-intake.md and pass2-sharpened.md.
    - Canonical Discovery (GH-1022): issue_intake.discover_weekly adds paginated, repository-qualified
      open issues updated since the window that the roadmap does not know yet, plus every open PR
      (discovered_prs). Discovered items pass through the same live grounding as every other source;
      a discovery failure refuses unless --fallback was selected explicitly.
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

    # Canonical GitHub discovery (GH-1022): paginated, repository-qualified issues updated since the
    # window plus every open PR. It augments the native/fallback roadmap with open issues the ledger
    # does not know yet; the live grounding below stays the authority for what survives. A discovery
    # failure refuses (hold on unknown) unless --fallback was selected explicitly.
    target_repo = gh_repo or resolve_gh_repo(repo_root)
    discovered_prs: list[dict] = []
    if target_repo:
        try:
            intake_module = load_issue_intake()
            if not since:
                since = (datetime.now(timezone.utc) - timedelta(days=7)).isoformat()
            discovery = intake_module.discover_weekly(target_repo, since, repo_root)
        except Exception as e:
            if not fallback_mode:
                raise RuntimeError(
                    f"Canonical issue intake discovery failed ({e}); repair GitHub access or explicitly select --fallback"
                ) from e
            print(f"[WARN] Canonical issue intake discovery skipped under --fallback ({e}).", file=sys.stderr)
        else:
            discovered_prs = discovery.get("prs", [])
            known_numbers = set()
            for item in raw_items:
                try:
                    known_numbers.add(int(item.get("gh_number")))
                except (ValueError, TypeError):
                    continue
            for iss in discovery.get("issues", []):
                if iss.get("state") != "OPEN" or iss.get("number") in known_numbers:
                    continue
                raw_items.append({
                    "gh_number": iss.get("number"), "title": iss.get("title"),
                    "section": "Active Issues (Weekly Intake)", "issue_url": iss.get("url"),
                    "raw_text": "",
                })
                known_numbers.add(iss.get("number"))
            intake_mode = f"{intake_mode}+canonical"

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
            if target_repo:
                cmd.extend(["-R", target_repo])
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
        "discovered_prs": discovered_prs,
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
        "## 5. Adversarial Northstars Audit",
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


def load_weekly_runtime(intake, extra_files=None):
    import hashlib
    import importlib.util
    harness = Path(intake.__file__).resolve().parents[4]
    app = harness / "utils/py/releases_app.py"
    renderer = harness / "utils/hq/hq-lib.sh"
    spec = importlib.util.spec_from_file_location("weekly_releases_owner", app)
    canonical = importlib.util.module_from_spec(spec)
    app_bytes = app.read_bytes()
    exec(compile(app_bytes, str(app), "exec"), canonical.__dict__)
    process_path = harness / "utils/py/proc_group.py"
    process_spec = importlib.util.spec_from_file_location("weekly_process_owner", process_path)
    process = importlib.util.module_from_spec(process_spec)
    sys.modules[process_spec.name] = process  # dataclasses resolves its owning module
    process_bytes = process_path.read_bytes()
    exec(compile(process_bytes, str(process_path), "exec"), process.__dict__)
    runtime_files = {"planner": Path(__file__).resolve(), "intake": Path(intake.__file__).resolve(),
                     "writer": app, "renderer": renderer, "process_runner": process_path}
    runtime_files.update(extra_files or {})
    runtime_hashes = {name: hashlib.sha256(path.read_bytes()).hexdigest() for name, path in runtime_files.items()}
    if (runtime_hashes["planner"] != PLANNER_SOURCE_SHA256
            or runtime_hashes["intake"] != intake.loaded_sha256
            or runtime_hashes["writer"] != hashlib.sha256(app_bytes).hexdigest()
            or runtime_hashes["process_runner"] != hashlib.sha256(process_bytes).hexdigest()):
        raise ValueError("runtime code changed while loading; refresh without side effects")
    runtime = {"harness": str(harness), "paths": {name: str(path.resolve()) for name, path in runtime_files.items()},
               "sha256": runtime_hashes, "io_timeout_seconds": WEEKLY_IO_TIMEOUT_SECONDS}

    def check_runtime():
        if any(str(path.resolve()) != runtime["paths"][name]
               or hashlib.sha256(path.read_bytes()).hexdigest() != runtime_hashes[name]
               for name, path in runtime_files.items()):
            raise ValueError("runtime code changed during preparation; preserve partial state and refresh")

    return harness, canonical, process, runtime, check_runtime


def weekly_command(process, env, accepted_returncodes=(0,), timeout=None):
    def command(argv, cwd):
        limit = WEEKLY_IO_TIMEOUT_SECONDS if timeout is None else timeout
        result = process.run_bounded(argv, cwd=str(cwd), env=env,
                                     timeout=limit, grace=1)
        if result.timed_out:
            raise RuntimeError(f"command timed out after {limit}s: {argv[0]}; preserve partial state")
        if result.rc not in accepted_returncodes:
            raise RuntimeError(f"command refused ({result.rc}): {argv[0]} {result.stderr.strip()}")
        return result.stdout
    return command


def observe_weekly_work(authority_file, repo_root, command=None):
    """Explicit declared-root observations only; no preparation, selection or dispatch."""
    intake = load_issue_intake()
    harness = Path(intake.__file__).resolve().parents[4]
    _, _, process, runtime, check = load_weekly_runtime(intake, {
        "observer": harness / "relay-automation/marathon.sh",
        "lock_resolver": harness / "utils/py/rtl.py",
    })
    authority = json.loads(Path(authority_file).read_text())
    if (not isinstance(authority, dict) or authority.get("schema") != "weekly/authorities@1"
            or not isinstance(authority.get("roots"), list) or not authority["roots"]):
        raise ValueError("explicit weekly/authorities@1 nonempty root list required")
    ids = set()
    for source in authority["roots"]:
        if not isinstance(source, dict) or not isinstance(source.get("id"), str) or not source["id"] or source["id"] in ids:
            raise ValueError("declared root IDs must be unique and nonempty")
        ids.add(source["id"])
        if not isinstance(source.get("root"), str) or not Path(source["root"]).is_absolute():
            raise ValueError("declared root must be an explicit absolute path")
        intake.repository_name(source.get("repository"))
        if not isinstance(source.get("contexts"), list):
            raise ValueError("every root must explicitly declare its context list")
        for context in source["contexts"]:
            for key in ("path", "coordination_root", "product_root"):
                if not isinstance(context, dict) or not isinstance(context.get(key), str) or not Path(context[key]).is_absolute():
                    raise ValueError("observer path/coordination/product roots must be explicit absolute paths")
            if not isinstance(context.get("metadata_roots", []), list) or any(not isinstance(x, str) or not Path(x).is_absolute() for x in context.get("metadata_roots", [])):
                raise ValueError("observer metadata roots must be absolute paths")
    if command is None:
        command = weekly_command(process, dict(os.environ, PYTHONDONTWRITEBYTECODE="1", XYZ_WORK_CONNECTORS="0"),
                                 accepted_returncodes=(0, 2))
    observations = []
    for source in authority["roots"]:
        root = source["root"]
        item = {"id": source["id"], "declared_root": root,
                "repository": intake.repository_name(source["repository"]), "contexts": []}
        try:
            check()
            item["inventory"] = json.loads(command([sys.executable, str(harness / "utils/py/releases_app.py"),
                                                   "--root", root, "work", "inventory"], repo_root))
            check()
            for context in source["contexts"]:
                argv = ["bash", str(harness / "relay-automation/marathon.sh"), "--progress-observer", "snapshot",
                        context["path"], "--root", context["coordination_root"], "--product-root", context["product_root"]]
                for directory in context.get("metadata_roots", []):
                    argv.extend(["--metadata-root", directory])
                check()
                raw = command(argv, repo_root)
                check()
                prefix = "marathon-progress: "
                if not raw.startswith(prefix):
                    raise ValueError("unsupported observer output; no legacy fallback")
                item["contexts"].append(json.loads(raw[len(prefix):]))
        except (OSError, ValueError, RuntimeError, TypeError) as error:
            item["error"] = str(error)
        observations.append(item)
    result = intake.normalise_work_observations(observations)
    try:
        check()
    except (OSError, ValueError) as error:
        result.update(complete=False, status="UNKNOWN")
        result["holds"].append(str(error))
    result.update(runtime=runtime, authority=authority,
                  observedAt=datetime.now(timezone.utc).isoformat())
    return result


def weekly_durable(path, value, check_runtime):
    import tempfile
    check_runtime()
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".weekly-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            json.dump(value, stream, indent=2, sort_keys=True); stream.write("\n")
            stream.flush(); os.fsync(stream.fileno())
        os.replace(temporary, path)
        directory = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)

def prepare_weekly(args, source_root, command=None, carryover=None, reconciled_base=None, private_lock=None):
    """Local canonical accumulation; never selection, approval, publication or fire.

    The caller supplies a separate preparation directory. New directories are full
    clones; existing ones require this entry point's ownership record. Canonical
    RELEASES transactions retain their own locks/journal. This receipt records only
    preparation intent and owned file hashes, not a competing ledger or scheduler.
    """
    import fcntl
    import hashlib
    import importlib.util
    import math
    import tempfile

    source_root = Path(source_root).resolve()
    intake = load_issue_intake()
    harness, canonical, process, runtime, check_runtime = load_weekly_runtime(intake)
    app = harness / "utils/py/releases_app.py"
    renderer = harness / "utils/hq/hq-lib.sh"

    def require_unrated_title(issue):
        # Canonical add parses rating tokens from its rendered line, including
        # the title. Weekly never treats GitHub title text as an owner rating.
        try:
            rating = canonical.parse_rating(issue["title"], issue["title"])
        except SystemExit as error:
            raise ValueError("new issue title contains invalid canonical rating tokens; explicit reconciliation required") from error
        if any(value is not None for value in rating.values()):
            raise ValueError("new issue title contains canonical rating tokens; explicit reconciliation required")

    repository = intake.repository_name(args.gh_repo)
    date = datetime.strptime(args.planning_date, "%Y-%m-%d").date().isoformat()
    if date != args.planning_date or not math.isfinite(args.overlap_hours) or args.overlap_hours < 0:
        raise ValueError("planning date must be YYYY-MM-DD; overlap must be finite and nonnegative")
    branch = "auto-" + date
    root = Path(args.prepare_root).resolve()
    if (root.is_relative_to(source_root) or source_root.is_relative_to(root)
            or root.is_relative_to(harness) or harness.is_relative_to(root)
            or Path(args.prepare_root).is_symlink()):
        raise ValueError("preparation directory must be a separate owned full clone")

    def local_path(relative, directory=root):
        if not isinstance(relative, str) or Path(relative).is_absolute():
            raise ValueError("canonical preparation paths must be relative")
        path = directory / relative
        if (not path.resolve().is_relative_to(directory)
                or any(part.is_symlink() for part in (path, *path.parents) if part.is_relative_to(directory))):
            raise ValueError("canonical preparation path is foreign or symlinked")
        return path
    env = dict(os.environ, XYZ_WORK_CONNECTORS="0", PYTHONDONTWRITEBYTECODE="1")
    if command is None:
        command = weekly_command(process, env)

    def durable(path, value):
        return weekly_durable(path, value, check_runtime)

    def git(argv, cwd=source_root):
        check_runtime()
        return command(["git", *argv], cwd).strip()

    remote = git(["remote", "get-url", "origin"])
    match = re.fullmatch(r"(?:https://github\.com/|git@github\.com:)([\w.-]+/[\w.-]+?)(?:\.git)?", remote)
    if not match or intake.repository_name(match[1]) != repository:
        raise ValueError("origin must name the exact GitHub repository")
    git(["check-ref-format", "refs/heads/" + args.target_ref])

    def target_head(cwd):
        rows = git(["ls-remote", "origin", "refs/heads/" + args.target_ref], cwd).splitlines()
        if len(rows) != 1 or not re.fullmatch(r"[0-9a-f]{40}\trefs/heads/" + re.escape(args.target_ref), rows[0]):
            raise ValueError("canonical target HEAD unavailable or ambiguous")
        return rows[0].split("\t")[0]

    base = target_head(source_root)
    cut = datetime.now(timezone.utc).isoformat()
    relative = f"PROJECT/4-MISC/weekly/{date}/intake.json"
    observation_path = local_path(relative)
    owner = root / ".git/weekly-owner.json"
    previous = None
    starting_commit = None
    if root.exists():
        if not owner.is_file() or owner.is_symlink():
            raise ValueError("existing preparation directory is not owned; preserve it for inspection")
        ownership = json.loads(owner.read_text())
        if ownership != {"repository": repository, "branch": branch}:
            raise ValueError("preparation ownership mismatch")
        if git(["rev-parse", "--is-bare-repository"], root) != "false" or (root / ".git").is_symlink():
            raise ValueError("preparation requires a non-bare full clone")
        common = Path(git(["rev-parse", "--git-common-dir"], root))
        actual = Path(git(["rev-parse", "--git-dir"], root))
        if (root / common).resolve() != (root / actual).resolve() or not (root / ".git").is_dir():
            raise ValueError("linked worktrees are refused")
        if git(["remote", "get-url", "origin"], root) != remote or git(["branch", "--show-current"], root) != branch:
            raise ValueError("preparation origin/branch changed; preserve state")
        starting_commit = git(["rev-parse", "HEAD"], root)
        if (root / relative).is_file():
            previous = json.loads((root / relative).read_text())
            if not isinstance(previous, dict) or previous.get("complete") is not True:
                raise ValueError("prior committed observation is incomplete or malformed")
            if previous.get("planning_base") != base and not (
                    reconciled_base == (previous.get("planning_base"), base, starting_commit)):
                raise ValueError(f"target advanced: planning base {previous.get('planning_base')} current {base}; explicit reconciliation required")
    if args.intake_file or carryover is not None:
        supplied = json.loads(Path(args.intake_file).read_text()) if args.intake_file else carryover
        if (not isinstance(supplied, dict) or supplied.get("complete") is not True
                or intake.repository_name(supplied.get("repository")) != repository
                or not isinstance(supplied.get("issues"), list)):
            raise ValueError("explicit carryovers must be complete and repository-qualified")
        supplied = dict(supplied, issues=intake.deduplicate([intake.normalize_record(item, repository) for item in supplied["issues"]]))
        if previous is not None:
            supplied = dict(supplied, issues=intake.deduplicate(supplied["issues"] + previous["issues"]))
        previous = supplied
    since = datetime.fromisoformat(args.since.replace("Z", "+00:00"))
    if since.tzinfo is None:
        raise ValueError("since must include timezone")
    if previous is not None and previous.get("checkpoint_cut"):
        if not isinstance(previous["checkpoint_cut"], str):
            raise ValueError("invalid prior checkpoint cut")
        prior_cut = datetime.fromisoformat(previous["checkpoint_cut"].replace("Z", "+00:00"))
        if prior_cut.tzinfo is None:
            raise ValueError("prior checkpoint cut requires timezone")
        since = min(since, prior_cut - timedelta(hours=args.overlap_hours))
    observed = intake.discover_weekly(repository, since.isoformat(), source_root, previous, runner=command)
    if args.initial_backfill == "all-open":
        records, pages = intake.read_pages(f"repos/{repository}/issues?state=open&per_page=100", source_root, command)
        backfill = [intake.normalize_record(record, repository) for record in records if "pull_request" not in record]
        observed["issues"] = intake.deduplicate(observed["issues"] + backfill)
        observed["pages"]["initial_open"] = pages
    stable = {key: value for key, value in observed.items() if key not in ("observedAt", "since", "pages")}
    # URLs/times identify a check attempt, not a change to held accounting.
    # Retain every result/readiness/unknown field; executable freeze receipts
    # must bind fresh full check evidence separately and remain unimplemented.
    volatile_check_fields = {"detailsUrl", "url", "startedAt", "completedAt"}
    stable["prs"] = [dict(pr, statusCheckRollup=[
        {key: value for key, value in check.items() if key not in volatile_check_fields}
        for check in pr["statusCheckRollup"]]) if isinstance(pr.get("statusCheckRollup"), list)
        else dict(pr) for pr in observed["prs"]]
    stable["runtime"] = runtime
    stable["holds"] = ["Local canonical accounting only; dependency expansion, authoritative selection, criterion review, freeze and shared dispatch boundaries remain held.",
                       "Owner rank alone grants no execution authority; selection requires separately reviewed readiness and criterion evidence."]
    def inspect_members(ledger_rows, directory):
        writes = []
        for issue in observed["issues"]:
            matches = [row for row in ledger_rows if row.get("gh_number") == issue["number"] or intake.github_url_matches(row.get("issue_url"), issue["url"])]
            if len(matches) > 1 or (matches and not intake.github_url_matches(matches[0].get("issue_url"), issue["url"])):
                raise ValueError("ambiguous/foreign canonical identity during preparation")
            candidates = [path for bucket in intake.BUCKETS
                          for path in (directory / "PROJECT" / bucket).glob(f"GH-{issue['number']}-*.md")]
            if not matches:
                require_unrated_title(issue)
            if not matches and len(candidates) > 1:
                raise ValueError("ambiguous capture during preparation")
            doc = matches[0].get("doc_path") if matches else (str(candidates[0].relative_to(directory)) if candidates else None)
            if not matches and not candidates:
                created_at = issue.get("createdAt")
                if not isinstance(created_at, str):
                    raise ValueError("new canonical capture requires qualified createdAt")
                if (datetime.fromisoformat(created_at.replace("Z", "+00:00")).tzinfo is None
                        or any(char in issue["title"] for char in "\r\n\0")):
                    raise ValueError("new capture requires qualified createdAt and a single-line title")
                local_path(f"PROJECT/1-INBOX/GH-{issue['number']}-WEEKLY-CAPTURE.md", directory)
            if matches and not doc:
                raise ValueError("existing canonical row has no capture; explicit reconciliation required")
            if doc and not local_path(doc, directory).is_file():
                raise ValueError("canonical capture missing during preparation")
            writes.append({"identity": issue["identity"], "existing_row": matches[0] if matches else None,
                           "capture": doc or f"PROJECT/1-INBOX/GH-{issue['number']}-WEEKLY-CAPTURE.md",
                           "action": "preserve" if matches else ("register-only" if doc else "capture-and-register")})
        return writes

    if not args.apply:
        inspection_root = root if root.exists() else source_root
        if not root.exists() and git(["rev-parse", "HEAD"], source_root) != base:
            raise ValueError("dry preparation needs source at exact canonical target HEAD; preserve source and use a fresh full clone")
        ledger_rows = json.loads(command([sys.executable, str(app), "--root", str(inspection_root),
                                         "roadmap", "list", "--json"], inspection_root))
        if not isinstance(ledger_rows, list) or any(not isinstance(row, dict) for row in ledger_rows):
            raise ValueError("invalid canonical ledger response")
        writes = inspect_members(ledger_rows, inspection_root)
        return dict(observed, runtime=runtime, holds=stable["holds"], preparation={"root": str(root), "branch": branch, "target_head": base,
                    "effects": "apply creates/resumes full clone, canonical captures/DB/dump and local receipts; never pushes",
                    "initial_backfill": args.initial_backfill, "intended_writes": writes}, status="HELD", dispatch_allowed=False)
    if not root.exists():
        check_runtime()
        command(["git", "clone", "--no-hardlinks", "--", remote, str(root)], source_root)
        if (root / ".git").is_file() or (root / ".git").is_symlink():
            raise ValueError("clone did not produce an independent Git directory")
        if git(["rev-parse", "refs/remotes/origin/" + args.target_ref], root) != base:
            raise ValueError("target drift during clone; preserve clone and refresh")
        # Do not overwrite a previously published planning branch with a new base.
        known = git(["branch", "-r", "--list", "origin/" + branch], root)
        if known:
            raise ValueError("remote planning branch already exists; explicit preserved-branch reconciliation required")
        git(["switch", "-c", branch, base], root)
        durable(owner, {"repository": repository, "branch": branch})
    gitdir = root / ".git"
    receipt_path = gitdir / ("weekly-" + date + ".json")

    def digest(path):
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def ledger(*argv):
        check_runtime()
        return command([sys.executable, str(app), "--root", str(root), *argv], root).strip()

    def rows():
        value = json.loads(ledger("roadmap", "list", "--json"))
        if not isinstance(value, list) or any(not isinstance(row, dict) for row in value):
            raise ValueError("invalid canonical ledger response")
        return value

    def dirty_paths():
        raw = command(["git", "status", "--porcelain=v1", "-z", "--untracked-files=all"], root)
        entries = [entry for entry in raw.split("\0") if entry]
        if any(len(entry) < 4 or any(code in entry[:2] for code in "RCU") for entry in entries):
            raise ValueError("renamed/conflicting preparation paths require explicit reconciliation")
        return {entry[3:] for entry in entries}

    def exact_commit_result(intent, completed):
        return (git(["rev-parse", "HEAD"], root) == completed
                and git(["rev-list", "--parents", "-n", "1", completed], root).split()[1:] == [intent["parent"]]
                and git(["rev-parse", completed + "^{tree}"], root) == intent["tree"]
                and not dirty_paths()
                and all(git(["rev-parse", completed + ":" + path], root) == value
                        and git(["hash-object", "--", path], root) == value
                        for path, value in intent["objects"].items()))

    import contextlib
    lock_context = contextlib.nullcontext(private_lock) if private_lock is not None else (gitdir / "weekly-prepare.lock").open("a")
    with lock_context as lock:
        if private_lock is not None and (Path(lock.name).resolve() != (gitdir / "weekly-prepare.lock").resolve()
                or (os.fstat(lock.fileno()).st_dev, os.fstat(lock.fileno()).st_ino)
                != ((gitdir / "weekly-prepare.lock").stat().st_dev, (gitdir / "weekly-prepare.lock").stat().st_ino)):
            raise ValueError("inherited preparation lock identity differs")
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise RuntimeError("weekly preparation writer is active") from error
        if json.loads(owner.read_text()) != {"repository": repository, "branch": branch}:
            raise ValueError("preparation ownership changed before lock; preserve handoff state")
        if starting_commit is not None and git(["rev-parse", "HEAD"], root) != starting_commit:
            raise ValueError("preparation branch changed during discovery; refresh without overwriting it")
        if (gitdir / "releases-app-journal.json").exists():
            raise ValueError("canonical writer journal present; preserve it and recover via canonical CLI before retry")
        if git(["rev-parse", "--show-object-format"], root) != "sha1":
            raise ValueError("unsupported planning Git object format; preserve state")
        preparation_head = git(["rev-parse", "HEAD"], root)
        ledger("check")
        current_rows = rows()
        generation = int(ledger("settings", "get", "generation"))
        state = json.loads(receipt_path.read_text()) if receipt_path.is_file() else None
        if state is not None and (not isinstance(state, dict) or type(state.get("generation")) is not int
                or not isinstance(state.get("ledger_rows"), list) or not isinstance(state.get("paths"), dict)):
            raise ValueError("malformed preparation receipt; preserve it for inspection")
        if state is not None:
            if state.get("repository") != repository or state.get("branch") != branch or state.get("base") != base:
                raise ValueError("preparation receipt identity/base conflict; preserve it")
            completed = state.get("complete_commit")
            if not isinstance(state.get("checkpoint_cut"), str) or datetime.fromisoformat(state["checkpoint_cut"].replace("Z", "+00:00")).tzinfo is None:
                raise ValueError("invalid preparation checkpoint cut")
            if completed is not None and (not isinstance(completed, str) or not re.fullmatch(r"[0-9a-f]{40}", completed)):
                raise ValueError("invalid preparation commit receipt")
            if completed:
                if previous is None:
                    raise ValueError("committed observation missing; preserve receipt and reconcile explicitly")
                git(["merge-base", "--is-ancestor", completed, "HEAD"], root)
        resuming_partial = state is not None and not state.get("complete_commit")
        if resuming_partial:
            if state.get("repository") != repository or state.get("branch") != branch or state.get("base") != base or state.get("snapshot") != stable:
                raise ValueError("partial preparation drift; preserve receipt and reconcile explicitly")
            # A CLI transaction may have committed before receipt persistence
            # failed. Adopt only the exact intended addition, with every old row
            # unchanged and one canonical generation increment. Otherwise hold.
            intent = state.get("pending_add")
            additions = [row for row in current_rows if row not in state["ledger_rows"]]
            if (intent and generation == state["generation"] + 1
                    and len(additions) == 1 and len(current_rows) == len(state["ledger_rows"]) + 1
                    and all(row in current_rows for row in state["ledger_rows"])
                    and all(additions[0].get(key) == value for key, value in intent.items())
                    and all(additions[0].get(key) is None for key in ("rating_pri", "rating_sev", "rating_appeal", "rating_effort", "rating_ovr"))):
                state.update(ledger_rows=current_rows, generation=generation, pending_add=None)
                durable(receipt_path, state)
            if state["generation"] != generation or state["ledger_rows"] != current_rows:
                raise ValueError("ledger changed during partial preparation; preserve state and reconcile explicitly")
            for path, expected in state["paths"].items():
                if not isinstance(path, str) or not re.fullmatch(r"PROJECT/1-INBOX/GH-[1-9][0-9]*-WEEKLY-CAPTURE\.md", path):
                    raise ValueError("receipt names an unowned capture path")
                actual = local_path(path)
                if (not isinstance(expected, str) or not re.fullmatch(r"[0-9a-f]{64}", expected)
                        or not actual.resolve().is_relative_to(root)):
                    raise ValueError("invalid owned partial path/hash")
                if actual.exists() and (actual.is_symlink() or digest(actual) != expected):
                    raise ValueError(f"owned partial file changed: {path}")
            allowed = set(state["paths"]) | {"releases.db", "releases.sql", relative}
            if dirty_paths() - allowed:
                raise ValueError("unrelated dirty state in preparation clone")
            pending_commit = state.get("pending_commit")
            if pending_commit is not None:
                if (not isinstance(pending_commit, dict) or set(pending_commit) != {"parent", "tree", "objects"}
                        or any(not isinstance(pending_commit.get(k), str)
                               or not re.fullmatch(r"[0-9a-f]{40}", pending_commit[k]) for k in ("parent", "tree"))
                        or not isinstance(pending_commit["objects"], dict) or not pending_commit["objects"]
                        or any(not isinstance(path, str) or not isinstance(value, str)
                               or not re.fullmatch(r"[0-9a-f]{40}", value)
                               for path, value in pending_commit["objects"].items())):
                    raise ValueError("malformed pending preparation commit; preserve receipt")
                for path in pending_commit["objects"]:
                    local_path(path)
                if (preparation_head != pending_commit["parent"]
                        and not exact_commit_result(pending_commit, preparation_head)):
                    raise ValueError("unknown preparation commit result; preserve intent")
        else:
            if dirty_paths():
                raise ValueError("preparation clone has owner edits not yet committed; preserve them")
            state = {"repository": repository, "branch": branch, "base": base, "snapshot": stable,
                     "generation": generation, "ledger_rows": current_rows, "paths": {}, "complete_commit": None,
                     "checkpoint_cut": cut}
        # Validate the entire batch before the first capture/registration.
        # Per-member checks below still guard intervening owner changes.
        inspect_members(state["ledger_rows"], root)
        accounting = []
        capture_objects = {}
        for issue in observed["issues"]:
            if target_head(root) != base:
                raise ValueError("canonical target advanced during preparation; preserve partial state")
            if int(ledger("settings", "get", "generation")) != state["generation"] or rows() != state["ledger_rows"]:
                raise ValueError("concurrent ledger change; preserve owner state")
            matches = [row for row in state["ledger_rows"] if row.get("gh_number") == issue["number"] or intake.github_url_matches(row.get("issue_url"), issue["url"])]
            if len(matches) > 1 or (matches and not intake.github_url_matches(matches[0].get("issue_url"), issue["url"])):
                raise ValueError(f"ambiguous/foreign canonical identity: {issue['identity']}")
            if matches:
                doc = matches[0].get("doc_path")
                if not doc:
                    raise ValueError("existing canonical row has no capture; explicit reconciliation required")
            else:
                require_unrated_title(issue)
                candidates = [path for bucket in intake.BUCKETS
                              for path in (root / "PROJECT" / bucket).glob(f"GH-{issue['number']}-*.md")]
                if len(candidates) > 1:
                    raise ValueError("multiple capture candidates; preserve owner docs and reconcile explicitly")
                doc = str(candidates[0].relative_to(root)) if candidates else None
            if doc:
                path = local_path(doc)
                if path.is_symlink() or not path.is_file() or not path.resolve().is_relative_to(root):
                    raise ValueError(f"canonical capture unavailable or foreign: {doc}")
            else:
                doc = f"PROJECT/1-INBOX/GH-{issue['number']}-WEEKLY-CAPTURE.md"
                path = local_path(doc)
                if path.is_symlink() or not path.resolve().is_relative_to(root):
                    raise ValueError("capture path escapes preparation clone")
                if not isinstance(issue.get("createdAt"), str):
                    raise ValueError("new canonical capture requires qualified createdAt")
                created_at = datetime.fromisoformat(issue["createdAt"].replace("Z", "+00:00"))
                if created_at.tzinfo is None or any(char in issue["title"] for char in "\r\n\0"):
                    raise ValueError("new capture requires qualified createdAt and a single-line title")
                created = created_at.date().isoformat()
                check_runtime()
                content = command(["bash", "-c", 'source "$1"; shift; hq_render_capture "$@"', "weekly-capture",
                                   str(renderer), str(issue["number"]), issue["url"], issue["title"], created,
                                   "feedback", repository, repository, issue["body"]], root)
                expected = hashlib.sha256(content.encode()).hexdigest()
                state["paths"][doc] = expected
                durable(receipt_path, state)  # intent before exclusive capture creation
                path.parent.mkdir(parents=True, exist_ok=True)
                with path.open("x") as stream:
                    stream.write(content)
            capture_bytes = path.read_bytes()
            before_hash = hashlib.sha256(capture_bytes).hexdigest()
            if doc in state["paths"] and state["paths"][doc] != before_hash:
                raise ValueError("owned creation intent differs from capture; preserve owner edit")
            # Bind Git's blob to the SAME immutable bytes as declared SHA-256
            # evidence; sampling the live path after observation persistence
            # would incorrectly certify an intervening owner edit.
            capture_objects[doc] = hashlib.sha1(
                f"blob {len(capture_bytes)}\0".encode() + capture_bytes,
                usedforsecurity=False).hexdigest()
            if not matches:
                state["pending_add"] = {"gh_number": issue["number"], "issue_url": issue["url"],
                                        "title": issue["title"], "doc_path": doc,
                                        "section": "Queue / parked intake", "status_marker": "🆕"}
                durable(receipt_path, state)
                ledger("roadmap", "add", "--issue-num", str(issue["number"]), "--issue-url", issue["url"],
                       "--title", issue["title"], "--created", date, "--doc-path", doc)
                updated = rows()
                new = [row for row in updated if row.get("issue_url") == issue["url"]]
                if (len(new) != 1 or any(new[0].get(key) is not None for key in canonical.RATING_COLUMNS)):
                    raise ValueError("registration produced assessed ratings; preserve result and reconcile explicitly")
                if len(new) != 1 or any(row not in updated for row in state["ledger_rows"]) or len(updated) != len(state["ledger_rows"]) + 1:
                    raise ValueError("unexpected concurrent registration; preserve canonical result")
                after_generation = int(ledger("settings", "get", "generation"))
                if after_generation != state["generation"] + 1:
                    raise ValueError("unexpected writer generation; preserve canonical result")
                state.update(ledger_rows=updated, generation=after_generation, pending_add=None)
                durable(receipt_path, state)
                matches = new
            if digest(path) != before_hash:
                raise ValueError("capture changed during registration; preserve owner edits")
            accounting.append({"identity": issue["identity"], "global_id": matches[0]["global_id"],
                               "doc_path": doc, "doc_sha256": before_hash, "ledger": matches[0],
                               "decision": "HELD", "reason": "criterion delivery/readiness not reviewed"})
        payload = dict(stable, planning_base=base, planning_branch=branch, accounting=accounting,
                       initial_backfill=args.initial_backfill, overlap_hours=args.overlap_hours)
        try:
            with canonical.WriterLock(str(root)) as writer:
                if Path(writer.journal_path).exists():
                    raise ValueError("canonical writer journal appeared before commit; preserve state")
                if (git(["branch", "--show-current"], root) != branch
                        or git(["rev-parse", "HEAD"], root) != preparation_head):
                    raise ValueError("preparation branch/HEAD changed before commit; preserve state")
                if target_head(root) != base or rows() != state["ledger_rows"] or int(ledger("settings", "get", "generation")) != state["generation"]:
                    raise ValueError("target/ledger drift before commit; preserve partial state")
                old = json.loads((root / relative).read_text()) if (root / relative).is_file() else None
                old_stable = {key: value for key, value in old.items() if key != "checkpoint_cut"} if old else None
                if old_stable == payload and not dirty_paths():
                    completed = git(["rev-parse", "HEAD"], root)
                    if resuming_partial:
                        pending_commit = state.get("pending_commit")
                        expected_paths = {relative, "releases.db", "releases.sql", *[item["doc_path"] for item in accounting]}
                        if (not pending_commit or set(pending_commit["objects"]) != expected_paths
                                or not exact_commit_result(pending_commit, completed)):
                            raise ValueError("unbound partial no-change result; preserve incomplete checkpoint")
                    state["complete_commit"] = completed
                    state["checkpoint_cut"] = old["checkpoint_cut"]
                    if resuming_partial:
                        durable(receipt_path, state)
                    return dict(old, prs=observed["prs"], observedAt=observed["observedAt"],
                                changed=False, planning_commit=state["complete_commit"])
                if target_head(root) != base or rows() != state["ledger_rows"] or int(ledger("settings", "get", "generation")) != state["generation"]:
                    raise ValueError("target/ledger drift before commit; preserve partial state")
                if any((root / item["doc_path"]).is_symlink() or digest(root / item["doc_path"]) != item["doc_sha256"] for item in accounting):
                    raise ValueError("owner capture changed before commit; preserve edits")
                payload["checkpoint_cut"] = state["checkpoint_cut"]
                durable(receipt_path, state)
                durable(root / relative, payload)
                allowed = set(state["paths"]) | {"releases.db", "releases.sql", relative}
                if dirty_paths() - allowed:
                    raise ValueError("unrelated changes before commit; preserve state")
                owned = {relative, "releases.db", "releases.sql", *[item["doc_path"] for item in accounting]}
                expected_objects = {path: git(["hash-object", "--", path], root) for path in owned}
                expected_objects.update(capture_objects)
                git(["add", "--", relative, "releases.db", "releases.sql", *sorted(state["paths"])], root)
                if any(git(["rev-parse", ":" + path], root) != value for path, value in expected_objects.items()):
                    raise ValueError("staged canonical accounting differs; preserve partial state")
                intended_tree = git(["write-tree"], root)
                changed_paths = set(git(["diff-tree", "--no-commit-id", "--name-only", "-r",
                                         preparation_head + "^{tree}", intended_tree], root).splitlines())
                if (changed_paths - allowed
                        or any(git(["rev-parse", intended_tree + ":" + path], root) != value
                               for path, value in expected_objects.items())):
                    raise ValueError("unaccounted intended preparation tree; preserve partial state")
                intended_commit = {"parent": preparation_head, "tree": intended_tree, "objects": expected_objects}
                if state.get("pending_commit") is not None and state["pending_commit"] != intended_commit:
                    raise ValueError("pending preparation commit changed; preserve intent")
                state["pending_commit"] = intended_commit
                durable(receipt_path, state)
                if target_head(root) != base or git(["rev-parse", "HEAD"], root) != preparation_head:
                    raise ValueError("target/HEAD drift immediately before commit; preserve partial state")
                git(["commit", "-m", f"weekly: accumulate {repository} intake for {date}"], root)
                completed = git(["rev-parse", "HEAD"], root)
                if (git(["branch", "--show-current"], root) != branch
                        or not exact_commit_result(intended_commit, completed)
                        or target_head(root) != base
                        or rows() != state["ledger_rows"]
                        or int(ledger("settings", "get", "generation")) != state["generation"]
                        or any(git(["rev-parse", "HEAD:" + path], root) != value
                               or git(["hash-object", "--", path], root) != value
                               for path, value in expected_objects.items())):
                    raise ValueError("committed accounting/branch drift; preserve commit without complete checkpoint")
                state["complete_commit"] = completed
                durable(receipt_path, state)  # checkpoint becomes complete only after commit
                return dict(payload, prs=observed["prs"], observedAt=observed["observedAt"],
                            changed=True, planning_commit=state["complete_commit"])
        except SystemExit as error:
            raise ValueError("canonical writer refused commit boundary; preserve partial state") from error

def reconcile_weekly(args, source_root, command=None):
    """Preserve one exact predecessor into a new held projection; no execution authority."""
    import base64
    import fcntl
    import hashlib
    import math

    source_root = Path(source_root).resolve()
    intake = load_issue_intake()
    harness, canonical, process, runtime, check = load_weekly_runtime(intake, {
        'lock_resolver': Path(intake.__file__).resolve().parents[4] / 'utils/py/rtl.py',
        'hook_installer': Path(intake.__file__).resolve().parents[4] / 'githooks/install.sh'})
    env = dict(os.environ, XYZ_WORK_CONNECTORS='0', PYTHONDONTWRITEBYTECODE='1')
    supplied_command = command
    command = command or weekly_command(process, env)
    owner_command = supplied_command or weekly_command(process, env, (0, 2))
    repository = intake.repository_name(args.gh_repo)
    old = Path(args.predecessor_root).resolve()
    root = Path(args.prepare_root).resolve()
    date = datetime.strptime(args.planning_date, '%Y-%m-%d').date().isoformat()
    if date != args.planning_date or not math.isfinite(args.overlap_hours) or args.overlap_hours < 0:
        raise ValueError('explicit valid date/overlap required')
    if (not Path(args.predecessor_root).is_absolute() or not Path(args.prepare_root).is_absolute()
            or not re.fullmatch(r'[0-9a-f]{40}', args.expected_predecessor_head or '')
            or old == source_root or any(a.is_relative_to(b) or b.is_relative_to(a)
                                        for a, b in ((old, root), (root, source_root), (root, harness), (old, harness)))
            or Path(args.predecessor_root).is_symlink() or Path(args.prepare_root).is_symlink()):
        raise ValueError('exact separate predecessor/new full-clone roots required')
    branch = 'auto-' + date
    if args.publish and os.environ.get('XYZ_SKIP_PREPUSH', '0') not in ('', '0'):
        raise ValueError('normal-hook bypass is incompatible with held publication')
    if args.publish and (args.publication_timeout is None or not math.isfinite(args.publication_timeout)
                         or args.publication_timeout <= 0 or not args.apply):
        raise ValueError('publication requires explicit apply and finite normal-hook IO budget')
    def git(argv, directory=source_root):
        check()
        value = command(['git', *argv], directory)
        check()
        return value.strip()
    def full_clone(directory):
        if (not (directory / '.git').is_dir() or (directory / '.git').is_symlink()
                or git(['rev-parse', '--show-toplevel'], directory) != str(directory)
                or git(['rev-parse', '--is-shallow-repository'], directory) != 'false'):
            raise ValueError('independent complete clone required')
    def local(directory, relative):
        path = directory / relative
        if (not isinstance(relative, str) or Path(relative).is_absolute()
                or not path.resolve().is_relative_to(directory)
                or any(p.is_symlink() for p in (path, *path.parents) if p.is_relative_to(directory))):
            raise ValueError('foreign/symlinked reconciliation path')
        return path
    def dirty(directory):
        text = command(['git', 'status', '--porcelain=v1', '-z', '--untracked-files=all'], directory)
        parts = [p for p in text.split('\0') if p]
        if any(len(p) < 4 or any(x in p[:2] for x in 'RCU') for p in parts):
            raise ValueError('renamed/conflicting state requires disposition')
        return {p[3:] for p in parts}
    def durable(path, value):
        weekly_durable(path, value, check)
    def owner(directory, *argv):
        check()
        output = owner_command([sys.executable, str(harness / 'utils/py/releases_app.py'),
                                '--root', str(directory), *argv], directory)
        check()
        return output.strip()
    full_clone(old)
    old_branch = git(['branch', '--show-current'], old)
    if not re.fullmatch(r'auto-\d{4}-\d{2}-\d{2}', old_branch):
        raise ValueError('predecessor must be an explicit auto-date branch')
    old_date = old_branch[5:]
    datetime.strptime(old_date, '%Y-%m-%d')
    old_relative = f'PROJECT/4-MISC/weekly/{old_date}/intake.json'
    old_intake_path = local(old, old_relative)
    old_intake = json.loads(old_intake_path.read_text())
    if (not isinstance(old_intake, dict) or old_intake.get('complete') is not True or old_intake.get('planning_branch') != old_branch
            or intake.repository_name(old_intake.get('repository')) != repository
            or not re.fullmatch(r'[0-9a-f]{40}', old_intake.get('planning_base', ''))):
        raise ValueError('complete exact committed predecessor intake required')
    old_head = args.expected_predecessor_head
    if git(['rev-parse', 'HEAD'], old) != old_head or dirty(old):
        raise ValueError('predecessor HEAD/owner edits changed')
    remote = git(['remote', 'get-url', 'origin'])
    if git(['remote', 'get-url', 'origin'], old) != remote:
        raise ValueError('predecessor origin differs')
    match = re.fullmatch(r'(?:https://github\.com/|git@github\.com:)([\w.-]+/[\w.-]+?)(?:\.git)?', remote)
    if not match or intake.repository_name(match[1]) != repository:
        raise ValueError('exact GitHub origin required')
    git(['check-ref-format', 'refs/heads/' + args.target_ref])
    def fresh_target():
        rows = git(['ls-remote', 'origin', 'refs/heads/' + args.target_ref]).splitlines()
        if len(rows) != 1 or not re.fullmatch(r'[0-9a-f]{40}\trefs/heads/' + re.escape(args.target_ref), rows[0]):
            raise ValueError('fresh canonical target unavailable')
        return rows[0].split('\t')[0]
    target = fresh_target()
    owner_path = old / '.git/weekly-owner.json'
    receipt_path = old / ('.git/weekly-' + old_date + '.json')
    ownership = json.loads(owner_path.read_text()) if owner_path.is_file() else None
    receipt = json.loads(receipt_path.read_text()) if receipt_path.is_file() else None
    if ((ownership is not None and not isinstance(ownership, dict))
            or (receipt is not None and not isinstance(receipt, dict))
            or owner_path.is_symlink() or receipt_path.is_symlink()):
        raise ValueError('malformed/symlinked predecessor private evidence')
    spec = {'repository': repository, 'source_root': str(old), 'source_head': old_head,
            'source_branch': old_branch, 'root': str(root), 'branch': branch, 'target': target,
            'target_ref': args.target_ref, 'runtime': runtime}
    if receipt and receipt.get('schema') == 'weekly/handoff@1':
        if receipt.get('operation') != spec:
            raise ValueError('handoff inputs drifted; preserve both roots')
        original_owner = receipt.get('original_owner')
        original_receipt = receipt['original']
        if ownership and ownership.get('schema') == 'weekly/handoff@1':
            if ownership.get('operation') != spec or ownership.get('original') != original_owner:
                raise ValueError('handoff ownership pair differs')
        elif (ownership != original_owner
              or (base64.b64encode(owner_path.read_bytes()).decode() if owner_path.is_file() else None)
              != receipt.get('original_owner_bytes')):
            raise ValueError('partial ownership bytes changed; preserve evidence')
    else:
        original_owner, original_receipt = ownership, receipt
        if ownership != {'repository': repository, 'branch': old_branch}:
            if not args.adopt_predecessor or ownership is not None or receipt is not None:
                raise ValueError('unknown predecessor ownership; explicit exact published adoption required')
            published = git(['ls-remote', 'origin', 'refs/heads/' + old_branch])
            if published != old_head + '\trefs/heads/' + old_branch:
                raise ValueError('adoption commit differs from fresh published head')
            original_owner = {'repository': repository, 'branch': old_branch}
            original_receipt = {'repository': repository, 'branch': old_branch,
                                'base': old_intake['planning_base'], 'complete_commit': old_head,
                                'checkpoint_cut': old_intake.get('checkpoint_cut'), 'adopted': True}
        if (not isinstance(original_receipt, dict) or original_receipt.get('complete_commit') != old_head
                or original_receipt.get('base') != old_intake['planning_base']):
            raise ValueError('partial/stale predecessor receipt; no blind adoption')
    if (not isinstance(old_intake.get('issues'), list) or not isinstance(old_intake.get('accounting'), list)
            or not isinstance(old_intake.get('checkpoint_cut'), str)
            or datetime.fromisoformat(old_intake['checkpoint_cut'].replace('Z', '+00:00')).tzinfo is None):
        raise ValueError('predecessor accounting/checkpoint shape incomplete')
    members = intake.deduplicate([intake.normalize_record(item, repository) for item in old_intake['issues']])
    accounts = old_intake['accounting']
    if (len(accounts) != len(members) or any(not isinstance(a, dict) for a in accounts)
            or {a.get('identity') for a in accounts} != {m['identity'] for m in members}):
        raise ValueError('every predecessor member must have unique canonical accounting')
    source_rows = json.loads(owner(old, 'roadmap', 'list', '--json'))
    source_generation = int(owner(old, 'settings', 'get', 'generation'))
    if not isinstance(source_rows, list) or any(not isinstance(row, dict) for row in source_rows):
        raise ValueError('canonical predecessor rows unavailable')
    if not original_receipt.get('adopted') and (
            original_receipt.get('ledger_rows') != source_rows
            or original_receipt.get('generation') != source_generation):
        raise ValueError('predecessor owner changed since complete receipt')
    for account in accounts:
        row = next((r for r in source_rows if r['global_id'] == account.get('global_id')), None)
        if row is None or account.get('ledger') != row or account.get('doc_path') != row.get('doc_path'):
            raise ValueError('predecessor canonical accounting/GID drift')
        path = local(old, account['doc_path'])
        if (not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != account.get('doc_sha256')
                or command(['git', 'show', old_head + ':' + account['doc_path']], old).encode() != path.read_bytes()):
            raise ValueError('predecessor capture changed or is not committed')
    if git(['show', old_head + ':' + old_relative], old) != old_intake_path.read_text().strip():
        raise ValueError('predecessor observation differs from committed object')
    census = observe_weekly_work(args.authority_file, source_root)
    response = {'schema': 'weekly/reconciliation@1', 'complete': False, 'status': 'UNKNOWN',
                'dispatch_allowed': False, 'operation': spec, 'work': census, 'holds': list(census['holds'])}
    declared = {str(Path(s['declared_root']).resolve()): s for s in census['observations']}
    if str(old) not in declared:
        raise ValueError('predecessor must be included in declared authorities')
    source_inventory = declared[str(old)].get('inventory', {})
    if (not census['complete'] or source_inventory.get('driver_lock', {}).get('present')
            or any(r.get('lease_pid') is not None for r in source_inventory.get('rows', []))):
        response['holds'].append('Incomplete work/active predecessor ownership; preserve source')
        return response
    response.update(status='HELD', complete=True, effects='preview: Git/owner/declared-work reads only; apply: new full clone, existing owner/receipt handoff, canonical ledger/capture/Git commits; no execution')
    if not args.apply:
        return response
    if root.exists() and (not receipt or receipt.get('schema') != 'weekly/handoff@1'):
        raise ValueError('destination already exists without this handoff intent; preserve it')
    with (old / '.git/weekly-prepare.lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise ValueError('predecessor writer active') from error
        if git(['rev-parse', 'HEAD'], old) != old_head or dirty(old) or fresh_target() != target:
            raise ValueError('source/target changed before handoff')
        latest_owner = json.loads(owner_path.read_text()) if owner_path.is_file() else None
        latest_receipt = json.loads(receipt_path.read_text()) if receipt_path.is_file() else None
        if latest_owner != ownership or latest_receipt != receipt:
            raise ValueError('predecessor private ownership changed before lock')
        if not receipt or receipt.get('schema') != 'weekly/handoff@1':
            state = {'schema': 'weekly/handoff@1', 'operation': spec, 'original': original_receipt,
                     'original_bytes': base64.b64encode(receipt_path.read_bytes()).decode() if receipt_path.is_file() else None,
                     'original_owner': original_owner,
                     'original_owner_bytes': base64.b64encode(owner_path.read_bytes()).decode() if owner_path.is_file() else None,
                     'phase': 'intent', 'root_head': target, 'complete_commit': None}
            # Receipt is inspected again after even an older writer's lock, so
            # this envelope also stops a writer with cached pre-lock ownership.
            durable(receipt_path, state)
        else:
            state = receipt
        if not ownership or ownership.get('schema') != 'weekly/handoff@1':
            durable(owner_path, {'schema': 'weekly/handoff@1', 'operation': spec,
                                 'original': original_owner, 'original_bytes': state['original_owner_bytes']})
        was_complete = state.get('phase') == 'complete'
        def guard():
            check()
            if git(['rev-parse', 'HEAD'], old) != old_head or dirty(old) or fresh_target() != target:
                raise ValueError('source/target drift; preserve handoff evidence')
            expected_owner = {'schema': 'weekly/handoff@1', 'operation': spec,
                              'original': original_owner, 'original_bytes': state['original_owner_bytes']}
            if json.loads(owner_path.read_text()) != expected_owner or json.loads(receipt_path.read_text()) != state:
                raise ValueError('predecessor ownership/intent drift; preserve evidence')
        if not root.exists():
            guard(); root.mkdir()
            st = root.stat()
            state.update(root_identity=[st.st_dev, st.st_ino], phase='bootstrap')
            durable(receipt_path, state)
        st = root.stat()
        if state.get('root_identity') != [st.st_dev, st.st_ino]:
            raise ValueError('destination directory identity unknown; preserve partial state')
        if state['phase'] == 'bootstrap':
            if not (root / '.git').exists():
                if any(root.iterdir()):
                    raise ValueError('unknown partial clone contents')
                guard(); command(['git', 'clone', '--no-hardlinks', '--', remote, str(root)], source_root)
            full_clone(root)
            if (git(['remote', 'get-url', 'origin'], root) != remote
                    or git(['rev-parse', 'refs/remotes/origin/' + args.target_ref], root) != target
                    or dirty(root)):
                raise ValueError('clone identity/target/owner state changed')
            known = git(['branch', '-r', '--list', 'origin/' + branch], root)
            if known and (branch != old_branch or git(['rev-parse', 'origin/' + branch], root) != old_head):
                raise ValueError('unowned published destination branch')
            current_branch = git(['branch', '--show-current'], root)
            if current_branch != branch:
                if git(['rev-parse', 'HEAD'], root) not in (target, git(['rev-parse', 'refs/remotes/origin/HEAD'], root)):
                    raise ValueError('bootstrap checkout changed')
                git(['switch', '-c', branch, target], root)
            elif git(['rev-parse', 'HEAD'], root) != target:
                raise ValueError('bootstrap branch changed')
            destination_owner = root / '.git/weekly-owner.json'
            expected_owner = {'schema': 'weekly/destination@1', 'operation': spec,
                              'original': {'repository': repository, 'branch': branch}}
            if destination_owner.exists():
                if destination_owner.is_symlink() or json.loads(destination_owner.read_text()) != expected_owner:
                    raise ValueError('bootstrap ownership changed')
            else:
                durable(destination_owner, expected_owner)
            state.update(phase='intent', root_head=target); durable(receipt_path, state)
        full_clone(root)
        destination_owner_value = json.loads((root / '.git/weekly-owner.json').read_text())
        standard_owner = {'repository': repository, 'branch': branch}
        pending_owner = {'schema': 'weekly/destination@1', 'operation': spec, 'original': standard_owner}
        allowed_owners = [pending_owner] + ([standard_owner] if state['phase'] in ('prepare', 'complete') else [])
        if (destination_owner_value not in allowed_owners
                or git(['branch', '--show-current'], root) != branch
                or git(['remote', 'get-url', 'origin'], root) != remote):
            raise ValueError('destination ownership changed')
        destination_lock = (root / '.git/weekly-prepare.lock').open('a')
        try:
            try:
                fcntl.flock(destination_lock.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError as error:
                raise ValueError('destination preparation writer is active') from error
            git(['fetch', '--no-tags', '--', str(old), old_head], root)
            common = git(['merge-base', '--all', target, old_head], root)
            if common != old_intake['planning_base']:
                raise ValueError('unique recorded canonical common base required')
            incoming_paths = git(['diff', '--name-only', common, old_head], root).splitlines()
            allowed_capture = re.compile(r'PROJECT/1-INBOX/GH-[1-9][0-9]*-WEEKLY-CAPTURE\.md')
            if any(p not in ('releases.db', 'releases.sql', old_relative) and not allowed_capture.fullmatch(p) for p in incoming_paths):
                raise ValueError('incoming non-owned work requires review/landing; preserve it')
            def commit(paths, message):
                guard()
                previous = state['root_head']
                pending = state.get('pending_commit')
                if pending:
                    current = git(['rev-parse', 'HEAD'], root)
                    if current != previous:
                        if (not state.get('pending_tree')
                                or git(['rev-parse', 'HEAD^{tree}'], root) != state['pending_tree']
                                or git(['rev-list', '--parents', '-n', '1', 'HEAD'], root).split()[1:] != [previous]
                                or any(git(['rev-parse', 'HEAD:' + p], root) != h
                                       or git(['hash-object', '--', p], root) != h for p, h in pending.items())
                                or dirty(root)):
                            raise ValueError('unknown committed handoff state')
                        state.update(root_head=current, pending_commit=None, pending_tree=None); durable(receipt_path, state); return
                    if any(git(['hash-object', '--', p], root) != h for p, h in pending.items()):
                        raise ValueError('pending preservation bytes changed; retain evidence')
                elif git(['rev-parse', 'HEAD'], root) != previous:
                    raise ValueError('destination HEAD changed')
                if not dirty(root):
                    return
                if dirty(root) - set(paths):
                    raise ValueError('unrelated destination owner edits')
                blobs = {p: git(['hash-object', '--', p], root) for p in paths}
                state['pending_commit'] = blobs; durable(receipt_path, state)
                git(['add', '--', *paths], root)
                if any(git(['rev-parse', ':' + p], root) != h for p, h in blobs.items()):
                    raise ValueError('staged preservation differs')
                staged_paths = set(git(['diff', '--cached', '--name-only'], root).splitlines())
                if staged_paths - set(paths):
                    raise ValueError('unaccounted staged preservation paths; retain intent')
                state['pending_tree'] = git(['write-tree'], root); durable(receipt_path, state)
                guard(); git(['commit', '-m', message], root)
                if (git(['rev-list', '--parents', '-n', '1', 'HEAD'], root).split()[1:] != [previous]
                        or git(['rev-parse', 'HEAD^{tree}'], root) != state['pending_tree']
                        or dirty(root)):
                    raise ValueError('committed preservation result differs; retain intent')
                state.update(root_head=git(['rev-parse', 'HEAD'], root), pending_commit=None, pending_tree=None); durable(receipt_path, state)
            if state.get('pending_commit'):
                commit(list(state['pending_commit']), 'weekly: complete exact pending preservation')
            if state['phase'] in ('intent', 'ledger'):
                guard()
                reply = json.loads(owner(root, 'check', '--merge-base', common, '--merge-target', old_head,
                                          '--expected-head', state['root_head'], '--expected-branch', branch,
                                          '--merge-delta-parent', 'target', '--apply'))
                response['ledger'] = reply
                if reply.get('complete') is not True:
                    response.update(complete=False, status='UNKNOWN'); return response
                commit(['releases.db', 'releases.sql'], 'weekly: preserve canonical parent ledger')
                state['phase'] = 'captures'; durable(receipt_path, state)
            if state['phase'] == 'captures':
                guard(); copied = []
                for relative in incoming_paths:
                    if not allowed_capture.fullmatch(relative):
                        continue
                    path = local(root, relative)
                    incoming = command(['git', 'show', old_head + ':' + relative], root).encode()
                    # Existing canonical content may differ only when the old branch
                    # changed the same existing capture: that needs owner disposition.
                    if path.exists() and path.read_bytes() != incoming:
                        raise ValueError('canonical/predecessor capture conflict: ' + relative)
                    if not path.exists():
                        path.parent.mkdir(parents=True, exist_ok=True)
                        with path.open('xb') as stream:
                            stream.write(incoming); stream.flush(); os.fsync(stream.fileno())
                    copied.append(relative)
                commit(copied, 'weekly: preserve predecessor captures')
                state['phase'] = 'ancestry'; durable(receipt_path, state)
            pending_merge = state.get('pending_merge')
            if pending_merge and git(['rev-parse', 'HEAD'], root) != pending_merge['head']:
                parents = git(['rev-list', '--parents', '-n', '1', 'HEAD'], root).split()[1:]
                if (parents != [pending_merge['head'], old_head]
                        or git(['rev-parse', 'HEAD^{tree}'], root) != pending_merge['tree'] or dirty(root)):
                    raise ValueError('unknown native ancestry result; preserve evidence')
                state.update(root_head=git(['rev-parse', 'HEAD'], root), phase='prepare', pending_merge=None)
                durable(receipt_path, state)
            if state['phase'] == 'ancestry':
                guard()
                # Ledger/capture changes have been accounted for. Keep the original
                # intake as an immutable source artifact, including same-date rollover.
                archive = f'PROJECT/4-MISC/weekly/{date}/sources/{old_head}/intake.json'
                archive_path = local(root, archive)
                source_bytes = old_intake_path.read_bytes()
                if archive_path.exists() and archive_path.read_bytes() != source_bytes:
                    raise ValueError('source intake archive owner conflict')
                if not archive_path.exists():
                    archive_path.parent.mkdir(parents=True, exist_ok=True)
                    with archive_path.open('xb') as stream:
                        stream.write(source_bytes); stream.flush(); os.fsync(stream.fileno())
                commit([archive], 'weekly: retain exact predecessor intake')
                merge_head = root / '.git/MERGE_HEAD'
                if merge_head.exists() and merge_head.read_text().strip() != old_head:
                    raise ValueError('foreign native merge in progress')
                if not merge_head.exists():
                    result = process.run_bounded(['git', 'merge-base', '--is-ancestor', old_head, 'HEAD'],
                                                 cwd=str(root), env=env, timeout=WEEKLY_IO_TIMEOUT_SECONDS, grace=1)
                    if result.rc == 1:
                        state['pending_merge'] = {'head': state['root_head'], 'tree': git(['rev-parse', 'HEAD^{tree}'], root)}
                        durable(receipt_path, state)
                        git(['merge', '--no-ff', '--no-commit', '-s', 'ours', old_head], root)
                    elif result.rc != 0 or result.timed_out:
                        raise ValueError('ancestry unavailable')
                if merge_head.exists():
                    if (not state.get('pending_merge') or dirty(root)
                            or git(['rev-parse', 'HEAD^{tree}'], root) != state['pending_merge']['tree']):
                        raise ValueError('native merge state/owner content unknown')
                    guard(); git(['commit', '-m', 'weekly: retain fully preserved predecessor ancestry'], root)
                    # GH-1031: admit the commit Git actually produced, not the one we intended. Same check
                    # as the interrupted-recovery path above; a hook-staged file or an extra parent refuses
                    # here and leaves pending_merge set so recovery owns it.
                    parents = git(['rev-list', '--parents', '-n', '1', 'HEAD'], root).split()[1:]
                    if (parents != [state['pending_merge']['head'], old_head]
                            or git(['rev-parse', 'HEAD^{tree}'], root) != state['pending_merge']['tree'] or dirty(root)):
                        raise ValueError('unknown native ancestry result; preserve evidence')
                state.update(root_head=git(['rev-parse', 'HEAD'], root), phase='prepare', pending_merge=None); durable(receipt_path, state)
            if state['phase'] in ('prepare', 'complete'):
                guard()
                if state['phase'] == 'complete' and (git(['rev-parse', 'HEAD'], root) != state['complete_commit'] or dirty(root)):
                    raise ValueError('active destination changed outside this operation; use its ordinary preparation owner')
                if json.loads((root / '.git/weekly-owner.json').read_text()) == pending_owner:
                    durable(root / '.git/weekly-owner.json', standard_owner)
                prepared = prepare_weekly(args, source_root, command=supplied_command,
                                          carryover=old_intake, reconciled_base=(old_intake['planning_base'], target, state['root_head']),
                                          private_lock=destination_lock)
                response['preparation'] = prepared
                state.update(phase='complete', root_head=prepared['planning_commit'], complete_commit=prepared['planning_commit'])
                if not was_complete or prepared.get('changed'):
                    durable(receipt_path, state)
            guard()
            if state.get('complete_commit') != git(['rev-parse', 'HEAD'], root) or dirty(root):
                raise ValueError('completed destination drift; preserve evidence')
            response.update(changed=not was_complete or bool(response.get('preparation', {}).get('changed')),
                            planning_commit=state['complete_commit'], preparation_root=str(root))
            response['accounting'] = []
            # Qualified explicit PR links are review leads, never completion proof.
            prepared_observation = response.get('preparation') or json.loads(
                (root / f'PROJECT/4-MISC/weekly/{date}/intake.json').read_text())
            for member in prepared_observation.get('accounting', []):
                identity = member['identity']
                number = member['ledger']['gh_number']
                facts = [fact for fact in census['facts'] if fact['fact'].get('repository') == repository
                         and fact['fact'].get('gh_number') == number]
                leads = []
                for pr in prepared_observation.get('prs', []):
                    body = pr.get('body') or ''
                    qualified = re.search(r'https://github\.com/' + re.escape(repository) +
                                          r'/issues/' + str(number) + r'(?![0-9])', body, re.I)
                    scoped = re.search(r'(?i)\b(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\s+#' +
                                       str(number) + r'(?![0-9])', body)
                    if qualified or scoped:
                        leads.append({'identity': pr['identity'], 'source': 'explicit-qualified-link' if qualified
                                      else 'repository-scoped-closing-reference', 'isDraft': pr.get('isDraft'),
                                      'head': pr.get('headRefOid'), 'meaning': 'review/landing lead; overlap/delivery unreviewed'})
                response['accounting'].append({'identity': identity, 'global_id': member['global_id'],
                                              'decision': 'REVIEW_OR_LANDING' if leads else 'HELD',
                                              'existing_work': facts, 'pr_leads': leads,
                                              'reported_ledger_state': canonical._live_roadmap_event(
                                                  member['ledger'].get('section'), member['ledger'].get('status_marker'),
                                                  member['ledger'].get('rating_rank') is not None),
                                              'delivery': 'UNKNOWN; reported completion is not criterion evidence',
                                              'reason': 'criterion delivery, active overlap and readiness require independent review'})
            if args.publish:
                if (args.publication_timeout is None or not math.isfinite(args.publication_timeout)
                        or args.publication_timeout <= 0):
                    raise ValueError('publication requires an explicit finite normal-hook IO budget')
                guard()
                hook_installer = harness / 'githooks/install.sh'
                def installed_hook():
                    check()
                    result = process.run_bounded(['bash', str(hook_installer), '--check'],
                                                 cwd=str(root), env=env, timeout=WEEKLY_IO_TIMEOUT_SECONDS, grace=1)
                    check()
                    if result.timed_out or result.rc not in (0, 1):
                        raise ValueError('existing hook check unavailable; preserve local projection')
                    return result.rc == 0
                if not installed_hook():
                    command(['bash', str(hook_installer)], root)
                    if not installed_hook():
                        raise ValueError('normal hook is not installed; publication held')
                response['hook_workflow'] = {'installer': str(hook_installer),
                                             'sha256': runtime['sha256']['hook_installer'], 'checked': True,
                                             'effects': 'existing installer may wire owned-clone hook metadata; no new gate'}
                remote_rows = git(['ls-remote', 'origin', 'refs/heads/' + branch], root).splitlines()
                remote_head = None
                if remote_rows:
                    if len(remote_rows) != 1 or not re.fullmatch(r'[0-9a-f]{40}\trefs/heads/' + re.escape(branch), remote_rows[0]):
                        raise ValueError('published destination identity unknown')
                    remote_head = remote_rows[0].split('\t')[0]
                    if remote_head not in (old_head, state['complete_commit']):
                        raise ValueError('published branch has another owner; preserve all revisions')
                if remote_head != state['complete_commit']:
                    publish_command = supplied_command or weekly_command(process, env, timeout=args.publication_timeout)
                    guard(); publish_command(['git', 'push', 'origin', 'HEAD:refs/heads/' + branch], root)
                    guard()
                    if git(['ls-remote', 'origin', 'refs/heads/' + branch], root) != state['complete_commit'] + '\trefs/heads/' + branch:
                        raise ValueError('publication drift; retain completed local state')
                response['published_commit'] = state['complete_commit']
                response['publication_effects'] = 'explicit ordinary fast-forward Git push and normal hooks; no force/dispatch/merge'

            response['holds'].append('Criterion/readiness/freeze/dispatch/landing remain unreviewed; source history preserved, not delivered')
            return response

        finally:
            fcntl.flock(destination_lock.fileno(), fcntl.LOCK_UN)
            destination_lock.close()


def main():
    parser = argparse.ArgumentParser(description="Planner Core Engine")
    parser.add_argument("--repo-root", default=".", help="Path to repository root")
    parser.add_argument("--gh-repo", default=None, help="Target GitHub repo (e.g. Org/Name)")
    parser.add_argument("--mode", choices=["weekly", "daily", "audit", "sequence", "intake", "weekly-intake", "weekly-prepare", "weekly-work", "weekly-reconcile"], default="weekly")
    parser.add_argument("--plan-file", help="Path to existing weekly plan JSON/MD")
    parser.add_argument("--decisions-issue", help="Canonical GH issue number for provisional decisions tracker")
    parser.add_argument("--team-issue", "--issue", dest="team_issue", type=int, help="Team weekly issue number for focus assignments")
    parser.add_argument("--hours", type=int, default=36, help="Lookback interval in hours for daily mode")
    parser.add_argument("--fallback", action="store_true", help="Force scratch markdown fallback intake")
    parser.add_argument("--create-issue", action="store_true", help="Publish the generated weekly plan outline as a GitHub issue")

    parser.add_argument("--since", help="UTC/offset ISO timestamp for held weekly intake")
    parser.add_argument("--intake-file", help="Previous complete weekly-intake JSON; carry every member")
    parser.add_argument("--authority-file", help="Explicit weekly/authorities@1 root/context declarations for held work reads")
    parser.add_argument("--prepare-root", help="Separate new/owned full clone for local weekly preparation")
    parser.add_argument("--planning-date", help="Explicit YYYY-MM-DD for auto-* planning branch")
    parser.add_argument("--target-ref", help="Explicit canonical target branch")
    parser.add_argument("--initial-backfill", choices=["all-open", "updated-only"])
    parser.add_argument("--overlap-hours", type=float, help="Explicit inclusive checkpoint overlap")
    parser.add_argument("--predecessor-root", help="Explicit preserved auto-date full clone")
    parser.add_argument("--expected-predecessor-head", help="Exact predecessor commit SHA")
    parser.add_argument("--adopt-predecessor", action="store_true", help="Explicit exact published predecessor adoption")
    parser.add_argument("--publish", action="store_true", help="Explicit held planning-branch publication; reconciliation only")
    parser.add_argument("--publication-timeout", type=float, help="Explicit normal Git-hook publication IO ceiling")
    parser.add_argument("--apply", action="store_true", help="Apply held preparation locally; never push/fire")

    args = parser.parse_args()
    if args.publish and args.mode != "weekly-reconcile":
        parser.error("publish is available only for explicit weekly-reconcile")
    repo_root = Path(args.repo_root).resolve()
    if not repo_root.is_dir():
        print(f"[ERROR] repo root not found: {repo_root}", file=sys.stderr)
        sys.exit(2)
    if args.mode == "weekly-reconcile":
        try:
            if not all((args.gh_repo, args.since, args.prepare_root, args.planning_date, args.target_ref,
                        args.initial_backfill, args.authority_file, args.predecessor_root,
                        args.expected_predecessor_head)) or args.overlap_hours is None:
                raise ValueError("weekly-reconcile requires all explicit preparation/predecessor/authority inputs")
            result = reconcile_weekly(args, repo_root)
            print(json.dumps(result, indent=2))
            if not result["complete"]:
                sys.exit(2)
            return
        except (OSError, ValueError, TypeError, KeyError, RuntimeError) as error:
            print(json.dumps({"complete": False, "status": "UNKNOWN", "dispatch_allowed": False,
                              "error": str(error)}))
            sys.exit(2)
    if args.mode == "weekly-work":
        try:
            if not args.authority_file or args.apply:
                raise ValueError("weekly-work requires authority-file and does not accept apply")
            result = observe_weekly_work(args.authority_file, repo_root)
            print(json.dumps(result, indent=2))
            if not result["complete"]:
                sys.exit(2)
            return
        except (OSError, ValueError, TypeError, KeyError, RuntimeError) as error:
            print(json.dumps({"complete": False, "status": "UNKNOWN", "dispatch_allowed": False,
                              "error": str(error)}))
            sys.exit(2)
    if args.mode in ("weekly-intake", "weekly-prepare"):
        # Opt-in discovery, before legacy scratch creation. Installed copies use
        # the same shipped harness locator as 10days; no sibling-skill dependency.
        try:
            intake_module = load_issue_intake()
            if not args.gh_repo or not args.since:
                raise ValueError("weekly-intake requires --gh-repo OWNER/REPO and --since with timezone")
            if args.mode == "weekly-prepare":
                if not all((args.prepare_root, args.planning_date, args.target_ref, args.initial_backfill)) or args.overlap_hours is None:
                    raise ValueError("weekly-prepare requires prepare-root, planning-date, target-ref, initial-backfill and overlap-hours")
                print(json.dumps(prepare_weekly(args, repo_root), indent=2))
                return
            previous = json.loads(Path(args.intake_file).read_text()) if args.intake_file else None
            result = intake_module.discover_weekly(args.gh_repo, args.since, repo_root, previous)
            result["advisory_merge_sequence"] = detect_merge_sequence(result["prs"])
            result["advisory_audit"] = audit_adversarial({"prs": result["prs"]}, prs=result["prs"])
            result["holds"].append("Outline sequencing/audit are advisory; CI NONE, dependencies and completion heuristics are not readiness proof.")
            print(json.dumps(result, indent=2))
            return
        except (OSError, ValueError, TypeError, KeyError, RuntimeError) as error:
            print(json.dumps({"complete": False, "status": "UNKNOWN", "dispatch_allowed": False,
                              "error": str(error)}))
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
    target_repo = args.gh_repo or resolve_gh_repo(repo_root)
    intake = ingest_weekly_intake(repo_root, target_repo, team_issue=args.team_issue, fallback_mode=args.fallback, since=args.since)
    if intake.get("discovered_prs"):
        prs = intake["discovered_prs"]
        sequence = detect_merge_sequence(prs)
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

    if args.create_issue:
        title = f"Weekly Plan Outline — {date_str}"
        cmd = ["gh", "issue", "create", "--title", title, "--body-file", str(out_md)]
        if target_repo:
            cmd.extend(["-R", target_repo])
        print(f"Publishing weekly plan GitHub issue for {target_repo or 'repository'}...")
        res = subprocess.run(cmd, capture_output=True, text=True, cwd=repo_root)
        if res.returncode == 0:
            issue_url = res.stdout.strip()
            print(f"Weekly plan issue created: {issue_url}")
        else:
            print(f"[ERROR] Failed to create issue: {res.stderr.strip()}", file=sys.stderr)


if __name__ == "__main__":
    main()
