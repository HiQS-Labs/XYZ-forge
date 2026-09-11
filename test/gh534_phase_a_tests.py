#!/usr/bin/env python3
"""test/gh534_phase_a_tests.py — GH-534 Phase A: the scanner tells the truth and fails closed.

Imported by test/gh436-merge-cleanup.py (one registered entry point, A.6). Every fixture is a real
git repo with a real local origin; `tick` is the real bin/tick; `lsof` is the real binary except
where a case needs a stub (absent, signal-killed). `gh` is always a stub — no network.

Sections: A.1 roots · A.2 provenance · A.3 dirt · A.4 session evidence (tick + lsof) · A.5 fresh
inspection + fail-closed queries.
"""

import ast
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
import unittest.mock as mock
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "skills" / "merge-cleanup" / "scripts"))

import scan_clones  # noqa: E402
import merge_cleanup  # noqa: E402
from scan_clones import (  # noqa: E402
    DEFAULT_SAFE_ROOTS, GH_BIN_ENV, LSOF_BIN_ENV, TICK_BIN_ENV,
    classify_local_refs, inspect_checkout, inspect_open_handles, inspect_tick_claims,
    is_safe_deletable_path, scan_directories,
)

TICK = REPO / "bin" / "tick"


def _git(cwd, *args, check=True):
    return subprocess.run(["git", "-C", str(cwd)] + list(args), capture_output=True, text=True, check=check)


def _commit(cwd, name, content, msg=None):
    (Path(cwd) / name).parent.mkdir(parents=True, exist_ok=True)
    (Path(cwd) / name).write_text(content)
    _git(cwd, "add", "-A")
    _git(cwd, "commit", "-q", "-m", msg or f"add {name}")
    return _git(cwd, "rev-parse", "HEAD").stdout.strip()


def make_origin_and_clone(tmp, name="clone"):
    origin = Path(tmp) / "origin.git"
    clone = Path(tmp) / name
    subprocess.run(["git", "init", "-q", "--bare", "-b", "development", str(origin)], check=True)
    subprocess.run(["git", "clone", "-q", str(origin), str(clone)], check=True, capture_output=True)
    for k, v in (("user.name", "t"), ("user.email", "t@e.com")):
        _git(clone, "config", k, v)
    _commit(clone, "README.md", "hello", "initial")
    _git(clone, "push", "-q", "-u", "origin", "development")
    return origin, clone


def write_gh_stub(tmp, origin, merged):
    """A `gh` that answers `repo view` with the fixture origin and `pr list` with `merged`."""
    stub = Path(tmp) / "gh"
    data = Path(tmp) / "gh-merged.json"
    data.write_text(json.dumps(merged))
    stub.write_text(
        "#!/usr/bin/env bash\n"
        f"if [ \"$1\" = repo ]; then printf '{{\"url\":\"%s\"}}\\n' '{origin}'; exit 0; fi\n"
        f"if [ \"$1\" = pr ]; then cat '{data}'; exit 0; fi\n"
        "echo 'stub: unexpected args' >&2; exit 9\n"
    )
    stub.chmod(0o755)
    return stub


def squash_land(clone, branch, number):
    """Land `branch` on development the way this repo does: squash, then push. Returns
    (head_of_branch, squash_commit) and the gh-shaped merged record."""
    head = _git(clone, "rev-parse", branch).stdout.strip()
    _git(clone, "checkout", "-q", "development")
    _git(clone, "merge", "--squash", "-q", branch)
    _git(clone, "commit", "-q", "-m", f"squash #{number}")
    mc = _git(clone, "rev-parse", "HEAD").stdout.strip()
    _git(clone, "push", "-q", "origin", "development")
    _git(clone, "checkout", "-q", branch)
    return head, mc, {"number": number, "state": "MERGED", "headRefOid": head,
                      "mergeCommit": {"oid": mc}, "baseRefName": "development"}


def stub_env(**kv):
    env = {k: v for k, v in kv.items()}
    return mock.patch.dict(os.environ, env)


