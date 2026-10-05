#!/usr/bin/env python3
"""GH-789 / GH-965 manual verification matrix (evidence script, NOT a registered suite — GH-831).

Run from a disposable full clone:  python3 TESTS-RESULTS/2026-10-05+GH-789/manual_matrix.py [-v]

The cases are the approved source's own (commit 08bb0655, test/gh534_phase_b_tests.py and
test/gh436-merge-cleanup.py), moved here instead of into the registry, plus the cases Codex plan
QA asked for (relay-system/2026-10-05/gh789-port-plan-qa.md, F1-F3). They reuse the existing
fixtures (LedgerFixture, TestPrimaryLandingEvidence setUp) rather than defining new ones.
Exit 0 only if every case passes; any failure, error or zero collected cases exits 1.
"""
import contextlib
import importlib.util
import io
import subprocess
import sys
import unittest
import unittest.mock as mock
from argparse import Namespace
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "skills" / "2-daily" / "merge-cleanup" / "scripts"))
sys.path.insert(0, str(REPO / "test"))

import gh534_phase_b_tests as phase_b  # noqa: E402  (existing fixtures, not re-run here)
import ledger_merge  # noqa: E402
import merge_cleanup  # noqa: E402
import toposort_prs  # noqa: E402
from ledger_merge import resolve_ledger_conflict  # noqa: E402
from scan_clones import inspect_primary_landing  # noqa: E402

_spec = importlib.util.spec_from_file_location("gh436_merge_cleanup", REPO / "test" / "gh436-merge-cleanup.py")
gh436 = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(gh436)

LedgerFixture, _git, commit_all, park, _app = (phase_b.LedgerFixture, phase_b._git, phase_b.commit_all,
                                              phase_b.park, phase_b._app)


