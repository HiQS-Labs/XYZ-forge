#!/usr/bin/env python3
"""test/gh534_phase_b_tests.py — GH-534 Phase B: the Phase 5 feedback loop (E), the pre-merge
ledger gate (E.6) and disjoint-only ledger conflict resolution (B1).

Collected by test/gh436-merge-cleanup.py. Fixtures are REAL: a bare origin, a ledger created with
`releases init` and rows parked through `roadmap add`, PR branches pushed to the origin, and a
`gh` stub that answers `pr view/list` from a state file, computes `mergeable` with
`git merge-tree`, and performs a genuine squash merge into the origin on `pr merge`.
"""

import contextlib
import io
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
import unittest.mock as mock
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "skills" / "merge-cleanup" / "scripts"))

import ledger_merge  # noqa: E402
import merge_cleanup  # noqa: E402
import scan_clones  # noqa: E402
from ledger_merge import classify, pre_merge_ledger_gate, resolve_ledger_conflict  # noqa: E402
from scan_clones import GH_BIN_ENV  # noqa: E402

APP_SRC = REPO / "utils" / "py" / "releases_app.py"
RESOLVER_SRC = REPO / "utils" / "releases-merge-resolve.sh"


def _git(cwd, *args, check=True):
    return subprocess.run(["git", "-C", str(cwd)] + list(args), capture_output=True, text=True, check=check)


def _app(root, *args, check=True):
    r = subprocess.run([sys.executable, str(Path(root) / "utils/py/releases_app.py"), "--root", str(root)] + list(args),
                       capture_output=True, text=True)
    if check and r.returncode != 0:
        raise AssertionError(f"releases_app {' '.join(args)} failed rc={r.returncode}: {r.stderr}\n{r.stdout}")
    return r


def park(root, n, title="row", rated=None, section=None):
    raw = f"- **GH-{n} · {title}** 🆕" + (f" rated {rated}" if rated else "")
    _app(root, "roadmap", "add", "--issue-num", str(n), "--issue-url", f"https://github.com/o/r/issues/{n}",
         "--title", title, "--created", "2026-09-01", "--doc-path", f"PROJECT/1-INBOX/GH-{n}.md", "--raw-text", raw)
    if section:
        _app(root, "roadmap", "update", "--issue-num", str(n), "--section", section)


def commit_all(root, msg):
    _git(root, "add", "-A")
    _git(root, "commit", "-q", "-m", msg)
    return _git(root, "rev-parse", "HEAD").stdout.strip()


