#!/usr/bin/env python3
"""GH-534 Phase C — the durable attempt record, its record-adjacent lock, and the dependent map.

Collected by test/gh436-merge-cleanup.py. Reuses the Phase B LedgerFixture (bare origin + gh stub)
for the script-side runs; the record tests below need only a directory and the CLI.
"""
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "skills" / "merge-cleanup" / "scripts"))
sys.path.insert(0, str(REPO / "utils" / "py"))
sys.path.insert(0, str(REPO / "test"))

import attempt_record as ar  # noqa: E402
import contextlib
import io
import ledger_merge  # noqa: E402
import merge_cleanup  # noqa: E402
import scan_clones  # noqa: E402
import unittest.mock as mock
from attempt_record import RECORD_ENV, RecordError, RecordLock, reserve  # noqa: E402
from gh534_phase_a_tests import TestA2Provenance, TestA4OpenHandles, TestA4TickClaims, TestA5FailClosed, TestA5FreshInspection  # noqa: E402,F401
from gh534_phase_b_tests import LedgerFixture, TestE6Gate, TestPhase5EndToEnd, _app, _git, commit_all, park  # noqa: E402,F401

CLI = REPO / "skills" / "merge-cleanup" / "scripts" / "attempt_record.py"


GH_RUN_WRAPPER = r'''#!/usr/bin/env python3
"""Phase C extension: answer gh run list, delegating every other command to Phase B."""
import json, os, pathlib, shutil, subprocess, sys, tempfile

state_path = os.environ["GH_STATE"]
args = sys.argv[1:]
if args[:2] != ["run", "list"]:
    backend = os.path.join(os.path.dirname(__file__), "gh-phase-b")
    os.execv(backend, [backend] + args)

with open(state_path) as fh:
    state = json.load(fh)
state.setdefault("calls", []).append(args)
if not state.get("hosted_wait"):
    with open(state_path, "w") as fh:
        json.dump(state, fh, indent=1)
    print("[]")
    raise SystemExit(0)

def git(cwd, *argv):
    return subprocess.run(["git", "-C", str(cwd)] + list(argv),
                          capture_output=True, text=True, check=True)

state["run_list_count"] = state.get("run_list_count", 0) + 1
if not state.get("hosted_head"):
    state["hosted_head"] = git(
        state["probe"], "ls-remote", state["origin"],
        "refs/heads/" + state["base"],
    ).stdout.split()[0]

if state["run_list_count"] == 1:
    run = {"databaseId": 62901, "status": "in_progress", "conclusion": ""}
else:
    if not state.get("hosted_commit"):
        work = tempfile.mkdtemp(prefix="gh629-hosted.")
        try:
            subprocess.run(["git", "clone", "-q", state["origin"], work], check=True)
            git(work, "config", "user.email", "hosted@stub")
            git(work, "config", "user.name", "hosted-reconcile")
            git(work, "checkout", "-q", state["base"])
            pathlib.Path(work, "hosted-reconcile.txt").write_text("hosted\n")
            git(work, "add", "hosted-reconcile.txt")
            git(work, "commit", "-q", "-m", "hosted reconcile")
            state["hosted_commit"] = git(work, "rev-parse", "HEAD").stdout.strip()
            git(work, "push", "-q", "origin", state["base"])
        finally:
            shutil.rmtree(work, ignore_errors=True)
    run = {"databaseId": 62901, "status": "completed", "conclusion": "success"}

with open(state_path, "w") as fh:
    json.dump(state, fh, indent=1)
print(json.dumps([run]))
'''


def cli(cwd, *args, env=None, timeout=None):
    e = {k: v for k, v in os.environ.items() if k != RECORD_ENV}
    e.update(env or {})
    return subprocess.run([sys.executable, str(CLI)] + list(args), cwd=str(cwd), env=e,
                          capture_output=True, text=True, timeout=timeout)


