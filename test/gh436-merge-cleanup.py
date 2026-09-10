#!/usr/bin/env python3
"""test/gh436-merge-cleanup.py — Unit tests for /merge-cleanup skill.

Tests:
1. Deletable path containment & NEVER_DELETE boundary guards.
2. PR dependency parsing and topological sorting.
3. Git checkout inspection & disposition classification.
"""

import os
import sys
import tempfile
import subprocess
import shutil
import unittest
import unittest.mock as mock
from pathlib import Path

# Add skill scripts to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "skills" / "merge-cleanup" / "scripts"))

from scan_clones import (
    _within,
    scan_directories,
    inspect_primary_landing,
    is_safe_deletable_path,
    inspect_checkout,
    inspect_driver_lock,
    DEFAULT_SAFE_ROOTS,
    DEFAULT_NEVER_DELETE
)
import merge_cleanup
import scan_clones
from merge_cleanup import prune_dangling_skill_symlinks
from toposort_prs import (
    parse_pr_dependencies,
    extract_touched_files,
    toposort_prs
)


class TestMergeCleanupSafety(unittest.TestCase):
    def test_within_logic(self):
        parent = Path("/a/b")
        child = Path("/a/b/c")
        self.assertTrue(_within(child, parent))
        self.assertFalse(_within(parent, parent))  # child == parent rejected
        self.assertFalse(_within(Path("/a/b_other"), parent))
        self.assertFalse(_within(Path("/a"), parent))

    def test_safe_deletable_path_boundaries(self):
        safe_root = Path("/tmp/test_safe_root")
        safe_root.mkdir(parents=True, exist_ok=True)
        never_delete = {Path("/tmp/test_safe_root"), Path.home(), Path("/")}

        child = safe_root / "repo_clone"
        child.mkdir(parents=True, exist_ok=True)

        # Child inside safe root
        ok, msg = is_safe_deletable_path(child, safe_roots=[safe_root], never_delete=never_delete)
        self.assertTrue(ok)

        # Safe root itself is rejected
        ok, msg = is_safe_deletable_path(safe_root, safe_roots=[safe_root], never_delete=never_delete)
        self.assertFalse(ok)
        self.assertIn("NEVER_DELETE", msg)

        # Protected system root
        ok, msg = is_safe_deletable_path(Path("/"), safe_roots=[safe_root], never_delete=never_delete)
        self.assertFalse(ok)

        # Path outside safe roots
        outside = Path("/tmp/outside_repo")
        outside.mkdir(parents=True, exist_ok=True)
        ok, msg = is_safe_deletable_path(outside, safe_roots=[safe_root], never_delete=never_delete)
        self.assertFalse(ok)
        self.assertIn("SAFE_ROOTS", msg)


class TestTopologicalSort(unittest.TestCase):
    def test_parse_dependencies(self):
        body1 = "This fix depends on #123 and is blocked by https://github.com/HiQS-Labs/XYZ-forge/pull/456."
        deps = parse_pr_dependencies(body1, "feat: implement X")
        self.assertEqual(deps, {123, 456})

        body2 = "No dependencies here."
        deps2 = parse_pr_dependencies(body2, "fix: bug Y")
        self.assertEqual(deps2, set())

    def test_toposort_linear_chain(self):
        prs = [
            {"number": 3, "title": "PR 3", "body": "Depends on #2", "createdAt": "2026-09-01T03:00:00Z"},
            {"number": 1, "title": "PR 1", "body": "Initial base", "createdAt": "2026-09-01T01:00:00Z"},
            {"number": 2, "title": "PR 2", "body": "Depends on #1", "createdAt": "2026-09-01T02:00:00Z"},
        ]
        ordered, _, _ = toposort_prs(prs)
        ordered_nums = [p["number"] for p in ordered]
        self.assertEqual(ordered_nums, [1, 2, 3])

    def test_toposort_file_collision_ordering(self):
        prs = [
            {"number": 20, "title": "PR 20", "body": "", "createdAt": "2026-09-01T02:00:00Z", "files": [{"path": "shared.py"}]},
            {"number": 10, "title": "PR 10", "body": "", "createdAt": "2026-09-01T01:00:00Z", "files": [{"path": "shared.py"}]},
        ]
        ordered, _, warnings = toposort_prs(prs)
        ordered_nums = [p["number"] for p in ordered]
        # PR 10 is older, so it should merge before PR 20
        self.assertEqual(ordered_nums, [10, 20])
        self.assertTrue(any("File collision" in w for w in warnings))


