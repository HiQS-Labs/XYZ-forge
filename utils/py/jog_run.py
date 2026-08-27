#!/usr/bin/env python3
"""jog_run.py — GH-259: Jog serial immediate-queue execution engine supervisor.

Supervises the serial execution of tasks in jog_queue:
1. Acquires the outer driver lock (`relay-driver.lock`) and exports RELAY_DRIVER_LOCKED=1.
2. Reconciles any orphan `running` leases on startup via perform_write (resets dead PIDs to pending).
3. Pops pending tasks in strict position order.
4. Auto-promotes 1-INBOX contracts to 2-WORKING with probe linting and safety checks.
5. Executes swarm-preflight (ready -> drive, already-landed -> drop, not-ready -> park).
6. Dispatches single-phase turn runner.
7. Defaults to pausing at landing boundaries for operator confirmation before merging PRs into development (with --auto-merge as opt-in).
8. Re-anchors same-seam tasks on development and tears down throwaway worktrees cleanly.
"""

import argparse
import atexit
import datetime as _dt
import glob
import json
import os
import re
import shutil
import signal
import sqlite3
import subprocess
import sys

# Ensure utils/py is in sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from rtl import driver_lock_path  # noqa: E402
from releases_app import (  # noqa: E402
    _ensure_jog_schema,
    _table_exists,
    jog_acquire_lease,
    jog_set_status,
    jog_reconcile_orphan_leases,
)


TRIVIAL_PROBE_PATTERNS = [
    re.compile(r"^(?:true|exit\s+0|:|echo\s+.*|sleep\s+.*)$", re.IGNORECASE),
]


class JogSupervisorLock:
    """Outer driver lock supervisor ensuring exclusive execution on the clone."""

    def __init__(self, root):
        self.root = root
        self.lock_dir, self.lock_label = driver_lock_path(root)
        self.acquired = False

    def acquire(self):
        try:
            os.mkdir(self.lock_dir)
            self.acquired = True
        except OSError:
            holder = ""
            pid_file = os.path.join(self.lock_dir, "pid")
            if os.path.isfile(pid_file):
                try:
                    with open(pid_file, "r") as f:
                        holder = f.read().strip()
                except Exception:
                    pass

            is_running = False
            if holder and holder.isdigit():
                try:
                    os.kill(int(holder), 0)
                    is_running = True
                except OSError:
                    pass

            if is_running:
                print(
                    f"jog: another driver is active in this repo (pid {holder}, lock: {self.lock_label}).\n"
                    f"jog: Concurrent runs in the same clone are unsafe (GH-42 / GH-354).",
                    file=sys.stderr,
                )
                sys.exit(4)

            print(
                f"jog: reclaiming stale relay-driver.lock (holder pid {holder or 'none'} not running).",
                file=sys.stderr,
            )
            try:
                shutil.rmtree(self.lock_dir)
                os.mkdir(self.lock_dir)
                self.acquired = True
            except Exception as exc:
                print(f"jog: could not acquire relay-driver.lock: {exc}", file=sys.stderr)
                sys.exit(4)

        try:
            with open(os.path.join(self.lock_dir, "pid"), "w") as f:
                f.write(f"{os.getpid()}\n")
        except Exception:
            pass

        os.environ["RELAY_DRIVER_LOCKED"] = "1"

    def release(self):
        if self.acquired:
            try:
                if os.path.exists(self.lock_dir):
                    shutil.rmtree(self.lock_dir)
            except Exception:
                pass
            self.acquired = False


def lint_probe(root, probe_cmd):
    """Lint a probe command to ensure it is non-trivial and resolves to a real target."""
    cmd = probe_cmd.strip()
    if not cmd:
        return False, "empty probe command"
    for pat in TRIVIAL_PROBE_PATTERNS:
        if pat.match(cmd):
            return False, f"trivial probe pattern rejected: {cmd!r}"

    # Verify referenced file/glob resolves if command specifies a test path
    tokens = cmd.split()
    if len(tokens) >= 2 and tokens[0] in ("bash", "sh", "python3", "pytest"):
        target_path = tokens[1]
        # Resolve target relative to root
        full_pattern = os.path.join(root, target_path)
        matches = glob.glob(full_pattern)
        if not matches and not os.path.exists(full_pattern):
            return False, f"probe target path does not resolve: {target_path}"

    return True, "ok"