class TestCRecord(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="gh534c."))
        self.addCleanup(lambda: subprocess.run(["rm", "-rf", str(self.tmp)]))
        self.primary = self.tmp / "primary"
        self.clone1 = self.tmp / "clone1"
        self.clone2 = self.tmp / "clone2"
        for d in (self.primary, self.clone1, self.clone2):
            d.mkdir()
        self.origin = "git@github.com:HiQS-Labs/XYZ-forge.git"
        self.record = ar.record_path(self.primary, self.origin, 538)
        self.fresh = ar.new_record(538, self.origin, base_sha="b" * 40)
        self.env = {RECORD_ENV: str(self.record)}

    def test_schema_and_pinned_location(self):
        self.assertEqual(self.record, self.primary.resolve() / ".tick" / "merge-cleanup" / "HiQS-Labs-XYZ-forge" / "pr-538.json")
        self.assertEqual(ar.record_path(self.primary, "https://github.com/HiQS-Labs/XYZ-forge", 538), self.record)
        self.assertEqual(ar.repo_slug("/Users/x/fixtures/origin.git"), "fixtures-origin")
        idx, why = reserve(self.record, by="script", head_sha="a" * 40, rung="B1", clone_path="/c", create=self.fresh)
        self.assertEqual(idx, 0)
        rec = json.loads(self.record.read_text())
        for k in ("pr", "repo", "base_sha", "merge_base", "attempts", "conflict_files", "last_side_touched"):
            self.assertIn(k, rec)
        a = rec["attempts"][0]
        for k in ("by", "head_sha", "rung", "started", "outcome", "clone_path"):
            self.assertIn(k, a)
        self.assertEqual((a["by"], a["rung"], a["outcome"]), ("script", "B1", "in_progress"))
        ar.finish(self.record, 0, "handoff", reason="same-key")
        self.assertEqual(json.loads(self.record.read_text())["attempts"][0]["outcome"], "handoff")

    def test_two_clones_one_coordinator_third_repair_is_refused(self):
        """Caller repair from clone 1, script repair from clone 2 — same physical record; the third
        from EITHER clone is refused."""
        r = cli(self.clone1, "reserve", "--rung", "ponytail", "--head", "1" * 40, env=self.env)
        self.assertEqual(r.returncode, 2, r.stderr)  # no record yet: a caller never creates one
        ar.save(self.record, self.fresh)
        r = cli(self.clone1, "reserve", "--rung", "ponytail", "--head", "1" * 40, env=self.env)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("index=0", r.stdout)
        cwd = os.getcwd()
        os.chdir(self.clone2)
        try:
            idx, _ = reserve(self.record, by="script", head_sha="2" * 40, rung="B1")
        finally:
            os.chdir(cwd)
        self.assertEqual(idx, 1)
        third_cli = cli(self.clone1, "reserve", "--rung", "start-task", "--head", "3" * 40, env=self.env)
        self.assertEqual(third_cli.returncode, 3, third_cli.stdout)
        self.assertIn("budget exhausted", third_cli.stdout)
        os.chdir(self.clone2)
        try:
            idx3, why3 = reserve(self.record, by="script", head_sha="3" * 40, rung="B1")
        finally:
            os.chdir(cwd)
        self.assertIsNone(idx3)
        rec = json.loads(self.record.read_text())
        self.assertEqual([a["by"] for a in rec["attempts"]], ["caller", "script"])
        self.assertFalse((self.clone1 / ".tick").exists())
        self.assertFalse((self.clone2 / ".tick").exists())

    def test_diagnosis_and_recon_do_not_consume_budget(self):
        ar.save(self.record, self.fresh)
        for kind in ("diagnosis", "recon", "budget_exceeded"):
            self.assertEqual(cli(self.clone1, "note", "--kind", kind, "--text", "x", env=self.env).returncode, 0)
        self.assertEqual(ar.repair_count(ar.load(self.record)), 0)
        self.assertEqual(reserve(self.record, "caller", "1" * 40, "ponytail")[0], 0)
        ar.note(self.record, "recon", {"files": 3})
        self.assertEqual(reserve(self.record, "script", "2" * 40, "B1")[0], 1)
        rec = ar.load(self.record)
        self.assertEqual(len(rec["pre_repair"]["diagnosis"]), 1)
        self.assertEqual(rec["attempts"][0]["recon"][0]["data"], {"files": 3})
        with self.assertRaises(RecordError):
            reserve(self.record, "caller", "9" * 40, "recon")  # recon is not a repair rung

    def test_a_repair_that_mints_a_new_head_does_not_reset_the_budget(self):
        ar.save(self.record, self.fresh)
        idx, _ = reserve(self.record, "script", "a" * 40, "B1")
        ar.finish(self.record, idx, "resolved", commit="c" * 40)
        idx, _ = reserve(self.record, "caller", "c" * 40, "ponytail")  # the head the first repair produced
        ar.finish(self.record, idx, "failed")
        idx3, why = reserve(self.record, "caller", "d" * 40, "ponytail")
        self.assertIsNone(idx3)
        self.assertIn("2 repair attempts", why)

    def test_two_racers_for_the_last_slot_exactly_one_wins(self):
        ar.save(self.record, self.fresh)
        reserve(self.record, "caller", "1" * 40, "ponytail")
        gate = RecordLock(self.record).__enter__()  # hold the record lock so both racers queue on it
        env = dict(self.env, **{ar.LOCK_TIMEOUT_ENV: "10"})
        procs = [subprocess.Popen([sys.executable, str(CLI), "reserve", "--rung", "ponytail", "--head", h * 40],
                                  cwd=str(self.clone1 if i == 0 else self.clone2), env={**os.environ, **env},
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                 for i, h in enumerate("ab")]
        time.sleep(0.5)  # both are now blocked on the lock
        self.assertTrue(all(p.poll() is None for p in procs), "a racer finished while the lock was held")
        gate.__exit__(None, None, None)
        rcs = sorted(p.wait(timeout=20) for p in procs)
        self.assertEqual(rcs, [0, 3], [(p.stdout.read(), p.stderr.read()) for p in procs])
        self.assertEqual(ar.repair_count(ar.load(self.record)), 2)

    def test_worker_under_a_held_driver_mkdir_lock_still_reserves(self):
        """The record lock is independent of the driver's mkdir lock (a nominal 'same lock' fails)."""
        from rtl import driver_lock_path
        subprocess.run(["git", "init", "-q", str(self.primary)], check=True)
        lock_dir, _ = driver_lock_path(str(self.primary))
        os.mkdir(lock_dir)
        (Path(lock_dir) / "pid").write_text(str(os.getpid()))  # a LIVE driver
        ar.save(self.record, self.fresh)
        r = cli(self.clone1, "reserve", "--rung", "ponytail", "--head", "1" * 40, env=self.env, timeout=10)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertTrue(Path(lock_dir).is_dir(), "the driver lock was touched")
        self.assertEqual(RecordLock(self.record).lock_path, self.record.with_name("pr-538.json.lock"))
        self.assertNotEqual(str(RecordLock(self.record).lock_path), lock_dir)

    def test_lock_timeout_stops_the_attempt_and_counts_nothing(self):
        ar.save(self.record, self.fresh)
        with RecordLock(self.record):
            with self.assertRaises(RecordError) as cm:
                reserve(self.record, "caller", "1" * 40, "ponytail", timeout_s=0.2)
            self.assertIn("STOPPED", str(cm.exception))
            r = cli(self.clone1, "reserve", "--rung", "ponytail", "--head", "1" * 40,
                    env=dict(self.env, **{ar.LOCK_TIMEOUT_ENV: "0.2"}), timeout=10)
            self.assertEqual(r.returncode, 2)
            self.assertIn("lock-timeout", r.stderr)
        self.assertEqual(ar.repair_count(ar.load(self.record)), 0)

    def test_worker_without_record_env_or_with_unreadable_record_stops(self):
        r = cli(self.clone1, "reserve", "--rung", "ponytail", "--head", "1" * 40, env={})
        self.assertEqual(r.returncode, 2)
        self.assertIn(RECORD_ENV, r.stderr)
        self.assertFalse((self.clone1 / ".tick").exists(), "a worker derived a record root from its CWD")
        r = cli(self.clone1, "reserve", "--rung", "ponytail", "--head", "1" * 40, env={RECORD_ENV: "rel/pr-1.json"})
        self.assertEqual(r.returncode, 2)
        self.assertIn("not absolute", r.stderr)
        self.record.parent.mkdir(parents=True)
        self.record.write_text("{not json")
        r = cli(self.clone1, "reserve", "--rung", "ponytail", "--head", "1" * 40, env=self.env)
        self.assertEqual(r.returncode, 2)
        self.assertIn("malformed", r.stderr)
        self.record.write_text(json.dumps({"attempts": "nope"}))
        self.assertEqual(cli(self.clone1, "show", env=self.env).returncode, 2)


class TestCScript(LedgerFixture):
    """The orchestrator's side: B1 reserves a slot at the pinned coordinator, parks at the ceiling,
    and never attempts a dependent of a parked/handed-off PR."""

    def setUp(self):
        super().setUp()
        backend = self.tmp / "gh-phase-b"
        shutil.copy(self.gh, backend)
        backend.chmod(0o755)
        self.gh.write_text(GH_RUN_WRAPPER)
        self.gh.chmod(0o755)
        env = mock.patch.dict(os.environ, {merge_cleanup.HOSTED_POLL_ENV: "0",
                                            merge_cleanup.HOSTED_GRACE_ENV: "0"})
        env.start()
        self.addCleanup(env.stop)

    def same_key_conflict(self):
        self.branch("feat/a", 1, lambda r: _app(r, "roadmap", "update", "--issue-num", "100", "--section", "Completed"))
        self.branch("feat/b", 2, lambda r: _app(r, "roadmap", "update", "--issue-num", "100", "--section", "In progress"))

    def record_for(self, n):
        return ar.record_path(self.primary, str(self.origin), n)

    def test_two_ledger_prs_emit_only_after_fast_forward_and_finish_durable(self):
        """GH-624: a witnessed event cannot dirty the primary before either fast-forward.

        Both PRs touch the ledger and emit pr_merged in one execute run. The pre-fix ordering
        (emit before merge --ff-only) fails this scenario instead of reaching the second landing.
        """
        self.branch("feat/a", 1, lambda r: park(r, 200, "from PR 1"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "from PR 2"))
        self.st["prs"]["1"]["body"] = "Closes #200"
        self.st["prs"]["2"]["body"] = "Closes #201"
        self.save()

        rc = self.run_main()

        self.assertEqual(rc, 0, self.err)
        self.assertEqual({p["state"] for p in self.load()["prs"].values()}, {"MERGED"})
        self.assertEqual(_git(self.primary, "status", "--porcelain").stdout, "")
        self.assertEqual(_git(self.primary, "rev-parse", "HEAD").stdout.strip(), self.origin_dev())
        with sqlite3.connect(self.primary / "releases.db") as conn:
            events = conn.execute(
                "SELECT gh_number FROM work_events WHERE event='pr_merged' ORDER BY id"
            ).fetchall()
        self.assertEqual(events, [(200,), (201,)])
        run_lists = [c for c in self.load()["calls"] if c[:2] == ["run", "list"]]
        self.assertEqual(len(run_lists), 2, "each merged head must check for its hosted reconcile run")

    def test_hosted_run_is_waited_for_and_fast_forwarded_before_emission(self):
        """GH-629: an active hosted writer wins; the local writer must never race it."""
        self.branch("feat/a", 1, lambda r: park(r, 200, "from PR 1"))
        self.st["prs"]["1"]["body"] = "Closes #200"
        self.st["hosted_wait"] = True
        self.save()

        with mock.patch.object(
                merge_cleanup, "run_local_wave_reconcile",
                wraps=merge_cleanup.run_local_wave_reconcile) as local_reconcile:
            rc = self.run_main()

        self.assertEqual(rc, 0, self.err)
        local_reconcile.assert_not_called()
        state = self.load()
        self.assertGreaterEqual(state.get("run_list_count", 0), 2)
        self.assertTrue((self.primary / "hosted-reconcile.txt").is_file())
        self.assertEqual(_git(self.primary, "status", "--porcelain").stdout, "")
        self.assertEqual(_git(self.primary, "rev-parse", "HEAD").stdout.strip(), self.origin_dev())
        self.assertEqual(
            _git(self.primary, "merge-base", "--is-ancestor", state["hosted_commit"], "HEAD").returncode,
            0,
        )

    def test_b1_attempt_is_recorded_at_the_pinned_coordinator(self):
        self.same_key_conflict()
        cwd = os.getcwd()
        os.chdir(self.tmp / "w-2")  # run from a disposable clone, NOT the primary
        try:
            rc = self.run_main()
        finally:
            os.chdir(cwd)
        self.assertEqual(rc, 3)
        rec = ar.load(self.record_for(2))
        self.assertEqual(len(rec["attempts"]), 1)
        a = rec["attempts"][0]
        self.assertEqual((a["by"], a["rung"], a["outcome"]), ("script", "B1", "handoff"))
        self.assertIn("same-key", a["reason"])
        self.assertTrue(rec["conflict_files"])
        self.assertIn(f"export {RECORD_ENV}={self.record_for(2)}", self.err)
        self.assertFalse((self.tmp / "w-2" / ".tick" / "merge-cleanup").exists())

    def test_two_clones_one_coordinator_third_repair_is_refused(self):
        """THE PIN: two caller repairs already in the pinned record (written from another clone) →
        the script's B1 is refused and the PR is parked. RED CONTROL: a record root derived from CWD
        reads an empty record and runs B1 anyway."""
        self.same_key_conflict()
        record = self.record_for(2)
        ar.save(record, ar.new_record(2, str(self.origin)))
        env = {RECORD_ENV: str(record)}
        self.assertEqual(cli(self.tmp / "w-1", "reserve", "--rung", "ponytail", "--head", "1" * 40, env=env).returncode, 0)
        self.assertEqual(cli(self.tmp / "w-1", "finish", "--index", "0", "--outcome", "failed", env=env).returncode, 0)
        self.assertEqual(cli(self.tmp / "w-1", "reserve", "--rung", "start-task", "--head", "2" * 40, env=env).returncode, 0)
        cwd = os.getcwd()
        os.chdir(self.tmp / "w-2")
        try:
            rc = self.run_main()
        finally:
            os.chdir(cwd)
        self.assertEqual(rc, 3)
        self.assertIn("PARKED — budget exhausted", self.err)
        self.assertNotIn("  B1:", self.err, "B1 ran despite an exhausted budget")
        self.assertEqual(len(ar.load(record)["attempts"]), 2)
        st = self.load()
        self.assertEqual((st["prs"]["1"]["state"], st["prs"]["2"]["state"]), ("MERGED", "OPEN"))
        self.assertFalse(any(c[:3] == ["pr", "merge", "2"] for c in st["calls"]))

    def test_unreadable_record_stops_the_script(self):
        self.same_key_conflict()
        record = self.record_for(2)
        record.parent.mkdir(parents=True)
        record.write_text("{broken")
        rc = self.run_main()
        self.assertEqual(rc, 2)
        self.assertIn("malformed", self.err)
        self.assertEqual(self.load()["prs"]["2"]["state"], "OPEN")

    def test_dry_run_reserves_nothing(self):
        self.same_key_conflict()
        rc = self.run_main(execute=False)
        self.assertEqual(rc, 0)
        self.assertFalse(self.record_for(2).exists())
        self.assertFalse(self.record_for(1).exists())

    def test_dependent_of_a_handed_off_pr_is_not_attempted_and_an_independent_pr_proceeds(self):
        self.same_key_conflict()  # PR 2 will be handed off
        self.branch("feat/c", 3, lambda r: park(r, 300, "dependent"))
        self.branch("feat/d", 4, lambda r: park(r, 301, "independent"))
        self.st["prs"]["3"]["body"] = "Depends on #2"
        self.save()
        rc = self.run_main()
        self.assertEqual(rc, 3)
        st = self.load()
        self.assertEqual({n: p["state"] for n, p in st["prs"].items()},
                         {"1": "MERGED", "2": "OPEN", "3": "OPEN", "4": "MERGED"})
        self.assertIn("PR #3: NOT attempted — depends on #2 (handoff)", self.err)
        self.assertFalse(any(c[:2] == ["pr", "view"] and c[2] == "3" for c in st["calls"]), "PR 3 was refreshed, i.e. attempted")
        self.assertIn(301, self.dev_rows())
        self.assertNotIn(300, self.dev_rows())
        self.assertFalse(self.record_for(3).exists())
        self.pruner.assert_not_called()  # a handoff is still a non-zero Phase 5; teardown does not run

    def test_omitted_primary_is_refused_and_no_record_root_is_minted(self):
        """R1-2: the coordinator is never the CWD. Run the orchestrator from a disposable clone
        with no --primary: it must stop before any phase and mint no record root anywhere."""
        self.same_key_conflict()
        foreign = self.tmp / "w-2"
        r = subprocess.run([sys.executable, str(MC_SRC), "--root", str(self.tmp / "no-roots"), "--execute"],
                           cwd=str(foreign), capture_output=True, text=True, env={**os.environ})
        self.assertEqual(r.returncode, 2, r.stderr)
        self.assertIn("--primary", r.stderr)
        for d in (foreign, self.primary, self.tmp):
            self.assertFalse((d / ".tick" / "merge-cleanup").exists(), f"a record root was minted under {d}")
        self.assertEqual({p["state"] for p in self.load()["prs"].values()}, {"OPEN"})

    def test_teardown_refuses_without_trash(self):
        """R1-4: Trash is the only removal path; with no ~/.Trash the clone is refused, not rmtree'd."""
        victim = self.clone("victim")
        rec = {"path": str(victim), "name": "victim", "checkout_type": "standalone_clone", "type": "standalone_clone", "disposition": "SAFE_REMOVE_CLONE",
               "scan_disposition": "SAFE_REMOVE_CLONE", "parent_clone": None}
        fake_home = self.tmp / "home-without-trash"
        fake_home.mkdir()
        err = io.StringIO()
        roots = mock.patch.object(scan_clones, "DEFAULT_SAFE_ROOTS", [self.tmp.resolve()])  # the fixture dir is a safe root here
        roots.start()
        self.addCleanup(roots.stop)
        with mock.patch.object(Path, "home", return_value=fake_home), contextlib.redirect_stderr(err):
            ok = merge_cleanup.teardown_checkout(rec, dry_run=False)
        self.assertFalse(ok)
        self.assertTrue(victim.is_dir(), "the clone was removed without Trash")
        self.assertIn("REFUSING", err.getvalue())
        self.assertFalse((fake_home / ".Trash").exists())
        # With Trash present the same record is moved there, never rmtree'd.
        (fake_home / ".Trash").mkdir()
        with mock.patch.object(Path, "home", return_value=fake_home), contextlib.redirect_stderr(err):
            ok = merge_cleanup.teardown_checkout(rec, dry_run=False)
        self.assertTrue(ok)
        self.assertFalse(victim.exists())
        self.assertTrue(any(d.name.startswith("victim-") for d in (fake_home / ".Trash").iterdir()))

    # --- R1-3: the three B1 acceptance cases that had no direct pin ---------------------------
    def test_view_deletion_on_the_pr_side_is_preserved_through_b1(self):
        """A view un-adopted on the PR side while the integration side regenerated it (delete/modify)
        stays deleted after B1; the resolver honours the deletion, the rows still merge."""
        seed = self.clone("seed-view")
        (seed / "RELEASES-PREVIEW.html").write_text("baked view v0\n")
        commit_all(seed, "adopt preview")
        _git(seed, "push", "-q", "origin", "development")
        def pr1(r):
            park(r, 200, "from PR 1")
            (r / "RELEASES-PREVIEW.html").write_text("baked view v1 (regenerated)\n")
        def pr2(r):
            park(r, 201, "from PR 2")
            (r / "RELEASES-PREVIEW.html").unlink()
        self.branch("feat/a", 1, pr1)
        self.branch("feat/b", 2, pr2)
        rc = self.run_main()
        self.assertEqual(rc, 0, self.err)
        self.assertEqual({p["state"] for p in self.load()["prs"].values()}, {"MERGED"})
        self.assertEqual(self.dev_rows(), [100, 101, 200, 201])
        c = self.clone("verify-view")
        self.assertFalse((c / "RELEASES-PREVIEW.html").exists(), "the deleted view was resurrected")

    def test_generator_failure_means_no_push(self):
        """The resolver (rebuild + view generation) failing → B1 stops, nothing is pushed to the PR."""
        self.same_key_free_conflict()
        real = ledger_merge._run
        def failing(argv, cwd, **kw):
            if any(str(a).endswith("releases-merge-resolve.sh") for a in argv):
                return subprocess.CompletedProcess(argv, 1, stdout="", stderr="generator exploded (injected)")
            return real(argv, cwd, **kw)
        before = self.pr_head("feat/b")
        with mock.patch.object(ledger_merge, "_run", side_effect=failing):
            rc = self.run_main()
        self.assertEqual(rc, 2)
        self.assertIn("resolver refused", self.err)
        self.assertEqual(self.pr_head("feat/b"), before, "the PR branch was pushed despite a generator failure")
        self.assertEqual(self.load()["prs"]["2"]["state"], "OPEN")

    def test_genuinely_invalid_final_head_fails_second_clone_validation_and_is_not_pushed(self):
        """Not a mock of the validator: B1 is made to commit a corrupt ledger; the SECOND clone's
        real `releases check` goes red and the head is never pushed."""
        self.same_key_free_conflict()
        def corrupt_b1(clone, execute):
            for f in ("releases.sql", "releases.db"):
                (clone / f).write_text("corrupt\n")
            _git(clone, "add", "-A")
            _git(clone, "commit", "-q", "-m", "bad merge")
            head = _git(clone, "rev-parse", "HEAD").stdout.strip()
            return {"resolved": True, "handoff": False, "reason": "x", "log": [], "commit": head, "conflict_set": ["releases.sql"]}
        before = self.pr_head("feat/b")
        with mock.patch.object(merge_cleanup, "resolve_ledger_conflict", side_effect=corrupt_b1):
            rc = self.run_main()
        self.assertEqual(rc, 2)
        self.assertIn("failed validation", self.err)
        self.assertIn("releases check red in the second clone", self.err)
        self.assertEqual(self.pr_head("feat/b"), before, "an invalid head was pushed")
        self.assertEqual(self.load()["prs"]["2"]["state"], "OPEN")

    def same_key_free_conflict(self):
        """Two disjoint parks: a real ledger conflict that B1 WOULD resolve."""
        self.branch("feat/a", 1, lambda r: park(r, 200, "from PR 1"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "from PR 2"))

    def pr_head(self, branch):
        return _git(self.probe, "ls-remote", str(self.origin), f"refs/heads/{branch}").stdout.split()[0]


class TestB1SchemaGuard(unittest.TestCase):
    """R1-1: non-row dump content (DDL/unknown statements) differing from base on either side is
    never disjoint — the classifier hands off instead of resolving a shape it cannot read."""
    BASE = "-- generation: 5\n-- table: roadmap_items\nINSERT INTO roadmap_items(gid, gh_number) VALUES('g1', '100');\n"

    def test_ddl_only_change_is_handoff(self):
        ours = self.BASE + "CREATE INDEX idx_gh ON roadmap_items(gh_number);\n"
        theirs = self.BASE.replace("generation: 5", "generation: 6")
        cls = ledger_merge.classify(self.BASE, ours, theirs)
        self.assertFalse(cls["disjoint"])
        self.assertTrue(any("non-row dump content changed on ours" in r and "CREATE INDEX" in r for r in cls["reasons"]), cls["reasons"])
        cls = ledger_merge.classify(self.BASE, theirs, ours)
        self.assertTrue(any("changed on theirs" in r for r in cls["reasons"]))

    def test_generation_stamp_alone_is_not_a_schema_change(self):
        theirs = self.BASE.replace("generation: 5", "generation: 6")
        cls = ledger_merge.classify(self.BASE, self.BASE, theirs)
        self.assertTrue(cls["disjoint"], cls["reasons"])


# --- Parity guard: SKILL.md's capability table vs the code and the tests ------------------------
SKILL_MD = REPO / "skills" / "merge-cleanup" / "SKILL.md"
MC_SRC = REPO / "skills" / "merge-cleanup" / "scripts" / "merge_cleanup.py"
SC_SRC = REPO / "skills" / "merge-cleanup" / "scripts" / "scan_clones.py"
# The FIXED required set: deleting a row cannot pass because the others remain.
REQUIRED_CAPABILITIES = {
    "session-evidence-driver-lock": "script", "session-evidence-tick-claims": "script",
    "session-evidence-open-handles": "script", "preservation-dirty-stash-unlanded": "script",
    "preservation-fail-closed": "script", "landing-refetch-and-gate": "script",
    "ledger-resolution-disjoint": "script", "ledger-handoff-and-record": "script",
    "dependents-blocked": "script", "reconciliation-gating": "script",
    "coordinator-pinned-to-primary": "script", "teardown-trash-only": "script",
    "code-conflict-recon": "caller", "code-conflict-resolution": "caller",
    "teardown-fresh-inspection": "script",
    # GH-623 (final-QA finding 1): the new rows are REQUIRED too — a row that the guard does
    # not demand can be deleted from SKILL.md with the parity test still green.
    "soft-edge-nonblocking": "script", "network-retry-defer": "script",
    "resume-skips-parked": "script",
}
AST_CALLS = {  # (module source, enclosing function, callee that must be invoked — a comment is not a call)
    "D": (SC_SRC, "inspect_checkout", "inspect_tick_claims"),
    "B1": (MC_SRC, "land_prs", "resolve_ledger_conflict"),
    "C": (MC_SRC, "land_prs", "reserve"),
}


def _calls_in(src: str, func: str):
    import ast
    tree = ast.parse(src)
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef) and node.name == func:
            names = set()
            for n in ast.walk(node):
                if isinstance(n, ast.Call):
                    f = n.func
                    names.add(f.attr if isinstance(f, ast.Attribute) else getattr(f, "id", ""))
            return names
    return None


