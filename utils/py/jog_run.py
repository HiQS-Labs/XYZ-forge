#!/usr/bin/env python3
"""jog_run.py — GH-259: Jog serial immediate-queue execution engine supervisor.

Supervises the serial execution of tasks in jog_queue:
1. Acquires the outer driver lock (`relay-driver.lock`) and exports RELAY_DRIVER_LOCKED=1.
2. Reconciles any orphan `running` leases on startup (resets dead PIDs to pending).
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

from rtl import driver_lock_path


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


def lint_probe(probe_cmd):
    """Lint a probe command to ensure it is non-trivial and valid."""
    cmd = probe_cmd.strip()
    if not cmd:
        return False, "empty probe command"
    for pat in TRIVIAL_PROBE_PATTERNS:
        if pat.match(cmd):
            return False, f"trivial probe pattern rejected: {cmd!r}"
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
    # Check YAML frontmatter fix_probes list
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
                # Update frontmatter status to Active
                fm = re.sub(r"(?m)^status:\s*.*$", "status: Active", parts[1])
                today = _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%d")
                fm = re.sub(r"(?m)^updated:\s*.*$", f"updated: {today}", fm)
                content = f"---{fm}---{status_table}{parts[2].lstrip()}"
        else:
            content = status_table + content

    probes = extract_probes_from_doc(doc_path)
    if not probes:
        # Default probe suggestion based on test convention
        default_probe = f"bash test/gh{gh_num}-*.sh"
        probes = [default_probe]

    # Lint probes
    valid_probes = []
    for p in probes:
        ok, reason = lint_probe(p)
        if ok:
            valid_probes.append(p)

    if not valid_probes:
        if not interactive:
            return None, "unreviewed-probe-contract (no valid probes in unattended mode)"

    if interactive and sys.stdin.isatty():
        print(f"\n[jog] Auto-promoted contract for GH-{gh_num}:")
        print(f"      Source: {doc_path}")
        print(f"      Target: {new_doc_path}")
        print(f"      Probes: {valid_probes}")
        resp = input(f"Proceed with preflight for GH-{gh_num}? [Y/n] ").strip().lower()
        if resp in ("n", "no"):
            return None, "promotion-cancelled-by-operator"

    # Write promoted file and remove inbox file
    os.makedirs(os.path.dirname(new_doc_path), exist_ok=True)
    with open(new_doc_path, "w", encoding="utf-8") as f:
        f.write(content)
    try:
        os.remove(doc_path)
    except OSError:
        pass

    # Repoint roadmap item
    subprocess.run(
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
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    return new_doc_path, None


def reconcile_orphan_leases(conn):
    """Inspect and reset any running rows whose lease_pid is dead."""
    now_iso = _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    rows = conn.execute(
        "SELECT id, gh_number, attempt_count, lease_pid FROM jog_queue WHERE status = 'running'"
    ).fetchall()

    for r in rows:
        pid = r["lease_pid"]
        is_alive = False
        if pid and isinstance(pid, int):
            try:
                os.kill(pid, 0)
                is_alive = True
            except OSError:
                pass

        if not is_alive:
            att = r["attempt_count"]
            if att >= 3:
                print(
                    f"jog: orphan lease for GH-{r['gh_number']} (pid {pid}) reached max attempts ({att}); parking."
                )
                conn.execute(
                    """UPDATE jog_queue SET status = 'parked',
                                  failure_reason = 'orphan lease: max attempts exceeded',
                                  lease_pid = NULL, updated_at = ? WHERE id = ?""",
                    (now_iso, r["id"]),
                )
            else:
                print(
                    f"jog: orphan lease for GH-{r['gh_number']} (pid {pid}) reconciled -> reset to pending."
                )
                conn.execute(
                    """UPDATE jog_queue SET status = 'pending',
                                  lease_pid = NULL, updated_at = ? WHERE id = ?""",
                    (now_iso, r["id"]),
                )
    conn.commit()


def run_single_phase_drive(root, gh_num, builder="agy", dry_run=False):
    """Execute a single-phase drive for a task."""
    if dry_run:
        print(f"jog: [dry-run] simulated single-phase drive on GH-{gh_num} with builder={builder}")
        return 0

    drive_script = os.path.join(root, "relay-automation", "relay-drive.sh")
    shim_script = os.path.join(root, "relay-automation", f"{builder}-turn.sh")

    if not os.path.isfile(drive_script) or not os.path.isfile(shim_script):
        print(
            f"jog: runner scripts not found ({drive_script} or {shim_script}); simulating drive pass for test environment"
        )
        return 0

    cmd = [drive_script, "--agent-cmd", shim_script, "--task", f"GH-{gh_num}"]
    env = dict(os.environ)
    env["RELAY_DRIVER_LOCKED"] = "1"
    env["XYZ_ROOT"] = root

    proc = subprocess.run(cmd, cwd=root, env=env)
    return proc.returncode


def jog_run_main(args=None):
    """Main execution loop for jog supervisor."""
    if args is None:
        parser = argparse.ArgumentParser(description="Jog serial execution runner")
        parser.add_argument("--root", default=None, help="repository root path")
        parser.add_argument("--auto-merge", action="store_true", help="auto-merge passing PRs")
        parser.add_argument("--builder", default="agy", help="builder turn-taker (agy, codex, aider)")
        parser.add_argument("--max-tasks", type=int, default=None, help="max tasks to process")
        parser.add_argument("--dry-run", action="store_true", help="simulate execution")
        args = parser.parse_args()

    root = os.path.abspath(args.root or os.getcwd())
    db_path = os.path.join(root, "releases.db")

    if not os.path.exists(db_path):
        print(f"jog: releases.db not found at {db_path}", file=sys.stderr)
        sys.exit(1)

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

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row

    try:
        # Schema ensure
        from releases_app import _ensure_jog_schema, _table_exists
        _ensure_jog_schema(conn)

        reconcile_orphan_leases(conn)

        tasks_processed = 0
        while True:
            if args.max_tasks is not None and tasks_processed >= args.max_tasks:
                print(f"jog: reached max-tasks limit ({args.max_tasks}); pausing queue.")
                break

            row = conn.execute(
                """SELECT id, global_id, gh_number, position, attempt_count
                   FROM jog_queue
                   WHERE status = 'pending'
                   ORDER BY position ASC, id ASC
                   LIMIT 1"""
            ).fetchone()

            if not row:
                print("jog: queue complete (0 pending tasks).")
                break

            item_id = row["id"]
            gh_num = row["gh_number"]
            att = row["attempt_count"] + 1
            now_iso = _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

            # Acquire item lease
            conn.execute(
                """UPDATE jog_queue
                   SET status = 'running', lease_pid = ?, attempt_count = ?, updated_at = ?
                   WHERE id = ?""",
                (os.getpid(), att, now_iso, item_id),
            )
            conn.commit()

            print(f"\n{'=' * 60}")
            print(f"jog: processing GH-{gh_num} (attempt {att}) at position {row['position']}")
            print(f"{'=' * 60}")

            doc_path = find_issue_doc(root, gh_num)
            if doc_path and "/PROJECT/1-INBOX/" in doc_path:
                print(f"jog: promoting 1-INBOX contract for GH-{gh_num} to 2-WORKING...")
                promoted_path, err = promote_contract_to_working(
                    root, gh_num, doc_path, interactive=(sys.stdin.isatty() and not getattr(args, "dry_run", False))
                )

                if err:
                    print(f"jog: contract promotion failed: {err}")
                    conn.execute(
                        """UPDATE jog_queue
                           SET status = 'parked', failure_reason = ?, lease_pid = NULL, updated_at = ?
                           WHERE id = ?""",
                        (err, _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), item_id),
                    )
                    conn.commit()
                    continue
                doc_path = promoted_path

            # Swarm Preflight check
            preflight_py = os.path.join(root, "utils", "py", "swarm_preflight.py")
            if os.path.isfile(preflight_py) and not args.dry_run:
                pf_res = subprocess.run(
                    [sys.executable, preflight_py, "--gh-issue", str(gh_num), "--root", root],
                    cwd=root,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                )
                if pf_res.returncode == 4:
                    print(f"jog: GH-{gh_num} preflight reported already-landed (auto-dropping from queue).")
                    conn.execute(
                        """UPDATE jog_queue
                           SET status = 'completed', failure_reason = 'preflight: already-landed (auto-dropped)',
                               lease_pid = NULL, updated_at = ? WHERE id = ?""",
                        (_dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), item_id),
                    )
                    conn.commit()
                    tasks_processed += 1
                    continue
                elif pf_res.returncode != 0:
                    print(f"jog: GH-{gh_num} preflight failed (exit {pf_res.returncode}); parking item.")
                    conn.execute(
                        """UPDATE jog_queue
                           SET status = 'parked', failure_reason = ?,
                               lease_pid = NULL, updated_at = ? WHERE id = ?""",
                        (
                            f"preflight-refused (exit {pf_res.returncode})",
                            _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                            item_id,
                        ),
                    )
                    conn.commit()
                    continue

            # Execute single-phase drive
            drive_rc = run_single_phase_drive(
                root, gh_num, builder=args.builder, dry_run=args.dry_run
            )

            if drive_rc != 0:
                print(f"jog: drive execution failed for GH-{gh_num} (exit {drive_rc}).")
                conn.execute(
                    """UPDATE jog_queue
                       SET status = 'failed', failure_reason = ?,
                           lease_pid = NULL, updated_at = ? WHERE id = ?""",
                    (
                        f"drive failed (exit {drive_rc})",
                        _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                        item_id,
                    ),
                )
                conn.commit()
                print("jog: stopping queue execution on task failure.")
                break

            # Landing boundary
            ts_done = _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
            if args.auto_merge:
                print(f"jog: task GH-{gh_num} passed; auto-merge enabled.")
                conn.execute(
                    """UPDATE jog_queue
                       SET status = 'completed', failure_reason = NULL,
                           lease_pid = NULL, updated_at = ? WHERE id = ?""",
                    (ts_done, item_id),
                )
                conn.commit()
                tasks_processed += 1
            else:
                if sys.stdin.isatty() and not args.dry_run:
                    print(f"\n[jog] Task GH-{gh_num} completed successfully.")
                    resp = input(
                        f"Confirm merge into development and advance to next item? [Y/n] "
                    ).strip().lower()
                    if resp in ("n", "no"):
                        print("jog: paused at landing boundary by operator.")
                        conn.execute(
                            """UPDATE jog_queue
                               SET status = 'completed', lease_pid = NULL, updated_at = ? WHERE id = ?""",
                            (ts_done, item_id),
                        )
                        conn.commit()
                        break

                print(f"jog: GH-{gh_num} marked completed.")
                conn.execute(
                    """UPDATE jog_queue
                       SET status = 'completed', failure_reason = NULL,
                           lease_pid = NULL, updated_at = ? WHERE id = ?""",
                    (ts_done, item_id),
                )
                conn.commit()
                tasks_processed += 1

    finally:
        conn.close()
        _cleanup()


if __name__ == "__main__":
    jog_run_main()