class TestCheckoutInspection(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.repo_dir = Path(self.temp_dir) / "test_repo"
        self.repo_dir.mkdir()
        subprocess.run(["git", "init"], cwd=self.repo_dir, capture_output=True, check=True)
        subprocess.run(["git", "config", "user.name", "Test User"], cwd=self.repo_dir, check=True)
        subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=self.repo_dir, check=True)

        # Initial commit
        (self.repo_dir / "README.md").write_text("Hello")
        subprocess.run(["git", "add", "README.md"], cwd=self.repo_dir, check=True)
        subprocess.run(["git", "commit", "-m", "initial commit"], cwd=self.repo_dir, check=True)

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_clean_repo_inspection(self):
        info = inspect_checkout(self.repo_dir)
        self.assertTrue(info["is_git"])
        self.assertEqual(info["checkout_type"], "standalone_clone")
        self.assertTrue(info["is_clean"])
        self.assertEqual(info["stash_count"], 0)

    def test_dirty_repo_disposition(self):
        (self.repo_dir / "dirty.txt").write_text("uncommitted")
        info = inspect_checkout(self.repo_dir)
        self.assertFalse(info["is_clean"])
        self.assertEqual(info["disposition"], "PRESERVE_DIRTY")

    def test_driver_lock_inspection(self):
        lock_file = self.repo_dir / ".git" / "relay-driver.lock"
        lock_file.write_text(f"pid={os.getpid()}\nholder=test\n")
        lock_info = inspect_driver_lock(self.repo_dir)
        self.assertTrue(lock_info["locked"])
        self.assertTrue(lock_info["alive"])
        self.assertEqual(lock_info["pid"], os.getpid())