def parity_failures(skill_text: str, cli_help: str, sources=None, run_tests: bool = False):
    """Every way SKILL.md can drift from the code, named. Empty list = parity."""
    import re
    sources = sources or {k: v[0].read_text() for k, v in AST_CALLS.items()}
    fails = []
    m = re.search(r"## Capability table.*?(?=\n## )", skill_text, re.S)
    if not m:
        return ["capability table section missing"]
    rows = {}
    for line in m.group(0).splitlines():
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) == 4 and cells[0] not in ("Capability", "---"):
            rows[cells[0]] = (cells[2], cells[3])
    for cap, owner in REQUIRED_CAPABILITIES.items():
        if cap not in rows:
            fails.append(f"row missing: {cap}")
            continue
        got_owner, test = rows[cap]
        if got_owner != owner:
            fails.append(f"owner drift: {cap} is {got_owner!r}, required {owner!r}")
        if owner == "script":
            cls, _, meth = test.partition(".")
            klass = globals().get(cls)
            if klass is None or not callable(getattr(klass, meth, None)):
                fails.append(f"test missing: {cap} names {test}")
            elif run_tests:
                r = unittest.TextTestRunner(stream=open(os.devnull, "w")).run(klass(meth))
                if not r.wasSuccessful():
                    fails.append(f"test failing: {cap} → {test}")
    opts = re.search(r"CLI options this document describes[^\n]*?:\s*(.*)", m.group(0))
    for opt in re.findall(r"`(--[a-z-]+)`", opts.group(1) if opts else ""):
        if opt not in cli_help:
            fails.append(f"documented option not in argparse: {opt}")
    for key, (_, func, callee) in AST_CALLS.items():
        calls = _calls_in(sources[key], func)
        if calls is None or callee not in calls:
            fails.append(f"AST: {func}() does not call {callee}() ({key})")
    return fails