# ── Stale REBASE_HEAD on the primary (GH-789 item 1) ─────────────────────────────────────────────
class RebaseHeadCases(unittest.TestCase):
    setUp = gh436.TestPrimaryLandingEvidence.setUp
    tearDown = gh436.TestPrimaryLandingEvidence.tearDown

    def orphan(self):
        head = subprocess.run(["git", "rev-parse", "HEAD"], cwd=self.repo, capture_output=True, text=True, check=True).stdout.strip()
        subprocess.run(["git", "update-ref", "REBASE_HEAD", head], cwd=self.repo, check=True)
        return head

    def prepare(self, **overrides):
        args = dict(integration_branch="development", execute=True, scan_only=False, prs_only=False, teardown_only=False)
        args.update(overrides)
        return merge_cleanup.prepare_primary_landing(self.repo, Namespace(**args))

    def test_orphan_rebase_ref_is_pruned_only_for_execute_landing(self):
        head = self.orphan()
        info = inspect_primary_landing(self.repo)
        self.assertEqual(info["stale_rebase_head"], head)
        self.assertFalse(info["landing_ready"])
        for mode in ({"execute": False}, {"scan_only": True}, {"prs_only": True}, {"teardown_only": True}):
            with self.subTest(mode=mode):
                self.assertFalse(self.prepare(**mode)["landing_ready"])
                self.assertTrue((self.repo / ".git/REBASE_HEAD").exists())
        self.assertTrue(self.prepare()["landing_ready"])
        self.assertFalse((self.repo / ".git/REBASE_HEAD").exists())

    def test_active_rebase_or_dirty_tree_never_prunes(self):
        self.orphan()
        for name in ("rebase-merge", "rebase-apply", "sequencer"):
            marker = self.repo / ".git" / name
            marker.mkdir()
            self.assertFalse(self.prepare()["landing_ready"])
            self.assertTrue((self.repo / ".git/REBASE_HEAD").exists())
            marker.rmdir()
        (self.repo / "README.md").write_text("dirty")
        self.assertFalse(self.prepare()["landing_ready"])
        self.assertTrue((self.repo / ".git/REBASE_HEAD").exists())

    def test_active_rebase_directory_without_head_is_blocked(self):
        (self.repo / ".git/rebase-merge").mkdir()
        self.assertFalse(inspect_primary_landing(self.repo)["landing_ready"])

    def test_linked_worktree_marker_is_resolved_by_git(self):
        linked = Path(self.temp_dir) / "linked"
        subprocess.run(["git", "worktree", "add", "--detach", str(linked)], cwd=self.repo, capture_output=True, check=True)
        try:
            head = self.orphan()
            subprocess.run(["git", "update-ref", "REBASE_HEAD", head], cwd=linked, check=True)
            info = inspect_primary_landing(linked)
            self.assertEqual(info["stale_rebase_head"], head)
            self.assertFalse(info["ready_except_stale_rebase"], "detached worktree must not be auto-repaired")
            self.assertTrue((self.repo / ".git/REBASE_HEAD").exists())
        finally:
            subprocess.run(["git", "worktree", "remove", str(linked)], cwd=self.repo, capture_output=True, check=True)

    def test_compare_delete_failure_preserves_block(self):
        self.orphan()
        real = merge_cleanup.run_git

        def fail(cwd, args):
            if args[:2] == ["update-ref", "-d"]:
                return subprocess.CompletedProcess(args, 1, stdout="", stderr="ref changed")
            return real(cwd, args)
        with mock.patch.object(merge_cleanup, "run_git", side_effect=fail):
            self.assertFalse(self.prepare()["landing_ready"])
        self.assertTrue((self.repo / ".git/REBASE_HEAD").exists())

    def test_rebase_head_moved_after_inspection_is_not_deleted(self):
        """Codex F3: compare-and-delete uses the OBSERVED oid, so a REBASE_HEAD that moved between
        inspection and deletion survives (real git, no mocked failure)."""
        observed = self.orphan()
        tree = subprocess.run(["git", "rev-parse", "HEAD^{tree}"], cwd=self.repo, capture_output=True, text=True, check=True).stdout.strip()
        moved = subprocess.run(["git", "commit-tree", tree, "-m", "other"], cwd=self.repo, capture_output=True, text=True, check=True).stdout.strip()
        self.assertNotEqual(moved, observed)
        real = merge_cleanup.run_git

        def move_then_delete(cwd, args):
            if args[:3] == ["update-ref", "-d", "REBASE_HEAD"]:
                subprocess.run(["git", "update-ref", "REBASE_HEAD", moved], cwd=self.repo, check=True)
            return real(cwd, args)
        with mock.patch.object(merge_cleanup, "run_git", side_effect=move_then_delete):
            self.assertFalse(self.prepare()["landing_ready"])
        now = subprocess.run(["git", "rev-parse", "REBASE_HEAD"], cwd=self.repo, capture_output=True, text=True, check=True).stdout.strip()
        self.assertEqual(now, moved, "a REBASE_HEAD that changed after inspection must not be deleted")