GH_STUB = r'''#!/usr/bin/env python3
"""gh stub: state in $GH_STATE (json). Subcommands: repo view, pr list, pr view, pr merge, issue view."""
import json, os, subprocess, sys, tempfile, shutil
S = os.environ["GH_STATE"]
def load(): return json.load(open(S))
def save(st): json.dump(st, open(S, "w"), indent=1)
def git(cwd, *a): return subprocess.run(["git", "-C", cwd] + list(a), capture_output=True, text=True)
def mergeable(st, pr):
    probe = st["probe"]
    git(probe, "fetch", "-q", "origin")
    r = git(probe, "merge-tree", "--write-tree", "origin/" + st["base"], "origin/" + pr["headRefName"])
    return "MERGEABLE" if r.returncode == 0 else ("CONFLICTING" if r.returncode == 1 else "UNKNOWN")
def view(st, pr):
    git(st["probe"], "fetch", "-q", "origin")
    head = git(st["probe"], "rev-parse", "origin/" + pr["headRefName"]).stdout.strip() if pr["state"] == "OPEN" else pr.get("headRefOid")
    d = {"number": pr["number"], "state": pr["state"], "headRefName": pr["headRefName"], "baseRefName": st["base"],
         "labels": [{"name": l} for l in pr.get("labels", [])], "headRefOid": head or pr.get("headRefOid"),
         "mergeCommit": ({"oid": pr["mergeCommit"]} if pr.get("mergeCommit") else None),
         "url": f"https://example.invalid/pr/{pr['number']}", "title": f"PR {pr['number']}", "body": pr.get("body", ""),
         "files": [], "createdAt": f"2026-09-01T0{pr['number'] % 10}:00:00Z", "statusCheckRollup": []}
    d["mergeable"] = st.get("force_mergeable", {}).get(str(pr["number"])) or (mergeable(st, pr) if pr["state"] == "OPEN" else "UNKNOWN")
    return d
a = sys.argv[1:]
st = load()
st.setdefault("calls", []).append(a); save(st)
if a[:2] == ["repo", "view"]:
    print(json.dumps({"url": st["origin"]})); sys.exit(0)
if a[:2] == ["issue", "view"]:
    print(json.dumps({"state": "OPEN", "stateReason": None})); sys.exit(0)
if a[:2] == ["pr", "list"]:
    if "--state" in a and a[a.index("--state") + 1] == "merged":
        print(json.dumps([{"number": p["number"], "state": "MERGED", "headRefOid": p.get("headRefOid"),
                           "mergeCommit": {"oid": p.get("mergeCommit")}, "baseRefName": st["base"]}
                          for p in st["prs"].values() if p["state"] == "MERGED"])); sys.exit(0)
    print(json.dumps([view(st, p) for p in st["prs"].values() if p["state"] == "OPEN"])); sys.exit(0)
if a[:2] == ["pr", "view"]:
    pr = st["prs"].get(a[2])
    if pr is None or st.get("view_fail"): print("stub: view failed", file=sys.stderr); sys.exit(1)
    print(json.dumps(view(st, pr))); sys.exit(0)
if a[:2] == ["pr", "merge"]:
    pr = st["prs"][a[2]]
    if st.get("merge_lies"): sys.exit(0)
    w = tempfile.mkdtemp(prefix="ghstub-merge.")
    try:
        assert subprocess.run(["git", "clone", "-q", st["origin"], w]).returncode == 0
        git(w, "config", "user.email", "gh@stub"); git(w, "config", "user.name", "gh")
        git(w, "checkout", "-q", st["base"])
        r = git(w, "merge", "--squash", "origin/" + pr["headRefName"])
        if r.returncode != 0: print(r.stderr, file=sys.stderr); sys.exit(1)
        git(w, "commit", "-q", "-m", f"squash #{pr['number']}")
        mc = git(w, "rev-parse", "HEAD").stdout.strip()
        head = git(w, "rev-parse", "origin/" + pr["headRefName"]).stdout.strip()
        if git(w, "push", "-q", "origin", st["base"]).returncode != 0: sys.exit(1)
        git(w, "push", "-q", "origin", "--delete", pr["headRefName"])
        pr.update(state="MERGED", mergeCommit=mc, headRefOid=head); save(st)
    finally:
        shutil.rmtree(w, ignore_errors=True)
    sys.exit(0)
print("stub: unknown " + " ".join(a), file=sys.stderr); sys.exit(9)
'''