class TestPrimaryCheckoutIsInspectedFirst(unittest.TestCase):
    """Phase 0: the primary on-disk checkout is reviewed before any PR (fixed 2026-09-09).

    Two defects, both observed on a real run:
      1. `scan_directories` only inspected the primary if a SAFE_ROOT walk happened to reach it
         AND its directory name matched `--prefix`. A primary outside those roots, or under a
         non-matching prefix, was absent from the audit entirely while Phase 5 went on merging
         PRs into it and running reconciliation there.
      2. Nothing asserted the primary could actually RECEIVE the landing. Phase 5 merged every
         PR remotely and only then tried `git merge --ff-only`, so a dirty tree or a feature
         branch was discovered after the merges were already irreversible.
    """

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.origin = Path(self.temp_dir) / "origin.git"
        self.primary = Path(self.temp_dir) / "primary"
        self.elsewhere = Path(self.temp_dir) / "roots"
        self.elsewhere.mkdir()
        subprocess.run(["git", "init", "--bare", "-b", "development", str(self.origin)], capture_output=True, check=True)
        subprocess.run(["git", "clone", str(self.origin), str(self.primary)], capture_output=True, check=True)
        for k, v in (("user.name", "Test User"), ("user.email", "test@example.com")):
            subprocess.run(["git", "config", k, v], cwd=self.primary, check=True)
        (self.primary / "README.md").write_text("hello")
        subprocess.run(["git", "add", "README.md"], cwd=self.primary, check=True)
        subprocess.run(["git", "commit", "-m", "initial"], cwd=self.primary, capture_output=True, check=True)
        subprocess.run(["git", "push", "-u", "origin", "development"], cwd=self.primary, capture_output=True, check=True)

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_primary_is_scanned_even_when_prefix_and_roots_miss_it(self):
        """THE PIN: the primary is inspected because it is the primary, not because a scan found it."""
        found = scan_directories([self.elsewhere], prefix_filter="no-such-prefix", primary_repo=self.primary)
        names = [c["name"] for c in found]
        self.assertIn("primary", names, f"primary vanished from the audit: {names}")
        primary_rows = [c for c in found if c["disposition"] == "PRIMARY_CHECKOUT"]
        self.assertEqual(len(primary_rows), 1)
        # It is reported FIRST — the operator reads their own checkout before anyone else's.
        self.assertEqual(found[0]["disposition"], "PRIMARY_CHECKOUT")

    def test_primary_is_not_duplicated_when_the_scan_also_finds_it(self):
        found = scan_directories([Path(self.temp_dir)], prefix_filter="", primary_repo=self.primary)
        primary_rows = [c for c in found if c["disposition"] == "PRIMARY_CHECKOUT"]
        self.assertEqual(len(primary_rows), 1, "primary counted twice when the scan reached it too")

    def test_discovered_primary_is_promoted_above_an_earlier_sorting_sibling(self):
        """Round-1 QA (Codex): prepending only when unseen left a sibling repo above the operator's tree."""
        sibling = Path(self.temp_dir) / "aaa-sorts-first"
        sibling.mkdir()
        subprocess.run(["git", "init", str(sibling)], capture_output=True, check=True)
        found = scan_directories([Path(self.temp_dir)], prefix_filter="", primary_repo=self.primary)
        names = [c["name"] for c in found]
        self.assertIn("aaa-sorts-first", names, f"sibling missing from the scan: {names}")
        self.assertEqual(found[0]["disposition"], "PRIMARY_CHECKOUT",
                         f"primary was not first: {names}")

    def test_clean_primary_on_integration_branch_is_landing_ready(self):
        info = inspect_primary_landing(self.primary, integration_branch="development")
        self.assertTrue(info["landing_ready"], info["blockers"])
        self.assertEqual(info["blockers"], [])

    def test_dirty_primary_is_not_landing_ready(self):
        (self.primary / "scratch.txt").write_text("uncommitted")
        info = inspect_primary_landing(self.primary, integration_branch="development")
        self.assertFalse(info["landing_ready"])
        self.assertTrue(any("uncommitted" in b for b in info["blockers"]), info["blockers"])

    def test_primary_on_a_feature_branch_is_not_landing_ready(self):
        subprocess.run(["git", "checkout", "-b", "feat/whatever"], cwd=self.primary, capture_output=True, check=True)
        info = inspect_primary_landing(self.primary, integration_branch="development")
        self.assertFalse(info["landing_ready"])
        self.assertTrue(any("integration branch" in b for b in info["blockers"]), info["blockers"])

    def test_unpushed_commits_on_the_integration_branch_block_the_landing(self):
        """A squash-merge landing would silently skip these, which is how local work is lost."""
        (self.primary / "local-only.txt").write_text("never pushed")
        subprocess.run(["git", "add", "local-only.txt"], cwd=self.primary, check=True)
        subprocess.run(["git", "commit", "-m", "local only"], cwd=self.primary, capture_output=True, check=True)
        info = inspect_primary_landing(self.primary, integration_branch="development")
        self.assertEqual(info["unpushed_on_integration"], 1)
        self.assertFalse(info["landing_ready"])
        self.assertTrue(any("not on origin" in b for b in info["blockers"]), info["blockers"])

    def test_non_git_primary_reports_not_ready_rather_than_raising(self):
        info = inspect_primary_landing(Path(self.temp_dir) / "nowhere", integration_branch="development")
        self.assertFalse(info["landing_ready"])
        self.assertTrue(info["blockers"])