# ── Drafts (GH-789 item 2, GH-965) ───────────────────────────────────────────────────────────────
class DraftCases(LedgerFixture):
    def run_capture(self):
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            rc = self.run_main()
        return rc, out.getvalue() + err.getvalue()

    def test_f1_draft_and_independent_exit_zero_one_merge_draft_named(self):
        """Codex F1 (f1): draft + independent → exit 0, exactly one merge, draft named in summary."""
        for n in (1, 3):
            self.branch(f"feat/{n}", n, lambda r, n=n: (r / f"note{n}").write_text("x"))
        self.st["prs"]["1"]["isDraft"] = True
        self.save()
        rc, text = self.run_capture()
        self.assertEqual(rc, 0, text[-2000:])
        st = self.load()
        self.assertEqual([c[2] for c in st["calls"] if c[:2] == ["pr", "merge"]], ["3"])
        self.assertIn("Skipped draft PR(s): #1", text)

    def test_draft_blocks_hard_dependent_but_independent_lands(self):
        """Codex F1 (f2): hard dependent of a draft is never attempted; independent lands; exit 3."""
        for n in (1, 2, 3):
            self.branch(f"feat/{n}", n, lambda r, n=n: (r / f"note{n}").write_text("x"))
        self.st["prs"]["1"]["isDraft"] = True
        self.st["prs"]["2"]["body"] = "Depends on #1"
        self.save()
        with mock.patch.object(merge_cleanup, "prepare_landing_clone", wraps=merge_cleanup.prepare_landing_clone) as prep:
            self.assertEqual(self.run_main(), 3)
        st = self.load()
        self.assertEqual([st["prs"][str(n)]["state"] for n in (1, 2, 3)], ["OPEN", "OPEN", "MERGED"])
        self.assertEqual([c.args[0]["number"] for c in prep.call_args_list], [3])
        self.assertFalse(any(c[:3] in (["pr", "merge", "1"], ["pr", "merge", "2"]) for c in st["calls"]))
        for c in st["calls"]:
            if c[:2] in (["pr", "list"], ["pr", "view"]):
                self.assertIn("isDraft", c[c.index("--json") + 1])

    def test_draft_appearing_during_poll_never_reaches_repair(self):
        self.branch("feat/a", 1, lambda r: (r / "note").write_text("x"))
        info = merge_cleanup.refresh_pr(1, self.primary)
        info["mergeable"] = "UNKNOWN"
        draft = dict(info, isDraft=True)
        with mock.patch.object(merge_cleanup, "refresh_pr_with_retry", side_effect=[info, draft]), \
             mock.patch.object(merge_cleanup, "_sleep"), \
             mock.patch.object(merge_cleanup, "prepare_landing_clone") as prep:
            self.assertEqual(self.run_main(), 0)
        prep.assert_not_called()

    def test_draft_appearing_after_gate_never_reaches_merge_api(self):
        self.branch("feat/a", 1, lambda r: (r / "note").write_text("x"))
        real = merge_cleanup.pre_merge_ledger_gate

        def gate(*args, **kwargs):
            result = real(*args, **kwargs)
            self.load()["prs"]["1"]["isDraft"] = True
            self.save()
            return result
        with mock.patch.object(merge_cleanup, "pre_merge_ledger_gate", side_effect=gate):
            self.assertEqual(self.run_main(), 0)
        self.assertFalse(any(c[:2] == ["pr", "merge"] for c in self.load()["calls"]))

    def test_changed_head_after_gate_is_not_merged(self):
        self.branch("feat/a", 1, lambda r: (r / "note").write_text("x"))
        real = merge_cleanup.refresh_pr_with_retry
        calls = 0

        def refresh(*args):
            nonlocal calls
            info = real(*args)
            calls += 1
            if calls == 2:
                info["headRefOid"] = "f" * 40
            return info
        with mock.patch.object(merge_cleanup, "refresh_pr_with_retry", side_effect=refresh):
            self.assertEqual(self.run_main(), 2)
        self.assertEqual(calls, 2)
        self.assertFalse(any(c[:2] == ["pr", "merge"] for c in self.load()["calls"]))

    def collision_queue(self, dependency=True):
        for n in (1, 2, 3):
            self.branch(f"feat/{n}", n, lambda r, n=n: (r / f"note{n}").write_text("x"))
        self.st["prs"]["1"]["body"] = "Depends on #3" if dependency else ""
        for n, files in ((1, ["a"]), (2, ["a", "b"]), (3, ["b"])):
            self.st["prs"][str(n)]["files"] = files
        self.st["prs"]["3"]["isDraft"] = True
        self.save()

    def test_collision_cycle_never_bypasses_draft_prerequisite(self):
        self.collision_queue()
        ordered, _, _ = merge_cleanup.toposort_prs(merge_cleanup.fetch_open_prs(str(self.primary)))
        order = [p["number"] for p in ordered]
        self.assertLess(order.index(3), order.index(1), "soft edges defeated hard dependency order")
        with mock.patch.object(merge_cleanup, "prepare_landing_clone", wraps=merge_cleanup.prepare_landing_clone) as prep:
            self.assertEqual(self.run_main(), 3)
        self.assertEqual([c.args[0]["number"] for c in prep.call_args_list], [2])
        self.assertEqual([self.load()["prs"][str(n)]["state"] for n in (1, 2, 3)], ["OPEN", "MERGED", "OPEN"])

    def test_soft_collisions_without_hard_dependency_do_not_block(self):
        self.collision_queue(dependency=False)
        self.assertEqual(self.run_main(), 0)
        self.assertEqual([self.load()["prs"][str(n)]["state"] for n in (1, 2, 3)], ["MERGED", "MERGED", "OPEN"])

    def test_true_hard_cycle_never_merges_numerical_fallback(self):
        self.collision_queue(dependency=False)
        self.st["prs"]["1"]["body"] = "Depends on #2"
        self.st["prs"]["2"]["body"] = "Depends on #1"
        self.st["prs"]["3"]["isDraft"] = False
        self.save()
        with mock.patch.object(merge_cleanup, "prepare_landing_clone", wraps=merge_cleanup.prepare_landing_clone) as prep:
            self.assertEqual(self.run_main(), 3)
        self.assertEqual([c.args[0]["number"] for c in prep.call_args_list], [3])

    def test_push_boundary_draft_is_the_named_refusal_and_never_pushes(self):
        """Codex F2 (unit): an OPEN draft at the push boundary returns DRAFT_REFUSAL, no git push."""
        info = {"number": 1, "headRefOid": "a" * 40, "headRefName": "feat/a"}
        with mock.patch.object(merge_cleanup, "refresh_pr", return_value=dict(info, state="OPEN", isDraft=True)), \
             mock.patch.object(merge_cleanup, "_net_git") as git:
            ok, why = merge_cleanup.push_resolved_head(info, self.primary, "b" * 40, self.primary)
        self.assertEqual((ok, why), (False, merge_cleanup.DRAFT_REFUSAL))
        git.assert_not_called()
        with mock.patch.object(merge_cleanup, "refresh_pr", return_value=dict(info, state="CLOSED", isDraft=False)), \
             mock.patch.object(merge_cleanup, "_net_git") as git:
            ok, why = merge_cleanup.push_resolved_head(info, self.primary, "b" * 40, self.primary)
        self.assertFalse(ok)
        self.assertNotEqual(why, merge_cleanup.DRAFT_REFUSAL, "a closed PR must keep the fail-closed path")
        git.assert_not_called()

    def test_phase4_table_shows_draft_cells(self):
        """GH-965: the Phase 4 table has a Draft column, yes/no per PR."""
        table = toposort_prs.format_pr_table([
            {"number": 1, "title": "a", "headRefName": "a", "baseRefName": "development", "isDraft": True},
            {"number": 2, "title": "b", "headRefName": "b", "baseRefName": "development", "isDraft": False},
        ])
        rows = table.splitlines()
        self.assertIn("| Draft |", rows[0])
        col = rows[0].split("|").index(" Draft ")
        self.assertEqual([r.split("|")[col].strip() for r in rows[2:]], ["yes", "no"])