class _Fixture(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="gh534."))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        scan_clones._merged_pr_cache.clear()
        self.origin, self.clone = make_origin_and_clone(self.tmp)
        # Fixtures live under $TMPDIR, which is not a SAFE_ROOT: widen for the duration.
        p = mock.patch.object(scan_clones, "DEFAULT_SAFE_ROOTS", DEFAULT_SAFE_ROOTS + [self.tmp])
        p.start()
        self.addCleanup(p.stop)
        # Never talk to GitHub: default gh stub knows no merged PRs.
        self.gh = write_gh_stub(self.tmp, self.origin, [])
        e = mock.patch.dict(os.environ, {GH_BIN_ENV: str(self.gh)})
        e.start()
        self.addCleanup(e.stop)

    def inspect(self, path=None, **kw):
        return inspect_checkout(path or self.clone, **kw)


# --- A.1 roots ----------------------------------------------------------------------------

class TestA1Roots(unittest.TestCase):
    def test_marathon_clones_is_a_safe_root(self):
        self.assertIn(Path.home() / "marathon-clones", DEFAULT_SAFE_ROOTS)

    def test_doc_and_code_root_lists_agree(self):
        """THE PIN: WORKTREE-SAFETY.md's SAFE_ROOTS example IS DEFAULT_SAFE_ROOTS."""
        doc = (REPO / "WORKTREE-SAFETY.md").read_text()
        block = re.search(r"SAFE_ROOTS = \[(.*?)\]", doc, re.S).group(1)
        doc_roots = [Path.home().joinpath(*re.findall(r'"([^"]+)"', line))
                     for line in block.splitlines() if "Path.home()" in line]
        self.assertEqual(doc_roots, DEFAULT_SAFE_ROOTS)

    def test_strict_root_prefix_sibling_and_symlink_escape_are_rejected(self):
        tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, tmp, True)
        root = tmp / "XYZ-forge"
        root.mkdir()
        never = {tmp, Path("/")}
        ok, _ = is_safe_deletable_path(root, safe_roots=[root], never_delete=never)
        self.assertFalse(ok, "the root itself must not be deletable")
        sib = tmp / "XYZ-forge-foo" / "clone"
        sib.mkdir(parents=True)
        ok, msg = is_safe_deletable_path(sib, safe_roots=[root], never_delete=never)
        self.assertFalse(ok, f"prefix sibling accepted: {msg}")
        outside = tmp / "outside"
        outside.mkdir()
        link = root / "escapee"
        link.symlink_to(outside)
        ok, msg = is_safe_deletable_path(link, safe_roots=[root], never_delete=never)
        self.assertFalse(ok, f"symlink escaping the root accepted: {msg}")
        inside = root / "clone"
        inside.mkdir()
        self.assertTrue(is_safe_deletable_path(inside, safe_roots=[root], never_delete=never)[0])


# --- A.2 provenance ---------------------------------------------------------------------

