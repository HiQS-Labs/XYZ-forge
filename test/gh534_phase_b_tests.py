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
sys.path.insert(0, str(REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts"))

import ledger_merge  # noqa: E402
import merge_cleanup  # noqa: E402
import scan_clones  # noqa: E402
from ledger_merge import classify, parse_dump, pre_merge_ledger_gate, resolve_ledger_conflict  # noqa: E402
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
def infer_merged(st, pr):
    """GH-1656: GitHub marks an OPEN PR MERGED once its head is reachable from the base (a direct
    push). Opt-in per test (`infer_merged`), from real origin ancestry only; `confirm_lag` N skips
    the inference N times, `confirm_withheld` never infers, `confirm_oid` reports another commit."""
    if not st.get("infer_merged") or pr["state"] != "OPEN" or st.get("confirm_withheld"):
        return
    probe = st["probe"]
    head = git(probe, "rev-parse", "origin/" + pr["headRefName"]).stdout.strip()
    if not head or git(probe, "merge-base", "--is-ancestor", head, "origin/" + st["base"]).returncode != 0:
        return
    if st.get("confirm_lag", 0) > 0:  # counts only reads made after the head reached the base
        st["confirm_lag"] -= 1
        save(st)
        return
    merges = git(probe, "rev-list", "--ancestry-path", "--merges", "--reverse", f"{head}..origin/{st['base']}").stdout.split()
    pr.update(state="MERGED", headRefOid=head, mergeCommit=st.get("confirm_oid") or (merges[0] if merges else head))
    save(st)
def view(st, pr):
    git(st["probe"], "fetch", "-q", "origin")
    infer_merged(st, pr)
    head = git(st["probe"], "rev-parse", "origin/" + pr["headRefName"]).stdout.strip() if pr["state"] == "OPEN" else pr.get("headRefOid")
    d = {"number": pr["number"], "state": pr["state"], "headRefName": pr["headRefName"], "baseRefName": st["base"],
         "isDraft": pr.get("isDraft", False), "labels": [{"name": l} for l in pr.get("labels", [])], "headRefOid": head or pr.get("headRefOid"),
         "mergeCommit": ({"oid": pr["mergeCommit"]} if pr.get("mergeCommit") else None),
         "url": f"https://example.invalid/pr/{pr['number']}", "title": f"PR {pr['number']}", "body": pr.get("body", ""),
         "files": pr.get("files", []), "createdAt": f"2026-09-01T0{pr['number'] % 10}:00:00Z", "statusCheckRollup": []}
    forced = st.get("force_mergeable", {}).get(str(pr["number"]))
    if isinstance(forced, dict):  # GH-736: {"value": ..., "remaining": N} reads `value` N times, then the truth
        if forced.get("remaining", 0) > 0:
            forced["remaining"] -= 1
            save(st)
            forced = forced["value"]
        else:
            forced = None
    d["mergeable"] = forced or (mergeable(st, pr) if pr["state"] == "OPEN" else "UNKNOWN")
    return d
def stub_fail(st, key, prnum=None):
    """GH-623: a failure injector. `True` -> fixed non-transient message (back-compat);
    {"remaining": N, "msg": ...} -> a global countdown; {"<pr#>": {...}} -> per-PR countdown.
    Counts down only when it fires, so a test can make exactly the first N calls fail."""
    spec = st.get(key)
    if not spec:
        return None
    if isinstance(spec, dict):
        entry = spec.get(str(prnum), spec if "remaining" in spec else None)
        if entry and entry.get("remaining", 0) > 0:
            entry["remaining"] -= 1
            save(st)
            return entry.get("msg") or f"stub: {key} failed"
        return None
    return f"stub: {key} failed"
a = sys.argv[1:]
st = load()
st.setdefault("calls", []).append(a); save(st)
if a[:2] == ["repo", "view"]:
    print(json.dumps({"url": st["origin"]})); sys.exit(0)
# GH-1064: the batch issue. Bodies live in st["issues"].
if a[:2] == ["label", "create"]:
    sys.exit(0)
if a[:2] == ["issue", "create"]:
    n = str(900 + len(st.setdefault("issues", {})))
    st["issues"][n] = open(a[a.index("--body-file") + 1]).read(); save(st)
    print(f"https://example.invalid/issues/{n}"); sys.exit(0)
if a[:2] == ["issue", "edit"]:
    st.setdefault("issues", {})[a[2]] = open(a[a.index("--body-file") + 1]).read(); save(st); sys.exit(0)
if a[:2] == ["issue", "view"] and "body" in a:
    if a[2] not in st.get("issues", {}):
        print("stub: no such issue", file=sys.stderr); sys.exit(1)
    print(json.dumps({"body": st["issues"][a[2]]})); sys.exit(0)
if a[:2] == ["issue", "view"]:
    print(json.dumps({"state": "OPEN", "stateReason": None})); sys.exit(0)
if a[:2] == ["pr", "list"]:
    if "--state" in a and a[a.index("--state") + 1] == "merged":
        print(json.dumps([{"number": p["number"], "state": "MERGED", "headRefOid": p.get("headRefOid"),
                           "mergeCommit": {"oid": p.get("mergeCommit")}, "baseRefName": st["base"]}
                          for p in st["prs"].values() if p["state"] == "MERGED"])); sys.exit(0)
    fail = stub_fail(st, "list_fail")
    if fail:
        print(fail, file=sys.stderr); sys.exit(1)
    print(json.dumps([view(st, p) for p in st["prs"].values() if p["state"] == "OPEN"])); sys.exit(0)
if a[:2] == ["pr", "view"]:
    pr = st["prs"].get(a[2])
    fail = stub_fail(st, "view_fail", a[2]) if pr is not None else "stub: view failed"
    if fail:
        print(fail, file=sys.stderr); sys.exit(1)
    print(json.dumps(view(st, pr))); sys.exit(0)
if a[:2] == ["pr", "merge"]:
    pr = st["prs"][a[2]]
    if st.get("merge_lies"): sys.exit(0)
    if st.get("force_mergeable", {}).get(a[2]) == "CONFLICTING":  # GH-1656: GitHub refuses what it calls CONFLICTING
        print(f"X Pull request example/repo#{a[2]} is not mergeable: the merge commit cannot be cleanly created.", file=sys.stderr)
        sys.exit(1)
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
if a[:2] == ["pr", "checks"]:  # GH-1226: st["checks"][N] = [{"name":..,"bucket":..}]; absent = none required
    checks = st.get("checks", {}).get(a[2])
    if checks is None:
        print(f"no required checks reported on the '{st['base']}' branch", file=sys.stderr); sys.exit(1)
    print(json.dumps(checks))
    buckets = {c["bucket"] for c in checks}
    sys.exit(1 if buckets & {"fail", "cancel"} else 8 if "pending" in buckets else 0)
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
        # GH-1576: merge-cleanup refuses to push from a clone whose `githooks/install.sh --check` fails, and this
        # fixture's synthetic seed repo has no `githooks/`. The suites built on it exercise landing, repair and
        # ledger behaviour, not hook wiring (the refusal itself is witnessed by TESTS-RESULTS/2026-11-21+GH-1576/),
        # so the probe is stubbed here, scoped to each fixture test and restored afterwards. test/gh436-merge-cleanup.py
        # stubs it module-wide for its own process; this keeps the standalone phase B and C runs truthful too (GH-1615).
        wiring = mock.patch.object(merge_cleanup, "gate_unwired_reason", lambda clone, install=False: "")
        wiring.start()
        self.addCleanup(wiring.stop)

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

    def pin(self, prs=None, branch="development"):
        """GH-1226: stand in for the dry run — pin the open PRs (or `prs`) at their current heads."""
        open_prs = {int(n): p for n, p in self.st["prs"].items() if p["state"] == "OPEN"}
        nums = sorted(open_prs) if prs is None else list(prs)
        heads = {str(n): _git(self.probe, "ls-remote", str(self.origin), "refs/heads/" + open_prs[n]["headRefName"]).stdout.split()[0]
                 for n in nums if n in open_prs}
        path = merge_cleanup.selection_path(self.primary.resolve(), merge_cleanup.origin_url(self.primary) or "", branch)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps({"integration": branch, "prs": heads}))
        return nums

    def assert_repinned(self, n):
        """GH-1475 (P2.1): a B1-repaired head lands in the run that pushed it, once its checks pass
        on that exact commit; the run re-pins it instead of deferring it to a second dry run."""
        self.assertNotIn(f"PR #{n}: DEFERRED — head", self.err)
        pr = self.load()["prs"][str(n)]
        self.assertEqual(pr["state"], "MERGED", self.err)
        path = merge_cleanup.selection_path(self.primary.resolve(), merge_cleanup.origin_url(self.primary) or "",
                                            "development")
        self.assertEqual(json.loads(path.read_text())["prs"][str(n)], pr["headRefOid"],
                         "the published selection must pin the repaired head that merged")

    def run_main(self, execute=True, extra=()):
        extra = list(extra)
        self.load()
        if (execute and "--prs" not in extra and not {"--teardown-only", "--scan-only", "--prs-only"} & set(extra)):
            nums = self.pin()
            if nums:
                extra += ["--prs", ",".join(map(str, nums))]
        argv = ["merge_cleanup.py", "--primary", str(self.primary), "--root", str(self.tmp / "no-roots")] + extra
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

    def test_gid_remint_of_unchanged_base_row_is_disjoint_but_an_edit_is_not(self):
        root = self.clone("remint-base")
        park(root, 678, "remint source")
        base = (root / "releases.sql").read_text()
        ours_root = self.tmp / "remint-ours"
        theirs_root = self.tmp / "remint-theirs"
        shutil.copytree(root, ours_root)
        shutil.copytree(root, theirs_root)
        park(ours_root, 680, "ours only")
        park(theirs_root, 679, "theirs only")
        ours = (ours_root / "releases.sql").read_text()
        theirs = (theirs_root / "releases.sql").read_text()

        base_row = next(row for row in parse_dump(base)["tables"]["roadmap_items"].values()
                        if row["gh_number"] == "678")
        old_gid = base_row["global_id"]
        new_gid = old_gid[:-1] + ("0" if old_gid[-1] != "0" else "1")
        theirs = theirs.replace(f"VALUES('{old_gid}',", f"VALUES('{new_gid}',", 1)

        c = classify(base, ours, theirs)
        self.assertTrue(c["disjoint"], c["reasons"])
        self.assertEqual(c["keep"], "theirs")
        self.assertEqual([op["row"]["gh_number"] for op in c["replay"]], ["680"])

        edited_ours = ours.replace("'remint source'", "'remint source edited'", 1)
        red = classify(base, edited_ours, theirs)
        self.assertFalse(red["disjoint"])
        self.assertTrue(any("same-key" in reason or "gh_number 678" in reason
                            for reason in red["reasons"]), red["reasons"])

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
        self.assert_repinned(2)  # GH-1475 (P2.1): PR 2's repaired head is re-pinned in the same run
        self.assertEqual(rc, 4, self.err)  # GH-1064: landed, QA pending (no sweep verdict yet); Phase 6 still ran
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
        sleeps = []  # GH-736: record the poll schedule without waiting it out
        with mock.patch.object(merge_cleanup, "_sleep", side_effect=sleeps.append):
            rc = self.run_main()
        self.assertEqual(rc, 2)
        self.assertEqual(self.load()["prs"]["1"]["state"], "OPEN")
        self.teardown.assert_not_called()
        self.pruner.assert_not_called()
        # GH-736: the stop comes only after the bounded poll, never on the first UNKNOWN read.
        polls = [s for s in sleeps if s == merge_cleanup.MERGEABLE_POLL_S]
        self.assertEqual(len(polls), merge_cleanup.MERGEABLE_POLL_ATTEMPTS, sleeps)

    def test_unknown_mergeable_settles_and_the_pr_lands(self):
        # GH-736: GitHub reads UNKNOWN for a few seconds after every landing on the base; a PR
        # that settles to MERGEABLE inside the poll lands instead of stopping the run.
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.st["force_mergeable"] = {"1": {"value": "UNKNOWN", "remaining": 3}}
        self.save()
        out, sleeps = io.StringIO(), []
        with contextlib.redirect_stdout(out), mock.patch.object(merge_cleanup, "_sleep", side_effect=sleeps.append):
            rc = self.run_main()
        self.assertEqual(rc, 0, self.err)
        self.assertEqual(self.load()["prs"]["1"]["state"], "MERGED")
        polls = [s for s in sleeps if s == merge_cleanup.MERGEABLE_POLL_S]
        self.assertTrue(1 <= len(polls) < merge_cleanup.MERGEABLE_POLL_ATTEMPTS, sleeps)
        self.assertIn("waiting 15s for GitHub to decide", out.getvalue())

    def test_unlisted_pr_is_never_sequenced(self):
        # GH-1226 (was GH-736's --exclude): --prs is an allowlist pinned by the dry run. PR 1 is
        # open but unlisted, so it is never sequenced or merged; PR 2 lands at its pinned head.
        self.branch("feat/a", 1, lambda r: park(r, 200, "unlisted"))
        self.branch("feat/b", 2, lambda r: park(r, 201, "kept"))
        self.pin([2])
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            rc = self.run_main(extra=("--prs", "2"))
        self.assertEqual(rc, 0, self.err)
        st = self.load()
        self.assertEqual(st["prs"]["1"]["state"], "OPEN")
        self.assertEqual(st["prs"]["2"]["state"], "MERGED")
        self.assertIn("PR #1: not in --prs; not sequenced", out.getvalue())

    def _error_after_first_read(self, msg):
        """GH-736: the first land-loop read is real (UNKNOWN via force_mergeable); every read after
        it — i.e. the poll's — fails with `msg`."""
        real, calls = merge_cleanup.refresh_pr_with_retry, []
        def fake(n, repo):
            calls.append(n)
            return real(n, repo) if len(calls) == 1 else {"error": msg}
        return fake, calls

    def test_transient_error_during_the_poll_defers_not_undecided(self):
        # Agy QA r1 blocker 1: an error inside the poll was masked as "GitHub has not decided" and
        # stopped the run; a transient one must defer the PR under the GH-623 rules instead.
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.st["force_mergeable"] = {"1": "UNKNOWN"}
        self.save()
        fake, calls = self._error_after_first_read("gh: Could not resolve host: github.com")
        with mock.patch.object(merge_cleanup, "refresh_pr_with_retry", side_effect=fake), \
             mock.patch.object(merge_cleanup, "_sleep"):
            rc = self.run_main()
        self.assertEqual(rc, 3, self.err)
        self.assertIn("DEFERRED", self.err)
        self.assertNotIn("has not decided", self.err)
        self.assertEqual(len(calls), 2, "the poll must stop at the first failed read, not retry it")
        self.assertEqual(self.load()["prs"]["1"]["state"], "OPEN")

    def test_hard_error_during_the_poll_stops_with_that_error(self):
        self.branch("feat/a", 1, lambda r: park(r, 200, "x"))
        self.st["force_mergeable"] = {"1": "UNKNOWN"}
        self.save()
        fake, _ = self._error_after_first_read("HTTP 404: Not Found (pr view)")
        with mock.patch.object(merge_cleanup, "refresh_pr_with_retry", side_effect=fake), \
             mock.patch.object(merge_cleanup, "_sleep"):
            rc = self.run_main()
        self.assertEqual(rc, 2, self.err)
        self.assertIn("HTTP 404: Not Found", self.err)
        self.assertNotIn("has not decided", self.err)
        self.assertEqual(self.load()["prs"]["1"]["state"], "OPEN")

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
        self.assertEqual(rc, 4)  # GH-1064: PR 2 landed with no sweep verdict, whatever PR 1's hold
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
        # --reconcile-pr refuses an unmerged PR (GH-852); PR 7 is merged, so rc 2 is the reconcile's.
        self.st["prs"]["7"] = {"number": 7, "state": "MERGED", "headRefName": "feat/seven", "labels": [],
                               "headRefOid": "a" * 40, "mergeCommit": "b" * 40}
        self.save()
        with mock.patch.object(merge_cleanup, "run_post_merge_reconcile", return_value=False) as reconcile:
            rc = self.run_main(extra=["--reconcile-pr", "7"])
        self.assertEqual(rc, 2)
        reconcile.assert_called_once()

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
        self.assertFalse(any(c[:2] == ["issue", "create"] for c in st["calls"]), "a 1-PR run opened a batch issue")

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
        self.assertEqual(rc, 4)  # GH-1064: landed, QA pending
        self.assertEqual(len(seen), 2)
        self.assertIn("'200'", seen[1], "PR 2's gate did not run against a tree containing PR 1's landing")


class TestGh1656NonLedgerConflict(LedgerFixture):
    """GH-1656: GitHub reads CONFLICTING but the conflict is not in the ledger. A clean local merge
    lands through the gated local-merge rung (merge strategy); anything else stops BEFORE
    `gh pr merge`. The stub refuses `pr merge` for a forced-CONFLICTING PR, as GitHub does, and infers
    MERGED only from real origin ancestry after a direct push."""

    def setUp(self):
        super().setUp()
        self.st["infer_merged"] = True
        self.save()
        sl = mock.patch.object(merge_cleanup, "_sleep", lambda s: None)
        sl.start()
        self.addCleanup(sl.stop)

    def land(self, execute=True, extra=("--strategy", "merge")):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            rc = self.run_main(execute=execute, extra=list(extra))
        self.out = out.getvalue()
        return rc

    def conflicting_pr(self, number=1, name="feat/a", two_commits=False):
        """A non-ledger PR cut from the current base (its simulation is up to date, no MERGE_HEAD)
        that GitHub nevertheless reports CONFLICTING."""
        def fn(r):
            (r / "docs").mkdir(exist_ok=True)
            if two_commits:
                (r / "docs" / f"pr{number}-1.md").write_text("first\n")
                commit_all(r, f"PR {number} first")
            (r / "docs" / f"pr{number}.md").write_text(f"pr {number}\n")
        head = self.branch(name, number, fn)
        self.st.setdefault("force_mergeable", {})[str(number)] = "CONFLICTING"
        self.save()
        return head

    def merge_calls(self, n):
        return [c for c in self.load()["calls"] if c[:3] == ["pr", "merge", str(n)]]

    def git_origin(self, *a):
        _git(self.probe, "fetch", "-q", "origin")
        return _git(self.probe, *a).stdout.strip()

    def push_child_of_origin(self, tag):
        w = self.clone(f"child-{tag}-{len(os.listdir(self.tmp))}")
        _git(w, "checkout", "-q", "development")
        (w / f"{tag}.txt").write_text(tag + "\n")
        sha = commit_all(w, tag)
        _git(w, "push", "-q", "origin", "development")
        return sha

    def issue_body(self):
        bodies = list((self.load().get("issues") or {}).values())
        return bodies[-1] if bodies else ""

    # --- R1 / R4 -----------------------------------------------------------------------------------

    def test_clean_conflicting_lands_through_rung(self):
        base = self.origin_dev()
        pin = self.conflicting_pr(1)
        self.branch("feat/b", 2, lambda r: (r / "b.txt").write_text("b\n"))
        rc = self.land()
        self.assertEqual(rc, 4, self.err)  # landed, QA pending (GH-1064)
        st = self.load()
        self.assertEqual({p["state"] for p in st["prs"].values()}, {"MERGED"}, self.err)
        self.assertEqual(self.merge_calls(1), [], "a CONFLICTING PR reached `gh pr merge`")
        self.assertTrue(self.merge_calls(2))
        mc = st["prs"]["1"]["mergeCommit"]
        self.assertEqual(self.git_origin("rev-parse", f"{mc}^1"), base, "first parent is not the gated base")
        self.assertEqual(self.git_origin("rev-parse", f"{mc}^2"), pin, "second parent is not the pin")
        self.assertIn("local-merge rung", self.out)
        self.assertIn("merged (local-merge rung)", self.issue_body())

    def test_rung_label_survives_recovery(self):
        import batch_record
        rec = {"planned": [{"pos": 1, "pr": 1, "title": "t", "hard": [], "soft": {}}], "outcomes": {}}
        rec["outcomes"]["1"] = {"status": "merged", "merge_oid": "c" * 40, "rung": "local-merge", "rung_oid": "c" * 40}
        self.assertIn("merged (local-merge rung)", batch_record.script_block(rec))
        rec["outcomes"]["1"]["merge_oid"] = "d" * 40
        block = batch_record.script_block(rec)
        self.assertNotIn("local-merge rung", block)

    # --- publication safety ------------------------------------------------------------------------

    def test_rejecting_hook_leaves_origin_unchanged(self):
        self.conflicting_pr(1)
        before = self.origin_dev()
        real = merge_cleanup.prepare_landing_clone

        def with_hook(*a, **k):
            prep = real(*a, **k)
            hook = Path(prep["clone"]) / ".git" / "hooks" / "pre-push"
            hook.write_text('#!/bin/sh\n[ "${XYZ_SKIP_PREPUSH:-0}" != "0" ] && exit 0\n'
                            'echo "rejected by the GH-1656 test hook" >&2\nexit 1\n')
            hook.chmod(0o755)
            return prep
        with mock.patch.object(merge_cleanup, "prepare_landing_clone", with_hook), \
             mock.patch.dict(os.environ, {"XYZ_SKIP_PREPUSH": "1"}):
            rc = self.land()
        self.assertEqual(rc, 2, self.err)
        self.assertEqual(self.origin_dev(), before, "the push bypassed the hook")
        self.assertEqual(self.load()["prs"]["1"]["state"], "OPEN")
        self.assertIn("rejected by the GH-1656 test hook", self.err)

    def test_moved_base_refused(self):
        pin = self.conflicting_pr(1, two_commits=True)
        first = self.git_origin("rev-parse", f"{pin}^1")  # reachable through the pinned parent
        fired = []

        def advance(clone, install=False):
            if not install and not fired:
                fired.append(1)
                _git(self.probe, "push", "-q", "origin", f"{first}:refs/heads/development")
            return ""
        with mock.patch.object(merge_cleanup, "gate_unwired_reason", advance):
            rc = self.land()
        self.assertTrue(fired)
        self.assertEqual(rc, 2, self.err)
        self.assertEqual(self.origin_dev(), first, "the lease did not hold the gated base")
        self.assertEqual(self.load()["prs"]["1"]["state"], "OPEN")

    def test_pr_closed_or_retargeted_before_push_stops(self):
        for n, field, value in ((1, "state", "CLOSED"), (3, "baseRefName", "main")):
            with self.subTest(field=field):
                self.load()
                self.st["prs"].clear()
                self.st.pop("force_mergeable", None)
                self.save()
                self.conflicting_pr(n, name=f"feat/{field}")
                before = self.origin_dev()
                real = merge_cleanup._final_eligibility_veto

                def mutate(live, _f=field, _v=value):
                    live[_f] = _v
                    return real(live)
                with mock.patch.object(merge_cleanup, "_final_eligibility_veto", mutate):
                    rc = self.land()
                self.assertEqual(rc, 2, self.err)
                self.assertEqual(self.origin_dev(), before)
                self.assertEqual(self.merge_calls(n), [])

    def test_confirmation_lag_then_tail_once(self):
        self.conflicting_pr(1)
        self.st["confirm_lag"] = 2
        self.save()
        real = merge_cleanup.run_post_merge_reconcile
        with mock.patch.object(merge_cleanup, "run_post_merge_reconcile", side_effect=real) as rec:
            rc = self.land()
        self.assertEqual(rc, 0, self.err)
        self.assertEqual(self.load()["prs"]["1"]["state"], "MERGED")
        self.assertEqual(self.load().get("confirm_lag"), 0, "confirmation never lagged")
        self.assertEqual(rec.call_count, 1)

    def test_confirmed_rung_reconciles_candidate(self):
        self.conflicting_pr(1)
        self.st["confirm_lag"] = 1
        self.save()
        pushed = []
        seen = []

        def sleep(_s):
            if not pushed:
                pushed.append(self.push_child_of_origin("descendant"))

        def hosted(merged_head, repo, branch, pr_head=None):
            seen.append((merged_head, pr_head))
            return "fallback"
        with mock.patch.object(merge_cleanup, "_sleep", sleep), \
             mock.patch.object(merge_cleanup, "wait_for_hosted_reconcile", hosted), \
             mock.patch.dict(os.environ, {merge_cleanup.USE_HOSTED_ENV: "1"}):
            rc = self.land()
        self.assertEqual(rc, 0, self.err)
        self.assertTrue(pushed, "the descendant was never published during confirmation")
        mc = self.load()["prs"]["1"]["mergeCommit"]
        self.assertEqual(len(seen), 1, seen)
        self.assertEqual(seen[0][0], mc, "hosted lookup did not receive the rung's candidate")
        self.assertNotEqual(_git(self.primary, "rev-parse", "HEAD").stdout.strip(), mc)

    def test_confirmation_withheld_stops_without_reconcile(self):
        for a, b, knob, word in ((1, 2, {"confirm_withheld": True}, "has not confirmed"),
                                 (3, 4, {"confirm_oid": "e" * 40}, "investigate")):
            with self.subTest(knob=knob):
                self.st = {k: v for k, v in self.load().items() if k not in ("confirm_withheld", "confirm_oid")}
                self.st["prs"] = {}
                self.st.pop("force_mergeable", None)
                self.st.update(knob)
                self.save()
                tag = list(knob)[0]
                pin = self.conflicting_pr(a, name=f"feat/a-{tag}")
                self.branch(f"feat/b-{tag}", b, lambda r, t=tag: (r / f"b-{t}.txt").write_text("b\n"))
                real = merge_cleanup.run_post_merge_reconcile
                with mock.patch.object(merge_cleanup, "run_post_merge_reconcile", side_effect=real) as rec:
                    rc = self.land()
                self.assertEqual(rc, 2, self.err)
                self.assertEqual(rec.call_count, 0)
                self.assertEqual(self.git_origin("rev-parse", "origin/development^2"), pin, "the candidate was not published")
                self.assertEqual(self.load()["prs"][str(b)]["state"], "OPEN", "the queue continued past an unconfirmed landing")
                self.assertIn(word, self.err)
                body = self.issue_body()
                self.assertIn("stopped: ", body)
                self.assertIn("local-merge rung published", body)
                self.assertNotIn("merged (local-merge rung)", body)

    def test_push_acknowledgement_lost(self):
        for n, descendant in ((1, False), (3, True)):
            with self.subTest(descendant=descendant):
                self.load()
                self.st["prs"].clear()
                self.st.pop("force_mergeable", None)
                self.save()
                self.conflicting_pr(n, name=f"feat/ack-{descendant}")
                real = merge_cleanup._net_git
                pushes = []

                def lossy(cwd, args, *a, **k):
                    r = real(cwd, args, *a, **k)
                    if args and args[0] == "push" and any(x.startswith("--force-with-lease") for x in args):
                        pushes.append(r.returncode)
                        if descendant:
                            self.push_child_of_origin(f"after-ack-{len(pushes)}")
                        return subprocess.CompletedProcess(args, 124, stdout="", stderr="timed out")
                    return r
                with mock.patch.object(merge_cleanup, "_net_git", lossy):
                    rc = self.land()
                self.assertEqual(len(pushes), 1, "the rung pushed more than once")
                self.assertEqual(pushes[0], 0, "the real push itself failed")
                self.assertEqual(rc, 0, self.err)
                self.assertEqual(self.load()["prs"][str(n)]["state"], "MERGED")

    # --- R2 ----------------------------------------------------------------------------------------

    def test_clean_conflicting_under_squash_stops(self):
        self.conflicting_pr(1)
        before = self.origin_dev()
        with mock.patch.object(merge_cleanup, "_protect_stacked_dependents") as stack:
            rc = self.land(extra=())
        self.assertEqual(rc, 2, self.err)
        self.assertIn("non-ledger conflict; local merge clean", self.err)
        self.assertEqual(self.merge_calls(1), [])
        self.assertEqual(self.origin_dev(), before)
        stack.assert_not_called()

    def test_dirty_non_ledger_conflict_message(self):
        self.branch("feat/a", 1, lambda r: (r / "README.md").write_text("from the PR\n"))
        (self.seed / "README.md").write_text("from development\n")
        commit_all(self.seed, "base edits README")
        _git(self.seed, "push", "-q", "origin", "development")
        rc = self.land()
        self.assertEqual(rc, 3, self.err)  # the existing B1 handoff exit
        self.assertIn("non-ledger conflict; local merge dirty: README.md", self.err)
        self.assertEqual(self.merge_calls(1), [])

    # --- R3 ----------------------------------------------------------------------------------------

    def test_dry_run_conflicting_clean_previews_rung(self):
        self.conflicting_pr(1)
        rc = self.land(execute=False)
        self.assertEqual(rc, 0, self.err)
        self.assertNotIn("Would merge PR #1", self.out)
        self.assertIn("local-merge rung", self.out)

    def test_dry_run_unknown_never_previews_merge(self):
        self.branch("feat/a", 1, lambda r: (r / "a.txt").write_text("a\n"))
        self.st["force_mergeable"] = {"1": "UNKNOWN"}
        self.save()
        rc = self.land(execute=False)
        self.assertEqual(rc, 2, self.err)
        self.assertNotIn("Would merge PR #1", self.out)
        self.assertIn("GitHub has not decided", self.err)


class TestGh736AwaitMergeable(unittest.TestCase):
    """GH-736 `_await_mergeable`: bounded, stops on the first error, never re-polls an error."""

    def _run(self, first, reads):
        seq = iter(reads)
        with mock.patch.object(merge_cleanup, "refresh_pr_with_retry", side_effect=lambda n, r: next(seq)) as rf, \
             mock.patch.object(merge_cleanup, "_sleep") as sl, \
             contextlib.redirect_stdout(io.StringIO()):
            out = merge_cleanup._await_mergeable(7, first, Path("."))
        return out, rf.call_count, sl.call_count

    def test_decided_first_read_is_not_polled(self):
        for state in ("MERGEABLE", "CONFLICTING"):
            out, refreshes, sleeps = self._run({"mergeable": state}, [])
            self.assertEqual((out["mergeable"], refreshes, sleeps), (state, 0, 0))

    def test_an_error_in_hand_is_not_polled(self):
        # Agy QA r1 blocker 2: a failed post-B1 re-fetch was re-polled six times.
        out, refreshes, sleeps = self._run({"error": "boom"}, [])
        self.assertEqual((out.get("error"), refreshes, sleeps), ("boom", 0, 0))

    def test_an_error_mid_poll_is_returned_at_once(self):
        out, refreshes, sleeps = self._run({"mergeable": "UNKNOWN"}, [{"mergeable": "UNKNOWN"}, {"error": "net"}])
        self.assertEqual((out.get("error"), refreshes, sleeps), ("net", 2, 2))

    def test_undecided_is_bounded_and_returned_undecided(self):
        reads = [{"mergeable": "UNKNOWN"}] * merge_cleanup.MERGEABLE_POLL_ATTEMPTS
        out, refreshes, sleeps = self._run({"mergeable": "UNKNOWN"}, reads)
        self.assertEqual(out["mergeable"], "UNKNOWN")
        self.assertEqual(refreshes, merge_cleanup.MERGEABLE_POLL_ATTEMPTS)
        self.assertEqual(sleeps, merge_cleanup.MERGEABLE_POLL_ATTEMPTS)

if __name__ == "__main__":
    unittest.main()