# ── CHANGELOG union (GH-789 item 3) ──────────────────────────────────────────────────────────────
class ChangelogUnitCases(unittest.TestCase):
    base = "# Changelog\n\n## 2026-09-01 — base\n\nKeep these exact bytes.\n"
    a = "## 2026-09-24 — Alpha\n\nAlpha addition.\n\n"
    b = "## 2026-09-24 — Beta\n\nBeta addition.\n\n"

    def prepend(self, block):
        return self.base.replace("## 2026", block + "## 2026", 1)

    def test_same_date_additions_preserve_history_and_deduplicate(self):
        result = ledger_merge.union_changelog(self.base, self.prepend(self.a), self.prepend(self.b + self.a))
        self.assertEqual(result, self.prepend(self.b + self.a))
        self.assertEqual(result.count("Alpha addition."), 1)

    def test_ambiguous_or_modified_history_is_rejected(self):
        cases = [self.prepend(self.a + self.a),
                 self.prepend(self.a).replace("# Changelog", "# Changed", 1),
                 self.prepend(self.a).replace("exact", "changed"),
                 self.prepend(self.a).replace("Keep these exact bytes.\n", ""),
                 self.prepend(self.a.replace("2026-09-24", "2026-99-99")),
                 self.prepend("## not a date\nbody\n"),
                 self.prepend("## 2026-09-24 — Empty\n\n"),
                 self.prepend(self.a.replace("Alpha addition.", "<<<<<<< ours")), ""]
        for text in cases:
            with self.subTest(text=text), self.assertRaises(ValueError):
                ledger_merge.union_changelog(self.base, self.prepend(self.b), text)
        with self.assertRaises(ValueError):
            ledger_merge.union_changelog(self.base, self.prepend(self.a), self.prepend(self.a.replace("Alpha addition.", "Other body.")))

    def test_fenced_or_html_heading_is_not_sorted_as_an_entry(self):
        for opening, closing in (("```markdown", "```"), ("~~~markdown", "~~~"), ("<!--", "-->"), ("Example <!--", "-->")):
            addition = self.a + opening + "\n## 2026-09-25 — Example\n\nExample only.\n" + closing + "\n\n"
            with self.subTest(opening=opening), self.assertRaisesRegex(ValueError, "fenced or HTML"):
                ledger_merge.union_changelog(self.base, self.prepend(addition), self.prepend(self.b))

    def test_reordered_base_sections_are_rejected(self):
        extra = "## 2026-08-01 — older\n\nOlder bytes.\n"
        base = self.base + extra
        ours = self.prepend(self.a) + extra
        theirs = "# Changelog\n\n" + self.b + extra + self.base.split("\n\n", 1)[1]
        with self.assertRaises(ValueError):
            ledger_merge.union_changelog(base, ours, theirs)