class TestPrimaryLandingEvidence(unittest.TestCase):
    """Round-1/2 QA (Codex): readiness must be AFFIRMATIVE, never the absence of a failure.

    Each case below mutates ONE condition away from a genuinely landing-ready baseline (a clone
    with a real `origin/development`), so it pins the condition it names. An earlier version
    built its fixture without a tracking ref, which made every case not-ready for the same
    reason and could not attest the operation gate independently (R2-5).
    """

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.origin = Path(self.temp_dir) / "origin.git"
        self.repo = Path(self.temp_dir) / "primary"
        subprocess.run(["git", "init", "--bare", "-b", "development", str(self.origin)], capture_output=True, check=True)
        subprocess.run(["git", "clone", str(self.origin), str(self.repo)], capture_output=True, check=True)
        for k, v in (("user.name", "Test User"), ("user.email", "test@example.com")):
            subprocess.run(["git", "config", k, v], cwd=self.repo, check=True)
        (self.repo / "README.md").write_text("hello")
        subprocess.run(["git", "add", "README.md"], cwd=self.repo, check=True)
        subprocess.run(["git", "commit", "-m", "initial"], cwd=self.repo, capture_output=True, check=True)
        subprocess.run(["git", "push", "-u", "origin", "development"], cwd=self.repo, capture_output=True, check=True)

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_baseline_is_genuinely_ready(self):
        """Control: every other case in this class mutates one condition away from THIS."""
        info = inspect_primary_landing(self.repo, integration_branch="development")
        self.assertTrue(info["landing_ready"], info["blockers"])
        self.assertTrue(info["evidence_complete"])

    def test_missing_tracking_ref_is_not_ready(self):
        """THE PIN: no origin/<branch> means unknown, not ready."""
        solo = Path(self.temp_dir) / "solo"
        solo.mkdir()
        subprocess.run(["git", "init", "-b", "development", str(solo)], capture_output=True, check=True)
        for k, v in (("user.name", "T"), ("user.email", "t@e.com")):
            subprocess.run(["git", "config", k, v], cwd=solo, check=True)
        (solo / "f.txt").write_text("x")
        subprocess.run(["git", "add", "f.txt"], cwd=solo, check=True)
        subprocess.run(["git", "commit", "-m", "c"], cwd=solo, capture_output=True, check=True)
        info = inspect_primary_landing(solo, integration_branch="development")
        self.assertFalse(info["landing_ready"], "a checkout with no landing target was declared ready")
        self.assertFalse(info["evidence_complete"])
        self.assertTrue(any("could not be resolved" in b for b in info["blockers"]), info["blockers"])

    def test_unfinished_merge_blocks_an_otherwise_ready_checkout(self):
        """THE PIN: mutates ONLY the operation condition away from the ready baseline."""
        self.assertTrue(inspect_primary_landing(self.repo, integration_branch="development")["landing_ready"])
        head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=self.repo,
                              capture_output=True, text=True, check=True).stdout.strip()
        (self.repo / ".git" / "MERGE_HEAD").write_text(head + "\n")
        info = inspect_primary_landing(self.repo, integration_branch="development")
        self.assertEqual(info["operation_in_progress"], "merge")
        self.assertFalse(info["landing_ready"])
        self.assertTrue(any("unfinished merge" in b for b in info["blockers"]), info["blockers"])

    def test_failed_operation_probe_is_not_ready(self):
        """THE PIN (R2-3): a probe that cannot answer must not read as 'no operation in progress'."""
        real = scan_clones.run_git

        def flaky(cwd, args):
            if args[:2] == ["rev-parse", "--git-path"]:
                return subprocess.CompletedProcess(args=args, returncode=1, stdout="", stderr="probe refused")
            return real(cwd, args)

        with mock.patch.object(scan_clones, "run_git", side_effect=flaky):
            info = inspect_primary_landing(self.repo, integration_branch="development")
        self.assertFalse(info["operation_evidence_ok"])
        self.assertFalse(info["landing_ready"], "a checkout with unknown operation state was declared ready")
        self.assertTrue(any("readiness is unknown" in b for b in info["blockers"]), info["blockers"])

    def test_unresolvable_home_path_reports_not_ready_instead_of_raising(self):
        """R2-4: ~unknown-user raises RuntimeError, not OSError."""
        info = inspect_primary_landing(Path("~no-such-user-xyz/repo"), integration_branch="development")
        self.assertFalse(info["landing_ready"])
        self.assertTrue(info["blockers"])

    def test_unreadable_git_reports_not_ready_instead_of_raising(self):
        with mock.patch("scan_clones.subprocess.run", side_effect=OSError("git not found")):
            info = inspect_primary_landing(self.repo, integration_branch="development")
        self.assertFalse(info["landing_ready"])
        self.assertTrue(info["blockers"])