class LedgerFixture(unittest.TestCase):
    """A bare origin on `development`, a ledger with two parked rows, and a primary clone."""

    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="gh534b."))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        scan_clones._merged_pr_cache.clear()
        self.origin = self.tmp / "origin.git"
        subprocess.run(["git", "init", "-q", "--bare", "-b", "development", str(self.origin)], check=True)
        self.seed = self.clone("seed")
        (self.seed / "utils" / "py").mkdir(parents=True)
        shutil.copy(APP_SRC, self.seed / "utils" / "py" / "releases_app.py")
        shutil.copy(RESOLVER_SRC, self.seed / "utils" / "releases-merge-resolve.sh")
        shutil.copy(REPO / ".gitattributes", self.seed / ".gitattributes")
        (self.seed / "README.md").write_text("fixture\n")
        (self.seed / ".gitignore").write_text(".tick/\n")  # as the real repo: the Phase C record is untracked state
        _app(self.seed, "init", "--slug", "fx")
        park(self.seed, 100, "first")
        park(self.seed, 101, "second", rated="50/50/50/50")
        commit_all(self.seed, "base ledger")
        _git(self.seed, "push", "-q", "-u", "origin", "development")
        self.primary = self.clone("primary")
        self.probe = self.clone("probe")
        self.state = self.tmp / "gh-state.json"
        self.gh = self.tmp / "gh"
        self.gh.write_text(GH_STUB)
        self.gh.chmod(0o755)
        self.st = {"origin": str(self.origin), "base": "development", "probe": str(self.probe), "prs": {}, "calls": []}
        self.save()
        env = mock.patch.dict(os.environ, {GH_BIN_ENV: str(self.gh), "GH_STATE": str(self.state), "RELEASES_GH_BIN": str(self.gh)})
        env.start()
        self.addCleanup(env.stop)

    def save(self):
        self.state.write_text(json.dumps(self.st, indent=1))

    def load(self):
        self.st = json.loads(self.state.read_text())
        return self.st

    def clone(self, name):
        c = self.tmp / name
        subprocess.run(["git", "clone", "-q", str(self.origin), str(c)], check=True, capture_output=True)
        for k, v in (("user.name", "t"), ("user.email", "t@e.com")):
            _git(c, "config", k, v)
        return c

    def branch(self, name, number, fn, labels=()):
        """Cut a PR branch off origin/development, apply fn(root), push, register in gh state."""
        w = self.clone(f"w-{number}")
        _git(w, "checkout", "-q", "-b", name, "origin/development")
        fn(w)
        head = commit_all(w, f"PR {number}")
        _git(w, "push", "-q", "-u", "origin", name)
        self.st["prs"][str(number)] = {"number": number, "state": "OPEN", "headRefName": name, "labels": list(labels)}
        self.save()
        return head

    def run_main(self, execute=True, extra=()):
        argv = ["merge_cleanup.py", "--primary", str(self.primary), "--root", str(self.tmp / "no-roots")] + list(extra)
        if execute:
            argv.append("--execute")
        err = io.StringIO()
        with mock.patch.object(sys, "argv", argv), \
             mock.patch.object(merge_cleanup, "prune_dangling_skill_symlinks") as pruner, \
             mock.patch.object(merge_cleanup, "teardown_checkout") as teardown, \
             mock.patch.object(merge_cleanup, "scan_directories", return_value=[]), \
             contextlib.redirect_stderr(err):
            rc = merge_cleanup.main()
        self.pruner, self.teardown, self.err = pruner, teardown, err.getvalue()
        return rc

    def dev_rows(self):
        c = self.clone("reader-" + str(len(os.listdir(self.tmp))))
        r = subprocess.run([sys.executable, "-c",
                            "import sqlite3,sys;c=sqlite3.connect(sys.argv[1]);print(sorted(int(r[0]) for r in c.execute('select gh_number from roadmap_items')))",
                            str(c / "releases.db")], capture_output=True, text=True)
        return json.loads(r.stdout)

    def origin_dev(self):
        return _git(self.probe, "ls-remote", str(self.origin), "refs/heads/development").stdout.split()[0]


# --- B1: pure classification -------------------------------------------------------------------

class TestB1Classify(LedgerFixture):
    def dumps(self, ours_fn, theirs_fn):
        base = (self.seed / "releases.sql").read_text()
        o = self.clone("o")
        ours_fn(o)
        t = self.clone("t")
        theirs_fn(t)
        return base, (o / "releases.sql").read_text(), (t / "releases.sql").read_text()

    def test_disjoint_additions_are_disjoint(self):
        b, o, t = self.dumps(lambda r: park(r, 200, "pr side"), lambda r: park(r, 201, "dev side"))
        c = classify(b, o, t)
        self.assertTrue(c["disjoint"], c["reasons"])
        self.assertEqual([op["op"] for op in c["replay"]], ["add"])
        self.assertEqual(c["replay"][0]["row"]["gh_number"], "200" if c["keep"] == "theirs" else "201")

    def test_same_key_update_vs_update_is_handoff(self):
        b, o, t = self.dumps(lambda r: _app(r, "roadmap", "update", "--issue-num", "100", "--section", "In progress"),
                             lambda r: _app(r, "roadmap", "update", "--issue-num", "100", "--section", "Completed"))
        c = classify(b, o, t)
        self.assertFalse(c["disjoint"])
        self.assertTrue(any("same-key" in r for r in c["reasons"]), c["reasons"])

    def test_update_vs_delete_is_handoff(self):
        def delete_100(r):
            s = (r / "releases.sql").read_text()
            s = "\n".join(l for l in s.splitlines() if not (l.startswith("INSERT INTO roadmap_items") and "'100'" in l)) + "\n"
            (r / "releases.sql").write_text(s)
        b, o, t = self.dumps(lambda r: _app(r, "roadmap", "update", "--issue-num", "100", "--section", "In progress"), delete_100)
        c = classify(b, o, t)
        self.assertFalse(c["disjoint"])
        self.assertTrue(any("deleted" in r and "same-key" in r for r in c["reasons"]), c["reasons"])

    def test_reference_to_a_deleted_row_is_handoff(self):
        def delete_repo(r):
            s = (r / "releases.sql").read_text()
            (r / "releases.sql").write_text("\n".join(l for l in s.splitlines() if not l.startswith("INSERT INTO repos")) + "\n")
        b, o, t = self.dumps(lambda r: park(r, 300, "new row referencing the repo"), delete_repo)
        c = classify(b, o, t)
        self.assertFalse(c["disjoint"])
        self.assertTrue(any("still references" in r for r in c["reasons"]), c["reasons"])

    def test_duplicate_gh_number_across_sides_is_handoff(self):
        b, o, t = self.dumps(lambda r: park(r, 400, "pr version"), lambda r: park(r, 400, "dev version"))
        c = classify(b, o, t)
        self.assertFalse(c["disjoint"])
        self.assertTrue(any("gh_number 400" in r for r in c["reasons"]), c["reasons"])

    def test_change_in_an_inexpressible_table_is_handoff(self):
        def add_release(r):
            _app(r, "add", "--version", "9.9.9", "--status", "draft", "--tracking-issue", "TMP-ZZZZZZ", "--description", "x")
        b, o, t = self.dumps(add_release, lambda r: park(r, 500, "dev side"))
        c = classify(b, o, t)
        self.assertFalse(c["disjoint"])
        self.assertTrue(any("writer path cannot express" in r for r in c["reasons"]), c["reasons"])

    def test_kept_side_is_the_higher_generation(self):
        def many(r):
            for n in (600, 601, 602):
                park(r, n, "pr")
        b, o, t = self.dumps(many, lambda r: park(r, 700, "dev"))
        c = classify(b, o, t)
        self.assertTrue(c["disjoint"], c["reasons"])
        self.assertEqual(c["keep"], "ours")
        self.assertEqual([op["row"]["gh_number"] for op in c["replay"]], ["700"])