class TestA2Provenance(_Fixture):
    def _feature(self, name="feat/x", commits=1):
        _git(self.clone, "checkout", "-q", "-b", name)
        for i in range(commits):
            _commit(self.clone, f"{name.replace('/', '-')}-{i}.txt", f"work {i}\n")
        return _git(self.clone, "rev-parse", "HEAD").stdout.strip()

    def _use_gh(self, merged):
        gh = write_gh_stub(self.tmp, self.origin, merged)
        os.environ[GH_BIN_ENV] = str(gh)
        scan_clones._merged_pr_cache.clear()

    def test_i_squash_merged_twin_is_landed(self):
        self._feature()
        head, mc, rec = squash_land(self.clone, "feat/x", 7)
        self._use_gh([rec])
        prov = classify_local_refs(self.clone)
        self.assertTrue(prov["ok"], prov)
        self.assertEqual(prov["unlanded"], [])
        self.assertTrue(any("PR #7" in l for l in prov["landed"]), prov["landed"])
        self.assertEqual(self.inspect()["disposition"], "SAFE_REMOVE_CLONE")

    def test_ii_unlanded_branch_is_preserved_naming_ref_and_commit(self):
        head = self._feature("feat/unlanded")
        info = self.inspect()
        self.assertEqual(info["disposition"], "PRESERVE_UNPUSHED")
        self.assertIn("refs/heads/feat/unlanded", info["disposition_reason"])
        self.assertIn(head[:10], info["disposition_reason"], "the commit must be named, not just the ref")

    def test_iii_multi_commit_squash_is_landed(self):
        self._feature("feat/multi", commits=3)
        head, mc, rec = squash_land(self.clone, "feat/multi", 8)
        self._use_gh([rec])
        self.assertEqual(self.inspect()["disposition"], "SAFE_REMOVE_CLONE")

    def test_iv_changed_conflict_resolution_is_preserved(self):
        self._feature("feat/res")
        head, mc, rec = squash_land(self.clone, "feat/res", 9)
        # The landed content differs from the branch: amend the squash commit upstream.
        _git(self.clone, "checkout", "-q", "development")
        (self.clone / "feat-res-0.txt").write_text("resolved differently\n")
        _git(self.clone, "commit", "-q", "-a", "--amend", "--no-edit")
        mc2 = _git(self.clone, "rev-parse", "HEAD").stdout.strip()
        _git(self.clone, "push", "-q", "-f", "origin", "development")
        _git(self.clone, "checkout", "-q", "feat/res")
        rec["mergeCommit"]["oid"] = mc2
        self._use_gh([rec])
        info = self.inspect()
        self.assertEqual(info["disposition"], "PRESERVE_UNPUSHED")
        self.assertIn("PR #9", info["disposition_reason"])
        self.assertIn("differs", info["disposition_reason"])

    def test_v_whitespace_only_mismatch_is_preserved(self):
        self._feature("feat/ws")
        head, mc, rec = squash_land(self.clone, "feat/ws", 10)
        _git(self.clone, "checkout", "-q", "development")
        (self.clone / "feat-ws-0.txt").write_text("work 0 \n")  # trailing space only
        _git(self.clone, "commit", "-q", "-a", "--amend", "--no-edit")
        rec["mergeCommit"]["oid"] = _git(self.clone, "rev-parse", "HEAD").stdout.strip()
        _git(self.clone, "push", "-q", "-f", "origin", "development")
        _git(self.clone, "checkout", "-q", "feat/ws")
        self._use_gh([rec])
        self.assertEqual(self.inspect()["disposition"], "PRESERVE_UNPUSHED")

    def test_vi_gone_upstream_is_enumerated_not_skipped(self):
        head = self._feature("feat/gone")
        _git(self.clone, "push", "-q", "-u", "origin", "feat/gone")
        _git(self.clone, "push", "-q", "origin", "--delete", "feat/gone")
        _git(self.clone, "fetch", "-q", "--prune")
        track = _git(self.clone, "for-each-ref", "--format=%(upstream:track)", "refs/heads/feat/gone").stdout
        self.assertIn("gone", track, "fixture did not produce a [gone] upstream")
        info = self.inspect()
        self.assertEqual(info["disposition"], "PRESERVE_UNPUSHED")
        self.assertIn(head[:10], info["disposition_reason"])

    def test_vii_detached_head_and_local_only_ref_are_enumerated(self):
        head = self._feature("feat/det")
        _git(self.clone, "checkout", "-q", "--detach")
        _git(self.clone, "branch", "-D", "feat/det")
        _git(self.clone, "update-ref", "refs/private/keep", head)
        prov = classify_local_refs(self.clone)
        self.assertTrue(prov["ok"], prov)
        joined = "\n".join(prov["unlanded"])
        self.assertIn("HEAD (detached)", joined)
        self.assertIn("refs/private/keep", joined)

    def test_viii_gh_failure_preserves(self):
        self._feature("feat/ghfail")
        head, mc, rec = squash_land(self.clone, "feat/ghfail", 11)
        bad = self.tmp / "gh-bad"
        bad.write_text("#!/usr/bin/env bash\necho boom >&2; exit 1\n")
        bad.chmod(0o755)
        os.environ[GH_BIN_ENV] = str(bad)
        scan_clones._merged_pr_cache.clear()
        info = self.inspect()
        self.assertEqual(info["disposition"], "PRESERVE_UNPUSHED")
        self.assertIn("lookup unavailable", info["disposition_reason"])

    def test_ix_extra_commit_beyond_the_matched_pr_head_is_preserved(self):
        self._feature("feat/extra")
        head, mc, rec = squash_land(self.clone, "feat/extra", 12)
        self._use_gh([rec])
        self.assertEqual(self.inspect()["disposition"], "SAFE_REMOVE_CLONE", "control")
        later = _commit(self.clone, "later.txt", "after the PR\n")
        info = self.inspect()
        self.assertEqual(info["disposition"], "PRESERVE_UNPUSHED")
        self.assertIn(later[:10], info["disposition_reason"])

    def test_remote_identity_mismatch_preserves(self):
        self._feature("feat/ident")
        head, mc, rec = squash_land(self.clone, "feat/ident", 13)
        gh = write_gh_stub(self.tmp, "https://github.com/someone/else", [rec])
        os.environ[GH_BIN_ENV] = str(gh)
        scan_clones._merged_pr_cache.clear()
        info = self.inspect()
        self.assertEqual(info["disposition"], "PRESERVE_UNPUSHED")
        self.assertIn("gh answered for", info["disposition_reason"])

    def test_cherry_is_not_consulted(self):
        src = (REPO / "skills/merge-cleanup/scripts/scan_clones.py").read_text()
        tree = ast.parse(src)
        for node in ast.walk(tree):
            if isinstance(node, ast.Constant) and isinstance(node.value, str):
                self.assertNotEqual(node.value, "cherry", "git cherry must not be an authorization input")