class TestMergeCleanupOrchestration(unittest.TestCase):
    """Round-1 QA (Codex): the orchestrator's own paths, not just the helpers.

    Three defects lived above the helper layer: `--reconcile-pr` returned before Phase 0 was
    computed at all, `--integration-branch` was checked but `origin/development` was landed, and
    a primary the scan also found was left below its siblings in the audit.
    """

    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()
        self.primary = Path(self.temp_dir) / "primary"
        self.primary.mkdir()
        subprocess.run(["git", "init", "-b", "development", str(self.primary)], capture_output=True, check=True)

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def _run_main(self, argv, landing_ready):
        verdict = {
            "path": str(self.primary), "integration_branch": "development", "current_branch": "development",
            "is_clean": landing_ready, "dirty_count": 0, "on_integration_branch": True,
            "unpushed_on_integration": 0, "can_ff": landing_ready, "operation_in_progress": "",
            "evidence_complete": landing_ready, "landing_ready": landing_ready,
            "blockers": [] if landing_ready else ["synthetic blocker"],
        }
        with mock.patch.object(sys, "argv", ["merge_cleanup.py"] + argv), \
             mock.patch.object(merge_cleanup, "inspect_primary_landing", return_value=verdict) as insp, \
             mock.patch.object(merge_cleanup, "run_post_merge_reconcile") as reconcile, \
             mock.patch.object(merge_cleanup, "scan_directories", return_value=[]), \
             mock.patch.object(merge_cleanup, "fetch_open_prs", return_value=[]):
            rc = merge_cleanup.main()
        return rc, insp, reconcile

    def test_reconcile_pr_refuses_on_an_unready_primary(self):
        """THE PIN: --reconcile-pr must not launch governance writers into an unready tree."""
        rc, insp, reconcile = self._run_main(
            ["--primary", str(self.primary), "--reconcile-pr", "42", "--execute"], landing_ready=False)
        self.assertEqual(rc, 2)
        self.assertTrue(insp.called, "Phase 0 was never computed before --reconcile-pr")
        reconcile.assert_not_called()

    def test_reconcile_pr_proceeds_on_a_ready_primary(self):
        rc, insp, reconcile = self._run_main(
            ["--primary", str(self.primary), "--reconcile-pr", "42", "--execute"], landing_ready=True)
        self.assertEqual(rc, 0)
        self.assertTrue(insp.called)
        reconcile.assert_called_once()

    def test_integration_branch_is_threaded_into_the_readiness_check(self):
        _, insp, _ = self._run_main(
            ["--primary", str(self.primary), "--integration-branch", "main", "--scan-only"], landing_ready=True)
        self.assertEqual(insp.call_args.kwargs.get("integration_branch"), "main")

    def _drive_phase5(self, argv, landing_ready=True, prs=None, fetch_rc=0, verdicts=None, ff_rc=0, final_fetch_rc=0):
        """Drive main() through a NONEMPTY Phase 5, capturing the git commands it issues.

        Phase 5's tail calls `prune_dangling_skill_symlinks(dry_run=False)`, which walks the REAL
        `Path.home()` and unlinks dangling skill symlinks under `~/.claude`, `~/.codex` and
        `~/.gemini`. An orchestration test that leaves it live would delete the operator's own
        links from a disposable clone (R3-1). It is mocked here, and `Path.home` is redirected at
        a sentinel home besides, so a future unmocking fails a test instead of the operator's
        machine. Real pruning behaviour stays in TestDanglingSymlinkPrune, which owns its own
        temporary home.
        """
        def _verdict(ready):
            return {
                "path": str(self.primary), "integration_branch": "development", "current_branch": "development",
                "is_clean": ready, "dirty_count": 0, "on_integration_branch": True,
                "unpushed_on_integration": 0, "can_ff": ready, "operation_in_progress": "",
                "operation_evidence_ok": True, "evidence_complete": ready,
                "landing_ready": ready, "blockers": [] if ready else ["synthetic blocker"],
            }

        fake_home = Path(self.temp_dir) / "sentinel-home"
        (fake_home / ".claude" / "skills" / "ghost").mkdir(parents=True)
        self.sentinel = fake_home / ".claude" / "skills" / "ghost" / "SKILL.md"
        self.sentinel.symlink_to(fake_home / "deleted-source" / "SKILL.md")  # deliberately dangling

        git_calls = []

        def fake_git(cwd, args):
            git_calls.append(list(args))
            rc = (final_fetch_rc if args == ["fetch", "origin"] else fetch_rc) if args and args[0] == "fetch" else (ff_rc if args[:2] == ["merge", "--ff-only"] else 0)
            return subprocess.CompletedProcess(args=args, returncode=rc, stdout="", stderr="boom" if rc else "")

        insp_kwargs = ({"side_effect": [_verdict(v) for v in verdicts]} if verdicts
                       else {"return_value": _verdict(landing_ready)})

        with mock.patch.object(sys, "argv", ["merge_cleanup.py"] + argv), \
             mock.patch.object(Path, "home", return_value=fake_home), \
             mock.patch.object(merge_cleanup, "prune_dangling_skill_symlinks") as pruner, \
             mock.patch.object(merge_cleanup, "inspect_primary_landing", **insp_kwargs) as insp, \
             mock.patch.object(merge_cleanup, "run_git", side_effect=fake_git), \
             mock.patch.object(merge_cleanup, "execute_pr_merge", return_value=True) as merged, \
             mock.patch.object(merge_cleanup, "run_post_merge_reconcile") as reconcile, \
             mock.patch.object(merge_cleanup, "teardown_checkout") as teardown, \
             mock.patch.object(merge_cleanup, "scan_directories", return_value=[]), \
             mock.patch.object(merge_cleanup, "fetch_open_prs", return_value=prs or []):
            rc = merge_cleanup.main()
        self.pruner = pruner
        self.inspections = insp
        return rc, git_calls, merged, reconcile, teardown

    def test_orchestration_tests_never_prune_the_real_home(self):
        """THE PIN (R3-1): containment. Unmocking the pruner must fail HERE, not on a real machine."""
        prs = [{"number": 7, "baseRefName": "development", "title": "t", "files": [], "body": ""}]
        rc, _, _, _, _ = self._drive_phase5(["--primary", str(self.primary), "--execute"], prs=prs)
        self.assertEqual(rc, 0)
        self.pruner.assert_called_once()
        self.assertTrue(self.sentinel.is_symlink(),
                        "a dangling sentinel link was pruned — the real home was reachable from this test")

    def test_readiness_that_changes_after_a_successful_fetch_stops_the_merge(self):
        """THE PIN (R3-2): the SECOND inspection is what catches divergence found by the fetch."""
        prs = [{"number": 7, "baseRefName": "development", "title": "t", "files": [], "body": ""}]
        rc, _, merged, reconcile, teardown = self._drive_phase5(
            ["--primary", str(self.primary), "--execute"], prs=prs, verdicts=[True, False])
        self.assertEqual(self.inspections.call_count, 2, "the post-fetch re-inspection did not happen")
        self.assertEqual(rc, 2)
        merged.assert_not_called()
        reconcile.assert_not_called()
        teardown.assert_not_called()
        self.pruner.assert_not_called()

    def test_failed_fast_forward_stops_before_teardown(self):
        prs = [{"number": 7, "baseRefName": "development", "title": "t", "files": [], "body": ""}]
        rc, _, merged, _, teardown = self._drive_phase5(
            ["--primary", str(self.primary), "--execute"], prs=prs, ff_rc=1)
        merged.assert_called_once()
        self.assertNotEqual(rc, 0)
        teardown.assert_not_called()
        self.pruner.assert_not_called()

    def test_failed_final_fetch_stops_before_fast_forward_and_teardown(self):
        prs = [{"number": 7, "baseRefName": "development", "title": "t", "files": [], "body": ""}]
        rc, calls, merged, _, teardown = self._drive_phase5(
            ["--primary", str(self.primary), "--execute"], prs=prs, final_fetch_rc=1)
        merged.assert_called_once()
        self.assertNotEqual(rc, 0)
        self.assertFalse(any(c[:2] == ["merge", "--ff-only"] for c in calls))
        teardown.assert_not_called()
        self.pruner.assert_not_called()

    def test_fast_forward_targets_the_branch_that_was_checked(self):
        """THE PIN (R2-5): the ACTUAL git argument, not a string in the source."""
        prs = [{"number": 7, "baseRefName": "main", "title": "t", "files": [], "body": ""}]
        rc, git_calls, merged, _, _ = self._drive_phase5(
            ["--primary", str(self.primary), "--integration-branch", "main", "--execute"], prs=prs)
        self.assertEqual(rc, 0)
        merged.assert_called_once()
        ff = [c for c in git_calls if c[:2] == ["merge", "--ff-only"]]
        self.assertEqual(ff, [["merge", "--ff-only", "origin/main"]], git_calls)

    def test_failed_fetch_refuses_rather_than_certifying_cached_refs(self):
        """THE PIN (R2-1): READY cached evidence + a failed refresh must not merge."""
        prs = [{"number": 7, "baseRefName": "development", "title": "t", "files": [], "body": ""}]
        rc, _, merged, reconcile, teardown = self._drive_phase5(
            ["--primary", str(self.primary), "--execute"], prs=prs, fetch_rc=1)
        self.assertEqual(rc, 2)
        merged.assert_not_called()
        reconcile.assert_not_called()
        teardown.assert_not_called()

    def test_pr_targeting_another_base_is_refused(self):
        """THE PIN (R2-2): Phase 0 only vouches for the branch it checked."""
        prs = [{"number": 7, "baseRefName": "main", "title": "t", "files": [], "body": ""}]
        rc, _, merged, reconcile, _ = self._drive_phase5(
            ["--primary", str(self.primary), "--execute"], prs=prs)
        self.assertEqual(rc, 2)
        merged.assert_not_called()
        reconcile.assert_not_called()

    def test_matching_base_on_a_non_default_target_proceeds(self):
        prs = [{"number": 7, "baseRefName": "main", "title": "t", "files": [], "body": ""}]
        rc, _, merged, reconcile, _ = self._drive_phase5(
            ["--primary", str(self.primary), "--integration-branch", "main", "--execute"], prs=prs)
        self.assertEqual(rc, 0)
        merged.assert_called_once()
        reconcile.assert_called_once()

    def test_unready_primary_refuses_before_any_merge(self):
        prs = [{"number": 7, "baseRefName": "development", "title": "t", "files": [], "body": ""}]
        rc, _, merged, reconcile, teardown = self._drive_phase5(
            ["--primary", str(self.primary), "--execute"], prs=prs, landing_ready=False)
        self.assertEqual(rc, 2)
        merged.assert_not_called()
        reconcile.assert_not_called()
        teardown.assert_not_called()