# --- GH-623: soft edges, network retry + defer, bounded calls, resume ---------------------------

import toposort_prs as toposort  # noqa: E402


class TestGh623Resilience(LedgerFixture):
    """Collision edges order but never block; transient network failures retry then defer the
    single PR instead of killing the run; network subprocess calls are bounded; --resume consults
    the attempt record only after the live refresh."""

    def same_key_conflict(self):
        self.branch("feat/a", 1, lambda r: _app(r, "roadmap", "update", "--issue-num", "100", "--section", "Completed"))
        self.branch("feat/b", 2, lambda r: _app(r, "roadmap", "update", "--issue-num", "100", "--section", "In progress"))

    def record_for(self, n):
        return ar.record_path(self.primary, str(self.origin), n)

    def exhausted_record(self, n, outcomes=("failed", "handoff")):
        record = self.record_for(n)
        rec = ar.new_record(n, str(self.origin))
        rec["attempts"] = [
            {"by": "caller", "head_sha": str(i) * 40, "rung": "ponytail", "started": "t",
             "outcome": outcome, "clone_path": ""}
            for i, outcome in enumerate(outcomes, 1)
        ]
        ar.save(record, rec)
        return record

    def views_for(self, st, n):
        return [c for c in st["calls"] if c[:2] == ["pr", "view"] and c[2] == str(n)]

    def test_soft_edge_predecessor_does_not_block_a_collision_dependent(self):
        """RED on current code: PR 3 shares a (stub) file with handed-off PR 2 and is refused as a
        dependent; GH-623 makes collision edges soft — the landing simulation decides instead."""
        self.same_key_conflict()  # PR 2 will hand off (same-key ledger conflict)
        self.branch("feat/c", 3, lambda r: park(r, 300, "soft dependent"))
        self.branch("feat/d", 4, lambda r: park(r, 301, "hard dependent"))
        st = self.load()
        st["prs"]["2"]["files"] = [{"path": "shared.txt"}]
        st["prs"]["3"]["files"] = [{"path": "shared.txt"}]
        st["prs"]["4"]["body"] = "Depends on #2"
        self.save()
        rc = self.run_main()
        self.assertEqual(rc, 3, self.err)
        st = self.load()
        self.assertEqual({n: p["state"] for n, p in st["prs"].items()},
                         {"1": "MERGED", "2": "OPEN", "3": "MERGED", "4": "OPEN"})
        self.assertIn("attempting anyway", self.err)
        self.assertIn("PR #4: NOT attempted — depends on #2 (handoff)", self.err)
        self.assertEqual(self.dev_rows(), [100, 101, 300])

    def test_transient_view_failure_defers_and_independents_land(self):
        """RED on current code: a DNS-flavored pr-view failure stops the whole run (rc 2) and PR 2
        is never attempted. GH-623: retry x3, defer PR 1, keep landing."""
        self.branch("feat/a", 1, lambda r: park(r, 200, "net"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "plain"))
        st = self.load()
        st["view_fail"] = {"1": {"remaining": 99, "msg": "gh: Could not resolve host: github.com"}}
        self.save()
        sleeps = []
        with mock.patch.object(merge_cleanup, "_sleep", side_effect=sleeps.append, create=True):
            rc = self.run_main()
        self.assertEqual(rc, 3, self.err)
        self.assertIn("DEFERRED", self.err)
        self.assertIn("Could not resolve host", self.err)
        st = self.load()
        self.assertEqual((st["prs"]["1"]["state"], st["prs"]["2"]["state"]), ("OPEN", "MERGED"))
        self.assertEqual(len(self.views_for(st, 1)), 3, "the deferred PR was not retried exactly 3 times")
        self.assertEqual(sleeps, [2, 4], "the retry schedule is 3 calls with 2s then 4s between them")

    def test_transient_view_failure_retry_then_success_lands(self):
        """RED on current code: two failures then success still stops the run. GH-623: the third
        attempt succeeds and the PR lands; the sleep sequence pins the retry contract."""
        self.branch("feat/a", 1, lambda r: park(r, 200, "flaky"))
        st = self.load()
        st["view_fail"] = {"1": {"remaining": 2, "msg": "gh: Could not resolve host: github.com"}}
        self.save()
        sleeps = []
        with mock.patch.object(merge_cleanup, "_sleep", side_effect=sleeps.append, create=True):
            rc = self.run_main()
        self.assertEqual(rc, 0, self.err)
        self.assertEqual(self.load()["prs"]["1"]["state"], "MERGED")
        self.assertGreaterEqual(len(self.views_for(self.load(), 1)), 3)
        self.assertEqual(sleeps, [2, 4])

    def test_pr_list_discovery_failure_exits_two_before_teardown(self):
        """RED on current code: a failing `gh pr list` reads as an empty queue ("No open PRs
        found", rc 0, teardown runs). GH-623: retried, then exit 2 BEFORE Phase 6."""
        self.branch("feat/a", 1, lambda r: park(r, 200, "queued"))
        st = self.load()
        st["list_fail"] = {"remaining": 99, "msg": "gh: Could not resolve host: github.com"}
        self.save()
        sleeps = []
        with mock.patch.object(merge_cleanup, "_sleep", side_effect=sleeps.append, create=True):
            rc = self.run_main()
        self.assertEqual(rc, 2)
        self.assertIn("Could not resolve host", self.err)
        self.pruner.assert_not_called()
        self.assertEqual(sleeps, [2, 4])

    def test_pr_list_discovery_is_bounded_in_time(self):
        """The discovery subprocess must be invoked with a FINITE timeout — handling a
        TimeoutExpired proves nothing if the call could hang forever."""
        self.branch("feat/a", 1, lambda r: park(r, 200, "queued"))
        real_run = toposort.subprocess.run

        def bounded(cmd, **kw):
            # Patch precisely: only the gh call is intercepted (subprocess is a shared module);
            # every git call from the scan/landing machinery passes through to the real run.
            if str(cmd[0]).endswith("gh"):
                if kw.get("timeout") in (None, 0):
                    raise AssertionError("gh pr list was invoked without a finite timeout")
                raise subprocess.TimeoutExpired(cmd, kw["timeout"])
            return real_run(cmd, **kw)

        with mock.patch.object(toposort.subprocess, "run", side_effect=bounded):
            rc = self.run_main()
        self.assertEqual(rc, 2)
        self.assertIn("timed out", self.err)
        self.pruner.assert_not_called()

    def test_net_git_bounds_and_converts_a_hung_call(self):
        """_net_git forwards a finite timeout and converts TimeoutExpired into the normal
        failure shape (rc 124, 'timed out' diagnostic) so it reaches the retry loop."""
        def hung(cwd, args, **kw):
            if kw.get("timeout") in (None, 0):
                raise AssertionError("_net_git must forward a finite timeout to run_git")
            raise subprocess.TimeoutExpired(cmd=["git"] + list(args), timeout=kw["timeout"])

        with mock.patch.object(merge_cleanup, "run_git", side_effect=hung):
            r = merge_cleanup._net_git(self.primary, ["fetch", "origin", "development"])
        self.assertEqual(r.returncode, 124)
        self.assertIn("timed out", r.stderr)

    def test_run_git_default_stays_unbounded(self):
        """The additive timeout parameter must default to unbounded — every scan/ledger caller
        keeps today's behavior (the compatibility shield GH-623 relies on)."""
        with mock.patch.object(scan_clones.subprocess, "run") as m:
            scan_clones.run_git(self.primary, ["status"])
        self.assertIsNone(m.call_args.kwargs.get("timeout"))
        with mock.patch.object(scan_clones.subprocess, "run") as m2:
            scan_clones.run_git(self.primary, ["status"], timeout=5)
        self.assertEqual(m2.call_args.kwargs.get("timeout"), 5)

    def test_hung_landing_clone_times_out_and_defers(self):
        """RED on current code: run_git has no timeout, so the hung clone propagates as an
        exception and kills the run. GH-623: bounded, retried, deferred, independents continue."""
        self.branch("feat/a", 1, lambda r: park(r, 200, "net"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "plain"))
        real = merge_cleanup.run_git

        def hung_clone(cwd, args, **kw):
            # Only PR 1's landing clone hangs (the clone target dir carries the pr-N prefix);
            # PR 2's network stays healthy so the defer-and-continue can be observed.
            if args[:1] == ["clone"] and "pr-1-" in str(args[-1]):
                raise subprocess.TimeoutExpired(cmd=["git", "-C", str(cwd)] + list(args), timeout=kw.get("timeout") or 0)
            return real(cwd, args, **kw)

        with mock.patch.object(merge_cleanup, "run_git", side_effect=hung_clone), \
                mock.patch.object(merge_cleanup, "_sleep", side_effect=lambda s: None, create=True):
            rc = self.run_main()
        self.assertEqual(rc, 3, self.err)
        self.assertIn("DEFERRED", self.err)
        self.assertIn("timed out", self.err)
        st = self.load()
        self.assertEqual((st["prs"]["1"]["state"], st["prs"]["2"]["state"]), ("OPEN", "MERGED"))

    def test_resume_skips_a_still_conflicting_exhausted_pr(self):
        """RED on current code: no --resume flag exists. Green: the exhausted record skips the
        PR as previously parked WITHOUT running B1 and without consuming a third slot."""
        self.same_key_conflict()  # PR 2 hands off
        record = self.exhausted_record(2)
        rc = self.run_main(extra=["--resume"])
        self.assertEqual(rc, 3, self.err)
        self.assertIn("previously parked", self.err)
        self.assertNotIn("  B1:", self.err, "B1 ran despite --resume seeing an exhausted record")
        self.assertEqual(len(ar.load(record)["attempts"]), 2, "resume consumed a repair slot")
        st = self.load()
        self.assertEqual((st["prs"]["1"]["state"], st["prs"]["2"]["state"]), ("MERGED", "OPEN"))

    def test_resume_lands_a_pr_whose_last_repair_resolved(self):
        """RED on current code: no --resume flag exists. THE ROUND-3 PIN: a PR whose record shows
        two finished repairs with the last `resolved` and whose live landing is clean is LANDED —
        the record is consulted only when a repair would actually be needed."""
        # PR 1 carries the ledger change; PR 2 touches only README, so its landing merges clean
        # (a clean landing never routes to B1, whatever the record says).
        self.branch("feat/a", 1, lambda r: park(r, 200, "first"))
        self.branch("feat/b", 2, lambda r: (r / "README.md").write_text("repaired docs\n"))
        self.exhausted_record(2, outcomes=("handoff", "resolved"))
        rc = self.run_main(extra=["--resume"])
        self.assertEqual(rc, 0, self.err)
        st = self.load()
        self.assertEqual((st["prs"]["1"]["state"], st["prs"]["2"]["state"]), ("MERGED", "MERGED"))
        self.assertNotIn("previously parked", self.err)

    def test_without_resume_the_park_path_is_unchanged(self):
        """Without --resume an exhausted record still reaches reserve() and parks — the ceiling
        authority never moved."""
        self.same_key_conflict()
        record = self.exhausted_record(2)
        rc = self.run_main()
        self.assertEqual(rc, 3)
        self.assertIn("PARKED — budget exhausted", self.err)
        self.assertEqual(len(ar.load(record)["attempts"]), 2)
        self.assertEqual(self.load()["prs"]["2"]["state"], "OPEN")

    def test_prequeue_fetch_failure_refuses_after_retries(self):
        """RED (partially) on current code: the refusal exists but fires on the FIRST failure;
        GH-623 retries a transient failure 3x with [2, 4] sleeps before refusing."""
        self.branch("feat/a", 1, lambda r: park(r, 200, "queued"))
        real = merge_cleanup.run_git
        fetches = []

        def down(cwd, args, **kw):
            if args == ["fetch", "origin", "development"] and Path(cwd).resolve() == self.primary.resolve():
                fetches.append(1)
                return subprocess.CompletedProcess(args=args, returncode=1, stdout="",
                                                   stderr="gh: Could not resolve host: github.com")
            return real(cwd, args, **kw)

        with mock.patch.object(merge_cleanup, "run_git", side_effect=down), \
                mock.patch.object(merge_cleanup, "_sleep", side_effect=lambda s: None, create=True):
            rc = self.run_main()
        self.assertEqual(rc, 2)
        self.assertIn("could not refresh", self.err)
        self.assertEqual(len(fetches), 3)
        self.assertEqual(self.load()["prs"]["1"]["state"], "OPEN")

    def test_prequeue_fetch_failure_proceeds_with_allow_unready_primary(self):
        """The existing --allow-unready-primary override survives retry exhaustion unchanged —
        GH-623 removes no escape hatch. (RED on the retry count only: today there is 1 attempt.)"""
        self.branch("feat/a", 1, lambda r: park(r, 200, "queued"))
        real = merge_cleanup.run_git
        fetches = []
        state = {"remaining": 3}  # network recovers right after the pre-queue retries exhaust

        def flaky(cwd, args, **kw):
            if args == ["fetch", "origin", "development"] and Path(cwd).resolve() == self.primary.resolve() and state["remaining"] > 0:
                state["remaining"] -= 1
                fetches.append(1)
                return subprocess.CompletedProcess(args=args, returncode=1, stdout="",
                                                   stderr="gh: Could not resolve host: github.com")
            return real(cwd, args, **kw)

        with mock.patch.object(merge_cleanup, "run_git", side_effect=flaky), \
                mock.patch.object(merge_cleanup, "_sleep", side_effect=lambda s: None, create=True):
            rc = self.run_main(extra=["--allow-unready-primary"])
        self.assertEqual(rc, 0, self.err)
        self.assertEqual(self.load()["prs"]["1"]["state"], "MERGED")
        self.assertEqual(len(fetches), 3)

    def test_toposort_standalone_reports_fetch_error(self):
        """RED on current code: the standalone sorter prints 'No open PRs found.' and exits 0 on
        a failed gh pr list. GH-623: FetchError -> diagnostic, non-zero exit, no traceback."""
        st = self.load()
        st["list_fail"] = {"remaining": 99, "msg": "gh: Could not resolve host: github.com"}
        self.save()
        r = subprocess.run([sys.executable, str(REPO / "skills" / "merge-cleanup" / "scripts" / "toposort_prs.py"),
                            "--repo", str(self.primary)],
                           capture_output=True, text=True,
                           env={**os.environ, "MERGE_CLEANUP_GH_BIN": str(self.gh), "GH_STATE": str(self.state)})
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("Could not resolve host", r.stderr)
        self.assertNotIn("Traceback", r.stderr)
        self.assertNotIn("No open PRs found", r.stdout)