# --- A.3 dirt -----------------------------------------------------------------------------

class TestA3Dirt(_Fixture):
    def test_twelve_dirty_files_all_named(self):
        for i in range(12):
            (self.clone / f"dirty-{i:02d}.txt").write_text("x")
        info = self.inspect()
        self.assertEqual(info["disposition"], "PRESERVE_DIRTY")
        self.assertEqual(info["dirty_count"], 12)
        self.assertEqual(len(info["dirty_files"]), 12)
        for i in range(12):
            self.assertIn(f"dirty-{i:02d}.txt", info["disposition_reason"])

    def test_no_regenerable_allowance(self):
        for name in ("harnesses.db", "releases.db.bak", "MARATHON-PLAN-2026-09-09.md"):
            (self.clone / name).write_text("x")
        self.assertEqual(self.inspect()["disposition"], "PRESERVE_DIRTY")


# --- A.4 session evidence -----------------------------------------------------------------

def tick(root, *args):
    env = dict(os.environ, TICK_REPO_ROOT=str(root))
    return subprocess.run([str(TICK)] + list(args), env=env, cwd=tempfile.gettempdir(),
                          capture_output=True, text=True)


class TestA4TickClaims(_Fixture):
    def setUp(self):
        super().setUp()
        self.assertEqual(tick(self.clone, "init").returncode, 0)
        _git(self.clone, "add", "-A")  # .tick/ is untracked otherwise -> dirty would mask the case
        self.gitignore()

    def gitignore(self):
        (self.clone / ".gitignore").write_text(".tick/\n")
        _git(self.clone, "add", ".gitignore")
        _git(self.clone, "commit", "-q", "-m", "ignore tick")
        _git(self.clone, "push", "-q", "origin", "development")

    def claim(self, task="T-1", agent="agy"):
        self.assertEqual(tick(self.clone, "log", "task.created", task, "--agent", agent).returncode, 0)
        r = tick(self.clone, "claim", task, "--agent", agent, "--paths", "README.md")
        self.assertEqual(r.returncode, 0, r.stderr)

    def test_i_canonical_empty_root_is_eligible(self):
        self.assertEqual(self.inspect()["disposition"], "SAFE_REMOVE_CLONE")

    def test_ii_active_claim_names_task_and_agent(self):
        self.claim("T-42", "codex")
        info = self.inspect()
        self.assertEqual(info["disposition"], "ACTIVE_TICK_CLAIM")
        self.assertIn("T-42", info["disposition_reason"])
        self.assertIn("codex", info["disposition_reason"])

    def test_iii_claim_is_read_from_the_fold_not_state_md(self):
        """THE PIN: STATE.md stale ("_(none)_") or deleted, the event log still says claimed."""
        self.claim("T-7", "agy")
        state = self.clone / ".tick" / "STATE.md"
        state.write_text("# Coordination State\n\n## Claimed\n_(none)_\n")
        self.assertEqual(self.inspect()["disposition"], "ACTIVE_TICK_CLAIM")
        state.unlink()
        self.assertEqual(self.inspect()["disposition"], "ACTIVE_TICK_CLAIM")

    def test_iv_unreadable_event_log_preserves(self):
        ev = self.clone / ".tick" / "events"
        ev.chmod(0)
        self.addCleanup(ev.chmod, 0o755)
        info = self.inspect()
        self.assertEqual(info["disposition"], "PRESERVE_UNVERIFIED_SESSION")
        self.assertIn("tick claims", info["disposition_reason"])

    def test_v_directory_shaped_lock_counts_as_a_claim(self):
        (self.clone / ".tick" / "locks" / "relay-driver").mkdir(parents=True)
        info = self.inspect()
        self.assertEqual(info["disposition"], "ACTIVE_TICK_CLAIM")
        self.assertIn("relay-driver", info["disposition_reason"])

    def test_vi_linked_worktree_uses_the_parent_coordination_root(self):
        wt = self.tmp / "wt"
        _git(self.clone, "worktree", "add", "-q", str(wt), "-b", "feat/wt")
        self.claim("T-wt", "agy")
        self.assertEqual(scan_clones.coordination_root(wt), self.clone.resolve())
        info = inspect_checkout(wt)
        self.assertEqual(info["disposition"], "ACTIVE_TICK_CLAIM")
        self.assertIn("T-wt", info["disposition_reason"])

    def test_vii_tick_absent_or_failing_preserves(self):
        with stub_env(**{TICK_BIN_ENV: str(self.tmp / "no-such-tick")}):
            info = self.inspect()
        self.assertEqual(info["disposition"], "PRESERVE_UNVERIFIED_SESSION")
        bad = self.tmp / "tick-bad"
        bad.write_text("#!/usr/bin/env bash\nexit 1\n")
        bad.chmod(0o755)
        with stub_env(**{TICK_BIN_ENV: str(bad)}):
            info = self.inspect()
        self.assertEqual(info["disposition"], "PRESERVE_UNVERIFIED_SESSION")

    def test_xii_events_dir_missing_is_refused_not_empty(self):
        """THE PIN (GH-561-narrowed): a coordination surface present WITHOUT a readable log is
        refused — the verb must not trust an absent log. A bare telemetry-only .tick/ takes the
        GH-561 uninitialized path instead (test_xiv)."""
        shutil.rmtree(self.clone / ".tick" / "events")
        (self.clone / ".tick" / "STATE.md").write_text("(stale derived snapshot)\n")
        r = tick(self.clone, "claims", "--json")
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("events-dir-missing", r.stderr)
        info = self.inspect()
        self.assertEqual(info["disposition"], "PRESERVE_UNVERIFIED_SESSION")
        self.assertIn("events-dir-missing", info["disposition_reason"])

    def test_xiv_telemetry_only_tick_is_uninitialized_eligible(self):
        """GH-561: a .tick/ holding ONLY gate-run artifacts (telemetry/, orphan-backups/) with no
        coordination surface is claim-free by construction — exit 0, uninitialized flagged."""
        shutil.rmtree(self.clone / ".tick")
        (self.clone / ".tick" / "telemetry").mkdir(parents=True)
        (self.clone / ".tick" / "orphan-backups").mkdir()
        r = tick(self.clone, "claims", "--json")
        self.assertEqual(r.returncode, 0, r.stderr)
        payload = json.loads(r.stdout)
        self.assertEqual(payload["claimed"], [])
        self.assertTrue(payload["uninitialized"])

    def test_tick_claims_writes_nothing(self):
        self.claim("T-ro", "agy")
        state = self.clone / ".tick" / "STATE.md"
        rejected = self.clone / ".tick" / "rejected.jsonl"
        for p in (state, rejected):
            if p.exists():
                p.unlink()
        r = tick(self.clone, "claims", "--json")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(json.loads(r.stdout)["claimed"][0]["task"], "T-ro")
        self.assertFalse(state.exists(), "tick claims wrote STATE.md")
        self.assertFalse(rejected.exists(), "tick claims wrote rejected.jsonl")

    def test_ast_inspect_checkout_calls_inspect_tick_claims(self):
        """THE PIN: a call, not a mention in a string or comment."""
        src = (REPO / "skills/merge-cleanup/scripts/scan_clones.py").read_text()
        fn = next(n for n in ast.walk(ast.parse(src)) if isinstance(n, ast.FunctionDef) and n.name == "inspect_checkout")
        calls = [n for n in ast.walk(fn) if isinstance(n, ast.Call) and getattr(n.func, "id", "") == "inspect_tick_claims"]
        self.assertTrue(calls, "inspect_checkout never calls inspect_tick_claims")
        self.assertNotIn("STATE.md", ast.get_source_segment(src, fn) or "", "inspect_checkout must not read STATE.md")