class TestDanglingSymlinkPrune(unittest.TestCase):
    """Phase 6 prune missed two whole classes of dangling link (fixed 2026-09-05).

    Found when a run reported a clean prune and two dead links survived it:
      1. a hardcoded dir list skipped real installs (~/.gemini/antigravity-cli/skills)
      2. a depth-1 iterdir() could not see a dead link INSIDE a real skill directory
         (~/.claude/skills/front-door/SKILL.md)
    Sibling defect from the same run — Phase 5 merging vetoed PRs — is GH-444.
    """

    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self._real_home = Path.home
        # merge_cleanup resolves search roots through Path.home() at call time.
        Path.home = staticmethod(lambda: self.tmp)
        self.gone = self.tmp / "deleted-source-repo"

    def tearDown(self):
        Path.home = self._real_home
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _link(self, rel_path):
        p = self.tmp / rel_path
        p.parent.mkdir(parents=True, exist_ok=True)
        p.symlink_to(self.gone / rel_path.split("/")[-1])
        return p

    def test_finds_globbed_and_nested_dangling_links(self):
        # (2) dead link nested inside a real skill dir — invisible to a depth-1 scan
        nested = self._link(".claude/skills/front-door/SKILL.md")
        # (1) a skills dir that was never in the hardcoded list
        globbed = self._link(".gemini/antigravity-cli/skills/recon")
        live_target = self.tmp / "live-repo" / "real"
        live_target.mkdir(parents=True)
        healthy = self.tmp / ".claude" / "skills" / "healthy"
        healthy.symlink_to(live_target)

        prune_dangling_skill_symlinks(dry_run=False)

        self.assertFalse(nested.is_symlink(), "nested dangling link survived the prune")
        self.assertFalse(globbed.is_symlink(), "globbed-dir dangling link survived the prune")
        self.assertTrue(healthy.is_symlink(), "prune must not remove a healthy link")
        self.assertFalse(
            nested.parent.exists(), "skill dir left empty by the prune should be cleared"
        )

    def test_dry_run_mutates_nothing(self):
        nested = self._link(".claude/skills/front-door/SKILL.md")
        prune_dangling_skill_symlinks(dry_run=True)
        self.assertTrue(nested.is_symlink(), "dry run must not delete anything")

    def test_never_descends_through_a_symlinked_skills_dir(self):
        # A skills/ dir that is itself a symlink points back at a source repo; walking it
        # would delete real links there rather than install stubs.
        source = self.tmp / "source-repo" / "skills"
        source.mkdir(parents=True)
        (source / "dead").symlink_to(self.gone / "dead")
        linked_root = self.tmp / ".codex" / "skills"
        linked_root.parent.mkdir(parents=True, exist_ok=True)
        linked_root.symlink_to(source)

        prune_dangling_skill_symlinks(dry_run=False)

        self.assertTrue(
            (source / "dead").is_symlink(),
            "prune walked through a symlinked skills root into the source repo",
        )


if __name__ == "__main__":
    unittest.main()