class ChangelogMergeCases(LedgerFixture):
    def conflict(self, ledger=True, edit_history=False):
        base = ChangelogUnitCases.base
        (self.seed / "CHANGELOG.md").write_text(base)
        commit_all(self.seed, "changelog base")
        _git(self.seed, "push", "-q", "origin", "development")
        _git(self.primary, "fetch", "-q", "origin")
        _git(self.primary, "merge", "--ff-only", "origin/development")

        def edit(r, block, n):
            (r / "CHANGELOG.md").write_text(base.replace("## 2026", block + "## 2026", 1))
            if edit_history and n == 201:
                f = r / "CHANGELOG.md"
                f.write_text(f.read_text().replace("exact bytes", "edited bytes"))
            if ledger:
                park(r, n)
        self.branch("feat/a", 1, lambda r: edit(r, ChangelogUnitCases.a, 200))
        self.branch("feat/b", 2, lambda r: edit(r, ChangelogUnitCases.b, 201))
        subprocess.run([str(self.gh), "pr", "merge", "1"], check=True, capture_output=True)
        prep = merge_cleanup.prepare_landing_clone(merge_cleanup.refresh_pr(2, self.primary), self.primary, "development", self.tmp)
        self.assertNotEqual(prep["merge_rc"], 0, "fixture must conflict")
        return prep["clone"]

    def test_ledger_plus_changelog_resolves_without_loss(self):
        c = self.conflict()
        result = resolve_ledger_conflict(c, execute=True)
        self.assertTrue(result["resolved"], result)
        text = (c / "CHANGELOG.md").read_text()
        self.assertIn(ChangelogUnitCases.a, text)
        self.assertIn(ChangelogUnitCases.b, text)
        self.assertTrue(text.endswith(ChangelogUnitCases.base.split("\n\n", 1)[1]))
        self.assertEqual(_app(c, "check").returncode, 0)
        self.assertFalse((c / "releases.db.bak").exists())
        self.assertEqual(_git(c, "ls-files", "-u").stdout, "")

    def test_changelog_only_conflict_and_dry_run(self):
        c = self.conflict(ledger=False)
        self.assertEqual(ledger_merge.extract_conflict_set(c)[1], {"CHANGELOG.md"})
        before = (c / "CHANGELOG.md").read_bytes(), _git(c, "ls-files", "--stage").stdout
        result = resolve_ledger_conflict(c, execute=False)
        self.assertIn("DRY RUN", result["reason"])
        self.assertEqual(before, ((c / "CHANGELOG.md").read_bytes(), _git(c, "ls-files", "--stage").stdout))
        self.assertTrue(resolve_ledger_conflict(c, execute=True)["resolved"])

    def test_base_edit_hands_off_before_any_writer_or_file_change(self):
        c = self.conflict(edit_history=True)
        before = (c / "CHANGELOG.md").read_bytes(), _git(c, "ls-files", "--stage").stdout
        with mock.patch.object(ledger_merge, "_run") as writer:
            result = resolve_ledger_conflict(c, execute=True)
        self.assertTrue(result["handoff"])
        writer.assert_not_called()
        self.assertEqual(before, ((c / "CHANGELOG.md").read_bytes(), _git(c, "ls-files", "--stage").stdout))

    def test_repaired_changelog_reaches_landed_outcome(self):
        self.conflict()
        self.assertEqual(self.run_main(), 0)
        self.assertEqual(self.load()["prs"]["2"]["state"], "MERGED")
        self.assertEqual(self.dev_rows(), [100, 101, 200, 201])
        text = (self.primary / "CHANGELOG.md").read_text()
        self.assertIn(ChangelogUnitCases.a, text)
        self.assertIn(ChangelogUnitCases.b, text)

    def test_draft_at_repaired_push_is_skipped_and_independent_lands(self):
        """Codex F2 (integration): draft observed at the push boundary after B1 → zero push and merge
        for that PR, named skip, run continues and exits 0 (no other non-landing)."""
        self.conflict()
        real_refresh = merge_cleanup.refresh_pr

        def refresh(n, *args, **kwargs):
            info = real_refresh(n, *args, **kwargs)
            return dict(info, isDraft=True) if n == 2 and refresh.push_phase else info
        refresh.push_phase = False
        real_push = merge_cleanup.push_resolved_head

        def push(*args, **kwargs):
            refresh.push_phase = True
            return real_push(*args, **kwargs)
        out = io.StringIO()
        with mock.patch.object(merge_cleanup, "refresh_pr", side_effect=refresh), \
             mock.patch.object(merge_cleanup, "push_resolved_head", side_effect=push), \
             contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            rc = self.run_main()
        st = self.load()
        self.assertEqual(rc, 0, out.getvalue()[-2000:])
        self.assertEqual(st["prs"]["2"]["state"], "OPEN")
        self.assertFalse(any(c[:3] == ["pr", "merge", "2"] for c in st["calls"]))
        self.assertIn("SKIPPED (draft before repaired-head push", out.getvalue())

    def test_draft_after_repaired_push_is_skipped(self):
        self.conflict()
        real = merge_cleanup.push_resolved_head

        def push(*args, **kwargs):
            result = real(*args, **kwargs)
            self.assertTrue(result[0], result)
            self.load()["prs"]["2"]["isDraft"] = True
            self.save()
            return result
        with mock.patch.object(merge_cleanup, "push_resolved_head", side_effect=push):
            self.assertEqual(self.run_main(), 0)
        st = self.load()
        self.assertEqual(st["prs"]["2"]["state"], "OPEN")
        self.assertFalse(any(c[:3] == ["pr", "merge", "2"] for c in st["calls"]))


CASES = (RebaseHeadCases, DraftCases, ChangelogUnitCases, ChangelogMergeCases)

if __name__ == "__main__":
    suite = unittest.TestSuite(unittest.defaultTestLoader.loadTestsFromTestCase(c) for c in CASES)
    if suite.countTestCases() == 0:
        print("RESULT: FAIL (no cases collected)")
        sys.exit(1)
    result = unittest.TextTestRunner(verbosity=2 if "-v" in sys.argv else 1).run(suite)
    print(f"RESULT: {'ALL PASS' if result.wasSuccessful() else 'FAIL'} ({suite.countTestCases()} cases)")
    sys.exit(0 if result.wasSuccessful() else 1)