class TestA4OpenHandles(_Fixture):
    def setUp(self):
        super().setUp()
        if not shutil.which("lsof"):
            self.skipTest("lsof not installed")

    def test_viii_real_idle_directory_is_verified_idle(self):
        """THE PIN: lsof exits 1 on an idle dir; exit-code gating would preserve forever."""
        self.assertNotEqual(os.getcwd(), str(self.clone))
        h = inspect_open_handles(self.clone)
        self.assertTrue(h["verified"], h)
        self.assertFalse(h["active"], h)
        self.assertEqual(self.inspect()["disposition"], "SAFE_REMOVE_CLONE")

    def test_ix_held_descriptor_is_active_process_naming_the_pid(self):
        holder = subprocess.Popen([sys.executable, "-c",
                                   "import sys,time; f=open(sys.argv[1]); print('open', flush=True); time.sleep(60)",
                                   str(self.clone / "README.md")], stdout=subprocess.PIPE, text=True)
        self.addCleanup(holder.kill)
        holder.stdout.readline()
        h = inspect_open_handles(self.clone)
        self.assertTrue(h["verified"], h)
        self.assertTrue(h["active"], h)
        self.assertIn(holder.pid, [x["pid"] for x in h["holders"]])
        info = self.inspect()
        self.assertEqual(info["disposition"], "ACTIVE_PROCESS")
        self.assertIn(str(holder.pid), info["disposition_reason"])

    def test_x_unreadable_subdirectory_is_incomplete_not_idle(self):
        """Isolated: the WARNING must actually be produced, and no live descriptor of our own."""
        if os.geteuid() == 0:
            self.skipTest("root can read everything; the traversal failure cannot be injected")
        sub = self.clone / "sealed"
        sub.mkdir()
        (sub / "f").write_text("x")
        sub.chmod(0)
        self.addCleanup(sub.chmod, 0o755)
        raw = subprocess.run(["lsof", "-F", "pcn", "+D", str(self.clone)], capture_output=True, text=True, cwd=tempfile.gettempdir())
        self.assertIn("WARNING", raw.stderr, "fixture did not produce the lsof traversal warning")
        h = inspect_open_handles(self.clone)
        self.assertFalse(h["verified"], h)
        self.assertEqual(h["holders"], [])
        self.assertIn("WARNING", h["details"])
        info = self.inspect()
        self.assertEqual(info["disposition"], "PRESERVE_UNVERIFIED_SESSION")
        self.assertIn("WARNING", info["disposition_reason"])

    def test_xi_lsof_absent_preserves(self):
        with stub_env(**{LSOF_BIN_ENV: str(self.tmp / "no-lsof")}):
            info = self.inspect()
        self.assertEqual(info["disposition"], "PRESERVE_UNVERIFIED_SESSION")
        self.assertIn("lsof", info["disposition_reason"])

    def test_xiii_signal_killed_lsof_is_incomplete_even_with_empty_stderr(self):
        """THE PIN: completion is checked before stderr is trusted."""
        stub = self.tmp / "lsof-suicide"
        stub.write_text("#!/usr/bin/env bash\nkill -TERM $$\n")
        stub.chmod(0o755)
        with stub_env(**{LSOF_BIN_ENV: str(stub)}):
            h = inspect_open_handles(self.clone)
            info = self.inspect()
        self.assertFalse(h["verified"], h)
        self.assertIn("signal", h["details"])
        self.assertEqual(info["disposition"], "PRESERVE_UNVERIFIED_SESSION")

    def test_own_process_is_not_a_holder(self):
        # The scanner's own CWD is outside the checkout, but a caller may hold a handle inside
        # via an ancestor; those are excluded, everything else stays.
        self.assertIn(os.getpid(), scan_clones._ancestor_pids())
        self.assertIn(os.getppid(), scan_clones._ancestor_pids())