# --- E / E.6 / B1 end to end --------------------------------------------------------------------

class TestPhase5EndToEnd(LedgerFixture):
    def b1_conflict_clone(self):
        """Land PR 1, then return PR 2's real conflicted landing clone."""
        self.branch("feat/a", 1, lambda r: park(r, 200, "from PR 1"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "from PR 2"))
        subprocess.run([str(self.gh), "pr", "merge", "1"], check=True, capture_output=True, text=True)
        info = merge_cleanup.refresh_pr(2, self.primary)
        prep = merge_cleanup.prepare_landing_clone(info, self.primary, "development", self.tmp)
        self.assertNotEqual(prep["merge_rc"], 0, "fixture did not produce a B1 ledger conflict")
        return prep["clone"]

    def test_b1_success_removes_only_the_rebuild_backup(self):
        clone = self.b1_conflict_clone()
        outside_backup = self.tmp / "releases.db.bak"
        outside_backup.write_bytes(b"outside")
        result = resolve_ledger_conflict(clone, execute=True)
        self.assertTrue(result["resolved"], result)
        self.assertFalse((clone / "releases.db.bak").exists(), "successful B1 left rebuild backup")
        self.assertEqual(outside_backup.read_bytes(), b"outside", "cleanup escaped the landing clone")
        status = _git(clone, "status", "--porcelain", "--untracked-files=all").stdout.splitlines()
        self.assertFalse([line for line in status if line.startswith("?? ")], status)

    def test_b1_failed_rebuild_preserves_recovery_backup(self):
        clone = self.b1_conflict_clone()
        real = ledger_merge._run

        def fail_rebuild(argv, cwd, **kwargs):
            if list(argv)[-2:] == ["check", "--rebuild"]:
                (Path(cwd) / "releases.db.bak").write_bytes(b"recovery evidence")
                return subprocess.CompletedProcess(argv, 1, stdout="", stderr="injected rebuild failure")
            return real(argv, cwd, **kwargs)

        with mock.patch.object(ledger_merge, "_run", side_effect=fail_rebuild):
            result = resolve_ledger_conflict(clone, execute=True)
        self.assertFalse(result["resolved"], result)
        self.assertEqual((clone / "releases.db.bak").read_bytes(), b"recovery evidence")

    def test_two_prs_second_conflicts_after_first_lands_and_b1_resolves_it(self):
        """THE run: PR 2 is re-fetched after PR 1 lands, reads CONFLICTING, is resolved through the
        writer path + resolver, validated in a second clone, pushed, re-gated, and merged."""
        self.branch("feat/a", 1, lambda r: park(r, 200, "from PR 1"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "from PR 2", rated="60/40/50/70"))
        rc = self.run_main()
        self.assertEqual(rc, 0)
        st = self.load()
        self.assertEqual({p["state"] for p in st["prs"].values()}, {"MERGED"})
        self.assertEqual(self.dev_rows(), [100, 101, 200, 201])
        views = [c for c in st["calls"] if c[:2] == ["pr", "view"]]
        self.assertGreaterEqual(len([v for v in views if v[2] == "2"]), 2, "PR 2 was not re-fetched after PR 1 landed")
        # The primary followed the landing and its ledger checks clean.
        self.assertEqual(_git(self.primary, "rev-parse", "HEAD").stdout.strip(), self.origin_dev())
        self.assertEqual(_app(self.primary, "check").returncode, 0)
        self.pruner.assert_called_once()

    def test_dry_run_mutates_nothing(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "from PR 1"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "from PR 2"))
        before = _git(self.probe, "ls-remote", str(self.origin)).stdout
        rc = self.run_main(execute=False)
        self.assertEqual(rc, 0)
        self.assertEqual(_git(self.probe, "ls-remote", str(self.origin)).stdout, before, "dry run changed the origin")
        self.assertEqual({p["state"] for p in self.load()["prs"].values()}, {"OPEN"})

    def test_unknown_mergeable_stops_before_any_merge(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.st["force_mergeable"] = {"1": "UNKNOWN"}
        self.save()
        rc = self.run_main()
        self.assertEqual(rc, 2)
        self.assertEqual(self.load()["prs"]["1"]["state"], "OPEN")
        self.teardown.assert_not_called()
        self.pruner.assert_not_called()

    def test_gh_view_failure_stops(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.st["view_fail"] = True
        self.save()
        # fetch_open_prs (pr list) still works; the per-PR refresh fails.
        with mock.patch.object(merge_cleanup, "fetch_open_prs", return_value=[{"number": 1, "baseRefName": "development", "title": "t", "body": "", "files": [], "createdAt": "2026-09-01T01:00:00Z"}]):
            rc = self.run_main()
        self.assertEqual(rc, 2)
        self.assertEqual(self.load()["prs"]["1"]["state"], "OPEN")

    def test_hold_label_is_skipped_and_the_next_pr_still_lands(self):
        self.branch("feat/held", 1, lambda r: park(r, 200, "held"), labels=["do-not-merge"])
        self.branch("feat/b", 2, lambda r: park(r, 201, "free"))
        rc = self.run_main()
        self.assertEqual(rc, 0)
        st = self.load()
        self.assertEqual(st["prs"]["1"]["state"], "OPEN")
        self.assertEqual(st["prs"]["2"]["state"], "MERGED")

    def test_merge_exit_zero_without_MERGED_fails(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.st["merge_lies"] = True
        self.save()
        with mock.patch.object(merge_cleanup.time, "sleep"):
            rc = self.run_main()
        self.assertEqual(rc, 2)
        self.assertEqual(self.dev_rows(), [100, 101])
        self.pruner.assert_not_called()

    def test_failed_reconcile_stops_before_the_next_pr(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "y"))
        with mock.patch.object(merge_cleanup, "run_post_merge_reconcile", return_value=False):
            rc = self.run_main()
        self.assertEqual(rc, 2)
        st = self.load()
        self.assertEqual(st["prs"]["1"]["state"], "MERGED")
        self.assertEqual(st["prs"]["2"]["state"], "OPEN")
        self.teardown.assert_not_called()
        self.pruner.assert_not_called()

    def test_reconcile_pr_failure_propagates(self):
        with mock.patch.object(merge_cleanup, "run_post_merge_reconcile", return_value=False):
            rc = self.run_main(extra=["--reconcile-pr", "7"])
        self.assertEqual(rc, 2)

    def test_conflicting_pr_is_never_gh_merged_on_handoff(self):
        """Same gh_number parked on both sides: textual conflict, semantic conflict → handoff (rc 3)."""
        self.branch("feat/a", 1, lambda r: park(r, 200, "pr version"))
        self.branch("feat/b", 2, lambda r: park(r, 200, "other version"))
        rc = self.run_main()
        self.assertEqual(rc, 3)
        st = self.load()
        self.assertEqual(st["prs"]["1"]["state"], "MERGED")
        self.assertEqual(st["prs"]["2"]["state"], "OPEN")
        self.assertFalse(any(c[:3] == ["pr", "merge", "2"] for c in st["calls"]), "a handoff PR reached gh pr merge")

    def test_same_key_update_on_both_sides_is_handoff_and_nothing_is_overwritten(self):
        """THE PIN (B1): without the disjoint check the PR's update would be replayed over the
        integration side's, silently overwriting it. Dev's value must survive and the PR stays open."""
        self.branch("feat/a", 1, lambda r: _app(r, "roadmap", "update", "--issue-num", "100", "--section", "Completed"))
        self.branch("feat/b", 2, lambda r: _app(r, "roadmap", "update", "--issue-num", "100", "--section", "In progress"))
        rc = self.run_main()
        self.assertEqual(rc, 3)
        self.assertIn("same-key change on both sides", self.err)
        st = self.load()
        self.assertEqual(st["prs"]["1"]["state"], "MERGED")
        self.assertEqual(st["prs"]["2"]["state"], "OPEN")
        c = self.clone("verify-100")
        sec = subprocess.run([sys.executable, "-c", "import sqlite3,sys;print(sqlite3.connect(sys.argv[1]).execute(\"select section from roadmap_items where gh_number='100'\").fetchone()[0])", str(c / "releases.db")], capture_output=True, text=True).stdout.strip()
        self.assertEqual(sec, "Completed", "the integration side's update was overwritten")
        # And the PR branch itself was never pushed to.
        self.assertFalse(any(c[:3] == ["pr", "merge", "2"] for c in st["calls"]))

    def test_harnesses_conflict_is_handoff(self):
        def touch(r, text):
            (r / "harnesses.sql").write_text(text)
        self.branch("feat/a", 1, lambda r: touch(r, "INSERT one\n"))
        self.branch("feat/b", 2, lambda r: touch(r, "INSERT two\n"))
        rc = self.run_main()
        self.assertEqual(rc, 3)
        self.assertEqual(self.load()["prs"]["2"]["state"], "OPEN")

    def test_code_conflict_is_handoff(self):
        self.branch("feat/a", 1, lambda r: (r / "README.md").write_text("A\n"))
        self.branch("feat/b", 2, lambda r: (r / "README.md").write_text("B\n"))
        rc = self.run_main()
        self.assertEqual(rc, 3)

    def test_remote_head_moved_during_resolution_is_not_pushed(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "y"))
        real = merge_cleanup.validate_head_in_second_clone

        def move_then_validate(primary, clone, sha, wd):
            w = self.clone("mover")
            _git(w, "checkout", "-q", "-b", "feat/b", "origin/feat/b")
            (w / "late.txt").write_text("late\n")
            commit_all(w, "late commit on the PR branch")
            _git(w, "push", "-q", "origin", "feat/b")
            return real(primary, clone, sha, wd)
        with mock.patch.object(merge_cleanup, "validate_head_in_second_clone", side_effect=move_then_validate):
            rc = self.run_main()
        self.assertEqual(rc, 2)
        self.assertIn("remote head moved", self.err, "the refusal must come from the head comparison, not from git rejecting the push")
        head = _git(self.probe, "ls-remote", str(self.origin), "refs/heads/feat/b").stdout.split()[0]
        w = self.clone("check-late")
        self.assertIn("late commit", _git(w, "log", "-1", "--format=%s", head).stdout)
        self.assertEqual(self.load()["prs"]["2"]["state"], "OPEN")

    def test_second_clone_validation_failure_is_not_pushed(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "y"))
        before = _git(self.probe, "ls-remote", str(self.origin), "refs/heads/feat/b").stdout
        with mock.patch.object(merge_cleanup, "validate_head_in_second_clone", return_value=(False, "injected")), \
             mock.patch.object(merge_cleanup, "push_resolved_head", return_value=(True, "mocked")) as push:
            rc = self.run_main()
        self.assertEqual(rc, 2)
        push.assert_not_called()
        self.assertEqual(_git(self.probe, "ls-remote", str(self.origin), "refs/heads/feat/b").stdout, before)

    def test_generation_rewind_refusal_stops_and_keeps_the_clone(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "y"))
        real = ledger_merge.replay_ops

        def replay_then_rewind(root, ops):
            ok, log = real(root, ops)
            import re as _re
            s = _re.sub(r"^-- generation: \d+$", "-- generation: 1", (root / "releases.sql").read_text(), count=1, flags=_re.M)
            (root / "releases.sql").write_text(s)  # header rewound below both parents
            return ok, log
        with mock.patch.object(ledger_merge, "replay_ops", side_effect=replay_then_rewind), \
             mock.patch.object(merge_cleanup, "push_resolved_head", return_value=(True, "mocked")) as push:
            rc = self.run_main()
        self.assertEqual(rc, 2)
        push.assert_not_called()

    def test_extraction_error_is_handoff_not_no_conflict(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "y"))
        real = scan_clones.run_git

        def flaky(cwd, args):
            if args[:2] == ["ls-files", "-u"]:
                return subprocess.CompletedProcess(args=args, returncode=1, stdout="", stderr="refused")
            return real(cwd, args)
        with mock.patch.object(ledger_merge, "run_git", side_effect=flaky):
            rc = self.run_main()
        self.assertEqual(rc, 3)
        self.assertIn("conflict-set extraction failed", self.err, "an extraction error must be reported as such, not as an empty conflict set")
        self.assertEqual(self.load()["prs"]["2"]["state"], "OPEN")


