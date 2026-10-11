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
        "--json", "number,title,author,headRefName,baseRefName,mergeable,reviewDecision,reviews,updatedAt,statusCheckRollup,files,body"
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
    phase_blocker_fixes = []
    phase_needs_rebase = []
    phase_in_review = []

    for pr in prs:
        decision = (pr.get("reviewDecision") or "").upper()
        mergeable = (pr.get("mergeable") or "").upper()
        ci = eval_ci_status(pr)
        pr_with_ci = dict(pr)
        pr_with_ci["ci_status"] = ci
        pr_with_ci["dependencies"] = sorted(list(pr_dependencies.get(pr.get("number"), set())))

        if decision == "CHANGES_REQUESTED" or ci == "FAILURE":
            phase_blocker_fixes.append(pr_with_ci)
        elif mergeable == "CONFLICTING":
            phase_needs_rebase.append(pr_with_ci)
        elif decision == "APPROVED" and mergeable == "MERGEABLE" and ci in {"SUCCESS", "NONE"}:
            phase_ready.append(pr_with_ci)
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
            "blockers_to_fix": phase_blocker_fixes,
            "needs_rebase": phase_needs_rebase,
            "in_review_or_wip": phase_in_review,
        },
        "topological_merge_sequence": sorted_ready,
        # Backward-compatible aliases at root
        "ready_to_land": sorted_ready,
        "blockers_to_fix": phase_blocker_fixes,
        "needs_rebase": phase_needs_rebase,
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
        for match in re.finditer(r"(?i)(?:fixes|closes|resolves|gh-|#)(\d+)", title):
            issue_id = match.group(1)
            seen_issues.setdefault(issue_id, []).append(pr_num)
    duplicates = {iss: nums for iss, nums in seen_issues.items() if len(nums) > 1}
    if duplicates:
        dup_summary = [f"Issue #{iss} claimed by PRs: {nums}" for iss, nums in duplicates.items()]
        findings.append({
            "severity": "MEDIUM",
            "type": "TASK_DUPLICATION",
            "message": f"Multiple PRs targeting identical issue/task: {'; '.join(dup_summary)}."
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
    - Mode A (Native XYZ): Query PRS 4-axis scores via releases_app.py roadmap list --json.
    - Mode B (Fallback): Query open GitHub issues and generate pass1-intake.md and pass2-sharpened.md.
    - Ingest team member domain assignments from team_issue or issue assignees.
    """
    temp_dir = ensure_temp_dir(repo_root)
    intake_mode = "fallback_scratch"
    roadmap_items = []
    teammates: dict[str, dict] = {
        "Jose": {"domain": "Data/Pipeline", "tasks": []},
        "Matthew": {"domain": "NexMail/Calendar", "tasks": []},
        "Noel": {"domain": "Orchestration/Gate", "tasks": []},
    }

    releases_cli = repo_root / "utils" / "py" / "releases_app.py"
    releases_db = repo_root / "releases.db"

    if not fallback_mode and (releases_db.exists() or releases_cli.exists()):
        try:
            cmd = ["python3", str(releases_cli), "roadmap", "list", "--json"]
            out = run_cmd(cmd, cwd=repo_root, check=True)
            if out:
                roadmap_items = json.loads(out)
                intake_mode = "native_prs"
        except (subprocess.SubprocessError, json.JSONDecodeError, OSError, RuntimeError) as e:
            print(f"[WARN] Native PRS intake failed ({e}); falling back to GitHub issues intake.", file=sys.stderr)

    if not roadmap_items:
        intake_mode = "fallback_scratch"
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
                "section": "Open Issues Intake",
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

    # Assign roadmap items to teammates
    for item in roadmap_items:
        title = (item.get("title") or "").lower()
        assigned = False
        for name, data in teammates.items():
            domain_words = [w.lower() for w in re.split(r"[\s/]+", data["domain"]) if len(w) > 3]
            if any(dw in title for dw in domain_words):
                data["tasks"].append(item)
                assigned = True
                break
        if not assigned and "Noel" in teammates:
            teammates["Noel"]["tasks"].append(item)

    return {
        "intake_mode": intake_mode,
        "roadmap_items": roadmap_items,
        "teammate_assignments": teammates,
    }


def format_weekly_markdown(date_str: str, plan_data: dict) -> str:
    """Format weekly plan as a clean, complete Markdown document."""
    seq = plan_data.get("merge_sequence", {})
    phases = seq.get("status_phases", {})
    ready = phases.get("ready_to_land", [])
    blockers = phases.get("blockers_to_fix", [])
    rebase = phases.get("needs_rebase", [])
    in_review = phases.get("in_review_or_wip", [])
    audit = plan_data.get("adversarial_audit", {})
    teammates = plan_data.get("teammate_assignments", {})
    decisions_issue = plan_data.get("decisions_issue", "NONE_SET")

    lines = [
        f"# Weekly Plan Outline — {date_str}",
        "",
        f"- **Generated:** {plan_data.get('timestamp')}",
        f"- **Intake Mode:** {plan_data.get('intake_mode')}",
        f"- **Provisional Decisions Register:** Issue #{decisions_issue}" if decisions_issue != "NONE_SET" else "- **Provisional Decisions Register:** None configured",
        "",
        "## 1. Immediate P0 Blockers",
        ""
    ]

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
    else:
        lines.append("- *No PRs currently ready to land.*")

    if rebase:
        lines.extend(["", "### Phase 3: Needs Rebase"])
        for p in rebase:
            lines.append(f"- **PR #{p.get('number')}**: {p.get('title')} — `CONFLICTING` against base")

    if in_review:
        lines.extend(["", "### Phase 4: In Review / WIP"])
        for p in in_review:
            lines.append(f"- **PR #{p.get('number')}**: {p.get('title')} — Review: `{p.get('reviewDecision') or 'PENDING'}`, CI: `{p.get('ci_status')}`")

    lines.extend([
        "",
        "## 3. Teammate Focus & Action Outlines",
        ""
    ])

    for member, data in teammates.items():
        domain = data.get("domain", "General")
        tasks = data.get("tasks", [])
        lines.append(f"### {member} ({domain})")
        if tasks:
            for t in tasks[:7]:
                gh_num = t.get("gh_number") or t.get("number")
                lines.append(f"- [ ] **GH-{gh_num}**: {t.get('title')}")
        else:
            lines.append("- *No scheduled tasks assigned.*")
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


def prepare_weekly(args, source_root, command=None):
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
        def command(argv, cwd):
            result = process.run_bounded(argv, cwd=str(cwd), env=env,
                                         timeout=WEEKLY_IO_TIMEOUT_SECONDS, grace=1)
            if result.timed_out:
                raise RuntimeError(f"command timed out after {WEEKLY_IO_TIMEOUT_SECONDS}s: {argv[0]}; preserve partial state")
            if result.rc:
                raise RuntimeError(f"command refused ({result.rc}): {argv[0]} {result.stderr.strip()}")
            return result.stdout

    def durable(path, value):
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
            if previous.get("planning_base") != base:
                raise ValueError(f"target advanced: planning base {previous.get('planning_base')} current {base}; explicit reconciliation required")
    if args.intake_file:
        supplied = json.loads(Path(args.intake_file).read_text())
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

    with (gitdir / "weekly-prepare.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise RuntimeError("weekly preparation writer is active") from error
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
                    state["complete_commit"] = git(["rev-parse", "HEAD"], root)
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
                if target_head(root) != base or git(["rev-parse", "HEAD"], root) != preparation_head:
                    raise ValueError("target/HEAD drift immediately before commit; preserve partial state")
                git(["commit", "-m", f"weekly: accumulate {repository} intake for {date}"], root)
                completed = git(["rev-parse", "HEAD"], root)
                if (git(["branch", "--show-current"], root) != branch
                        or git(["rev-parse", "HEAD^"], root) != preparation_head
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

def main():
    parser = argparse.ArgumentParser(description="Planner Core Engine")
    parser.add_argument("--repo-root", default=".", help="Path to repository root")
    parser.add_argument("--gh-repo", default=None, help="Target GitHub repo (e.g. Org/Name)")
    parser.add_argument("--mode", choices=["weekly", "daily", "audit", "sequence", "intake", "weekly-intake", "weekly-prepare"], default="weekly")
    parser.add_argument("--plan-file", help="Path to existing weekly plan JSON/MD")
    parser.add_argument("--decisions-issue", help="Canonical GH issue number for provisional decisions tracker")
    parser.add_argument("--team-issue", "--issue", dest="team_issue", type=int, help="Team weekly issue number for focus assignments")
    parser.add_argument("--hours", type=int, default=36, help="Lookback interval in hours for daily mode")
    parser.add_argument("--fallback", action="store_true", help="Force scratch markdown fallback intake")

    parser.add_argument("--since", help="UTC/offset ISO timestamp for held weekly intake")
    parser.add_argument("--intake-file", help="Previous complete weekly-intake JSON; carry every member")
    parser.add_argument("--prepare-root", help="Separate new/owned full clone for local weekly preparation")
    parser.add_argument("--planning-date", help="Explicit YYYY-MM-DD for auto-* planning branch")
    parser.add_argument("--target-ref", help="Explicit canonical target branch")
    parser.add_argument("--initial-backfill", choices=["all-open", "updated-only"])
    parser.add_argument("--overlap-hours", type=float, help="Explicit inclusive checkpoint overlap")
    parser.add_argument("--apply", action="store_true", help="Apply held preparation locally; never push/fire")

    args = parser.parse_args()
    repo_root = Path(args.repo_root).resolve()
    if not repo_root.is_dir():
        print(f"[ERROR] repo root not found: {repo_root}", file=sys.stderr)
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
        "merge_sequence": sequence,
        "adversarial_audit": audit,
        "teammate_assignments": intake.get("teammate_assignments", {}),
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