# --- A.5 fresh inspection + fail-closed queries -------------------------------------------

class TestA5FailClosed(_Fixture):
    def _fail(self, prefix):
        real = scan_clones.run_git

        def flaky(cwd, args):
            if list(args[:len(prefix)]) == list(prefix):
                return subprocess.CompletedProcess(args=args, returncode=1, stdout="", stderr=f"{' '.join(prefix)} refused")
            return real(cwd, args)
        return mock.patch.object(scan_clones, "run_git", side_effect=flaky)

    def test_baseline_is_eligible(self):
        self.assertEqual(self.inspect()["disposition"], "SAFE_REMOVE_CLONE")

    def test_each_failed_git_query_preserves_naming_it(self):
        for prefix, label in ((["stash", "list"], "git stash list"), (["worktree", "list"], "git worktree list"),
                              (["for-each-ref"], "git for-each-ref"), (["fetch"], "git fetch")):
            with self._fail(prefix):
                info = self.inspect()
            self.assertEqual(info["disposition"], "PRESERVE_UNVERIFIED_QUERY", label)
            self.assertIn(label, info["disposition_reason"])

    def test_failed_status_preserves(self):
        with self._fail(["status"]):
            info = self.inspect()
        self.assertEqual(info["disposition"], "PRESERVE_UNVERIFIED_QUERY")
        self.assertIn("git status", info["disposition_reason"])