class TestGh623DriveLoopDocContract(unittest.TestCase):
    """R4 regression proof (GH-623 final-QA finding 2): SKILL.md's Drive loop section, its Done
    rule (with all three explicit-mode exceptions), and the permission-classifier retry-once
    rule are load-bearing contracts, not prose. The controls mutate the text and watch the
    checker go red, so these cannot pass on unrelated wording."""

    @classmethod
    def setUpClass(cls):
        cls.text = SKILL_MD.read_text()

    def drive_loop_section(self, text):
        m = re.search(r"## Drive loop[^\n]*\n(.*?)(?=\n## )", text, re.S)
        return m.group(0) if m else ""

    def assert_contract(self, text):
        section = self.drive_loop_section(text)
        self.assertTrue(section, "the ## Drive loop section is missing")
        for phrase in (
            "--resume --execute",                                  # the continuation command
            "do not report Done unless Phase 5 ran",               # the Done rule
            "`--teardown-only`", "`--scan-only`", "`--prs-only`",  # the three explicit-mode exceptions
            "exit 0 or a stop",                                    # the loop terminates on facts
            "retry the identical command once",                    # classifier-block rule (S2)
            "permission",
        ):
            self.assertIn(phrase, section, f"Drive loop lost a load-bearing contract: {phrase}")

    def test_drive_loop_contracts_present(self):
        self.assert_contract(self.text)

    def _section_with(self, replacement, pattern):
        mutated = re.sub(pattern, replacement, self.text, flags=re.S)
        self.assertNotEqual(mutated, self.text, "control pattern no longer matches SKILL.md — repoint it")
        return mutated

    def test_control_deleting_the_done_rule_is_caught(self):
        mutated = self._section_with("DONE-RULE-REMOVED", r"\*\*Done rule:\*\*.*?(?=\n\n)")
        with self.assertRaises(AssertionError):
            self.assert_contract(mutated)

    def test_control_deleting_the_classifier_rule_is_caught(self):
        mutated = self._section_with("RETRY-RULE-REMOVED", r"\*\*Permission-classifier blocks:\*\*.*?(?=\n\n)")
        with self.assertRaises(AssertionError):
            self.assert_contract(mutated)

    def test_control_deleting_the_whole_section_is_caught(self):
        mutated = re.sub(r"## Drive loop.*?(?=\n## Caller decision ladder)", "GONE\n", self.text, flags=re.S)
        self.assertNotEqual(mutated, self.text)
        with self.assertRaises(AssertionError):
            self.assert_contract(mutated)


