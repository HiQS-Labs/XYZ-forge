#!/usr/bin/env python3
"""GH-534 Phase C — the durable attempt record, its record-adjacent lock, and the dependent map.

Collected by test/gh436-merge-cleanup.py. Reuses the Phase B LedgerFixture (bare origin + gh stub)
for the script-side runs; the record tests below need only a directory and the CLI.
"""
import json
import os
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
from attempt_record import RECORD_ENV, RecordError, RecordLock, reserve  # noqa: E402
from gh534_phase_a_tests import TestA2Provenance, TestA4OpenHandles, TestA4TickClaims, TestA5FailClosed, TestA5FreshInspection  # noqa: E402,F401
from gh534_phase_b_tests import LedgerFixture, TestE6Gate, TestPhase5EndToEnd, _app, _git, park  # noqa: E402,F401

CLI = REPO / "skills" / "merge-cleanup" / "scripts" / "attempt_record.py"


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

    def same_key_conflict(self):
        self.branch("feat/a", 1, lambda r: _app(r, "roadmap", "update", "--issue-num", "100", "--section", "Completed"))
        self.branch("feat/b", 2, lambda r: _app(r, "roadmap", "update", "--issue-num", "100", "--section", "In progress"))

    def record_for(self, n):
        return ar.record_path(self.primary, str(self.origin), n)

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
    "code-conflict-recon": "caller", "code-conflict-resolution": "caller",
    "teardown-fresh-inspection": "script",
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
        mutated = self.skill.replace("`--execute`.", "`--execute`, `--bogus-flag`.")
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