class TestA5FreshInspection(unittest.TestCase):
    """Two checkouts, a mocked Phase 5 landing between scan and teardown."""

    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp(prefix="gh534-a5."))
        self.addCleanup(shutil.rmtree, self.tmp, True)
        scan_clones._merged_pr_cache.clear()
        self.roots = self.tmp / "roots"
        self.roots.mkdir()
        self.origin, self.primary = make_origin_and_clone(self.tmp, "primary")
        self.task = self.roots / "task-clone"
        subprocess.run(["git", "clone", "-q", str(self.origin), str(self.task)], check=True, capture_output=True)
        for k, v in (("user.name", "t"), ("user.email", "t@e.com")):
            _git(self.task, "config", k, v)
        _git(self.task, "checkout", "-q", "-b", "feat/land")
        self.head = _commit(self.task, "feature.txt", "feature\n")
        p = mock.patch.object(scan_clones, "DEFAULT_SAFE_ROOTS", DEFAULT_SAFE_ROOTS + [self.roots])
        p.start()
        self.addCleanup(p.stop)
        e = mock.patch.dict(os.environ, {GH_BIN_ENV: str(write_gh_stub(self.tmp, self.origin, []))})
        e.start()
        self.addCleanup(e.stop)

    def _land(self):
        """What Phase 5 does remotely: the task branch becomes reachable from origin/development."""
        _git(self.task, "push", "-q", "origin", "feat/land:development")

    def _run(self, on_merge=None, verdict_ready=True):
        prs = [{"number": 1, "baseRefName": "development", "title": "t", "files": [], "body": ""}]
        verdict = {"path": str(self.primary), "integration_branch": "development", "current_branch": "development",
                   "is_clean": True, "dirty_count": 0, "on_integration_branch": True, "unpushed_on_integration": 0,
                   "can_ff": True, "operation_in_progress": "", "operation_evidence_ok": True,
                   "evidence_complete": True, "landing_ready": True, "blockers": []}
        removed = []

        def fake_merge(pr_num, repo_path, strategy="squash", dry_run=True):
            if on_merge:
                on_merge()
            return True

        def fake_teardown(c, dry_run=True):
            removed.append((c["name"], c["disposition"], "scan_disposition" in c))
            return True

        argv = ["merge_cleanup.py", "--primary", str(self.primary), "--root", str(self.roots), "--execute"]
        with mock.patch.object(sys, "argv", argv), \
             mock.patch.object(merge_cleanup, "prune_dangling_skill_symlinks"), \
             mock.patch.object(merge_cleanup, "inspect_primary_landing", return_value=verdict), \
             mock.patch.object(merge_cleanup, "refresh_pr", return_value={"number": 1, "state": "OPEN", "mergeable": "MERGEABLE", "headRefOid": "b" * 40, "headRefName": "feat/land", "baseRefName": "development", "labels": [], "mergeCommit": None}), \
             mock.patch.object(merge_cleanup, "prepare_landing_clone", side_effect=lambda pr, primary, branch, wd: {"clone": wd, "merge_rc": 0, "error": ""}), \
             mock.patch.object(merge_cleanup, "pre_merge_ledger_gate", return_value={"green": True, "failures": [], "diagnostics": []}), \
             mock.patch.object(merge_cleanup, "execute_pr_merge", side_effect=fake_merge), \
             mock.patch.object(merge_cleanup, "run_post_merge_reconcile", return_value=True), \
             mock.patch.object(merge_cleanup, "teardown_checkout", side_effect=fake_teardown), \
             mock.patch.object(merge_cleanup, "fetch_open_prs", return_value=prs):
            rc = merge_cleanup.main()
        return rc, removed

    def test_preserve_unpushed_at_scan_becomes_eligible_after_landing(self):
        """THE PIN: Phase 6 rescans every candidate, not only the scan-time survivors."""
        scan = scan_directories([self.roots], primary_repo=self.primary)
        self.assertEqual([c["disposition"] for c in scan if c["name"] == "task-clone"], ["PRESERVE_UNPUSHED"])
        rc, removed = self._run(on_merge=self._land)
        self.assertEqual(rc, 0)
        self.assertEqual(removed, [("task-clone", "SAFE_REMOVE_CLONE", True)])

    def test_dirty_between_scan_and_teardown_is_not_removed(self):
        self._land()
        rc, removed = self._run(on_merge=lambda: (self.task / "late.txt").write_text("late"))
        self.assertEqual(rc, 0)
        self.assertEqual(removed, [])

    def test_new_claim_between_scan_and_teardown_blocks(self):
        self._land()
        (self.task / ".gitignore").write_text(".tick/\n")
        _git(self.task, "add", ".gitignore")
        _git(self.task, "commit", "-q", "-m", "ignore")
        _git(self.task, "push", "-q", "origin", "feat/land:development")

        def claim():
            self.assertEqual(tick(self.task, "init").returncode, 0)
            tick(self.task, "log", "task.created", "T-late", "--agent", "agy")
            self.assertEqual(tick(self.task, "claim", "T-late", "--agent", "agy", "--paths", "x").returncode, 0)
        rc, removed = self._run(on_merge=claim)
        self.assertEqual(removed, [])

    def test_new_local_ref_between_scan_and_teardown_blocks(self):
        self._land()
        rc, removed = self._run(on_merge=lambda: _commit(self.task, "more.txt", "more\n"))
        self.assertEqual(removed, [])

    def test_teardown_refuses_a_stale_scan_record(self):
        info = inspect_checkout(self.task, integration_branch="development")
        info["disposition"] = "SAFE_REMOVE_CLONE"  # forged, no scan_disposition -> not fresh
        self.assertFalse(merge_cleanup.teardown_checkout(info, dry_run=False))
        self.assertTrue(self.task.exists())

    def test_fault_injection_at_teardown_time_blocks_removal(self):
        self._land()
        for prefix, label in ((["stash", "list"], "git stash list"), (["worktree", "list"], "git worktree list"),
                              (["for-each-ref"], "git for-each-ref"), (["fetch"], "git fetch")):
            real = scan_clones.run_git

            def flaky(cwd, args, _p=prefix):
                if list(args[:len(_p)]) == list(_p):
                    return subprocess.CompletedProcess(args=args, returncode=1, stdout="", stderr="refused")
                return real(cwd, args)
            with mock.patch.object(scan_clones, "run_git", side_effect=flaky):
                rc, removed = self._run()
            self.assertEqual(removed, [], label)
        # A `tick claims` failure only matters where a coordination root exists: give it one.
        (self.task / ".gitignore").write_text(".tick/\n")
        _git(self.task, "add", ".gitignore")
        _git(self.task, "commit", "-q", "-m", "ignore")
        _git(self.task, "push", "-q", "origin", "feat/land:development")
        self.assertEqual(tick(self.task, "init").returncode, 0)
        self.assertEqual(self._run()[1], [("task-clone", "SAFE_REMOVE_CLONE", True)], "control: eligible with tick")
        with mock.patch.dict(os.environ, {TICK_BIN_ENV: str(self.tmp / "no-tick")}):
            self.assertEqual(self._run()[1], [], "tick claims")
        with mock.patch.dict(os.environ, {LSOF_BIN_ENV: str(self.tmp / "no-lsof")}):
            self.assertEqual(self._run()[1], [], "lsof")


if __name__ == "__main__":
    unittest.main()