class TestParityGuard(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.skill = SKILL_MD.read_text()
        cls.help = subprocess.run([sys.executable, str(MC_SRC), "--help"], capture_output=True, text=True).stdout

    def test_skill_md_matches_code_and_tests(self):
        self.assertEqual(parity_failures(self.skill, self.help, run_tests=True), [])

    def test_recon_owner_is_pinned_to_caller(self):
        self.assertEqual(REQUIRED_CAPABILITIES["code-conflict-recon"], "caller")
        self.assertEqual(REQUIRED_CAPABILITIES["code-conflict-resolution"], "caller")

    def _fails(self, skill=None, help_=None, sources=None):
        return parity_failures(skill or self.skill, help_ or self.help, sources)

    def test_control_deleted_row_is_named(self):
        for cap in REQUIRED_CAPABILITIES:
            mutated = "\n".join(l for l in self.skill.splitlines() if not l.startswith(f"| {cap} |"))
            self.assertIn(f"row missing: {cap}", self._fails(skill=mutated), cap)

    def test_control_owner_flip_is_named(self):
        mutated = self.skill.replace("| code-conflict-recon | 5 | caller |", "| code-conflict-recon | 5 | script |")
        self.assertTrue(any(f.startswith("owner drift: code-conflict-recon") for f in self._fails(skill=mutated)))

    def test_control_renamed_test_is_named(self):
        mutated = self.skill.replace("TestE6Gate.test_gate_red_prevents_the_merge", "TestE6Gate.test_gone")
        self.assertIn("test missing: landing-refetch-and-gate names TestE6Gate.test_gone", self._fails(skill=mutated))

    def test_control_documented_option_absent_from_argparse_is_named(self):
        mutated = self.skill.replace("`--resume`.", "`--resume`, `--bogus-flag`.")
        self.assertNotEqual(mutated, self.skill, "the options line moved — repoint this control")
        self.assertIn("documented option not in argparse: --bogus-flag", self._fails(skill=mutated))

    def test_control_call_replaced_by_comment_is_named(self):
        srcs = {k: v[0].read_text() for k, v in AST_CALLS.items()}
        d = srcs["D"].replace('res["tick_claims"] = inspect_tick_claims(path)', 'res["tick_claims"] = {"has_claims": False, "verified": True}  # inspect_tick_claims(path)')
        self.assertNotEqual(d, srcs["D"])
        self.assertIn("AST: inspect_checkout() does not call inspect_tick_claims() (D)", self._fails(sources=dict(srcs, D=d)))
        b1 = srcs["B1"].replace("b1 = resolve_ledger_conflict(clone, execute=not dry_run)", "b1 = {'handoff': True, 'reason': 'x', 'conflict_set': [], 'log': []}  # resolve_ledger_conflict")
        self.assertNotEqual(b1, srcs["B1"])
        self.assertIn("AST: land_prs() does not call resolve_ledger_conflict() (B1)", self._fails(sources=dict(srcs, B1=b1)))
        c = srcs["C"].replace("idx, why = attempt_record.reserve(", "idx, why = (0, 'nope')  # attempt_record.reserve(").replace(
            "                                                          clone_path=str(clone), create=fresh)", "                        # clone_path=str(clone), create=fresh)")
        self.assertNotEqual(c, srcs["C"])
        self.assertIn("AST: land_prs() does not call reserve() (C)", self._fails(sources=dict(srcs, C=c)))


if __name__ == "__main__":
    unittest.main(verbosity=2)
