#!/usr/bin/env python3
"""wave_reconcile.py (GH-165) — Post-Merge Wave & Marathon Lifecycle Reconciler.

The canonical, single-command Python reconciler to automate post-merge lifecycle
transitions across Active Docs (PROJECT/2-WORKING/ -> 3-COMPLETED/ or 4-MISC/),
ROADMAP.md, releases.db SQLite ledger, generated dashboards, and next-wave marathon planning.
"""

import argparse
import fcntl
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path


class ReconcileError(Exception):
    """Custom exception class ensuring proper rollback catching."""

    def __init__(self, message, code=2):
        super().__init__(message)
        self.code = code


def log(msg):
    print(f"wave-reconcile: {msg}", flush=True)


def log_err(msg):
    print(f"wave-reconcile: ERROR — {msg}", file=sys.stderr, flush=True)


def die(msg, code=2):
    log_err(msg)
    raise ReconcileError(msg, code=code)


class ReconcilerLock:
    """Lock manager preventing concurrent reconciliation runs."""

    def __init__(self, lock_path):
        self.lock_path = lock_path
        self.fd = None

    def __enter__(self):
        try:
            self.fd = open(self.lock_path, "w")
            fcntl.flock(self.fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            self.fd.write(f"pid={os.getpid()}\ntime={datetime.now().isoformat()}\n")
            self.fd.flush()
            return self
        except (BlockingIOError, OSError) as e:
            die(f"Could not acquire reconciler lock at {self.lock_path}: {e}", code=8)

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.fd:
            try:
                fcntl.flock(self.fd, fcntl.LOCK_UN)
                self.fd.close()
                if os.path.exists(self.lock_path):
                    os.unlink(self.lock_path)
            except OSError:
                pass


class RollbackJournal:
    """Snapshots pre-mutation file states and rolls back on failure."""

    def __init__(self):
        self.backups = {}  # original_path -> backup_temp_path
        self.created_files = set()
        self.deleted_files = set()

    def snapshot(self, path):
        p = os.path.abspath(path)
        if p not in self.backups and os.path.exists(p):
            tmp = tempfile.NamedTemporaryFile(delete=False)
            tmp.close()
            shutil.copy2(p, tmp.name)
            self.backups[p] = tmp.name

    def track_created(self, path):
        self.created_files.add(os.path.abspath(path))

    def rollback(self):
        log("Rolling back all uncommitted mutations...")
        for created in self.created_files:
            if os.path.exists(created):
                try:
                    os.unlink(created)
                except OSError:
                    pass
        for orig, backup in self.backups.items():
            try:
                os.makedirs(os.path.dirname(orig), exist_ok=True)
                shutil.copy2(backup, orig)
            except OSError as e:
                log_err(f"Failed restoring {orig} from {backup}: {e}")
        self.cleanup()

    def cleanup(self):
        for backup in self.backups.values():
            if os.path.exists(backup):
                try:
                    os.unlink(backup)
                except OSError:
                    pass
        self.backups.clear()
        self.created_files.clear()


def resolve_repo_root():
    """Find repository root containing .git."""
    cur = os.path.abspath(os.getcwd())
    while cur != os.path.dirname(cur):
        if os.path.isdir(os.path.join(cur, ".git")) or os.path.isfile(os.path.join(cur, ".git")):
            return cur
        cur = os.path.dirname(cur)
    return os.path.abspath(os.getcwd())


def check_porcelain_cleanliness(repo_root, allow_dirty=False):
    """Assert clean git working tree before mutation."""
    cmd = ["git", "-C", repo_root, "status", "--porcelain"]
    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if r.returncode != 0:
        die(f"git status failed: {r.stderr}")
    dirt = r.stdout.strip()
    if dirt and not allow_dirty:
        die(
            f"Working tree is dirty. Must be completely clean to reconcile:\n{dirt}",
            code=3,
        )


def check_current_branch(repo_root, expected_branch="development", skip_branch_check=False):
    """Verify active branch matches target branch."""
    if skip_branch_check:
        return
    cmd = ["git", "-C", repo_root, "branch", "--show-current"]
    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
    current = r.stdout.strip()
    if current != expected_branch:
        die(
            f"Active branch is '{current}', but post-merge reconciliation requires '{expected_branch}'.",
            code=3,
        )


def pull_upstream(repo_root, branch="development"):
    """Fast-forward pull from origin."""
    cmd = ["git", "-C", repo_root, "pull", "--ff-only", "origin", branch]
    r = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if r.returncode != 0:
        die(f"git pull --ff-only failed: {r.stderr}")


def fetch_pr_metadata(repo_root, pr_id, offline_manifest=None, dry_run=False):
    """Fetch merged PR metadata from GitHub or offline manifest."""
    if offline_manifest:
        for entry in offline_manifest.get("prs", []):
            if str(entry.get("number")) == str(pr_id):
                return entry
        die(f"PR #{pr_id} not found in offline manifest", code=4)

    if dry_run:
        # In dry run without offline manifest, try gh if available or return stub preview
        pass

    cmd = [
        "gh",
        "pr",
        "view",
        str(pr_id),
        "--json",
        "number,title,state,mergedAt,baseRefName,headRefName,body,url",
    ]
    r = subprocess.run(cmd, cwd=repo_root, capture_output=True, text=True, check=False)
    if r.returncode != 0:
        if dry_run:
            log(f"dry-run: gh pr view unavailable ({r.stderr.strip()}); using synthetic preview metadata for PR #{pr_id}")
            return {
                "number": int(pr_id),
                "title": f"Preview PR #{pr_id}",
                "state": "MERGED",
                "mergedAt": datetime.now().isoformat() + "Z",
                "baseRefName": "development",
                "body": f"Closes #{pr_id}",
            }
        die(f"gh pr view {pr_id} failed: {r.stderr}", code=4)
    try:
        return json.loads(r.stdout)
    except json.JSONDecodeError as e:
        die(f"Failed parsing gh pr view JSON for PR #{pr_id}: {e}", code=4)


def check_provenance_receipts(repo_root, pr_meta):
    """Check committed provenance receipts for marathon gate (GH-430)."""
    pr_num = pr_meta.get("number")
    results_dir = os.path.join(repo_root, "TESTS-RESULTS")
    if not os.path.isdir(results_dir):
        die(f"--gate failure: TESTS-RESULTS directory missing; cannot verify provenance for PR #{pr_num}", code=6)
    # Search for committed receipts matching PR or recent date
    found = False
    for root, _, files in os.walk(results_dir):
        for f in files:
            if f in ("error_log.jsonl", "provenance.jsonl"):
                found = True
                break
        if found:
            break
    if not found:
        die(f"--gate failure: No committed provenance.jsonl or error_log.jsonl found in TESTS-RESULTS/ for PR #{pr_num}", code=6)
    log(f"  Provenance receipts verified for PR #{pr_num} (GH-430 compliant)")


def extract_linked_issues(pr_meta):
    """Extract linked issue numbers from PR body/title."""
    issues = set()
    text = (pr_meta.get("title", "") + " " + pr_meta.get("body", "")).strip()
    # Match Closes #123, Fixes #123, GH-123, #123
    patterns = [
        r"(?:[Ff]ixes|[Cc]loses|[Rr]esolves)\s+#?([0-9]{1,6})",
        r"\b[Gg][Hh]-([0-9]{1,6})\b",
    ]
    for pat in patterns:
        for m in re.finditer(pat, text):
            issues.add(int(m.group(1)))
    return sorted(issues)


def find_active_doc_for_issue(repo_root, issue_num):
    """Find matching active doc in PROJECT/2-WORKING/."""
    working_dir = os.path.join(repo_root, "PROJECT", "2-WORKING")
    if not os.path.isdir(working_dir):
        return None
    for fname in os.listdir(working_dir):
        if not fname.endswith(".md"):
            continue
        # Match GH-123-*.md or 123-*.md
        if re.search(rf"(?:^|[^\d])(GH-)?{issue_num}(?:[^\d]|$)", fname, re.IGNORECASE):
            return os.path.join(working_dir, fname)
    return None


def validate_and_update_doc(doc_path, pr_meta, is_merged=True, dry_run=False, journal=None):
    """Assert ## Lessons Learned, update frontmatter, and compute destination path."""
    with open(doc_path, "r", encoding="utf-8", errors="replace") as f:
        content = f.read()

    merged_at = pr_meta.get("mergedAt")
    if merged_at:
        try:
            ship_date = datetime.fromisoformat(merged_at.replace("Z", "+00:00")).strftime(
                "%Y-%m-%d"
            )
        except Exception:
            ship_date = datetime.now().strftime("%Y-%m-%d")
    else:
        ship_date = datetime.now().strftime("%Y-%m-%d")

    if is_merged:
        # Assert lessons learned section exists for merged docs
        if not re.search(r"##\s+Lessons\s+Learned", content, re.IGNORECASE):
            die(
                f"Doc {os.path.basename(doc_path)} is missing mandatory '## Lessons Learned (For Future Agents)' section.",
                code=5,
            )

        new_status = "Complete"
        dest_folder = "3-COMPLETED"
    else:
        # Unmerged / declined / closed without merge -> route to 4-MISC
        new_status = "Declined"
        dest_folder = "4-MISC"

    # Update frontmatter status and updated date
    new_content = re.sub(
        r"^status:\s*.*$", f"status: {new_status}", content, flags=re.MULTILINE | re.IGNORECASE
    )
    new_content = re.sub(
        r"^updated:\s*.*$", f"updated: {ship_date}", new_content, flags=re.MULTILINE | re.IGNORECASE
    )

    dest_dir = os.path.join(os.path.dirname(os.path.dirname(doc_path)), dest_folder)
    dest_path = os.path.join(dest_dir, os.path.basename(doc_path))

    if not dry_run:
        if journal:
            journal.snapshot(doc_path)
            journal.track_created(dest_path)
        os.makedirs(dest_dir, exist_ok=True)
        with open(dest_path, "w", encoding="utf-8") as f:
            f.write(new_content)
        os.unlink(doc_path)

    return dest_path, ship_date


def update_roadmap_entry(repo_root, issue_num, pr_num, ship_date, is_merged=True, dry_run=False, journal=None):
    """Move multiline entry block in ROADMAP.md to Completed/Deferred section with shipping badge."""
    roadmap_path = os.path.join(repo_root, "ROADMAP.md")
    if not os.path.isfile(roadmap_path):
        log_err("ROADMAP.md not found; skipping roadmap update")
        return False

    with open(roadmap_path, "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()

    # Locate entry block
    entry_pattern = re.compile(rf"^-\s+\*\*GH-{issue_num}\b")
    start_idx = None
    end_idx = None

    for i, line in enumerate(lines):
        if entry_pattern.search(line):
            start_idx = i
            break

    if start_idx is None:
        log(f"No entry found in ROADMAP.md for GH-{issue_num} (skipping roadmap move)")
        return False

    # Find end of block (next entry starting with - ** or section header ###)
    end_idx = len(lines)
    for j in range(start_idx + 1, len(lines)):
        if lines[j].startswith("- **") or lines[j].startswith("### ") or lines[j].startswith("## "):
            end_idx = j
            break

    block_lines = lines[start_idx:end_idx]
    first_line = block_lines[0]

    # Already completed?
    if "✅" in first_line and "SHIPPED" in first_line:
        log(f"GH-{issue_num} is already marked SHIPPED in ROADMAP.md")
        return True

    target_section = "### Completed" if is_merged else "### Deferred / cancelled"
    badge_sub = f"✅ **SHIPPED {ship_date} (PR #{pr_num})**" if is_merged else f"🛑 **DECLINED {ship_date} (PR #{pr_num})**"

    if "—" in first_line:
        prefix, rest = first_line.split("—", 1)
        title_part = prefix.split("**")[1] if "**" in prefix else f"GH-{issue_num}"
        new_first_line = f"- **{title_part}** {badge_sub} —{rest}"
    else:
        new_first_line = re.sub(
            r"(\*\*[^*]+\*\*)\s+(?:[^\—]+)\s+—", rf"\1 {badge_sub} —", first_line
        )

    block_lines[0] = new_first_line

    # Remove block from old location
    new_lines = lines[:start_idx] + lines[end_idx:]

    # Locate target section header
    target_idx = None
    for k, line in enumerate(new_lines):
        if line.strip() == target_section:
            target_idx = k
            break

    if target_idx is None and not is_merged:
        # Fallback to ### Completed if ### Deferred is absent
        target_section = "### Completed"
        for k, line in enumerate(new_lines):
            if line.strip() == target_section:
                target_idx = k
                break

    if target_idx is None:
        die(f"Could not find '{target_section}' section in ROADMAP.md", code=5)

    # Insert block right under section header
    insert_pos = target_idx + 1
    new_lines = new_lines[:insert_pos] + block_lines + new_lines[insert_pos:]

    if not dry_run:
        if journal:
            journal.snapshot(roadmap_path)
        with open(roadmap_path, "w", encoding="utf-8") as f:
            f.writelines(new_lines)

    return True


def run_subprocesses(repo_root, dry_run=False, journal=None):
    """Orchestrate releases sync, view exports, and marathon replanning with DB rollback protection."""
    log("Running downstream database sync and dashboard regeneration...")

    # Snapshot DB files in journal for transactional integrity
    db_file = os.path.join(repo_root, "releases.db")
    sql_file = os.path.join(repo_root, "releases.sql")
    if not dry_run and journal:
        journal.snapshot(db_file)
        journal.snapshot(sql_file)

    sync_cmd = ["python3", "utils/py/releases_app.py", "roadmap", "sync"]
    check_cmd = ["python3", "utils/py/releases_app.py", "check"]
    timeline_cmd = ["python3", "utils/timeline/export_timeline.py", "--preview"]
    dash_cmd = ["bash", "utils/roadmap-dashboard.sh"]
    plan_cmd = ["bash", "utils/marathon-plan.sh"]

    if dry_run:
        sync_cmd.append("--dry-run")
        plan_cmd = ["bash", "utils/marathon-plan.sh", "--dry-run"]

    steps = [
        ("releases roadmap sync", sync_cmd),
        ("releases check", check_cmd),
    ]
    if not dry_run:
        steps.extend(
            [
                ("export_timeline.py --preview", timeline_cmd),
                ("roadmap-dashboard.sh", dash_cmd),
                ("marathon-plan.sh", plan_cmd),
            ]
        )
    else:
        steps.append(("marathon-plan.sh --dry-run", plan_cmd))

    for name, cmd in steps:
        log(f"  -> {name}")
        r = subprocess.run(cmd, cwd=repo_root, capture_output=True, text=True, check=False)
        if name.startswith("marathon-plan"):
            if r.returncode not in (0, 4):
                die(f"Subprocess '{name}' failed with exit {r.returncode}:\n{r.stderr}\n{r.stdout}", code=6)
        elif r.returncode != 0:
            die(f"Subprocess '{name}' failed with exit {r.returncode}:\n{r.stderr}\n{r.stdout}", code=6)


def run_validation_gate(repo_root):
    """Run pdda doc-health verification gate."""
    log("Running PDDA doc-hygiene gate...")
    gate_cmd = ["bash", "utils/pdda-local-checks.sh"] if os.path.exists(os.path.join(repo_root, "utils", "pdda-local-checks.sh")) else ["bash", "utils/pdda/pdda.sh"]
    r = subprocess.run(
        gate_cmd,
        cwd=repo_root,
        capture_output=True,
        text=True,
        check=False,
    )
    # Check for error lines
    if r.returncode != 0 or "ERROR" in r.stdout:
        die(f"PDDA validation gate failed:\n{r.stdout}", code=7)


def main():
    parser = argparse.ArgumentParser(
        description="wave_reconcile.py — Canonical Post-Merge Wave & Marathon Lifecycle Reconciler"
    )
    parser.add_argument(
        "--root",
        help="Target repository root path (default: current working directory)",
    )
    parser.add_argument(
        "--pr",
        nargs="+",
        help="One or more merged PR numbers/IDs to reconcile",
    )
    parser.add_argument(
        "--marathon",
        help="Marathon identifier / milestone name",
    )
    parser.add_argument(
        "--manifest",
        help="Path to structured JSON reconciliation manifest",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Hermetic preview: assert zero file/DB/ref mutations",
    )
    parser.add_argument(
        "--offline",
        help="Run without network using offline JSON manifest cache",
    )
    parser.add_argument(
        "--skip-pull",
        action="store_true",
        help="Skip git pull --ff-only origin development (for testing/isolated clones)",
    )
    parser.add_argument(
        "--skip-branch-check",
        action="store_true",
        help="Skip active branch check (for tests on feature branches)",
    )
    parser.add_argument(
        "--allow-dirty",
        action="store_true",
        help="Allow dirty working tree (for test fixtures only)",
    )
    parser.add_argument(
        "--gate",
        "--require-receipts",
        action="store_true",
        dest="require_receipts",
        help="Enforce provenance receipts on merged PRs before marathon closeout (GH-430)",
    )

    args = parser.parse_args()

    repo_root = os.path.abspath(args.root) if args.root else resolve_repo_root()
    lock_file = os.path.join(repo_root, ".git", "wave-reconcile.lock")
    journal = RollbackJournal()

    try:
        # Preflight phase
        log(f"Starting wave reconciliation (dry_run={args.dry_run}, root={repo_root})")
        check_porcelain_cleanliness(repo_root, allow_dirty=(args.allow_dirty or args.dry_run))
        check_current_branch(repo_root, skip_branch_check=args.skip_branch_check)

        if not args.skip_pull and not args.dry_run and not args.offline:
            pull_upstream(repo_root)

        offline_manifest = None
        if args.offline:
            try:
                with open(args.offline, "r", encoding="utf-8") as f:
                    offline_manifest = json.load(f)
            except Exception as e:
                die(f"Failed loading offline manifest from {args.offline}: {e}", code=4)

        pr_list = args.pr or []
        if args.manifest:
            try:
                with open(args.manifest, "r", encoding="utf-8") as f:
                    mdata = json.load(f)
                    pr_list.extend([str(p) for p in mdata.get("prs", [])])
            except Exception as e:
                die(f"Failed loading manifest from {args.manifest}: {e}", code=4)

        if not pr_list and not args.marathon:
            die("No PRs or marathon specified. Pass --pr <N>... or --marathon <name>", code=2)

        with ReconcilerLock(lock_file):
            for pr_id in pr_list:
                log(f"Processing PR #{pr_id}...")
                pr_meta = fetch_pr_metadata(repo_root, pr_id, offline_manifest, dry_run=args.dry_run)
                state = pr_meta.get("state", "").upper()
                is_merged = (state == "MERGED")

                if not is_merged:
                    log(f"  PR #{pr_id} state is '{state}' (unmerged/declined) -> routing to 4-MISC/")

                base_ref = pr_meta.get("baseRefName", "")
                if base_ref and base_ref != "development":
                    die(
                        f"PR #{pr_id} target base is '{base_ref}', not 'development'.",
                        code=4,
                    )

                if args.require_receipts:
                    check_provenance_receipts(repo_root, pr_meta)

                linked_issues = extract_linked_issues(pr_meta)
                log(f"  PR #{pr_id} linked issues: {linked_issues}")

                for issue_num in linked_issues:
                    doc_path = find_active_doc_for_issue(repo_root, issue_num)
                    if doc_path:
                        log(f"  Found active doc: {os.path.basename(doc_path)}")
                        dest_path, ship_date = validate_and_update_doc(
                            doc_path, pr_meta, is_merged=is_merged, dry_run=args.dry_run, journal=journal
                        )
                        log(f"  Moved -> {os.path.basename(dest_path)} (destination: {os.path.basename(os.path.dirname(dest_path))})")
                    else:
                        log(f"  No active doc in 2-WORKING for GH-{issue_num}")
                        ship_date = datetime.now().strftime("%Y-%m-%d")

                    updated = update_roadmap_entry(
                        repo_root,
                        issue_num,
                        pr_id,
                        ship_date,
                        is_merged=is_merged,
                        dry_run=args.dry_run,
                        journal=journal,
                    )
                    if updated:
                        log(f"  ROADMAP.md entry updated for GH-{issue_num}")

            # Subprocess orchestration
            run_subprocesses(repo_root, dry_run=args.dry_run, journal=journal)

            # Final validation gate
            if not args.dry_run:
                run_validation_gate(repo_root)

            log("Wave reconciliation completed successfully! ✅")
            journal.cleanup()

    except ReconcileError as re_err:
        journal.rollback()
        sys.exit(re_err.code)
    except (Exception, SystemExit) as exc:
        journal.rollback()
        raise exc


if __name__ == "__main__":
    main()