class TestE6Gate(LedgerFixture):
    def _merged_clone(self):
        """A clone at a PR head with origin/development merged cleanly (non-ledger PR)."""
        self.branch("feat/doc", 1, lambda r: (r / "NOTE.md").write_text("doc only\n"))
        c = self.clone("gate")
        _git(c, "checkout", "-q", "--detach", "origin/feat/doc")
        r = _git(c, "merge", "--no-edit", "origin/development", check=False)
        self.assertEqual(r.returncode, 0)
        return c

    def test_clean_merge_is_green_with_diagnostics_only(self):
        c = self._merged_clone()
        v = pre_merge_ledger_gate(c, gh_bin=str(self.gh))
        self.assertTrue(v["green"], v)

    def test_check_failure_names_the_rule(self):
        c = self._merged_clone()
        s = (c / "releases.sql").read_text().replace("-- generation: ", "-- generation: 9", 1)
        (c / "releases.sql").write_text(s)
        v = pre_merge_ledger_gate(c, gh_bin=str(self.gh))
        self.assertFalse(v["green"])
        self.assertTrue(any("rule=" in f for f in v["failures"]), v["failures"])

    def test_check_command_error_is_red(self):
        c = self._merged_clone()
        (c / "utils" / "py" / "releases_app.py").write_text("import sys; sys.exit(4)\n")
        v = pre_merge_ledger_gate(c, gh_bin=str(self.gh))
        self.assertFalse(v["green"])
        self.assertTrue(any("exit 4" in f for f in v["failures"]), v["failures"])

    def test_gate_red_prevents_the_merge(self):
        """THE PIN (E.6): a PR that is green alone but red once the integration head is merged in
        is never `gh pr merge`d. Simulated by a gate that goes red on the merged tree."""
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        with mock.patch.object(merge_cleanup, "pre_merge_ledger_gate", return_value={"green": False, "failures": ["releases check: FAIL: rule=synthetic"], "diagnostics": []}):
            rc = self.run_main()
        self.assertEqual(rc, 2)
        st = self.load()
        self.assertEqual(st["prs"]["1"]["state"], "OPEN")
        self.assertFalse(any(c[:2] == ["pr", "merge"] for c in st["calls"]))

    def test_gate_runs_against_the_current_integration_head(self):
        """PR 2's gate must see PR 1's landing: assert the clone the gate ran in contains PR 1's row."""
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.branch("feat/b", 2, lambda r: (r / "NOTE.md").write_text("doc only\n"))
        seen = []
        real = merge_cleanup.pre_merge_ledger_gate

        def spy(clone, gh_bin="gh", **kw):
            seen.append((clone / "releases.sql").read_text())
            return real(clone, gh_bin, **kw)
        with mock.patch.object(merge_cleanup, "pre_merge_ledger_gate", side_effect=spy):
            rc = self.run_main()
        self.assertEqual(rc, 0)
        self.assertEqual(len(seen), 2)
        self.assertIn("'200'", seen[1], "PR 2's gate did not run against a tree containing PR 1's landing")


if __name__ == "__main__":
    unittest.main()