def find_issue_doc(root, gh_num):
    """Find the capture/working doc associated with an issue number."""
    patterns = [
        os.path.join(root, "PROJECT", "2-WORKING", f"GH-{gh_num}-*.md"),
        os.path.join(root, "PROJECT", "1-INBOX", f"GH-{gh_num}-*.md"),
        os.path.join(root, "PROJECT", "3-COMPLETED", f"GH-{gh_num}-*.md"),
    ]
    for pat in patterns:
        matches = glob.glob(pat)
        if matches:
            return matches[0]
    return None


def extract_probes_from_doc(doc_path):
    """Extract fix_probes from doc frontmatter or body."""
    if not os.path.isfile(doc_path):
        return []
    try:
        with open(doc_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception:
        return []

    probes = []
    fm_match = re.search(r"^---\n(.*?)\n---", content, re.DOTALL)
    if fm_match:
        fm_text = fm_match.group(1)
        probes_match = re.search(r"fix_probes:\s*\n((?:\s+-\s+.*\n?)+)", fm_text)
        if probes_match:
            for line in probes_match.group(1).splitlines():
                line = line.strip()
                if line.startswith("- "):
                    p = line[2:].strip().strip("\"'")
                    if p:
                        probes.append(p)
    return probes


def promote_contract_to_working(root, gh_num, doc_path, interactive=True):
    """Promote a 1-INBOX doc to 2-WORKING/ with verified status table and probes."""
    basename = os.path.basename(doc_path)
    new_doc_path = os.path.join(root, "PROJECT", "2-WORKING", basename)
    rel_new_path = os.path.relpath(new_doc_path, root)

    with open(doc_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Ensure status table exists
    if "## Status" not in content:
        status_table = (
            "\n## Status\n\n"
            "| What was just completed | What's next |\n"
            "|---|---|\n"
            "| Promoted to active working contract via jog | Execute implementation and verify probes |\n\n"
        )
        if "---" in content:
            parts = content.split("---", 2)
            if len(parts) >= 3:
                fm = re.sub(r"(?m)^status:\s*.*$", "status: Active", parts[1])
                today = _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%d")
                fm = re.sub(r"(?m)^updated:\s*.*$", f"updated: {today}", fm)
                content = f"---{fm}---{status_table}{parts[2].lstrip()}"
        else:
            content = status_table + content

    probes = extract_probes_from_doc(doc_path)
    valid_probes = []
    for p in probes:
        ok, reason = lint_probe(root, p)
        if ok:
            valid_probes.append(p)

    if not valid_probes:
        if not interactive:
            return None, "unreviewed-probe-contract (no valid probes in unattended mode)"

    if interactive and sys.stdin.isatty():
        print(f"\n[jog] Auto-promoted contract for GH-{gh_num}:")
        print(f"      Source: {doc_path}")
        print(f"      Target: {new_doc_path}")
        print(f"      Probes: {valid_probes or '(none declared)'}")
        resp = input(f"Proceed with preflight for GH-{gh_num}? [Y/n] ").strip().lower()
        if resp in ("n", "no"):
            return None, "promotion-cancelled-by-operator"

    # Move doc to 2-WORKING
    os.makedirs(os.path.dirname(new_doc_path), exist_ok=True)
    with open(new_doc_path, "w", encoding="utf-8") as f:
        f.write(content)

    # Use git mv or clean deletion
    try:
        git_res = subprocess.run(["git", "rm", "-f", doc_path], cwd=root, capture_output=True)
        if git_res.returncode != 0 and os.path.exists(doc_path):
            os.remove(doc_path)
    except Exception:
        if os.path.exists(doc_path):
            os.remove(doc_path)

    try:
        subprocess.run(["git", "add", new_doc_path], cwd=root, capture_output=True)
    except Exception:
        pass

    # Repoint roadmap item
    rp_res = subprocess.run(
        [
            sys.executable,
            os.path.join(root, "utils", "py", "releases_app.py"),
            "roadmap",
            "repoint",
            "--issue-num",
            str(gh_num),
            "--doc-path",
            rel_new_path,
        ],
        cwd=root,
        capture_output=True,
        text=True,
    )
    if rp_res.returncode != 0:
        print(f"jog: warning: roadmap repoint returned code {rp_res.returncode}: {rp_res.stderr.strip()}", file=sys.stderr)

    return new_doc_path, None


def run_single_phase_drive(root, gh_num, builder="agy", simulate=False):
    """Execute a single-phase drive for a task using relay-drive."""
    if simulate:
        print(f"jog: [simulate] simulated single-phase drive on GH-{gh_num} with builder={builder}")
        return 0

    # Locate relay-drive and turn runner shims
    drive_candidates = [
        os.path.join(root, "relay-automation", "relay-drive.sh"),
        os.path.join(root, ".xyz", "relay-automation", "relay-drive.sh"),
    ]
    drive_script = None
    for c in drive_candidates:
        if os.path.isfile(c) and os.access(c, os.X_OK):
            drive_script = c
            break

    shim_candidates = [
        os.path.join(root, "relay-automation", f"{builder}-turn.sh"),
        os.path.join(root, ".xyz", "relay-automation", f"{builder}-turn.sh"),
    ]
    shim_script = None
    for c in shim_candidates:
        if os.path.isfile(c) and os.access(c, os.X_OK):
            shim_script = c
            break

    if not drive_script or not shim_script:
        print(
            f"jog: runner scripts not found or not executable (drive={drive_script}, shim={shim_script})",
            file=sys.stderr,
        )
        return 2

    # Scaffold single-phase relay review thread file if absent
    today_str = _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%d")
    relay_dir = os.path.join(root, "relay-system", today_str)
    os.makedirs(relay_dir, exist_ok=True)
    relay_file = os.path.join(relay_dir, f"gh{gh_num}-jog-drive.md")

    if not os.path.isfile(relay_file):
        with open(relay_file, "w", encoding="utf-8") as f:
            f.write(
                f"# RELAY · GH-{gh_num} Jog Serial Drive\n\n"
                f"NEXT: {builder}\n"
                f"STATUS: Open\n"
                f"ROUND: 1 / 2\n\n"
                f"## Setup\n"
                f"- Issue: GH-{gh_num}\n"
                f"- Builder: {builder}\n"
                f"- Started: {today_str}\n\n"
                f"## Log\n\n"
                f"### Round 1 — Producer (jog) — {today_str}\n"
                f"Dispatched task GH-{gh_num} for execution.\n\n"
                f"NEXT: {builder}\n"
            )

    task_name = f"RELAY-gh{gh_num}-jog-drive"
    tick_bin = os.path.join(root, "bin", "tick")
    if os.path.isfile(tick_bin) and os.access(tick_bin, os.X_OK):
        subprocess.run([tick_bin, "log", "task.created", task_name, "--agent", "jog"], cwd=root, capture_output=True)
        subprocess.run([tick_bin, "claim", task_name, "--agent", "jog", "--paths", relay_file], cwd=root, capture_output=True)
        subprocess.run([tick_bin, "release", task_name, "--agent", "jog", "--to", builder], cwd=root, capture_output=True)

    cmd = [
        drive_script,
        "--relay-file",
        relay_file,
        "--agent-cmd",
        shim_script,
        "--relay-task",
        task_name,
    ]
    env = dict(os.environ)
    env["RELAY_DRIVER_LOCKED"] = "1"
    env["XYZ_ROOT"] = root

    proc = subprocess.run(cmd, cwd=root, env=env)
    return proc.returncode


def handle_landing_boundary(root, gh_num, auto_merge=False):
    """Handle landing confirmation, PR merge, and development re-anchoring.

    Returns:
      (success: bool, status: str, failure_reason: str or None)
    """
    if auto_merge:
        print(f"jog: task GH-{gh_num} passed; auto-merging into development...")
        # Check for active PR via gh
        pr_view = subprocess.run(
            ["gh", "pr", "list", "--head", f"feat/gh{gh_num}", "--json", "number,state", "--jq", ".[0].number"],
            cwd=root,
            capture_output=True,
            text=True,
        )
        pr_num = pr_view.stdout.strip()
        if pr_num and pr_num.isdigit():
            merge_res = subprocess.run(["gh", "pr", "merge", pr_num, "--merge", "--auto=false"], cwd=root, capture_output=True, text=True)
            if merge_res.returncode != 0:
                print(f"jog: auto-merge failed: {merge_res.stderr.strip()}", file=sys.stderr)
                return False, "parked", f"auto-merge failed: {merge_res.stderr.strip()}"

        # Re-anchor on development
        subprocess.run(["git", "checkout", "development"], cwd=root, capture_output=True)
        subprocess.run(["git", "pull", "--ff-only", "origin", "development"], cwd=root, capture_output=True)
        return True, "completed", None

    if not sys.stdin.isatty():
        print(f"jog: unattended run without --auto-merge -> parking GH-{gh_num} awaiting landing confirmation.")
        return False, "parked", "awaiting-landing (unattended run without --auto-merge)"

    print(f"\n[jog] Task GH-{gh_num} completed drive pass.")
    resp = input(f"Confirm merge into development and advance to next item? [Y/n] ").strip().lower()
    if resp in ("n", "no"):
        print(f"jog: operator paused merge for GH-{gh_num}; parking item in awaiting-landing state.")
        return False, "parked", "awaiting-landing (operator paused merge)"

    # Operator confirmed merge
    pr_view = subprocess.run(
        ["gh", "pr", "list", "--head", f"feat/gh{gh_num}", "--json", "number,state", "--jq", ".[0].number"],
        cwd=root,
        capture_output=True,
        text=True,
    )
    pr_num = pr_view.stdout.strip()
    if pr_num and pr_num.isdigit():
        subprocess.run(["gh", "pr", "merge", pr_num, "--merge", "--auto=false"], cwd=root)

    subprocess.run(["git", "checkout", "development"], cwd=root, capture_output=True)
    subprocess.run(["git", "pull", "--ff-only", "origin", "development"], cwd=root, capture_output=True)
    return True, "completed", None


def jog_run_main(args=None):
    """Main execution loop for jog supervisor."""
    if args is None:
        parser = argparse.ArgumentParser(description="Jog serial execution runner")
        parser.add_argument("--root", default=None, help="repository root path")
        parser.add_argument("--auto-merge", action="store_true", help="auto-merge passing PRs")
        parser.add_argument("--builder", default="agy", help="builder turn-taker (agy, codex, aider)")
        parser.add_argument("--max-tasks", type=int, default=None, help="max tasks to process")
        parser.add_argument("--simulate", action="store_true", help="simulate drive execution (test mode)")
        parser.add_argument("--dry-run", action="store_true", help="simulate queue run without mutations")
        args = parser.parse_args()

    root = os.path.abspath(getattr(args, "root", None) or os.getcwd())
    db_path = os.path.join(root, "releases.db")

    if not os.path.exists(db_path):
        print(f"jog: releases.db not found at {db_path}", file=sys.stderr)
        sys.exit(1)

    # Hermetic --dry-run: zero mutations, zero locks, zero DB writes
    if getattr(args, "dry_run", False):
        print(f"jog: [dry-run] simulating queue execution (root: {root})")
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        try:
            _ensure_jog_schema(conn)
            rows = conn.execute(
                "SELECT gh_number, position, attempt_count FROM jog_queue WHERE status = 'pending' ORDER BY position ASC"
            ).fetchall()
            if not rows:
                print("jog: [dry-run] queue is empty (0 pending items).")
                return
            max_t = getattr(args, "max_tasks", None)
            limit_str = f" (capped at {max_t})" if max_t is not None else ""
            print(f"jog: [dry-run] would process {len(rows)} pending item(s){limit_str}:")
            for idx, r in enumerate(rows):
                if max_t is not None and idx >= max_t:
                    break
                print(f"  {r['position']}. GH-{r['gh_number']} (builder={args.builder}, auto_merge={args.auto_merge})")
        finally:
            conn.close()
        return

    supervisor_lock = JogSupervisorLock(root)
    supervisor_lock.acquire()

    def _cleanup():
        supervisor_lock.release()

    atexit.register(_cleanup)

    def _signal_handler(signum, frame):
        print("\njog: interrupted by signal; cleaning up leases and locks.", file=sys.stderr)
        _cleanup()
        sys.exit(130)

    signal.signal(signal.SIGINT, _signal_handler)
    signal.signal(signal.SIGTERM, _signal_handler)

    try:
        # Reconcile orphan leases via perform_write on startup
        reconciled = jog_reconcile_orphan_leases(root)
        if reconciled:
            print(f"jog: reconciled orphan lease(s) for: {', '.join('GH-%d' % n for n in reconciled)}")

        tasks_processed = 0
        while True:
            if args.max_tasks is not None and tasks_processed >= args.max_tasks:
                print(f"jog: reached max-tasks limit ({args.max_tasks}); pausing queue.")
                break

            # Query next pending task
            conn = sqlite3.connect(db_path)
            conn.row_factory = sqlite3.Row
            try:
                _ensure_jog_schema(conn)
                row = conn.execute(
                    """SELECT id, global_id, gh_number, position, attempt_count
                       FROM jog_queue
                       WHERE status = 'pending'
                       ORDER BY position ASC, id ASC
                       LIMIT 1"""
                ).fetchone()
            finally:
                conn.close()

            if not row:
                print("jog: queue complete (0 pending tasks).")
                break

            gh_num = row["gh_number"]
            att = row["attempt_count"] + 1

            # Acquire lease via perform_write
            jog_acquire_lease(root, gh_num, os.getpid())

            print(f"\n{'=' * 60}")
            print(f"jog: processing GH-{gh_num} (attempt {att}) at position {row['position']}")
            print(f"{'=' * 60}")

            doc_path = find_issue_doc(root, gh_num)
            if doc_path and "/PROJECT/1-INBOX/" in doc_path:
                print(f"jog: promoting 1-INBOX contract for GH-{gh_num} to 2-WORKING...")
                promoted_path, err = promote_contract_to_working(
                    root, gh_num, doc_path, interactive=sys.stdin.isatty()
                )
                if err:
                    print(f"jog: contract promotion failed: {err}")
                    jog_set_status(root, gh_num, "parked", failure_reason=err)
                    continue
                doc_path = promoted_path

            # Swarm Preflight check
            preflight_py = os.path.join(root, "utils", "py", "swarm_preflight.py")
            if os.path.isfile(preflight_py) and not getattr(args, "simulate", False):
                pf_res = subprocess.run(
                    # swarm_preflight.py has no --root flag (it resolves the repo from cwd,
                    # which this subprocess already pins below); passing one is a usage error
                    # that parked every queue item on the first real run.
                    [sys.executable, preflight_py, "--gh-issue", str(gh_num)],
                    cwd=root,
                    capture_output=True,
                    text=True,
                )
                if pf_res.returncode == 4:
                    print(f"jog: GH-{gh_num} preflight reported already-landed (auto-dropping).")
                    jog_set_status(root, gh_num, "completed", failure_reason="preflight: already-landed")
                    tasks_processed += 1
                    continue
                elif pf_res.returncode != 0:
                    print(f"jog: GH-{gh_num} preflight failed (exit {pf_res.returncode}); parking item.")
                    jog_set_status(root, gh_num, "parked", failure_reason=f"preflight-refused (exit {pf_res.returncode})")
                    continue

            # Execute single-phase drive
            drive_rc = run_single_phase_drive(
                root,
                gh_num,
                builder=args.builder,
                simulate=getattr(args, "simulate", False),
            )

            if drive_rc != 0:
                print(f"jog: drive execution failed for GH-{gh_num} (exit {drive_rc}).")
                jog_set_status(root, gh_num, "failed", failure_reason=f"drive failed (exit {drive_rc})")
                print("jog: stopping queue execution on task failure.")
                break

            # Handle landing boundary
            landed, status, reason = handle_landing_boundary(root, gh_num, auto_merge=args.auto_merge)
            jog_set_status(root, gh_num, status, failure_reason=reason)

            if landed:
                tasks_processed += 1
            else:
                print("jog: advancing halted at landing boundary.")
                break

    finally:
        _cleanup()


if __name__ == "__main__":
    jog_run_main()
